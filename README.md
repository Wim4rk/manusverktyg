# manusverktyg

Två verktyg för vägen från markdown till färdigt manus, samlade under ett
kommando: `manus`.

```bash
manus lint    # en mening per rad, städade mellanslag
manus bygg    # kör Pandoc på alla numrerade dokument, i nummerordning
```

Allt — kommandon, hjälptexter och dokumentation — är på svenska.

## Vad projektet vill

**Källfilen ska vara läsbar för människor, inte bara för Pandoc.**
Ett manus lever i git i flera år, och då spelar det roll hur ändringar ser
ut. Ligger ett stycke på en enda lång rad lyser hela stycket upp i en diff
så fort du rättar ett ord. Ligger varje mening på egen rad ser du exakt
vilken mening som ändrades. Det är den enda ändring `manus lint` gör åt
brödtexten, och den ändrar aldrig hur något renderas — en ensam radbrytning
är en mjuk brytning i Markdown och betyder mellanslag.

**Numreringen ska bära strukturen, inte en projektfil.**
Kapitelordningen finns i filnamnen. Ingen databas, ingen manifestfil som
kan komma ur synk med verkligheten. Byter du ordning byter du namn, och det
syns i `git log`.

**Anteckningar är inte kapitel.**
Ett manus samlar på sig research, makulatur och skisser. Sådant får inte
råka hamna i boken bara för att filerna är numrerade. En onumrerad katalog
är därför utanför bygget — men går att bygga för sig när du vill läsa den.

**Verktygen ska säga vad de gör.**
`manus bygg` skriver ut kapitelordningen, vilka stilmallar den hittade och
vilket typsnitt den valde, innan Pandoc kör. Fel kapitelordning är det enda
felet som inte syns förrän någon annan läser boken.

**Ingenting får försvinna.**
Originalen rörs aldrig utan `--in-place`, och då sparas en `.bak`.
Meningsdelaren är medvetet försiktig: vid minsta tvekan lämnas raden
hopfogad. En missad brytning kostar en lång rad, ingenting annat.

Verktygen arbetar på vanlig markdown och förutsätter ingenting om var
filerna kommit ifrån.

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

## Snabbstart

Ställ dig i bokens katalog:

```bash
manus bygg --lista                  # kontrollera kapitelordningen FÖRST
manus bygg --lint -o bok.pdf -- --pdf-engine=xelatex --toc
```

## Vilka filer tas med, och i vilken ordning

Sökningen går **rekursivt** genom hela trädet under katalogen du står i —
men bara genom **numrerade** kataloger.

| | Krav | Varför |
| --- | --- | --- |
| **Filer** | tre siffror först | kapitel är många och numreringen behöver luft: `010`, `020`, `021` |
| **Kataloger** | en siffra räcker | delar är få: `01_början`, `02_urtid` |

**En katalog som inte börjar med en siffra betyder att innehållet inte hör
till bygget.** Anteckningar, makulatur och skisser hålls utanför även om
filerna i dem är numrerade — vilket de gärna är, eftersom man vill kunna
bygga dem för sig.

```
Tidens_älv/
├── 01_början/
│   ├── 010_prolog.md          ✓
│   └── 020_ristningar.md      ✓
├── 02_urtid/
│   ├── 010_uppväxt.md         ✓
│   ├── research/              ✗  hoppas över helt
│   │   └── 010_boplatser.md      (även om filen är numrerad)
│   └── makulatur/             ✗
└── skisser/                   ✗
```

Katalogen du **står i** räknas alltid, oavsett vad den heter. Egna
anteckningar byggs alltså så här:

```bash
cd Tidens_älv/02_urtid/research
manus bygg -o anteckningar.pdf
```

### Ordningen

Filerna sorteras på **hela sökvägen**, så en numrerad katalog hamnar före
sitt eget innehåll och delarna kommer i nummerordning:

```
001_forord.md
01_början/010_prolog.md
01_början/020_ristningar.md
02_urtid/010_uppväxt.md
09_epilog/010_slutet.md
```

Numren måste ha lika många siffror inom varje nivå: `2_` sorterar **efter**
`10_`, medan `02_` sorterar före. Kör alltid `manus bygg --lista` först —
fel kapitelordning är det enda felet som inte syns förrän någon annan läser
boken.

`kapitel_001.md` och `01_utkast.md` tas inte med: siffrorna måste sitta
först, och filer kräver tre. Dolda kataloger och `*.pandoc.md` hoppas över.

## Typsnitt som kanske inte finns

xelatex **kraschar** om `mainfont` pekar på ett typsnitt som inte är
installerat: den försöker generera ett METAFONT-typsnitt, misslyckas, och
det blir ingen PDF alls. Ett manus som byggs på en annan dator än där det
skrevs ska inte stupa på det.

