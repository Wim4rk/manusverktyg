# manusverktyg

Två verktyg för vägen från markdown till färdigt manus, samlade under ett
kommando: `manus`.

```bash
manus lint       # en mening per rad, städade mellanslag
manus pratminus  # citatrepliker till pratminus
manus bygg       # kör Pandoc på alla numrerade dokument, i nummerordning
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
syns i `git log`. För sammanställningar som numreringen inte passar för
finns `--manifest`, men då varnar verktyget för varje fil som fallit ur
listan — se [Manifest](#manifest--när-numreringen-inte-passar).

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
| **Filer** | tre siffror först | kapitel kan vara  många och numreringen behöver luft: `010`, `020`, `021` |
| **Kataloger** | en siffra räcker | delar är få: `01_del_ett`, `02_del_tva` |

**En katalog som inte börjar med en siffra betyder att innehållet inte hör
till bygget.** Anteckningar, makulatur och skisser hålls utanför även om
filerna i dem är numrerade — vilket de gärna är, eftersom man vill kunna
bygga dem för sig.

```
MinBok/
├── 01_del_ett/
│   ├── 010_prolog.md          ✓
│   └── 020_inledning.md       ✓
├── 02_del_tva/
│   ├── 010_kapitel.md         ✓
│   ├── research/              ✗  hoppas över helt
│   │   └── 010_anteckning.md  (även om filen är numrerad)
│   └── makulatur/             ✗
└── skisser/                   ✗
```

Katalogen du **står i** räknas alltid, oavsett vad den heter. Egna
anteckningar byggs alltså så här:

```bash
cd MinBok/02_del_tva/research
manus bygg -o anteckningar.pdf
```

### Ordningen

Filerna sorteras på **hela sökvägen**, så en numrerad katalog hamnar före
sitt eget innehåll och delarna kommer i nummerordning:

```
001_forord.md
01_del_ett/010_prolog.md
01_del_ett/020_inledning.md
02_del_tva/010_kapitel.md
...
09_epilog/010_slutet.md
```

Numren måste ha lika många siffror inom varje nivå: `2_` sorterar **efter**
`10_`, medan `02_` sorterar före. Kör alltid `manus bygg --lista` först —
fel kapitelordning är det enda felet som inte syns förrän någon annan läser
boken.

`kapitel_001.md` och `01_utkast.md` tas inte med: siffrorna måste sitta
först, och filer kräver tre. Dolda kataloger och `*.pandoc.md` hoppas över.

## Repliker: citattecken till pratminus

Svensk skönlitteratur sätter oftast repliker med pratminus. Har du ett
manus skrivet med citattecken gör `manus pratminus` om dem:

```
”Heter du Elof?” frågade Eva.   →   -- Heter du Elof? frågade Eva.
```

**Vilka filer.** Utan filargument gäller samma regler som för `manus bygg`:
bara namn som börjar med tre siffror, och bara genom numrerade kataloger.
Anteckningar, research och makulatur hålls utanför här också.

```bash
manus pratminus --lista              # hela boken, bygg-reglerna
manus pratminus skisser/utkast.md    # en utpekad fil, oavsett namn
```

Pekar du ut en fil gäller precis den, oavsett vad den heter — ett utpekat
namn är ett medvetet val.

Den är lika försiktig som `manus lint`: originalet rörs aldrig utan
`--in-place`, och då sparas en `.bak`. `--lista` visar varje stycke som
skulle ändras, före och efter, utan att röra någon textfil — kör alltid det
först.

En rad görs om bara när alla tre stämmer: den **börjar** med ett
citattecken, har ett avslutande på samma rad, och ser ut som en replik —
slutar med skiljetecken innanför citatet eller följs av ett kommatecken
utanför det.

Den sista regeln finns för att ett citat först på raden inte alltid är en
replik:

```
”Nomen libri” är arbetsnamnet.        lämnas orörd — en titel, inte en replik
”Han sa ”hej” till mig”, sa hon.      lämnas orörd — nästlade citat
```

Hellre en replik du får göra om för hand än en mening som tyst blir
förvanskad. YAML-frontmatter, kodblock och HTML-kommentarer kopieras rakt
igenom — i arbetsanteckningar är citattecken ofta obalanserade med flit.

**Fler än en replik i stycket.** Det vanligaste mönstret i svensk dialog är
replik, berättande, replik i ett och samma stycke. Ett manus satt med
pratminus har i princip inga citattecken alls utom vid äkta citat, så alla
replikerna görs om och stycket delas framför varje ny:

```
”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
```
```
-- Jag gjorde det. Han såg bort.

-- Det var nödvändigt.
```

Berättandet stannar hos repliken det följer på.

### Stycket är enheten, inte raden

Framåtläsningen går över radgränser men stannar **alltid vid tomraden**.
Det ger två saker.

**Redan lintade filer fungerar.** En replik som `manus lint` delat över
flera rader är fortfarande ett stycke, och känns igen som en hel replik:

```
”Hej. Jag heter Eva.
Vad heter du?” frågade hon.
```

Ordningen mot `manus lint` spelar därför ingen roll. Lint ombryter inom
stycket och rör aldrig tomraderna, så ett stycke är samma sak före och
efter. Kör lint efteråt om du vill ha en mening per rad igen.

**Ett saknat citattecken blir ofarligt.** Ett stycke med udda antal
citattecken är obalanserat och lämnas helt orört:

```
Yhla suckade. ”Var gömde du honom? frågade hon.
```

Utan taket vid tomraden skulle det citatet svälja text ända fram till nästa
citattecken, kanske flera stycken bort.

### Arbetslistan

Varje körning skriver en att-göra-lista, `CITAT_PROBLEM.md`, i **varje
katalog** som innehåller en fil med obalanserade citat. Listan hamnar alltså
där arbetet ska göras, inte samlad på ett ställe:

```markdown
# Citatproblem

