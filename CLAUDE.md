# CLAUDE.md – Office, orchestrační centrum pro vývoj Čestyňáku

## Projekt

**Čestyňák** je vzdělávací hra pro děti zaměřená na češtinu.

Repozitář hry: `/c/Users/goldb/dev/cestynak`
Architektura a konvence hry: `/c/Users/goldb/dev/cestynak/CLAUDE.md`

---

## Základní principy

Tato pravidla řídí každé rozhodnutí — od definice feature přes architekturu po poslední řádek kódu.

1. **Produkt s vyšším smyslem** — Budujeme produkt pro děti. Využíváme jejich pozornost ve směru etiky, ekologie, seberozvoje a sounáležitosti.
2. **Respekt k času hráče** — Každá vteřina strávená hraním má smysl.
3. **Chyba je součást učení, ne selhání** — Herní mechaniky netrestají za špatnou odpověď. Motivace vnitřní, ne vnější srovnávání.
4. **Dlouhodobě udržitelná řešení** — Stavíme systémy pořádně (včetně testů). Žádné quick-wins.
5. **Bezpečnost dětí** — Žádný sběr dat nad rámec nezbytného. Důvěru rodičů nelze porušit.
6. **Přístupnost** — Best effort pro co nejširší spektrum dětí.
7. **Pravdivost a upřímnost** — Nejdřív pravda, pak naděje. Hráče nelze klamat ani zavádějícími formulacemi.

---

## Orchestrátor a agenti

### Přísné pravidlo

**Orchestrátor NIKDY neimplementuje změny v repozitáři hry sám.** Veškeré změny kódu provádí výhradně subagenti. Bez výjimky — ani pro triviální změny, jednořádkové opravy.

Orchestrátor smí pouze:
- Vytvářet a upravovat tasky, docs (v `features/`)
- Spouštět subagenty (`@task-agent`, `@code-reviewer`, `@tester`)
- Mergovat task větve do feature větve
- Přesouvat tasky do `done/`
- Spravovat GTD strukturu (inbox, blocked, icebox)

### Pipeline pro každý task

Každý task prochází třemi subagenty v pořadí:

1. **`@task-agent`** — implementuje změny, commituje na `task/<slug>` větev
2. **`@code-reviewer`** — reviewuje diff, ověří AC a konvence; vrátí `APPROVED` nebo `CHANGES REQUESTED`
3. **`@tester`** — spustí testy; vrátí `TESTS PASS` nebo `TESTS FAIL`

Pokud reviewer nebo tester vrátí neúspěch → orchestrátor spustí `@task-agent` znovu s konkrétním feedbackem.

### Neustálé zlepšování

Kdykoli orchestrátor narazí na chybu v procesu nebo prostor pro zlepšení (workflow, skripty, šablony…), **okamžitě to zachytí do `inbox/`**. Nečekat na "vhodnou chvíli".

### Spuštění feature orchestrátora

Spouští **uživatel z terminálu** (ne orchestrátor zevnitř Claude session):

```bash
./scripts/feature.sh <feature-name>
```

Při prvním spuštění vytvoří `features/<name>/` (GTD struktura, feature větev, worktree), vygeneruje `CLAUDE.md` a spustí Claude jako orchestrátora té feature.
Při dalších spuštěních otevře existující feature.

Feature `CLAUDE.md` vždy obsahuje tabulku **Klíčový kontext** — repozitář hry, worktree, větev. Orchestrátor ji musí přečíst jako první krok.

### Monitorování subagentů

Subagenti běží přímo v Claude session — jejich výstup je viditelný v reálném čase. Pro background subagenty Claude oznámí dokončení automaticky.

---

## GTD architektura

```
office/
├── features/
│   └── <name>/
│       ├── CLAUDE.md       # Kontext orchestrátora — obsahuje cestu k repozitáři hry, worktree, větev
│       ├── tasks/          # Aktivní, akční tasky
│       │   └── done/       # Dokončené tasky — archiv
│       ├── blocked/        # Nelze spustit — čeká na ext. rozhodnutí/info
│       ├── icebox/         # Vědomě odloženo na pozdější fázi
│       └── docs/           # Dokumentace specifická pro feature
└── inbox/                  # Root-level capture bucket — nezpracované nápady
```

### Konvence GTD složek

| Složka | Pravidlo |
|--------|----------|
| `inbox/` | Cokoli nezpracovaného — nápad, poznatek, TODO bez feature kontextu |
| `tasks/` | Akční, jasně definovaný, lze spustit ihned |
| `blocked/` | Definovaný task, ale nelze spustit — čeká na ext. rozhodnutí/implementaci/info |
| `icebox/` | Vědomě odloženo — víme co chceme, ale ne teď (pozdější fáze) |
| `tasks/done/` | Dokončené tasky — archiv v kontextu feature |

### Task lifecycle

| Situace | Akce |
|---------|------|
| Nový nápad bez kontextu | → `inbox/<slug>.md` |
| Inbox položka je akční | → `features/<name>/tasks/<slug>/task.md` |
| Task nelze spustit | → `features/<name>/blocked/<slug>/issue.md` |
| Task odložen vědomě | → `features/<name>/icebox/<slug>/issue.md` |
| Task dokončen | → přesun do `features/<name>/tasks/done/` |

---

## Git pravidla

### Repozitář hry

- `feature/<název>` — nová funkcionalita; **vždy z master, nikdy z jiné feature větve**
- `task/<název>` — agent větve; zakládá `@task-agent` automaticky; vždy z feature větve, nikdy z master
- Po mergi task větve do feature větve ji ihned smaž
- `master` — pouze přes review merge; agenti nesmí běžet přímo z master
- Merge request na GitLab (`feature/<název>` → `master`) vytváří **výhradně uživatel ručně**
- Orchestrátor pouze informuje že je feature připravena, ale MR nevytváří

### Office

- Všechny změny commitovat přímo na `main`, ihned pushovat
- Vždy nový commit, nikdy `--amend` na publishnutém commitu

---

## Pravidla pro agenty

- Agenti pracují **výhradně v rámci `## Scope`** svého `task.md`
- **Nesmí** vytvářet tasky ani soubory mimo Scope
- **Smí** zapsat log do své task složky
- **Smí** vytvořit `inbox/<slug>.md` při zachycení důležitého poznatku mimo scope
- Pokud narazí na blokátor → zdokumentují ho v `## Notes` svého `task.md`

---

## Pravidla pro kód hry (Godot 4 / GDScript)

- **Název hry v UI textech**: Vždy **Češťyňák** (š, ť). V kódu/identifikátorech: `cestynak`.
- **Game commits**: Neobsahují `Co-Authored-By` trailer.
- **Environment detection**: `OS.has_feature("cestynak-prod")`, ne hardcoded checks.
- **Settings**: Vždy `get_setting_with_override()`, ne `get_setting()`.
- **Analytics**: Každá nová feature musí mít od začátku naplánované analytics eventy.
- **Testy**: Povinné pro logiku (unit), doporučené pro UI (vizuální).
