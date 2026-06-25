# Guida Enterprise per pi.dev con DeepSeek

Questa guida fornisce una referenza completa per utilizzare pi.dev con i modelli DeepSeek (V4-Pro e V4-Flash) in un workflow enterprise, integrando skills, gestione ephemeral e best practice.

---

## 1. Configurazione dei Modelli DeepSeek

### 1.1 File `models.json`

Crea o modifica il file `~/.pi/agent/models.json`:

    {
      "providers": {
        "deepseek": {
          "baseUrl": "https://api.deepseek.com",
          "api": "openai-completions",
          "apiKey": "$DEEPSEEK_API_KEY",
          "models": [
            {
              "id": "deepseek-v4-pro",
              "name": "DeepSeek V4 Pro",
              "contextWindow": 1000000,
              "maxTokens": 384000,
              "input": ["text"],
              "reasoning": true,
              "cost": {
                "input": 1.74,
                "output": 3.48,
                "cacheRead": 0.145,
                "cacheWrite": 0
              },
              "compat": {
                "requiresReasoningContentOnAssistantMessages": true,
                "thinkingFormat": "deepseek",
                "reasoningEffortMap": {
                  "minimal": "high",
                  "low": "high",
                  "medium": "high",
                  "high": "high",
                  "xhigh": "max"
                }
              }
            },
            {
              "id": "deepseek-v4-flash",
              "name": "DeepSeek V4 Flash",
              "contextWindow": 1000000,
              "maxTokens": 384000,
              "input": ["text"],
              "reasoning": true,
              "cost": {
                "input": 0.14,
                "output": 0.28,
                "cacheRead": 0.028,
                "cacheWrite": 0
              },
              "compat": {
                "requiresReasoningContentOnAssistantMessages": true,
                "thinkingFormat": "deepseek",
                "reasoningEffortMap": {
                  "minimal": "high",
                  "low": "high",
                  "medium": "high",
                  "high": "high",
                  "xhigh": "max"
                }
              }
            }
          ]
        }
      }
    }

### 1.2 Variabile d'Ambiente

Imposta la variabile d'ambiente:

    export DEEPSEEK_API_KEY="<your-deepseek-api-key>"

### 1.3 Installazione Estensione per il Frontmatter

Per abilitare i campi `model`, `thinking` e `skill` nei prompt template:

    pi install npm:pi-prompt-template-model

Riavvia pi per caricare l'estensione.

---

## 2. Configurazione delle Skills

### 2.1 Struttura delle Directory

Crea la directory per le skills:

    mkdir -p ~/.pi/agent/skills

### 2.2 Skills Disponibili

Hai a disposizione 5 skills enterprise:

| Skill | File | Descrizione | Applicazione |
|-------|------|-------------|--------------|
| **Security Hardening** | `security-hardening.md` | OWASP Top 10, input validation, encryption, authentication | Obbligatoria per `/execute`, `/review`, `/plan` |
| **Testing Standards** | `testing-standards.md` | TDD, coverage, test quality, mocking | Obbligatoria per `/execute`, `/test`, `/review` |
| **Laravel Best Practices** | `laravel-best-practices.md` | PHP/Laravel specific (Eloquent, Services, Controllers) | Per progetti Laravel in `/execute` |
| **FastAPI Best Practices** | `fastapi-best-practices.md` | Python/FastAPI specific (async, Pydantic, SQLAlchemy) | Per progetti FastAPI in `/execute` |
| **Architecture Principles** | `architecture-principles.md` | DDD, event-driven, CQRS, microservices | Obbligatoria per `/plan` e `/review` |

### 2.3 Creazione delle Skills

Copia ciascuna skill nel file corrispondente in `~/.pi/agent/skills/`:

    ~/.pi/agent/skills/
    ├── security-hardening.md
    ├── testing-standards.md
    ├── laravel-best-practices.md
    ├── fastapi-best-practices.md
    └── architecture-principles.md

---

## 3. Prompt Template con Skills

### 3.1 Mappatura Model/Thinking/Skill

| Prompt | Modello | Thinking | Skills | Descrizione |
|--------|---------|----------|--------|-------------|
| `/init` | Flash | minimal | — | Sanity check, bootstrap |
| `/explore` | Flash | low | — | Mappatura codebase con cache |
| `/plan` | Pro | xhigh | architecture-principles, security-hardening, testing-standards | Architettura e pianificazione |
| `/execute` | Flash | medium | security-hardening, testing-standards, architecture-principles | Implementazione + test |
| `/review` | Pro | high | security-hardening, testing-standards, architecture-principles | Code review + audit |
| `/test` | Flash | low | testing-standards, security-hardening | Esecuzione suite + coverage |
| `/abort` | Flash | minimal | — | Rollback + pulizia |
| `/commit` | Flash | minimal | — | Conventional commit |

### 3.2 Esempio di Frontmatter con Skills

Per `/execute`:

    ---
    description: Activate execution mode — implement code and tests simultaneously
    argument-hint: "[target-component]"
    model: deepseek-v4-flash
    thinking: medium
    skill: security-hardening, testing-standards, architecture-principles
    restore: true
    ---

---

## 4. Flusso di Lavoro Enterprise

### 4.1 Ciclo di Sviluppo Completo

1. **Avvio Sessione**
       /init

   - Verifica ambiente (PHP, Node, Docker)
   - Crea struttura `.pi/tmp/` e `.pi/state/`
   - Genera `SESSION_ID`

2. **Esplorazione Codebase**
       /explore

   - Mappa struttura directory (cache 1h)
   - Identifica entry point e dipendenze
   - Analizza log (se presenti)

