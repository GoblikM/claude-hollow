# Feature: book-sorting-second-phase — Implementace

## Co bylo implementováno

Druhá fáze standalone book sorting minihry: mechanika šeptajících dětí.

### Nové soubory

- `game/minigames/books_sorting/standalone/children_distraction_manager.gd` — správce distrakcí
- `game/minigames/books_sorting/standalone/book_sorting_deti.dialogue` — konfrontační dialog

### Změněné soubory

- `game/minigames/books_sorting/books_sorting_minigame.gd` — signály a countdown overlay
- `game/minigames/books_sorting/books_sorting_minigame.tscn` — DistractionWarning UI
- `game/minigames/books_sorting/standalone/book_sorting_standalone.gd` — orchestrace
- `game/minigames/books_sorting/standalone/book_sorting_standalone.tscn` — ChildrenDistractionManager node
- `game/analytics/analytics_events.gd` — 3 nové eventy

---

## Herní mechanika

1. Hráč řadí knihy v standalone minihře
2. Po náhodné době (20–40 s) se zobrazí overlay: **"Šepty šepty, šušky-šušky!"** + countdown 15 s
3. Děti (Michaelka, Danielka, Martínek, Jiřík) se začnou pohybovat k náhodně vybranému seřazenému regálu
4. Hráč má dvě možnosti:
   - **Zavřít řazení** a navigovat k dětem → při přiblížení na 80px spustí dialog → hráč je seřve → děti utečou zpět na původní pozice, regál je zachráněn
   - **Ignorovat** → countdown doběhne → knížky na regálu se zamíchají, regál je opět ke třídění
5. První spuštění ukáže intro s varováním o dětech (`uvod`), restarty kratší intro bez varování (`uvod_bez_deti`)

## Architektonická rozhodnutí

- **Proximity detekce v standalone** (ne v ChildrenDistractionManager) — zamezuje race condition s dialogem
- **Signály registrovány v `_ready()`**, ne per-minigame — cleaner lifecycle
- **`distraction_enabled = true`** se předává každé instanci BookSortingMinigame — umožňuje budoucí konfiguraci
- Scramble volá `bookshelf.data.sorting_book_resources.shuffle()` + `change_texture_to_unsort()` — konzistentní se zbytkem Bookshelf API

## Analytics

| Event | Properties |
|-------|-----------|
| `Book Sorting Distraction Started` | `shelf_id`, `countdown_duration` |
| `Book Sorting Distraction Caught` | `time_remaining` |
| `Book Sorting Distraction Failed` | `shelf_id` |
