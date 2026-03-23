# Office – Orchestrační centrum pro vývoj Čestyňáku

Tento adresář je centrála vývoje. Každá feature má vlastního orchestrátora v samostatné Claude session.

## Tvá role (top-level)

Zpracováváš inbox a zakládáš nové features.

**Přísné pravidlo:** Nikdy neimplementuješ změny v cestynak projektu sám. Veškeré změny kódu provádí výhradně agenti spuštění přes `cc.sh`. Bez výjimky — ani pro triviální změny, jednořádkové opravy.

Kdykoli narazíš na chybu v procesu nebo prostor pro zlepšení (workflow, skripty, šablony…), **okamžitě to zachyť do `inbox/`**. Nečekat na "vhodnou chvíli".

## Vytvoření / otevření feature

```bash
./scripts/feature.sh <feature-name>
```

Skript vytvoří GTD strukturu, feature větev, worktree, vygeneruje `CLAUDE.md` a spustí Claude jako orchestrátora té feature. Při dalším spuštění otevře existující feature.

## Inbox

Cokoli nezpracovaného patří do `inbox/`. Při otevření tohoto adresáře projdi inbox a rozhoduj:

| Situace | Akce |
|---------|------|
| Nový nápad bez kontextu | → `inbox/<slug>.md` |
| Inbox položka je akční | → nová feature nebo přidat do existující |
| Inbox položka je akční, ale nelze spustit | → `features/<name>/blocked/<slug>/issue.md` |
| Inbox položka odložena vědomě | → `features/<name>/icebox/<slug>/issue.md` |
| Irelevantní | → smaž |

## GTD konvence

| Složka | Pravidlo |
|--------|----------|
| `inbox/` | Cokoli nezpracovaného — nápad, poznatek, TODO bez feature kontextu |
| `tasks/` | Akční, jasně definovaný, lze spustit ihned |
| `blocked/` | Definovaný task, ale nelze spustit — čeká na ext. rozhodnutí/info |
| `icebox/` | Vědomě odloženo — víme co chceme, ale ne teď |
| `tasks/done/` | Dokončené tasky — archiv v kontextu feature |

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
