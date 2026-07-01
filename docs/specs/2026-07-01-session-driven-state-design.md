# Session-Driven Command State — Design Spec

> **Status**: APPROVED  
> **Date**: 2026-07-01  
> **Feature**: Uniform session state across all commands — remove file-based state

## Problem

I comandi usano un mix inconsistente di fonti per lo stato:
- `/plan` legge `.pi/state/PLAN.md` ma scrive draft su `.pi/tmp/`
- `/execute` legge PLAN.md ma non persiste lo stato tra task
- `/review` e `/test` scrivono report su file `.pi/tmp/`
- `/brainstorm` è l'unico completamente session-driven

## Design Decision

**Tutti i comandi leggono e scrivono stato nella sessione pi.dev. Nessun file di stato.**

## Files to Remove

| File | Motivo |
|------|--------|
| `.pi/state/PLAN.md` | Sostituito da sessione pi.dev |
| `.pi/state/` (directory) | Non più necessaria |
| `.pi/tmp/plan_draft.md` | Draft in sessione |
| `.pi/tmp/review_report.json` | Report in sessione |
| `.pi/tmp/test_summary.json` | Summary in sessione |

## Kept Artifacts

| Path | Ruolo |
|------|-------|
| `.pi/tmp/cache/` | Explore cache (speed optimization, opzionale) |
| `.pi/tmp/coverage/` | Raw coverage data (debug, opzionale) |
| `docs/specs/` | Design specs (version-controlled, non di stato) |
| `.pi/tmp/` | Scratch directory (transiente, non persistente) |

## Changes Per Command

| Comando | Prima | Dopo |
|---------|-------|------|
| `/plan` | Legge PLAN.md, scrive `.pi/tmp/plan_draft.md` | Legge sessione, scrive sessione. **Nessun file.** |
| `/execute` | Legge PLAN.md, modifica PLAN.md | Legge sessione, scrive sessione. **Nessun file.** |
| `/review` | Scrive `.pi/tmp/review_report.json` | Scrive nella sessione |
| `/test` | Scrive `.pi/tmp/test_summary.json` | Scrive nella sessione |
| `/fix` | Output su stdout | Stato ciclo in sessione |
| `/commit` | Legge test output | Legge stato test dalla sessione |

## Success Criteria

- `.pi/state/` non esiste più
- `/brainstorm` → `/plan`: il piano emerge dal contesto sessione, nessun file intermedio
- `/plan` → `/execute`: l'esecuzione sa quale task eseguire senza leggere file
- `/test` → `/fix` → `/commit`: il fix loop usa lo stato test dalla sessione
- Nessun comando legge o scrive `.pi/state/` o `.pi/tmp/plan_draft.md`
