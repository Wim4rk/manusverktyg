# Manusverktyg

Vill du bara komma igång: **[KVICKGUIDE.md](KVICKGUIDE.md)**. Vill du veta
hur allt fungerar: **[HANDBOK.md](HANDBOK.md)**.

Projektet består av tre verktyg för vägen från
[markdown](https://commonmark.org/help/) till färdigt manus, samlade under
kommandot: `manus`.

```bash
manus lint       # en mening per rad, städade mellanslag
manus talstreck  # ändrar citatrepliker till talstreck
manus bygg       # kör Pandoc på alla numrerade dokument, i nummerordning
```

Allt - kommandon, hjälptexter och dokumentation - är på svenska.

Verktygen förutsätter genomgående ett skönlitterärt manus: kapitel i
läsordning, repliker och berättande De är _inte_ gjorda för facklitteratur,
rapporter eller teknisk dokumentation. De hanterar inte korsreferenser, 
källhänvisningar, register och figurnumrering bl. a.

Slutstationen är [Pandoc](https://pandoc.org/) som sammanställer ett dokument
i ett av tre format. Word (.docx), PDF, eller e-läsare (e-pub).

## Projektets syfte

Manusverktygen utför ändringar i filer för att göra dem uniforma och
föbereda sammanställning till ett manus.

**Markdown är en förutsättning**.
Markdown är utmärkt för att skriva text utan att behöva bry sig om format
eller utseende. Källfilen är _läsbar för människor_, och underlättar
samarbete och redigering. Manusverktygen är beroende av filer i
markdown. De läser .md och .txt-filer.

**Anteckningar.**
Anteckningar, research och refuserat kan ligga var som helst bland
dina kataloger. Så länge filnamnen inte börjar med siffror så 
ignoreras de. Samma med onumrerade kataloger.

**Ingenting får försvinna.**
Originalen rörs aldrig om du inte anger flaggan `--in-place`, och då sparas
ändå en backup, `.bak`. Spara alltid dina filer tills du är helt säker 
på att du inte behöver dem.

## Installation

```bash
make install        # länkar 'manus' till ~/.local/bin
make check          # kontrollerar skript och beroenden
make uninstall
```

Installationen är en **symlänk**, inte en kopia, så ändringar i verktygen slår
igenom direkt. Vill du ha dem någon annanstans: `make install PREFIX=/usr/local`.

Beroenden: `pandoc`, `awk`, `find`, `fc-list` (fontconfig). För PDF med eget
typsnitt behövs dessutom `xelatex` (`texlive-xetex`).

## Projektets katalogstruktur

```
bin/manus              vägvisaren: manus lint / talstreck / bygg
lib/lint.sh            städaren
lib/talstreck.sh       replikomvandlaren
lib/bygg.sh            pandoc-körningen
assets/                stilmallar och lua-filter
```

## Dokumentation

| Fil | För |
| --- | --- |
| [KVICKGUIDE.md](KVICKGUIDE.md) | kommandona, så länge allt går rätt |
| [HANDBOK.md](HANDBOK.md) | reglerna bakom, och när det inte går rätt |
| [PANDOC.md](PANDOC.md) | Pandoc: format, flaggor, markdown-dialekt |

Fullständig hjälp finns i verktygen: `manus hjälp`,
`manus lint --help`, `manus talstreck --help`, `manus bygg --help`.
