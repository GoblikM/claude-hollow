# Paralelní běh agentů

## Idea

Umožnit spuštění více task agentů zároveň, aby se více tasků vykonávalo paralelně.

## Co by bylo potřeba

1. `cc.sh --background` — flag pro spuštění na pozadí, vrátí PID nebo název logu
2. Konvence v `task.md` pro označení paralelizovatelných tasků (žádné sdílené soubory, žádná závislost)
3. Orchestrátor volí, které tasky spustit paralelně a které sekvenčně

## Poznámky

- Izolace je už připravená — každý agent má vlastní klon
- Riziko: merge konflikty při úpravě stejných souborů
- Vyplatí se jen pro nezávislé tasky (různé soubory, žádné závislosti)
