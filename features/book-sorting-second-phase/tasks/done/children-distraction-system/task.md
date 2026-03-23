# Task: children-distraction-system

## Cíl

Implementovat mechaniku šeptajících dětí: náhodný timer spustí varování uprostřed řazení knih, zobrazí se countdown overlay v minihře, děti se začnou pohybovat k regálu, a pokud hráč nestihne včas zasáhnout, knížky se rozházejí.

## Kontext

Standalone book sorting minigame se skládá ze dvou vrstev:
- **Library interior** (`book_sorting_standalone.tscn`): prostor s hráčem, knihovnicí, 4 dětmi (Michaelka, Danielka, Martínek, Jiřík), 4 regály (Bookshelf1–4)
- **Sorting minigame UI** (`books_sorting_minigame.tscn`): overlay vrstva (CanvasLayer) pro samotné řazení knih

Děti jsou v library interior, řazení probíhá v CanvasLayer overlay. Signal musí propojit obě vrstvy.

## Scope

Agent smí měnit POUZE tyto soubory:
- `game/minigames/books_sorting/books_sorting_minigame.gd`
- `game/minigames/books_sorting/books_sorting_minigame.tscn`
- `game/minigames/books_sorting/standalone/book_sorting_standalone.gd`
- `game/minigames/books_sorting/standalone/book_sorting_standalone.tscn`

Nové soubory (smí vytvořit):
- `game/minigames/books_sorting/standalone/children_distraction_manager.gd`

## Technický popis

### 1. `books_sorting_minigame.gd` — Distraction trigger + overlay

**Nový signal:**
```gdscript
signal distraction_warned  # emitted when whisper timer fires
signal distraction_expired # emitted when countdown hits zero (only if not caught)
```

**Nový export:**
```gdscript
@export var distraction_enabled: bool = false
@export var distraction_delay_min: float = 20.0   # sekund od startu než se spustí
@export var distraction_delay_max: float = 40.0
@export var distraction_countdown: float = 15.0   # sekund na reakci hráče
```

**Nový UI prvek v `books_sorting_minigame.tscn`:**
Přidej `DistactionWarning` container (defaultně skrytý) s:
- Label: "Šepty šepty, šušky-šušky!" (tučně, výrazná barva)
- Label pro countdown: "Jdi je odehnat! [15]"
- ProgressBar pro countdown (vizualizace ubývajícího času)

**Logika:**
1. V `_ready()`: pokud `distraction_enabled`, nastav náhodný Timer `distraction_delay_min..distraction_delay_max`
2. Po uplynutí delaye: emituj `distraction_warned`, zobraz `DistactionWarning`, spusť countdown timer
3. Countdown se zobrazuje v UI (odpočítává sekundy dolů)
4. Pokud volána metoda `distraction_caught()`: skryj overlay, zastav countdown, **neemituj** `distraction_expired`
5. Pokud countdown doběhne: emituj `distraction_expired`, skryj overlay

### 2. `children_distraction_manager.gd` — Nový script

Zodpovídá za koordinaci dětí v library interior při distrakcí.

```gdscript
class_name ChildrenDistractionManager
extends Node

signal distraction_started(target_bookshelf: Bookshelf)
signal distraction_caught      # hráč chytil děti včas
signal distraction_failed      # děti stihly rozházet regál

@export var children: Array[Node] = []         # reference na NPC dětí
@export var bookshelves_manager: BookshelfManager
@export var player: Player

var _active: bool = false
var _target_bookshelf: Bookshelf = null
var _original_positions: Dictionary = {}  # NPC → Vector2

func start_distraction() -> void:
    # 1. Ulož původní pozice dětí
    # 2. Vyber náhodný SEŘAZENÝ regál jako cíl (nebo první pokud žádný seřazen)
    # 3. Pohni dětmi (NavigationController) směrem k cílovému regálu
    # 4. Označ _active = true
    # 5. Emituj distraction_started(target_bookshelf)

func stop_distraction_caught() -> void:
    # 1. Zastav děti
    # 2. Emituj distraction_caught
    # 3. Pošli děti zpět na původní pozice
    # 4. _active = false

func stop_distraction_failed() -> void:
    # 1. Nechej děti dokončit pohyb nebo teleportuj k regálu
    # 2. Zavolej _scramble_bookshelf(_target_bookshelf)
    # 3. Pošli děti zpět na původní pozice
    # 4. Emituj distraction_failed
    # 5. _active = false

func _scramble_bookshelf(bookshelf: Bookshelf) -> void:
    # 1. Zamíchej bookshelf.data.sorting_book_resources (Array.shuffle())
    # 2. bookshelf.data.sorted = false
    # 3. Zavolej bookshelf.change_texture_to_unsort() nebo ekvivalent
    # (zkontroluj API Bookshelf — viz bookshelf.gd)

func notify_player_near_children() -> void:
    # Voláno když hráč interaguje s dítětem během aktívní distrakce
    if _active:
        stop_distraction_caught()
```

### 3. `book_sorting_standalone.gd` — Propojení

Po přijetí signálu `distraction_warned` z minihry:
- Zavolej `_children_distraction_manager.start_distraction()`

Po přijetí `distraction_expired`:
- Zavolej `_children_distraction_manager.stop_distraction_failed()`

Pokud `distraction_failed` → regál byl rozházán:
- Dekrementuj `_sorted_count` (regál opět není seřazen)
- Umožni hráči k regálu jít a znovu ho seřadit (signál `book_sorting_requested` přijde znovu automaticky přes Bookshelf)

### 4. `book_sorting_standalone.tscn` — Scene změny

- Přidej `ChildrenDistractionManager` node (nebo jako `@onready` child)
- Nastav references (`children`, `bookshelves_manager`, `player`)
- Nastav export property `distraction_enabled = true` na BookSortingMinigame instanci (pokud se předává přes kód, přidej setter v standalone)

## Acceptance Criteria

Ověř z diffu:

1. **AC1**: `books_sorting_minigame.gd` obsahuje export properties `distraction_enabled`, `distraction_delay_min`, `distraction_delay_max`, `distraction_countdown` a signály `distraction_warned`, `distraction_expired`
2. **AC2**: `books_sorting_minigame.tscn` obsahuje DistactionWarning UI element (Label + ProgressBar nebo Label s časem)
3. **AC3**: Existuje `children_distraction_manager.gd` s metodami `start_distraction()`, `stop_distraction_caught()`, `stop_distraction_failed()` a signály `distraction_started`, `distraction_caught`, `distraction_failed`
4. **AC4**: `book_sorting_standalone.gd` propojuje signály minihry s `ChildrenDistractionManager`
5. **AC5**: `_scramble_bookshelf()` nastaví `bookshelf.data.sorted = false` a zamíchá books array
6. **AC6**: Po scramble může hráč znovu seřadit rozházený regál (standalone neblokuje opakované řazení)

## Notes

- Zkontroluj `game/objects/bookshelf/bookshelf.gd` pro správné API (jak změnit texturu zpět na unsorted, jak jsou data strukturována)
- Zkontroluj `game/characters/navigation_controller.gd` pro správné API pohybu dětí
- Děti v scéně jsou Node typy — zkontroluj jejich třídy a zda mají NavigationController
- Pokud Bookshelf nemá metodu `change_texture_to_unsort()`, zkontroluj existující metody a použij správnou
