#!/usr/bin/env python3
"""
timew-summary.py — Resumo de tempo do Timewarrior para o QuickShell

Executa `timew export` e `task export` para calcular métricas de tempo
por contexto (work/personal) e projeto. Retorna JSON para o TimeDataManager.qml.

Categorização work/personal:
  - Tags do intervalo contêm 'work'     → tipo "work"
  - Tags do intervalo contêm 'personal' → tipo "personal"
  - Projeto do intervalo é 'Work'       → tipo "work"
  - Projeto do intervalo é 'Personal'   → tipo "personal"
  - Caso contrário                      → tipo "other"
"""

import json
import subprocess
import sys
from datetime import datetime, date, timedelta, timezone


# ---------------------------------------------------------------------------
# Helpers de segurança: subprocess com lista de argumentos (sem shell=True)
# ---------------------------------------------------------------------------

def run_cmd(args):
    """Executa um comando e retorna stdout como string. Nunca usa shell=True."""
    try:
        result = subprocess.run(
            args,
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            return None, result.stderr.strip()
        return result.stdout.strip(), None
    except FileNotFoundError:
        return None, f"Comando não encontrado: {args[0]}"
    except subprocess.TimeoutExpired:
        return None, f"Timeout ao executar: {args[0]}"
    except Exception as e:
        return None, str(e)


# ---------------------------------------------------------------------------
# Categorização de intervalos
# ---------------------------------------------------------------------------

def categorize(tags):
    """
    Determina o tipo (work/personal/other) com base nas tags do intervalo.
    As tags do Timewarrior herdam: description, project, tags da task (via hook).
    """
    tags_lower = [t.lower() for t in tags]

    if "work" in tags_lower:
        return "work"
    if "personal" in tags_lower:
        return "personal"

    # Verifica prefixo de subprojeto (ex: "work.Blog" → work)
    for tag in tags_lower:
        if tag.startswith("work.") or tag.startswith("work/"):
            return "work"
        if tag.startswith("personal.") or tag.startswith("personal/"):
            return "personal"

    return "other"


def extract_project(tags):
    """
    Extrai o nome do projeto das tags do intervalo.
    O hook passa o project como uma das tags. Heurística: tag que não contém
    espaço e não é 'work'/'personal' e não parece uma descrição longa.
    Retorna None se não identificar projeto claro.
    """
    reserved = {"work", "personal", "other"}
    for tag in tags:
        tag_lower = tag.lower()
        # Pula reservadas e descrições longas (com espaço)
        if tag_lower in reserved:
            continue
        if " " in tag:
            continue
        if len(tag) > 40:
            continue
        return tag
    return None


# ---------------------------------------------------------------------------
# Cálculo de segundos de um intervalo
# ---------------------------------------------------------------------------

def interval_seconds(interval, now_utc):
    """
    Calcula a duração em segundos de um intervalo do timew export.
    Um intervalo ativo não tem campo 'end' — usa now como fim.
    """
    start_str = interval.get("start")
    end_str = interval.get("end")

    if not start_str:
        return 0

    try:
        # Formato do timew: "20260820T143000Z"
        start = datetime.strptime(start_str, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
        if end_str:
            end = datetime.strptime(end_str, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
        else:
            end = now_utc
        seconds = int((end - start).total_seconds())
        return max(0, seconds)
    except (ValueError, TypeError):
        return 0


# ---------------------------------------------------------------------------
# Tarefa ativa via task export
# ---------------------------------------------------------------------------

def get_active_task():
    """
    Busca a tarefa ativa atual via `task export`.
    Retorna dict com description, project, elapsed_seconds ou None.
    """
    stdout, err = run_cmd(["task", "status:pending", "export"])
    if not stdout or err:
        return None

    try:
        tasks = json.loads(stdout)
    except (json.JSONDecodeError, ValueError):
        return None

    now_utc = datetime.now(timezone.utc)

    for task in tasks:
        start_str = task.get("start")
        if not start_str:
            continue

        try:
            start = datetime.strptime(start_str, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
            elapsed = int((now_utc - start).total_seconds())
            if elapsed < 0:
                elapsed = 0

            return {
                "description": task.get("description", ""),
                "project": task.get("project", ""),
                "elapsed_seconds": elapsed
            }
        except (ValueError, TypeError):
            continue

    return None


# ---------------------------------------------------------------------------
# Processamento dos intervalos do timew export
# ---------------------------------------------------------------------------

def process_intervals(intervals, target_date, now_utc):
    """
    Processa intervalos do timew export para uma data específica.
    Retorna: work_seconds, personal_seconds, other_seconds, by_project dict.
    """
    work_seconds = 0
    personal_seconds = 0
    other_seconds = 0
    by_project = {}  # project_name → {"seconds": int, "type": str}

    target_start = datetime(
        target_date.year, target_date.month, target_date.day,
        0, 0, 0, tzinfo=timezone.utc
    )
    target_end = target_start + timedelta(days=1)

    for interval in intervals:
        start_str = interval.get("start")
        end_str = interval.get("end")

        if not start_str:
            continue

        try:
            start = datetime.strptime(start_str, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
            if end_str:
                end = datetime.strptime(end_str, "%Y%m%dT%H%M%SZ").replace(tzinfo=timezone.utc)
            else:
                end = now_utc  # intervalo ativo
        except (ValueError, TypeError):
            continue

        # Intersecta o intervalo com a janela do dia alvo
        clipped_start = max(start, target_start)
        clipped_end = min(end, target_end)

        if clipped_start >= clipped_end:
            continue  # intervalo fora do dia

        seconds = int((clipped_end - clipped_start).total_seconds())
        if seconds <= 0:
            continue

        tags = interval.get("tags", [])
        tipo = categorize(tags)
        project = extract_project(tags)

        if tipo == "work":
            work_seconds += seconds
        elif tipo == "personal":
            personal_seconds += seconds
        else:
            other_seconds += seconds

        if project:
            if project not in by_project:
                by_project[project] = {"seconds": 0, "type": tipo}
            by_project[project]["seconds"] += seconds

    return work_seconds, personal_seconds, other_seconds, by_project


# ---------------------------------------------------------------------------
# Semana atual (Seg–Dom)
# ---------------------------------------------------------------------------

def get_week_dates(today):
    """Retorna lista de 7 dates da semana atual (segunda a domingo)."""
    monday = today - timedelta(days=today.weekday())
    return [monday + timedelta(days=i) for i in range(7)]


DAY_LABELS = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]


# ---------------------------------------------------------------------------
# Estrutura de saída vazia (fallback)
# ---------------------------------------------------------------------------

def empty_result(today, week_dates):
    return {
        "today": {
            "work_seconds": 0,
            "personal_seconds": 0,
            "other_seconds": 0,
            "by_project": [],
            "active_task": None
        },
        "week": [
            {
                "date": d.isoformat(),
                "label": DAY_LABELS[i],
                "work_seconds": 0,
                "personal_seconds": 0
            }
            for i, d in enumerate(week_dates)
        ]
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    now_utc = datetime.now(timezone.utc)
    today = now_utc.date()
    week_dates = get_week_dates(today)

    # Busca intervalos do timew para a semana (segunda até hoje + amanhã por segurança)
    monday = week_dates[0]
    monday_str = monday.strftime("%Y%m%dT000000Z")
    sunday_str = (week_dates[6] + timedelta(days=1)).strftime("%Y%m%dT000000Z")

    stdout, err = run_cmd(["timew", "export", monday_str, "-", sunday_str])

    if err or not stdout:
        result = empty_result(today, week_dates)
        result["error"] = err or "timew export retornou vazio"
        print(json.dumps(result))
        return

    try:
        intervals = json.loads(stdout)
    except (json.JSONDecodeError, ValueError):
        result = empty_result(today, week_dates)
        result["error"] = "JSON inválido do timew export"
        print(json.dumps(result))
        return

    if not isinstance(intervals, list):
        result = empty_result(today, week_dates)
        result["error"] = "timew export não retornou lista"
        print(json.dumps(result))
        return

    # --- Dados de hoje ---
    today_work, today_personal, today_other, today_by_project = process_intervals(
        intervals, today, now_utc
    )

    # Formata by_project como lista ordenada por seconds desc
    by_project_list = sorted(
        [
            {"project": k, "seconds": v["seconds"], "type": v["type"]}
            for k, v in today_by_project.items()
        ],
        key=lambda x: x["seconds"],
        reverse=True
    )

    # --- Tarefa ativa ---
    active_task = get_active_task()

    # --- Dados da semana ---
    week = []
    for i, day in enumerate(week_dates):
        w_sec, p_sec, _, _ = process_intervals(intervals, day, now_utc)
        week.append({
            "date": day.isoformat(),
            "label": DAY_LABELS[i],
            "work_seconds": w_sec,
            "personal_seconds": p_sec
        })

    result = {
        "today": {
            "work_seconds": today_work,
            "personal_seconds": today_personal,
            "other_seconds": today_other,
            "by_project": by_project_list,
            "active_task": active_task
        },
        "week": week
    }

    print(json.dumps(result))


if __name__ == "__main__":
    main()
