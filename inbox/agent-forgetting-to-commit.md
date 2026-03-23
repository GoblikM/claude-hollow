# Agent zapomíná commitovat změny

Opakovaně se stává, že agent provede správné změny v kódu, ale nevytvoří commit (výstup: "Agent nevytvořil žádné commity"). Orchestrátor pak musí commitovat ručně.

Možné řešení: do task.md šablony přidat explicitní instrukci "Po každé změně souboru ihned vytvoř commit s popisným message."
