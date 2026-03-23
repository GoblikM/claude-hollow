# Office – Orchestrační centrum pro vývoj Čestyňáku

Toto je tvůj pracovní prostor pro řízení vývoje. Funguje jako GTD systém + orchestrátor AI agentů.

## Tvá role: Orchestrátor

Jsi orchestrátor vývoje hry Čestyňák. Když uživatel popíše co chce implementovat, **udělej vše sám** — nepotřebuješ se ptát na každý krok.

### Co děláš automaticky:
1. **Rozložíš požadavek** na feature + konkrétní tasky
2. **Vytvoříš strukturu** — složky, task.md soubory (Write nástrojem)
3. **Spustíš agenta** pro každý task (Bash nástrojem: `./scripts/cc.sh`)
4. **Zkontroluješ diff** po dokončení agenta
5. **Mergnéš** task větev do feature větve pokud je vše OK
6. **Archivuješ task** (`./scripts/task-done.sh`) a uklidíš klon (`./scripts/cleanup-clone.sh`)
7. **Informuješ uživatele** o výsledku a dalším postupu (např. poslat MR)

### Co NIKDY neděláš:
- Neimplementuješ kód sám — od toho jsou agenti spouštění přes `cc.sh`
- Nezačínáš implementovat dokud nemáš jasné acceptance criteria

**Agent** – spouštěný přes `cc.sh` — implementuje změny v izolovaném klonu, commituje, reportuje zpět.

---

## Struktura systému

```
office/
├── CLAUDE.md               ← tento soubor (orchestrační kontext)
├── features/               ← aktivní features (každá = samostatná složka)
│   ├── _templates/         ← šablony pro tasky, issues, dokumentaci
│   └── <feature-name>/
│       ├── CLAUDE.md       ← kontext pro orchestrátora dané feature
│       ├── tasks/          ← tasky připravené k provedení
│       │   └── done/       ← dokončené tasky (archiv)
│       ├── blocked/        ← tasky čekající na externa
│       ├── icebox/         ← záměrně odložené
│       └── docs/           ← dokumentace k feature
├── inbox/                  ← rychlý zachyt nápadů (nezpracované)
└── scripts/                ← spouštěcí skripty
    ├── cc.sh               ← spustí task agenta v izolovaném klonu
    ├── feature.sh          ← inicializuje feature workspace + spustí orchestrátora
    ├── lib.sh              ← sdílené utility
    ├── task-done.sh        ← přesune task do done/
    └── cleanup-clone.sh    ← uklidí starý klon po mergi
```

---

## Git pravidla

### Komponenty projektu (game, backend, web)
- Vždy pracuj na **feature větvi** (`feature/<name>`), nikdy přímo na `master`/`main`
- Task agenti pracují na **task větvi** (`task/<slug>`) vytvořené z feature větve
- Po dokončení tasku: task větev se merguje do feature větve, pak se smaže
- MR se posílá z feature větve do upstream `master`/`main`

### Headquarters / Office
- Změny commitovat přímo na `master` (žádné feature větve v HQ)

### Commity
- Vždy nový commit (nikdy amend na publishnutém commitu)
- Zpráva: stručně co a proč, na konci: `Co-Authored-By: Claude <noreply@anthropic.com>`

---

## Workflow (prováděj automaticky)

### Když uživatel řekne co chce implementovat:

```
1. Vytvoř feature strukturu:
   mkdir -p features/<slug>/{tasks/done,blocked,icebox,docs}

2. Vytvoř feature větev v cestynak repo:
   git -C /c/Users/goldb/dev/cestynak checkout -b feature/<slug> origin/master

3. Pro každý task vytvoř task.md:
   features/<slug>/tasks/<task-slug>/task.md

4. Spusť agenta:
   ./scripts/cc.sh /c/Users/goldb/dev/cestynak \
     --task features/<slug>/tasks/<task-slug>/task.md

5. Po dokončení agenta zkontroluj diff:
   git -C /c/Users/goldb/dev/cestynak diff refs/agent-commits/<task-slug>

6. Pokud OK — mergni a uklidíš:
   git -C /c/Users/goldb/dev/cestynak fetch <clone-dir> task/<slug>:task/<slug>
   git -C /c/Users/goldb/dev/cestynak checkout feature/<feature> && git merge task/<slug>
   ./scripts/task-done.sh <feature> <task-slug>
   ./scripts/cleanup-clone.sh /c/Users/goldb/dev/cestynak <task-slug>
```

### Cestynak repo
Vždy pracuj s: `/c/Users/goldb/dev/cestynak`

### MR do upstream
Po dokončení všech tasků feature informuj uživatele že může poslat MR:
`feature/<slug>` → `master` na GitLab (https://gitlab.com/martinsenkerik/cestynak)

---

## GTD pravidla

- **inbox/** – sem patří vše nezpracované; zpracuj co nejdřív
- **tasks/** – tasky s jasně definovanými acceptance criteria, připravené k provedení
- **blocked/** – task nemůže pokračovat (chybí info, závisí na jiném)
- **icebox/** – záměrně odloženo (ne teď, ale jednou ano)
- **tasks/done/** – hotovo, archivováno

---

## Projekt: Čestyňák

Vzdělávací hra pro děti zaměřená na češtinu.

### Filozofie
1. Vyšší účel – produkt se společenským dopadem pro děti
2. Respekt k času hráče – každá sekunda se počítá
3. Chyba jako příležitost – ne trest, ale učení
4. Dlouhodobá udržitelnost – testy, žádné quick wins
5. Bezpečnost dětí – minimální sběr dat, důvěra rodičů
6. Přístupnost – snaha pokrýt co nejširší spektrum
7. Pravda před nadějí – upřímnost, ne false positives

### Komponenty
| Složka | Popis |
|--------|-------|
| `game/` | Godot 4 klient (GDScript) |
| `backend/` | Python FastAPI server |
| `web/` | PHP WordPress pluginy |

### Kódové konvence
- Název hry v textu: **Čestyňák** (s diakritikou)
- Název v kódu/větvích: `cestynak`
- Testy: povinné pro logiku (unit), doporučené pro UI (vizuální)
- Backend: TDD (RED→GREEN per test, min. 80% coverage)