3. **Pianificazione**
       /plan "Aggiungi gestione pagamenti con Stripe"

   - Genera bozza in `.pi/tmp/{SESSION_ID}/plan_draft.md`
   - Richiede conferma: `CONFIRM PLAN`
   - Sposta in `.pi/state/PLAN.md`

4. **Esecuzione Task**
       /execute PaymentService

   - Legge `PLAN.md`
   - Implementa codice + test (TDD)
   - Rispetta DoD checklist
   - Aggiorna `PLAN.md`

5. **Code Review**
       /review src/PaymentService.php

   - Analisi read‑only
   - Report JSON in `.pi/tmp/{SESSION_ID}/review_report.json`
   - Flagga criticità (security, architecture, testing)

6. **Test Suite**
       /test

   - Esegue tutti i test con coverage
   - Genera report in `.pi/tmp/{SESSION_ID}/test_summary.json`
   - Identifica percorsi non coperti

7. **Commit**
       /commit api

   - Analizza diff
   - Genera conventional commit message

8. **Rollback / Abort**
       /abort

   - Rimuove `.pi/tmp/{SESSION_ID}/`
   - Cancella `current_session`
   - Rollback git (se necessario)
   - Pulisce cache > 24h

### 4.2 Gestione del Contesto e dei Costi

| Modello | Costo (input/output per 1M token) | Utilizzo |
|---------|-----------------------------------|----------|
| DeepSeek V4 Pro | $1.74 / $3.48 | Plan, Review |
| DeepSeek V4 Flash | $0.14 / $0.28 | Explore, Execute, Test, Init, Abort, Commit |

**Raccomandazione**: Usa Flash per la maggior parte delle operazioni e Pro solo per pianificazione e review.

### 4.3 Integrazione CI/CD

- **Pre-commit hook**: Esegui `/review` e `/test` prima di ogni commit.
- **Pipeline CI**: Utilizza `/execute --headless` per esecuzioni automatizzate.
- **Monitoraggio**: I report JSON in `.pi/tmp/{SESSION_ID}/` possono essere parsati per metriche di qualità nel tempo.

---

## 5. Struttura delle Directory

### 5.1 Globale (~/.pi/)

    ~/.pi/
    ├── agent/
    │   ├── models.json          # Provider e modelli
    │   ├── prompts/             # Prompt template globali
    │   │   ├── init.md
    │   │   ├── explore.md
    │   │   ├── plan.md
    │   │   ├── execute.md
    │   │   ├── review.md
    │   │   ├── test.md
    │   │   ├── abort.md
    │   │   └── commit.md
    │   └── skills/              # Skills globali
    │       ├── security-hardening.md
    │       ├── testing-standards.md
    │       ├── laravel-best-practices.md
    │       ├── fastapi-best-practices.md
    │       └── architecture-principles.md
    └── ...

### 5.2 Per Progetto (.pi/)

    .pi/
    ├── prompts/                 # Prompt template specifici del progetto
    │   └── ...
    ├── tmp/                     # Ephemeral workspace
    │   ├── current_session      # SESSION_ID attivo
    │   ├── cache/               # Cache condivisa (TTL: 1h)
    │   └── {SESSION_ID}/        # Session‑isolated
    │       ├── lock/
    │       ├── artifacts/
    │       ├── plan_draft.md
    │       ├── execution.log
    │       ├── review_report.json
    │       └── coverage/
    └── state/                   # Persistent storage
        ├── PLAN.md              # Source of truth
        ├── MEMORY.md
        └── AGENTS.md

---

## 6. Best Practice per l'Apprendimento

### 6.1 Comandi di Base da Memorizzare

- `/init` — Avvia sessione, verifica ambiente
- `/explore` — Mappa codebase
- `/plan "feature"` — Pianifica feature
- `/execute [task]` — Esegue task (default: prossimo da PLAN.md)
- `/review [target]` — Review (default: tutta la root)
- `/test [directory]` — Test (default: `tests/`)
- `/commit [scope]` — Genera commit message
- `/abort` — Rollback e pulizia

### 6.2 Ciclo di Feedback

- Dopo `/execute`, verifica sempre la DoD checklist.
- Usa `/review` prima di ogni commit per catturare problemi.
- Usa `/test` per monitorare la coverage nel tempo.
- Usa `/abort` se il contesto diventa confuso o la sessione si degrada.

### 6.3 Estendibilità

- **Aggiungi nuove skills**: Crea file `.md` in `~/.pi/agent/skills/` e referenziali nel frontmatter.
- **Modifica prompt template**: Aggiorna i file in `~/.pi/agent/prompts/` o nel progetto.
- **Personalizza models.json**: Aggiungi provider aggiuntivi (OpenAI, Anthropic, etc.).

---

## 7. Risoluzione dei Problemi Comuni

### 7.1 Errore: "No active session found"

Esegui `/init` per creare una nuova sessione.

### 7.2 Errore: "Another execution is in progress"

Verifica lock orfani in `.pi/tmp/{SESSION_ID}/lock/` e rimuovili manualmente, oppure esegui `/abort` e riavvia.

### 7.3 Errore: "PLAN.md not found"

Assicurati di aver eseguito `/plan` e confermato il piano con `CONFIRM PLAN`.

### 7.4 Errore: "Skill not found"

Verifica che la skill esista in `~/.pi/agent/skills/` e che il nome sia scritto correttamente (senza estensione `.md`).

---

## 8. Riferimenti

- [pi.dev Documentation](https://pi.dev/docs/latest)
- [DeepSeek API Documentation](https://api-docs.deepseek.com)
- [pi-prompt-template-model Extension](https://www.npmjs.com/package/pi-prompt-template-model)
- [GitHub Repository](https://github.com/nicobailon/pi-prompt-template-model)

---

*Questa guida è un documento vivente. Aggiornala man mano che il workflow evolge.*
