# Office – Orchestrační centrum pro vývoj Čestyňáku

Tento adresář je centrála vývoje. Každá feature má vlastního orchestrátora spuštěného přes `feature.sh`.

## Tvá role zde (top-level)

Jsi top-level orchestrátor. Zpracováváš inbox, zakládáš nové features a máš přehled o stavu projektu.

**Novou feature** vytvoříš příkazem:
```bash
./scripts/feature.sh <feature-name> /c/Users/goldb/dev/cestynak
```
Tím se vytvoří `features/<name>/` se strukturou, vygeneruje se `CLAUDE.md` a spustí se orchestrátor přímo pro tuto feature.

**Orchestrátora existující feature** spustíš:
```bash
cd features/<name> && claude
```

## Struktura

```
office/
├── CLAUDE.md               ← tento soubor (top-level kontext)
├── features/
│   ├── _templates/         ← šablony (task.md, feature-claude.md, ...)
│   └── <feature-name>/
│       ├── CLAUDE.md       ← kontext orchestrátora dané feature (generován z šablony)
│       ├── tasks/          ← tasky (done/ = archiv)
│       ├── blocked/        ← čeká na external
│       ├── icebox/         ← záměrně odloženo
│       └── docs/           ← dokumentace k feature
├── inbox/                  ← rychlý zachyt nápadů — zpracuj co nejdřív
└── scripts/
    ├── cc.sh               ← spustí task agenta v izolovaném klonu
    ├── feature.sh          ← inicializuje feature + spustí orchestrátora
    ├── lib.sh              ← sdílené utility
    ├── task-done.sh        ← přesune task do done/
    └── cleanup-clone.sh    ← uklidí klon po mergi
```

## Inbox

Cokoli nezpracovaného patří do `inbox/`. Při otevření tohoto adresáře projdi inbox a rozhoduj:
- Akční → `features/<name>/tasks/<slug>/task.md`
- Patří do existující feature → tam
- Nová feature → `feature.sh`
- Irelevantní → smaž

## Přehled aktivních features

Projdi `features/` a zkontroluj stav každé feature (tasks vs done, blocked).