- [ ] **010_en_svår_födelse.md** rad 85

  > Yhla suckade. ”Var gömde du honom? Frågade hon hest.

---

1 kvar. Senast genomsökt 2026-09-10.
```

Rätta i källfilen och kör igen, så uppdateras listan. Blir en katalog ren
**tas filen bort** — en lista som ligger kvar tom läses som att det finns
något ogjort.

Bara kataloger som hör till **boken** får en lista, alltså kataloger med
numrerade filer. Anteckningar och makulatur samlar aldrig på sig
`CITAT_PROBLEM.md` — problemen syns i terminalen ändå när du kör på en
sådan fil uttryckligen.

En lista skrivs eller tas bort **bara om körningen läste alla numrerade
filer i katalogen**. Kör du på en enstaka fil kan verktyget inte veta om
grannfilerna har problem, och rör då inte listan:

```
DELVIS GENOMSÖKTA
    02_urtid: 1 av 7 filer lästa — CITAT_PROBLEM.md rörs inte
```

Annars skulle en körning på en ren fil kunna radera minnet av ett problem i
filen bredvid.

Filen är genererad och skrivs över varje gång — egna anteckningar i den
överlever inte. Den läses aldrig in som källtext, så `manus pratminus *.md`
tar inte med sin egen rapport.

`--rapport FIL` ger dessutom en samlad lista över hela körningen.
`--ingen-rapport` rör inga listor alls.

> **Ordningen mot `manus lint`:** kör `pratminus` **först**. Lint delar en
> replik som innehåller flera meningar över flera rader, och då sitter det
> avslutande citattecknet inte längre på samma rad som det inledande —
> ingenting konverteras. Åt andra hållet går det bra.

Förvalet är två bindestreck, eftersom Pandoc gör om `--` till ett riktigt
tankstreck vid rendering och `manus lint` känner igen formen. Vill du ha
tecknet direkt i källfilen ger `--tankstreck` det i stället.

## Manifest — när numreringen inte passar

Numreringen är förvalet och räcker för en bok som läses rakt igenom. Men
ibland ska något annat sammanställas: ett urval till en agent, ett utdrag
till en tävling, en inlämningsversion. Då är filerna godtyckliga, saknar
gemensam numrering och ska inte döpas om.

`-m, --manifest FIL` bygger i stället det som räknas upp i FIL, i den
ordning det står där:

```bash
manus bygg --manifest urval.yaml -o urval.docx
```

Manifestet är en **vanlig Pandoc-defaults-fil**:

```yaml
input-files:
  - inledning.md
  - "kapitel med mellanslag.md"

metadata:
  manus-uteslut:
    - "anteckningar/*"
    - makulatur.md
```

`input-files` ger ordningen — ingen sortering sker. Filnamn med mellanslag,
`#` eller kolon måste citeras, annars läser YAML dem som något annat.

Samma fil går att köra rakt igenom Pandoc utan verktyget:

```bash
pandoc --defaults=urval.yaml -o urval.docx
```

Då uteblir bara lint, typsnittskontrollen och den automatiska
stilmallsupplockningen. Att `manus-uteslut` ligger under `metadata:` är
avsiktligt: Pandoc vägrar okända nycklar på toppnivån men släpper igenom
vad som helst där, så filen förblir giltig åt båda hållen.

> **Sökvägarna räknas från katalogen du står i**, inte från manifestets egen
> katalog. Det är Pandocs regel för `--defaults` och gäller därför här också.
> Står du på fel ställe räknas de saknade filerna upp och bygget avbryts.

### Varför uteslutningslistan finns

Numreringen har **en** sanningskälla: trädet. Ett manifest har två, och då
kan de glida isär. Ett kapitel du skrivit men glömt lägga till i listan
byggs tyst bort — och det märks först när någon läser boken.

Därför räknas varje byggbar fil i trädet som varken står i `input-files`
eller matchar ett mönster i `manus-uteslut` upp som en varning:

```
VARNING: 1 fil(er) i trädet står varken i manifestet
         eller under manus-uteslut:
             glomd.md
```

Att tysta en fil kräver alltså att du skriver in den — att bestämma dig,
inte att glömma. Det är det som ger manifestet numreringens garanti att
ingenting försvinner tyst.

## Typsnitt som kanske inte finns

xelatex **kraschar** om `mainfont` pekar på ett typsnitt som inte är
installerat: den försöker generera ett METAFONT-typsnitt, misslyckas, och
det blir ingen PDF alls. Ett manus som byggs på en annan dator än där det
skrevs ska inte stupa på det.

Ange därför reserver i metadatan:

```yaml
---
title: Nomen libri
author: Scriptor Sum
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
typsnitt och marginaler lämnas som de är.

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
assets/                              ← den allmänna, i det här repot
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

Öppna den i Word, ändra formatmallarna (`Body Text`, `Heading 1` …), och
spara. Skriv ingen brödtext i den — bara stilarna används.

Den bifogade filen i projektet är pandocs standard. Det är bara att formatera
den och jobba vidare.

## Projektets katalogstruktur

```
bin/manus              vägvisaren: manus lint / pratminus / bygg
lib/lint.sh            städningen
lib/pratminus.sh       replikomvandlingen
lib/bygg.sh            pandoc-körningen
assets/                stilmallar och lua-filter
```

Fullständig hjälp finns i verktygen själva: `manus hjälp`,
`manus lint --help`, `manus bygg --help`.
