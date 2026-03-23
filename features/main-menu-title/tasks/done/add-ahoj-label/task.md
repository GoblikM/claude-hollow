# Task: Přidat nápis "ahoj" do hlavního menu

## Cíl

Přidat label s textem "ahoj" nad tlačítka v hlavním menu hry.

## Scope

- `game/ui/main_menu/main_menu.tscn`

## Acceptance Criteria

- V hlavním menu je nad tlačítky viditelný nápis "ahoj"
- Nápis je implementován jako Label node na začátku VBoxContaineru (před ostatními child nody)
- Scéna se korektně načítá bez chyb

## Kontext

Soubor: `game/ui/main_menu/main_menu.tscn`

Kořenový node je `VBoxContainer`. Nový Label přidat jako první child, před `ContinueContainer`.

Příklad struktury nového nodu v `.tscn`:

```
[node name="AhojLabel" type="Label" parent="."]
layout_mode = 2
text = "ahoj"
```

## Branch

`task/add-ahoj-label` (z `feature/main-menu-title`)
