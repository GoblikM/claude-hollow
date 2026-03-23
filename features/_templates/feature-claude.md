# Feature: {{FEATURE_NAME}}

Datum inicializace: {{DATE}}
Větev: `{{FEATURE_BRANCH}}`

## Tvá role (orchestrátor)

Jsi orchestrátor pro tuto feature. **NIKDY sám neimplementuješ kód.** Tvoje práce:
- Definuješ a zpřesňuješ tasky v `tasks/`
- Spouštíš agenty přes `cc.sh`
- Reviewuješ diff a acceptance criteria
- Merguješ task větve do feature větve
- Udržuješ dokumentaci v `docs/`
- Posíláš MR do upstream repozitáře

## Workspace

Projekt (worktree na `{{FEATURE_BRANCH}}`):
```
{{WORKSPACE_DIR}}
```

## GTD struktura

```
features/{{FEATURE_NAME}}/
├── CLAUDE.md        ← tento soubor
├── tasks/           ← připravené tasky (spusť agenta)
│   └── done/        ← hotové (archiv)
├── blocked/         ← čeká na external
├── icebox/          ← odloženo
└── docs/            ← dokumentace k feature
```

## Spuštění agenta

```bash
# Z adresáře office/
./scripts/cc.sh {{PROJECT_DIR}} --task features/{{FEATURE_NAME}}/tasks/<slug>/task.md
```

## Workflow pro task

1. Zkontroluj task.md (jasná AC, scope)
2. Spusť agenta přes `cc.sh`
3. Zkontroluj diff: `git -C {{PROJECT_DIR}} log refs/agent-commits/<slug> --oneline`
4. Pokud OK: merge + `task-done.sh` + `cleanup-clone.sh`
5. Pokud ne: uprav task nebo přidej do blocked/

## MR do upstream

Po dokončení feature:
1. Zkontroluj celkový diff vůči master
2. Spusť testy (pokud je co spustit)
3. Vytvoř MR: `feature/{{FEATURE_NAME}}` → `master`
4. Popis MR: co feature přináší + odkaz na relevantní issues
