#!/usr/bin/env python3
"""Hook on-modify: reflete no ClickUp (via n8n) as mudancas de estado da task.

Eventos detectados (so para tasks com UDA clickup_id):
  start    task start               -> n8n muda o status para "em progresso"
  stop     task stop                -> n8n muda o status para "planejando"
  blocked  depends/+blocked novo    -> n8n muda o status para "pausado"
  done     task done                -> n8n muda para "finalizado", registra o
                                       tempo (intervalos do TimeWarrior) e
                                       publica as annotations como comentario
Sair do bloqueio vira `start` (se a task esta iniciada) ou `stop`.

Quem decide o status do ClickUp, e quem identifica os cards que vieram do Zammad
(campo "Ticket" preenchido), e o n8n. Cards do Zammad nao tem o status alterado,
mas o tempo (evento done) e registrado normalmente. Aqui so evitamos chamar o
webhook nos eventos de status de cards "Ticket#...", que o n8n ignoraria.

Contrato de hook do Taskwarrior (on-modify):
  - stdin: 2 linhas JSON (task antes, task depois)
  - stdout: o JSON da task depois (obrigatorio, e deve ser impresso primeiro)
  - exit 0: aceita a modificacao

Este hook NUNCA bloqueia a modificacao: qualquer erro vira aviso no stderr e o
exit code continua 0.

Ordem de execucao: o Taskwarrior roda os hooks em ordem alfabetica. O nome
`on-modify.timewarrior-clickup` vem DEPOIS de `on-modify.timewarrior`, entao o
intervalo ativo ja foi fechado (timew stop) quando este hook le o timew.

Configuracao (variaveis de ambiente, todas opcionais):
  CLICKUP_TIMELOG_WEBHOOK  URL do webhook do n8n
                           (default: http://localhost:5678/webhook/clickup-timelog)
"""
import json
import os
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone

WEBHOOK_URL = os.environ.get(
    "CLICKUP_TIMELOG_WEBHOOK",
    "http://localhost:5678/webhook/clickup-timelog",
)
TIMEOUT_S = 5
# Intervalos menores que isso (ms) sao ignorados (start/stop acidental).
MIN_DURATION_MS = 1000
# Annotations criadas ate N segundos apos a task sao o resumo automatico do sync.
INITIAL_ANNOTATION_WINDOW_S = 120
# Cards criados pelo Zammad comecam assim e sao gerenciados la.
ZAMMAD_PREFIX = "Ticket#"


def warn(msg):
    print(f"[clickup-timelog] {msg}", file=sys.stderr)


def parse_timew_ts(value):
    """'20260506T120000Z' (UTC) -> datetime aware."""
    return datetime.strptime(value, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)


def pending_count(uuids):
    """Quantas dessas tasks ainda estao pendentes (mesmo criterio do `task blocked`).

    O `depends` continua preenchido depois que a dependencia e concluida, entao
    so ele nao diz se a task esta bloqueada. rc.hooks=0 evita recursao.
    """
    if not uuids:
        return 0
    out = subprocess.run(
        ["task", "rc.hooks=0", "rc.verbose=nothing", "rc.confirmation=no",
         *uuids, "status:pending", "count"],
        capture_output=True, text=True, timeout=TIMEOUT_S, check=True,
    ).stdout
    return int(out.strip() or 0)


def is_blocked(task):
    """Bloqueada = depende de task ainda pendente (ver `task blocked`) ou tem a tag `blocked`."""
    if "blocked" in (task.get("tags") or []):
        return True
    depends = task.get("depends") or []
    if isinstance(depends, str):  # Taskwarrior 2.x: "uuid1,uuid2"
        depends = [d for d in depends.split(",") if d]
    return pending_count(depends) > 0


def detect_event(old, new):
    """Retorna start | stop | blocked | done | None."""
    if new.get("status") == "completed" and old.get("status") != "completed":
        return "done"
    if new.get("status") != "pending":
        return None

    was_blocked, now_blocked = is_blocked(old), is_blocked(new)
    started = "start" in new
    if now_blocked and not was_blocked:
        return "blocked"
    if was_blocked and not now_blocked:
        return "start" if started else "stop"
    if started and "start" not in old:
        return "start"
    if "start" in old and not started and not now_blocked:
        return "stop"
    return None


def collect_intervals(description, end_hint):
    """Intervalos do timew com a tag = descricao da task (mesma tag do hook oficial)."""
    out = subprocess.run(
        ["timew", "export", ":all", description],
        capture_output=True, text=True, timeout=TIMEOUT_S, check=True,
    ).stdout
    now = end_hint or datetime.now(timezone.utc)
    intervals = []
    for item in json.loads(out or "[]"):
        if description not in item.get("tags", []):
            continue
        start = parse_timew_ts(item["start"])
        end = parse_timew_ts(item["end"]) if item.get("end") else now
        duration_ms = int((end - start).total_seconds() * 1000)
        if duration_ms >= MIN_DURATION_MS:
            intervals.append(
                {"start": int(start.timestamp() * 1000), "duration": duration_ms}
            )
    return intervals


def collect_annotations(task):
    """Annotations feitas pelo usuario, para virarem comentarios no ClickUp.

    O workflow ClickUp -> TaskWarrior cria a task e logo em seguida anota o resumo
    do text_content do proprio card. Esse resumo ja esta no card, entao e ignorado:
    annotations criadas em ate INITIAL_ANNOTATION_WINDOW_S segundos apos a criacao
    da task nao sao enviadas.
    """
    created = parse_timew_ts(task["entry"]) if task.get("entry") else None
    out = []
    for a in task.get("annotations") or []:
        text = (a.get("description") or "").strip()
        if not text or not a.get("entry"):
            continue
        at = parse_timew_ts(a["entry"])
        if created and (at - created).total_seconds() <= INITIAL_ANNOTATION_WINDOW_S:
            continue
        out.append({"entry": int(at.timestamp() * 1000), "description": text})
    return out


def main():
    old = json.loads(sys.stdin.readline())
    new = json.loads(sys.stdin.readline())

    # Sempre devolve a task primeiro, antes de qualquer trabalho que possa falhar.
    print(json.dumps(new))
    sys.stdout.flush()

    clickup_id = new.get("clickup_id")
    description = new.get("description", "")
    if not clickup_id:
        return

    event = detect_event(old, new)
    if event is None:
        return

    # Cards do Zammad: o status e gerenciado la, mas o tempo vale. So o `done`
    # (que leva as horas) segue para o n8n; os demais eventos so mexeriam no status.
    if description.startswith(ZAMMAD_PREFIX) and event != "done":
        return

    intervals = []
    annotations = []
    if event == "done":
        annotations = collect_annotations(new)
        end_hint = parse_timew_ts(new["end"]) if new.get("end") else None
        intervals = collect_intervals(description, end_hint)
        if not intervals:
            warn(f"sem tempo registrado no timew para '{description}'; so o status sera alterado")

    payload = {
        "event": event,
        "clickupId": clickup_id,
        "uuid": new.get("uuid"),
        "description": description,
        "intervals": intervals,
        "annotations": annotations,
    }
    req = urllib.request.Request(
        WEBHOOK_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
        extra = (
            f", {len(intervals)} intervalo(s), {len(annotations)} comentario(s)"
            if event == "done" else ""
        )
        warn(f"evento '{event}' enviado ao n8n (HTTP {resp.status}{extra})")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # noqa: BLE001 - hook nunca pode quebrar o `task`
        warn(f"erro: {exc}")
    sys.exit(0)
