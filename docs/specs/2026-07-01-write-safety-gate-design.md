# Write Safety Gate — Design Spec

> **Status**: APPROVED  
> **Date**: 2026-07-01  
> **Feature**: Pre-write validation gate for state files

## Problem

`.pi/state/PLAN.md`, `agent/settings.json`, e altri file critici possono essere sovrascritti con contenuto corrotto durante l'esecuzione dei comandi `/plan`, `/execute`, o modifiche manuali. Non esiste validazione pre-scrittura né backup automatico.

## Design Decision

**Validazione pre-scrittura con backup**: ogni scrittura su file di stato critici passa attraverso un gate che:
1. Valida il nuovo contenuto
2. Se valido: scrive il file con backup del vecchio
3. Se invalido: preserva il `.bak`, rifiuta la scrittura

## Protected Files

| File | Validazione | Gate Attivo In |
|------|-------------|----------------|
| `.pi/state/PLAN.md` | ≥10 linee, contiene sezioni richieste | `/plan`, `/execute` |
| `agent/settings.json` | `python3 -m json.tool` | `/init`, modifiche manuali |
| `.gitignore` | Contiene le 9 entry critiche | `/init` |

## Deliverables

1. **`tests/validate_state.sh`** — script di validazione:
   - Check PLAN.md: esiste, ≥10 linee, contiene `## Executive Summary`
   - Check settings.json: JSON valido, ha `defaultProvider`, `defaultModel`, `defaultThinkingLevel`
   - Check .gitignore: contiene entry critiche (delega a `validate_gitignore.sh`)

2. **Gate integrazione in `/plan` prompt**:
   - Prima di scrivere `.pi/state/PLAN.md`, eseguire `bash tests/validate_state.sh`
   - Se fallisce, salvare il draft come `.pi/state/PLAN.md.bak` e NON sovrascrivere

3. **Gate integrazione in `/execute` prompt**:
   - Dopo aver modificato PLAN.md, eseguire `bash tests/validate_state.sh`
   - Se fallisce, revert e loggare l'errore

## Non-Goals

- Non fare backup su git ad ogni modifica (troppo rumore)
- Non validare file esterni (`.env`, `auth.json`)
- Non aggiungere TTL/rotazione ai .bak

## Success Criteria

- `bash tests/validate_state.sh` ritorna 0 su stato integro
- Un PLAN.md con 2 linee viene rifiutato (exit 1)
- Un settings.json con sintassi rotta viene rifiutato
- Il vecchio contenuto è sempre recuperabile via `.bak`
