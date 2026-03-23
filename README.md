# Office – Orchestrační centrum pro vývoj Čestyňáku

Systém pro řízení AI agentů (Claude Code) při vývoji hry [Čestyňák](https://gitlab.com/martinsenkerik/cestynak). Kombinuje GTD metodiku s automatizovanou orchestrací agentů.

## Jak to funguje

Otevřeš Claude Code v tomto adresáři a popíšeš co chceš implementovat. Claude jako orchestrátor sám:
- rozloží požadavek na feature a tasky
- vytvoří task soubory
- spustí agenty v izolovaných git klonech
- zkontroluje diff a mergne výsledek
- informuje tě kdy je vše připraveno k MR

```bash
cd office/
claude
# → "Chci přidat zvukové efekty při správné odpovědi"
```

## Struktura

```
office/
├── features/           # Aktivní features (GTD: tasks, blocked, icebox, docs)
│   └── _templates/     # Šablony pro tasky a dokumentaci
├── inbox/              # Rychlý zachyt nápadů
└── scripts/
    ├── cc.sh           # Spustí task agenta v izolovaném klonu
    ├── feature.sh      # Inicializuje feature workspace
    ├── task-done.sh    # Archivuje dokončený task
    └── cleanup-clone.sh
```

## Požadavky

- [Claude Code CLI](https://claude.ai/code) (`claude` v PATH)
- Git
- Naklonované repo Čestyňáku lokálně (`~/dev/cestynak`)
