# Office – Orchestrační centrum pro vývoj Čestyňáku

Tento adresář je centrála vývoje. Každá feature má vlastního orchestrátora v samostatné Claude session.

## Tvá role (top-level)

Zpracováváš inbox a zakládáš nové features. Tasky neimplementuješ — od toho jsou feature orchestrátoři.

## Vytvoření nové feature

Spusť skript (cesta k cestynak je zabudovaná):
```bash
./scripts/feature.sh <feature-name>
```

Skript vytvoří GTD strukturu, feature větev, worktree, vygeneruje `CLAUDE.md` a spustí Claude jako orchestrátora té feature.

Pro otevření existující feature:
```bash
./scripts/feature.sh <feature-name>
```

## Inbox

Cokoli nezpracovaného patří do `inbox/`. Projdi inbox a zpracuj:
- Akční → vytvoř feature nebo přidej do existující
- Irelevantní → smaž

## Struktura

```
office/
├── CLAUDE.md               ← tento soubor
├── features/
│   ├── _templates/         ← šablony
│   └── <feature-name>/
│       ├── CLAUDE.md       ← kontext orchestrátora dané feature
│       ├── tasks/          ← tasky (done/ = archiv)
│       ├── blocked/
│       ├── icebox/
│       └── docs/
├── inbox/
└── scripts/
    ├── feature.sh          ← inicializuje feature + spustí orchestrátora
    ├── cc.sh               ← spustí task agenta v izolovaném klonu
    ├── task-done.sh        ← přesune task do done/
    └── cleanup-clone.sh    ← uklidí klon po mergi
```
