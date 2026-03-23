# CLAUDE.md – Office, orchestrační centrum pro vývoj Čestyňáku

## Projekt

**Čestyňák** je vzdělávací hra pro děti zaměřená na češtinu.

| Komponenta | Tech | Účel |
|------------|------|------|
| `game/` | Godot 4 + GDScript | Herní klient (Web, Android, iOS, Windows) |
| `backend/` | Python / FastAPI + PostgreSQL | Cloud save synchronizace |
| `web/` | PHP / WordPress pluginy | Správa licencí, autentizace, analytika |

Projekt: `/c/Users/goldb/dev/cestynak`
CLAUDE.md projektu (architektura, konvence): `/c/Users/goldb/dev/cestynak/CLAUDE.md`

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

**Orchestrátor NIKDY neimplementuje změny v `game/`, `backend/`, `web/` sám.** Veškeré změny kódu provádí výhradně agenti spuštění přes `cc.sh`. Bez výjimky — ani pro triviální změny, jednořádkové opravy.

Orchestrátor smí pouze:
- Vytvářet a upravovat tasky, docs (v `features/`)
- Spouštět agenty přes `cc.sh`
- Reviewovat výstup agentů
- Mergovat task větve do feature větve
- Přesouvat tasky do `done/`
- Spravovat GTD strukturu (inbox, blocked, icebox)

### Neustálé zlepšování

Kdykoli orchestrátor narazí na chybu v procesu nebo prostor pro zlepšení (workflow, skripty, šablony…), **okamžitě to zachytí do `inbox/`**. Nečekat na "vhodnou chvíli". Cílem je každým dnem zlepšovat celou flow.

### Spuštění feature orchestrátora

Každá feature má svůj orchestrátor spuštěný příkazem:

```bash
./scripts/feature.sh <feature-name>
```

Při prvním spuštění vytvoří `features/<name>/` (GTD struktura, feature větev, worktree), vygeneruje `CLAUDE.md` a spustí Claude jako orchestrátora té feature.
Při dalších spuštěních otevře existující feature.

---

## GTD architektura

```
office/
├── features/
│   └── <name>/
│       ├── CLAUDE.md       # Kontext orchestrátora (generován z _templates/feature-claude.md)
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

### Cestynak projekt (game, backend, web)

- `feature/<název>` — nová funkcionalita; **vždy z master, nikdy z jiné feature větve**
- `task/<název>` — agent větve; zakládá `cc.sh` automaticky; vždy z feature větve, nikdy z master
- Po mergi task větve do feature větve ji ihned smaž
- `master` — pouze přes review merge; agenti nesmí běžet přímo z master

### Office

- Všechny změny commitovat přímo na `main`
- Po každém commitu ihned pushovat (`git push`)
- Vždy nový commit, nikdy `--amend` na publishnutém commitu

---

## Pravidla pro agenty

- Agenti pracují **výhradně v rámci `## Scope`** svého `task.md`
- **Nesmí** vytvářet tasky ani soubory mimo Scope
- **Smí** zapsat log do své task složky
- **Smí** vytvořit `inbox/<slug>.md` při zachycení důležitého poznatku mimo scope
- Pokud narazí na blokátor → zdokumentují ho v sekci `## Notes` svého `task.md`

---

## Pravidla pro kód

### Obecná

- **Bash příkazy v Claude**: NIKDY `echo`. Místo toho vždy dedikované nástroje: Glob, Grep, Read, Edit/Write.
- **Při nejasnostech**: Použít `AskUserQuestion` místo hádání.

### Game — specifická pravidla

- **Název hry v UI textech**: Vždy **Češťyňák** (š, ť). V kódu/identifikátorech: `cestynak`.
- **Environment detection**: `OS.has_feature("cestynak-prod")`, ne hardcoded checks.
- **Settings**: Vždy `get_setting_with_override()`, ne `get_setting()`.
- **Analytics**: Každá nová feature musí mít od začátku naplánované analytics eventy.
- **Game commits**: Neobsahují `Co-Authored-By` trailer.

### Backend

- **Strict TDD**: Spusť `pytest` po každém testu (RED), pak po implementaci (GREEN). Min. 80% coverage.

### Web

- **Cryptographic keys**: Před každým deploymentem zálohuj `defuse.txt` a `secret.txt` — ztráta je nenapravitelná.
