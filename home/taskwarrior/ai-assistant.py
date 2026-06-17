#!/usr/bin/env python3
"""
Assistente IA para Taskwarrior usando Ollama
Analisa tarefas e fornece insights inteligentes
"""

import json
import subprocess
import requests
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any

class TaskwarriorAI:
    def __init__(self, ollama_url="http://localhost:11434"):
        self.ollama_url = ollama_url
        self.model = "llama3.2:3b"  # Modelo leve e eficiente
    
    def get_tasks(self, filter_query="status:pending") -> List[Dict[str, Any]]:
        """Obtém tarefas do Taskwarrior"""
        try:
            # Para taskwarrior 3, usar apenas 'export' sem filtro ou usar filtro diferente
            if filter_query == "status:pending":
                result = subprocess.run(
                    ['task', 'export'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
            else:
                result = subprocess.run(
                    ['task', 'export', filter_query],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
            
            if result.returncode != 0:
                return []
            
            if not result.stdout.strip():
                return []
            
            # Filtra apenas tarefas pendentes se necessário
            all_tasks = json.loads(result.stdout)
            if filter_query == "status:pending":
                return [task for task in all_tasks if task.get("status") == "pending"]
            else:
                return all_tasks
                
        except Exception as e:
            print(f"Erro ao obter tarefas: {e}")
            return []
    
    def query_ollama(self, prompt: str) -> str:
        """Faz query para o Ollama"""
        try:
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json={
                    "model": self.model,
                    "prompt": prompt,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "top_p": 0.9,
                        "max_tokens": 500
                    }
                },
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json().get("response", "")
            else:
                return f"Erro na API: {response.status_code}"
                
        except Exception as e:
            return f"Erro ao conectar com Ollama: {e}"
    
    def analyze_tasks(self) -> str:
        """Analisa tarefas e fornece insights"""
        tasks = self.get_tasks()
        
        if not tasks:
            return "Nenhuma tarefa pendente encontrada."
        
        # Prepara dados para análise
        task_summary = {
            "total": len(tasks),
            "high_priority": len([t for t in tasks if t.get("priority") == "H"]),
            "medium_priority": len([t for t in tasks if t.get("priority") == "M"]),
            "low_priority": len([t for t in tasks if t.get("priority") == "L"]),
            "no_priority": len([t for t in tasks if not t.get("priority")]),
            "projects": list(set([t.get("project", "Sem projeto") for t in tasks])),
            "overdue": len([t for t in tasks if self._is_overdue(t)]),
            "due_today": len([t for t in tasks if self._is_due_today(t)]),
            "due_this_week": len([t for t in tasks if self._is_due_this_week(t)])
        }
        
        # Lista das 5 tarefas mais urgentes
        urgent_tasks = sorted(tasks, key=lambda x: x.get("urgency", 0), reverse=True)[:5]
        
        prompt = f"""
Você é um assistente de produtividade especializado em análise de tarefas.

Analise o seguinte resumo de tarefas:
- Total de tarefas: {task_summary['total']}
- Alta prioridade: {task_summary['high_priority']}
- Média prioridade: {task_summary['medium_priority']}
- Baixa prioridade: {task_summary['low_priority']}
- Sem prioridade: {task_summary['no_priority']}
- Projetos: {', '.join(task_summary['projects'])}
- Tarefas atrasadas: {task_summary['overdue']}
- Vencendo hoje: {task_summary['due_today']}
- Vencendo esta semana: {task_summary['due_this_week']}

Top 5 tarefas mais urgentes:
{self._format_tasks_for_ai(urgent_tasks[:5])}

Forneça:
1. Uma análise breve da carga de trabalho
2. Sugestões de priorização
3. Recomendações de organização
4. Alertas sobre tarefas críticas

Responda em português, de forma concisa e prática.
"""
        
        return self.query_ollama(prompt)
    
    def suggest_task_improvements(self, task_id: str) -> str:
        """Sugere melhorias para uma tarefa específica"""
        tasks = self.get_tasks(f"id:{task_id}")
        
        if not tasks:
            return f"Tarefa {task_id} não encontrada."
        
        task = tasks[0]
        
        prompt = f"""
Analise esta tarefa e sugira melhorias:

Tarefa: {task.get('description', 'Sem descrição')}
Projeto: {task.get('project', 'Não definido')}
Prioridade: {task.get('priority', 'Não definida')}
Tags: {', '.join(task.get('tags', []))}
Data de vencimento: {task.get('due', 'Não definida')}
Urgência: {task.get('urgency', 0)}

Sugira:
1. Melhorias na descrição (mais específica/acionável)
2. Prioridade apropriada
3. Tags úteis
4. Quebra em subtarefas se necessário
5. Prazo realista

Responda em português, de forma prática.
"""
        
        return self.query_ollama(prompt)
    
    def generate_daily_plan(self) -> str:
        """Gera um plano diário baseado nas tarefas"""
        tasks = self.get_tasks()
        
        # Filtra tarefas relevantes para hoje
        today_tasks = [t for t in tasks if self._is_due_today(t) or self._is_overdue(t)]
        urgent_tasks = sorted(tasks, key=lambda x: x.get("urgency", 0), reverse=True)[:10]
        
        prompt = f"""
Você é um assistente de planejamento diário.

Baseado nestas tarefas, crie um plano de trabalho para hoje:

Tarefas vencendo hoje ou atrasadas:
{self._format_tasks_for_ai(today_tasks)}

Top 10 tarefas mais urgentes:
{self._format_tasks_for_ai(urgent_tasks)}

Crie um plano que inclua:
1. Ordem sugerida de execução
2. Estimativa de tempo para cada tarefa
3. Blocos de tempo recomendados
4. Pausas estratégicas
5. Tarefas que podem ser delegadas ou adiadas

Considere produtividade e bem-estar. Responda em português.
"""
        
        return self.query_ollama(prompt)
    
    def _is_overdue(self, task: Dict[str, Any]) -> bool:
        """Verifica se a tarefa está atrasada"""
        due = task.get("due")
        if not due:
            return False
        
        try:
            due_date = datetime.fromisoformat(due.replace('Z', '+00:00'))
            return due_date < datetime.now(due_date.tzinfo)
        except:
            return False
    
    def _is_due_today(self, task: Dict[str, Any]) -> bool:
        """Verifica se a tarefa vence hoje"""
        due = task.get("due")
        if not due:
            return False
        
        try:
            due_date = datetime.fromisoformat(due.replace('Z', '+00:00'))
            today = datetime.now(due_date.tzinfo).date()
            return due_date.date() == today
        except:
            return False
    
    def _is_due_this_week(self, task: Dict[str, Any]) -> bool:
        """Verifica se a tarefa vence esta semana"""
        due = task.get("due")
        if not due:
            return False
        
        try:
            due_date = datetime.fromisoformat(due.replace('Z', '+00:00'))
            today = datetime.now(due_date.tzinfo)
            week_end = today + timedelta(days=7)
            return today.date() <= due_date.date() <= week_end.date()
        except:
            return False
    
    def _format_tasks_for_ai(self, tasks: List[Dict[str, Any]]) -> str:
        """Formata tarefas para o prompt da IA"""
        if not tasks:
            return "Nenhuma tarefa"
        
        formatted = []
        for task in tasks:
            desc = task.get('description', 'Sem descrição')
            project = task.get('project', '')
            priority = task.get('priority', '')
            urgency = task.get('urgency', 0)
            due = task.get('due', '')
            
            task_str = f"- {desc}"
            if project:
                task_str += f" (Projeto: {project})"
            if priority:
                task_str += f" [Prioridade: {priority}]"
            if due:
                task_str += f" [Vence: {due}]"
            task_str += f" [Urgência: {urgency:.1f}]"
            
            formatted.append(task_str)
        
        return "\n".join(formatted)

def main():
    if len(sys.argv) < 2:
        print("Uso: python ai-assistant.py <comando> [argumentos]")
        print("Comandos:")
        print("  analyze - Analisa todas as tarefas pendentes")
        print("  improve <task_id> - Sugere melhorias para uma tarefa")
        print("  plan - Gera plano diário")
        return
    
    ai = TaskwarriorAI()
    command = sys.argv[1]
    
    if command == "analyze":
        print("🤖 Analisando suas tarefas...\n")
        result = ai.analyze_tasks()
        print(result)
    
    elif command == "improve" and len(sys.argv) > 2:
        task_id = sys.argv[2]
        print(f"🤖 Analisando tarefa {task_id}...\n")
        result = ai.suggest_task_improvements(task_id)
        print(result)
    
    elif command == "plan":
        print("🤖 Gerando plano diário...\n")
        result = ai.generate_daily_plan()
        print(result)
    
    else:
        print("Comando inválido ou argumentos insuficientes")

if __name__ == "__main__":
    main()