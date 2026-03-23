# Task: standalone-second-phase-wiring

## Cíl

Propojit celou druhou fázi v orchestrátoru: přepnout intro dialog na verzi s varováním o dětech, správně předávat `skip_intro` a `distraction_enabled` do minihry, a přidat analytics eventy pro distrakcí.

## Kontext

**Předpoklad**: Tasky `children-distraction-system` a `children-confrontation` jsou hotové.

V `book_sorting_standalone.gd` je nyní natvrdo použita sekce `"uvod_bez_deti"`. Pro druhou fázi:
- **První spuštění**: použít `"uvod"` (s varováním o dětech)
- **Restart**: použít `"uvod_bez_deti"` (rychlý start)

`skip_intro` flag již existuje a nastavuje ho `MinigamesMenu` nebo scene caller — ověř jak.

Analytics eventy potřebují dokumentovat klíčové momenty distrakcí.

## Scope

Agent smí měnit POUZE tyto soubory:
- `game/minigames/books_sorting/standalone/book_sorting_standalone.gd`
- `game/minigames/books_sorting/standalone/book_sorting_standalone.tscn`
- `game/analytics/` (přidat nový analytics soubor pokud je potřeba, zkontroluj strukturu)

Nové soubory (smí vytvořit):
- `game/analytics/book_sorting_events.gd` (pokud neexistuje)

## Technický popis

### 1. Intro dialog — první vs. restart

Aktuální kód:
```gdscript
await %Knihovnice.play_dialog(%Knihovnice.main_dialogue_resource, player, "uvod_bez_deti")
```

Nový kód:
```gdscript
var dialogue_section := "uvod" if not skip_intro else "uvod_bez_deti"
# ale "uvod_bez_deti" je bez varování — přejmenuj logiku:
# skip_intro = true → kratší intro BEZ varování (restart)
# skip_intro = false → plné intro S varováním (první spuštění)
await %Knihovnice.play_dialog(%Knihovnice.main_dialogue_resource, player, dialogue_section)
```

### 2. `distraction_enabled` — předávání do minihry

V `_on_book_sorting_requested()`:
```gdscript
func _on_book_sorting_requested(bookshelf: Bookshelf) -> void:
    ...
    var books_sorting_minigame: BookSortingMinigame = Minigames.BOOKS_SORTING.instantiate()
    books_sorting_minigame.sorting_book_resources = bookshelf.data.sorting_book_resources
    books_sorting_minigame.standalone_player = player
    books_sorting_minigame.distraction_enabled = true  # ← nové
    ...
```

Pokud `distraction_enabled` v minihře spustí countdown jen poprvé v session — přidej flag v standalone aby se distrakce nespustila opakovaně na každý regál (nebo nech chování konfigurovatelné). Navrhuj rozumné UX — distrakce by se měla spouštět maximálně 1× za regál nebo s minimálním cooldownem.

### 3. Analytics eventy

Zkontroluj jak jsou analytics eventy definovány v projektu (pravděpodobně `Mixpanel.track(...)` nebo přes `Events` autoload). Najdi vzor v jiných minigame souborech.

Přidej tracking pro:
- `book_sorting_distraction_started` — distrakce spuštěna (properties: shelf_id, countdown_duration)
- `book_sorting_distraction_caught` — hráč děti chytil (properties: time_remaining)
- `book_sorting_distraction_failed` — hráč nestih, regál rozházán (properties: shelf_id)

### 4. Propojení signálů v `_ready()`

Zkontroluj a zajisti:
```gdscript
_children_distraction_manager.distraction_caught.connect(_on_distraction_caught)
_children_distraction_manager.distraction_failed.connect(_on_distraction_failed)
```

`_on_distraction_failed(bookshelf: Bookshelf)`:
- Odstraň tento regál ze "seřazených" (`_sorted_count -= 1` pokud byl seřazen)
- Resetuj `bookshelf.data.sorted = false` (možná již řeší ChildrenDistractionManager)
- Zajisti že hráč může regál znovu seřadit

## Acceptance Criteria

Ověř z diffu:

1. **AC1**: `book_sorting_standalone.gd` používá `"uvod"` sekci při `skip_intro == false` a `"uvod_bez_deti"` při `skip_intro == true`
2. **AC2**: `distraction_enabled = true` se předává instanci minihry v `_on_book_sorting_requested()`
3. **AC3**: Existují Mixpanel/analytics volání pro `book_sorting_distraction_started`, `book_sorting_distraction_caught`, `book_sorting_distraction_failed`
4. **AC4**: Po `distraction_failed` je `_sorted_count` dekrementován (nebo není inkrementován) a regál je opět přístupný k seřazení
5. **AC5**: Signály `distraction_caught` a `distraction_failed` z `ChildrenDistractionManager` jsou napojeny v `_ready()` nebo při inicializaci

## Notes

- Zkontroluj jak funguje `skip_intro` — kdo ho nastavuje a kdy
- Zkontroluj vzor Mixpanel tracking v jiných minigame souborech (hledej `Mixpanel.track`)
- Zkontroluj `game/analytics/` adresář pro strukturu analytics definic
- `_sorted_count` logika v `_on_book_sorting_requested()` — ověř kde se inkrementuje a jak správně resetovat po scramble
