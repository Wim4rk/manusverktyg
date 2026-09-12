# Manusverktyg

Vill du bara komma igång: **[KVICKGUIDE.md](KVICKGUIDE.md)**. Vill du veta
hur allt fungerar: **[HANDBOK.md](HANDBOK.md)**.

Projektet består av tre verktyg för vägen från
[markdown](https://commonmark.org/help/) till färdigt manus, samlade under
kommandot: `manus`.

```bash
manus lint       # en mening per rad, städade mellanslag
manus bygg       # kör Pandoc på alla numrerade dokument, i nummerordning
manus talstreck  # ändrar citatrepliker till talstreck
```

Allt - kommandon, hjälptexter och dokumentation - är på svenska.

Verktygen förutsätter genomgående ett skönlitterärt manus: kapitel i
läsordning, repliker och berättande De är _inte_ gjorda för facklitteratur,
rapporter eller teknisk dokumentation. De hanterar inte korsreferenser, 
källhänvisningar, register och figurnumrering bl. a.

Slutstationen är [Pandoc](https://pandoc.org/) som sammanställer ett dokument
i ett av tre format.

## Projektets syfte

Manusverktygen utför ändringar i filer för att göra dem uniforma och
föbereda kompilering till ett manus.

**Markdown är en förutsättning**.
Markdown är utmärkt för att skriva text utan att behöva bry sig om format
eller utseende. Källfilen är _läsbar för människor_, och det underlättar
samarbete och redigering. Manusverktygen är beroende av filer i
markdown. Det läser .md och .txt-filer.

**Numreringen bär strukturen**
Kapitelordningen utgår från numrerade filer. Ingen databas, ingen
manifestfil som kan komma ur synk med verkligheten. Genom att ändra
filnamn styr du texternas ordnng. Det syns också bra i en `git log`.
Se nedan för fil- och katalognumreringar.

Textordningen kan också styras med en yaml-fil. Använd flaggan
`--manifest`. Verktyget varnar för varje fil som eventuellt fallit ur
listan - se [Manifest](HANDBOK.md#manifest---när-numreringen-inte-passar).

**Anteckningar är inte kapitel.**
Ett manus samlar på sig research, makulatur och skisser. Sådant får inte
råka hamna i boken. En onumrerad katalog hamnar därför utanför bygget - 
men går att bygga för sig om det behövs. Samma med onumrerade filer.

**Verktygen ska säga vad de gör.**
`manus bygg` skriver ut kapitelordningen, vilka stilmallar den hittade och
vilket typsnitt den valde, innan Pandoc kör. Fel kapitelordning är det enda
felet som inte syns förrän någon läser boken.

**Källfilen ska vara läsbar för människor.**
Versionshanterar du med git syns en ändrad mening som en ändrad rad, i
stället för att hela stycket lyser upp. Det är vad `manus lint` ordnar.

**Ingenting får försvinna.**
Originalen rörs aldrig om du inte anger flaggan `--in-place`, och då sparas
ändå en backup, `.bak`.

## Installation

```bash
make install        # länkar 'manus' till ~/.local/bin
make check          # kontrollerar skript och beroenden
make uninstall
```

Installationen är en **symlänk**, inte en kopia, så ändringar i repot slår
igenom direkt. Vill du ha det någon annanstans: `make install PREFIX=/usr/local`.

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
| [HANDBOK.md](HANDBOK.md) | reglerna bakom, och vad som händer när det inte gör det |
| [PANDOC.md](PANDOC.md) | Pandoc: format, flaggor, markdown-dialekt |

Fullständig hjälp finns i verktygen själva: `manus hjälp`,
`manus lint --help`, `manus talstreck --help`, `manus bygg --help`.
