# Task: children-confrontation

## Cíl

Implementovat interakci hráče s dětmi během distrakce: hráč přijde k dětem, spustí dialog ("seřve" je), děti se otočí a utečou zpět do chodby/původní pozice.

## Kontext

**Předpoklad**: Task `children-distraction-system` je hotový. `ChildrenDistractionManager` existuje a má metody `notify_player_near_children()`, `stop_distraction_caught()`.

Děti v standalone scéně jsou NPC charaktery. V library interior nemají defaultně nastavený interakční dialog. Pro tuto feature potřebují:
1. Dočasný interakční label (nebo bez labelu — hráč jde k nim a zmáčkne interact)
2. Dialog, kde hráč je seřve
3. Po dialogu: `ChildrenDistractionManager.notify_player_near_children()` → děti utečou

## Scope

Agent smí měnit POUZE tyto soubory:
- `game/minigames/books_sorting/standalone/book_sorting_standalone.gd`
- `game/minigames/books_sorting/standalone/book_sorting_standalone.tscn`
- `game/minigames/books_sorting/standalone/children_distraction_manager.gd`

Nové soubory (smí vytvořit):
- `game/minigames/books_sorting/standalone/book_sorting_deti.dialogue`

## Technický popis

### 1. `book_sorting_deti.dialogue` — Konfrontační dialog

```
~ serev

{{hrac}}: Hej! Co tady děláte?! Okamžitě pryč od těch regálů!
Dite: Áách! Promiň, promiňte! Utíkáme!

=> END
```

Poznámka: `{{hrac}}` je placeholder pro jméno hráče (viz jiné dialogue soubory v projektu).

### 2. Interakce hráče s dítětem

Možnosti implementace (zkontroluj co dává smysl po přečtení kódu):

**Varianta A — přes `Area2D` proximity:**
V `book_sorting_standalone.gd` přidej logiku: pokud je aktivní distrakce a hráč vstoupí do určité vzdálenosti od jakéhokoli dítěte → automaticky spusť dialog (bez nutnosti mačkat interact tlačítko).

**Varianta B — přes NPC interact:**
Nastav dětem `main_dialogue_resource` na `book_sorting_deti.dialogue` (sekce `serev`) dynamicky při startu distrakce. Hráč musí jít k dítěti a zmáčknout interact. Po dialogu reset.

Preferuj **Variantu A** (proximity trigger) pro lepší UX — hráč pod časovým tlakem nemá čas mačkat tlačítko.

**Implementace Varianty A v `book_sorting_standalone.gd`:**

```gdscript
const CONFRONT_DISTANCE: float = 80.0  # pixelů

func _physics_process(delta: float) -> void:
    if not _children_distraction_manager.is_distraction_active():
        return
    for child_npc in _children_distraction_manager.get_active_children():
        if player.global_position.distance_to(child_npc.global_position) < CONFRONT_DISTANCE:
            _on_player_confronted_children()
            return

func _on_player_confronted_children() -> void:
    player.lock()
    await Dialogs.start("serev", _deti_dialogue_resource)
    # nebo: await %Knihovnice.play_dialog(...) jako vzor — zkontroluj jak se spouští dialog bez NPC speakera
    _children_distraction_manager.notify_player_near_children()
    player.unlock()
```

Zkontroluj správné API pro spuštění dialogu bez konkrétního NPC speakera — viz vzory v ostatních .gd souborech.

### 3. `children_distraction_manager.gd` — Doplnění útěku

Rozšiř `stop_distraction_caught()`:
```gdscript
func stop_distraction_caught() -> void:
    _active = false
    # Zastav navigaci dětí
    for child in _active_children:
        child.get_node("NavigationController").stop()

    # Pošli děti zpět na původní pozice
    for child in _active_children:
        child.get_node("NavigationController").navigate_to(_original_positions[child])

    emit_signal("distraction_caught")
    _active_children.clear()
```

Zkontroluj správný název NavigationController nodu — viz `game/characters/navigation_controller.gd` a jak je dostupný přes `%NavigationController` nebo jinak.

### 4. Vizuální zpětná vazba útěku (volitelné, ale vhodné)

Pokud děti mají animaci "run" nebo jinou animaci pro rychlý pohyb — nastav ji při útěku. Pokud ne, postačí prostý pohyb zpět.

## Acceptance Criteria

Ověř z diffu:

1. **AC1**: Existuje `book_sorting_deti.dialogue` s sekcí `serev` (hráč seřve děti, děti se omluví a utečou)
2. **AC2**: `book_sorting_standalone.gd` implementuje proximity detekci pro konfrontaci (nebo NPC interact mechaniku)
3. **AC3**: Po konfrontaci se zavolá `_children_distraction_manager.notify_player_near_children()` nebo `stop_distraction_caught()`
4. **AC4**: Děti se po chycení pohnou zpět na původní pozice (NavigationController.navigate_to s uloženou původní pozicí)
5. **AC5**: Hráč je lock/unlock kolem dialogu (nezůstane uzamčený)
6. **AC6**: Konfrontace funguje pouze pokud je distrakce aktivní — mimo distrakcí se nic neděje

## Notes

- Zkontroluj `game/characters/navigation_controller.gd` pro správné metody (stop, navigate_to)
- Zkontroluj jak se v projektu spouští dialogový systém bez konkrétního NPC — viz vzory v `book_sorting_standalone.gd` (`await %Knihovnice.play_dialog(...)`) nebo `Dialogs.start(...)`
- Původní pozice dětí jsou v `_original_positions` dictionary (uloženy v `children_distraction_manager.gd` při `start_distraction()`)