Ange därför reserver i metadatan:

```yaml
---
title: Tidens älv
author: Olov Wimark
lang: sv

mainfont: "Garamond"
mainfontfallback:
  - "EB Garamond"
  - "Liberation Serif"
---
```

`manus bygg` provar dem uppifrån och ned och använder det första som
verkligen finns installerat, och skriver ut vilket det blev:

```
Typsnitt: Garamond saknas — använder EB Garamond i stället.
```

Finns inget av dem tas `mainfont` bort helt och Pandoc bygger med sitt
vanliga typsnitt — hellre en PDF med fel typsnitt än ingen PDF alls.

Kontrollen görs med `fc-list` och exakt familjenamn. `fc-match` duger inte:
den svarar med ett ersättningstypsnitt och påstår därmed att allt finns.

> **Namnkrock:** Pandoc har sedan 3.2 en egen variabel som också heter
> `mainfontfallback`, men den betyder *teckenfallback* — den fyller i
> enstaka glyfer som saknas i huvudtypsnittet, och bara för lualatex. Här
> betyder nyckeln "reservtypsnitt om huvudtypsnittet saknas".

## Byggtillgångar

Tre filer plockas upp automatiskt om de finns:

| Fil | Gör vad | Gäller |
| --- | --- | --- |
| `custom-reference.docx` | stilmall (typsnitt, marginaler, rubriker) | docx, odt, pptx |
| `vit-bakgrund.css` | vit bakgrund | html, epub |
| `swedish-quotes.lua` | svenska citattecken (`”`) på båda sidor | alla format |

Pandocs förvalda stilmall sätter `html { background-color: #fdfdfd }` — inte
riktigt vitt, vilket läses som en grå ton i e-boksläsare. `vit-bakgrund.css`
läggs efter pandocs egen och vinner. Den rör ingenting annat än bakgrunden;
typsnitt och marginaler lämnas åt läsaren.

### Stilmallen — så fungerar den

Du behöver inte göra något. Två villkor gäller:

1. Filen måste heta **exakt** `custom-reference.docx`
2. Utformatet måste vara docx, odt eller pptx — Pandoc struntar tyst i
   stilmallen för PDF och EPUB, så samma kommando fungerar för alla format

`manus bygg` skriver ut vad den hittade innan Pandoc kör, så du ser direkt
om den kom med:

```
Använder:
  stilmall:  ./bygg/custom-reference.docx
```

### Var den ska ligga

Fyra platser, i prioritetsordning — **första träffen vinner**:

```
./custom-reference.docx              ← bokens egen
./bygg/custom-reference.docx
./.pandoc/custom-reference.docx
tillgangar/                          ← den allmänna, i det här repot
```

Den allmänna ligger redan på plats, så utan att du gör något används den
för alla böcker.

`./` betyder katalogen du **står i när du kör kommandot**, inte där
kapitlen ligger. Står du i bokens rot och kapitlen ligger i underkataloger
är det bokens rot som räknas.

### Fler än en

Ja, på två sätt som gör olika saker:

**En egen per bok.** Lägg en `custom-reference.docx` i bokens katalog eller
i `bygg/`. Den slår den allmänna automatiskt, utan flaggor. Bra när en bok
ska se annorlunda ut än resten.

**Flera varianter i samma bok.** Peka ut dem med `-r`:

```bash
manus bygg -o inlamning.docx -r mallar/forlag.docx
manus bygg -o korrektur.docx -r mallar/dubbelt-radavstand.docx
```

`-r` tar vilket filnamn som helst, var som helst. Automatiken letar bara
efter namnet `custom-reference.docx`, så varianter med andra namn *måste*
pekas ut med `-r`. Anger du `-r` görs ingen automatisk sökning alls.

`--utan-mall` stänger av automatiken helt. Ger du både `--utan-mall` och
`-r` vinner `-r` — en uttrycklig flagga går före ett avstängt automatläge.

### Skapa eller ändra en stilmall

Pandoc kan skriva ut sin egen som utgångspunkt:

```bash
pandoc --print-default-data-file reference.docx > custom-reference.docx
```

Öppna den i Word eller LibreOffice, ändra formatmallarna (`Body Text`,
`Heading 1` …), och spara. Skriv ingen brödtext i den — bara stilarna
används.

## Katalogstruktur

```
bin/manus              vägvisaren: manus lint / manus bygg
lib/lint.sh            städningen
lib/bygg.sh            pandoc-körningen
tillgangar/            stilmallar och lua-filter
```

Fullständig hjälp finns i verktygen själva: `manus hjälp`,
`manus lint --help`, `manus bygg --help`.
