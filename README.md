# Manusverktyg

Om du bara vill komma igång finns en **[KVICKGUIDE.md](KVICKGUIDE.md)**.

Projektet består av tre verktyg för vägen från
[markdown](https://commonmark.org/help/) till färdigt manus, samlade under
kommandot: `manus`.

```bash
manus lint       # en mening per rad, städade mellanslag
manus bygg       # kör Pandoc på alla numrerade dokument, i nummerordning
manus pratminus  # ändrar citatrepliker till pratminus
```

Allt — kommandon, hjälptexter och dokumentation — är på svenska.

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
listan — se [Manifest](#manifest--när-numreringen-inte-passar).

**Anteckningar är inte kapitel.**
Ett manus samlar på sig research, makulatur och skisser. Sådant får inte
råka hamna i boken. En onumrerad katalog hamnar därför utanför bygget — 
men går att bygga för sig om det behövs. Samma med onumrerade filer.

**Verktygen ska säga vad de gör.**
`manus bygg` skriver ut kapitelordningen, vilka stilmallar den hittade och
vilket typsnitt den valde, innan Pandoc kör. Fel kapitelordning är det enda
felet som inte syns förrän någon läser boken.

Om du använder _git_ för att versionshantera ditt manuskript, då underlättar
det att dela upp dokumentet så att varje mening får sin egen rad.
Ligger ett stycke på en enda lång rad lyser hela stycket upp i en `git diff`
så fort du rättar ett ord. Ligger varje mening på egen rad ser du exakt
vilken mening som ändrades. Det är den enda ändring `manus lint` gör åt
brödtexten, och den ändrar aldrig hur något renderas — en ensam radbrytning
är en mjuk brytning i Markdown och betyder mellanslag. För nytt stycke
krävs en tom rad emellan.

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

## Vilka filer tas med, och i vilken ordning

Sökningen går **rekursivt** genom hela trädet under katalogen du står i —
men bara genom **numrerade** kataloger.

|               | Krav              | Varför |
| ------------- | ----------------- | --------------------------------------- |
| **Filer**     | tre siffror först | kapitel kan vara många och numreringen behöver luft: `010`, `020`, `021` |
| **Kataloger** | två siffra räcker | delar är få: `01_kapitel_ett`, `02_kapitel_tva` |

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
`--in-place`, och då sparas en `.bak`. Flaggan `--lista` visar varje stycke
som skulle ändras, före och efter, utan att röra någon textfil — kör alltid
det först.

Ett stycke görs om bara när alla tre stämmer: det **börjar** med ett
citattecken, har ett avslutande, och ser ut som en replik — slutar med
skiljetecken innanför citatet eller följs av ett kommatecken utanför det.

Kommatecknet räknas åt **båda** hållen. Korrekt svenska sätter det utanför
citattecknet, men innanför är vanligt i praktiken, och när mönstret dyker
upp är det med säkerhet en replik:

```
”Det blir bra”, säger Ulf.      →   -- Det blir bra, säger Ulf.
”Vilket väder,” säger Sara.     →   -- Vilket väder, säger Sara.
```

Båda ger samma resultat, eftersom kommat hamnar rätt av sig självt när
citattecknen faller bort.

Den sista regeln finns för att ett citat först på raden inte alltid är en
replik:

```
”Nomen libri” är arbetsnamnet.        lämnas orörd — en titel, inte en replik
”Han sa ”hej” till mig”, sa hon.      lämnas orörd — nästlade citat
```

Hellre en replik du får göra om för hand än en mening som tyst blir
förvanskad.

**Fler än en replik i stycket.** Det vanligaste mönstret i svensk dialog är
replik, berättande, replik i ett och samma stycke:

```
”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
```
```
-- Jag gjorde det. Han såg bort. Det var nödvändigt.
```

Pratminus markerar en **replikväxling**, inte varje yttrande. Samma person
talar, det kommer ett berättande avsnitt, samma person fortsätter — allt är en
och samma rad. Därför sätts ett enda pratminus först i stycket, de inre
citattecknen faller bort, och stycket delas **inte**. En delning skulle
påstå att någon annan tar över.

**Står repliken inte först** i stycket bryts stycket i stället:

```
Hon vände sig om. ”Vad gör du?” frågade hon.
```
```
Hon vände sig om.

-- Vad gör du? frågade hon.
```

Pratminus måste inleda stycket, och här är det en **ny** talartur som
börjar — till skillnad från fallet ovan, där samma tur fortsätter efter en
beat. Berättandet blir ett eget stycke.

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

Varje körning skriver en att-göra-lista, `CITAT_PROBLEM.md`, i katalogen
**där du står**:

```markdown
# Citatproblem

- [ ] `02_urtid/010_en_svår_födelse.md` rad 85

  > Yhla suckade. ”Var gömde du honom? Frågade hon hest.

---

1 stycke kvar. Senast genomsökt 2026-09-10.
```

Listan gäller **körningen**, inte en katalog, och stämmer därför alltid —
oavsett hur många filer som lästes. Står du i bokens rot och kör utan
filargument får du hela bokens problem i en lista där; står du i ett kapitel
får du kapitlets. Sökvägarna skrivs relativt samma katalog som listan ligger
i.

Rätta i källfilen och kör igen, så uppdateras listan. Hittar körningen inga
problem **tas filen bort** — en lista som ligger kvar tom läses som att det
finns något ogjort.

Filen är genererad och skrivs över varje gång, så egna anteckningar i den
överlever inte. Den läses aldrig in som källtext och kan alltså inte råka bli
manus.

`--rapport FIL` lägger listan någon annanstans. `--ingen-rapport` rör ingen
lista alls.

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

`-m, --manifest filnamn.yaml` bygger i stället det som räknas upp i aktuell
fil, i den ordning det står där:

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

Om du bara vill skriva in de filer du vill ha med så går det också. Lägg
till det här i slutet av manifestet.

```yaml
metadata:
  manus-uteslut:
    - "*"
    - "*/*"
```

Samma fil går att köra rakt igenom Pandoc utan manusverktygen:

```bash
pandoc --defaults=urval.yaml -o urval.docx
```

Då uteblir lint, typsnittskontrollen och den automatiska
stilmallen. Att `manus-uteslut` ligger under `metadata:` är
avsiktligt: Pandoc vägrar okända nycklar på toppnivån men släpper igenom
vad som helst där, så filen förblir giltig åt båda hållen.

> **Sökvägarna räknas från katalogen du står i**, inte från manifestets egen
> katalog. Det är Pandocs regel för `--defaults` och gäller därför här också.
> Står du på fel ställe räknas de saknade filerna upp, och bygget avbryts.

### Varför uteslutningslistan finns

Numreringen har **en** sanningskälla: trädet. Du måste följa konventionen 
med numrerade kataloger och filnamnen måste _alltid_ ha tre siffror för
att komma med.

Ett manifest har **två** källor, och dåvkan de glida isär. Ett kapitel du
skrivit men glömt lägga till i listan byggs tyst bort — och det märks
först när någon läser boken.

Med manifrestet räknas därför varje byggbar fil i trädet som inte står i
`input-files` eller matchar ett mönster i `manus-uteslut` upp som en varning:

```
VARNING: 1 fil(er) i trädet står varken i manifestet
         eller under manus-uteslut:
             bortglömd.md
```

Att tysta en fil kräver alltså att du skriver in den — du bestämmer, men
glöm inget. Varningen är en garanti att ingenting försvinner tyst.

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
> `mainfontfallback`, men den betyder *teckenfallback* - den fyller i
> enstaka glyfer som saknas i huvudtypsnittet, och bara för lualatex. Här
> betyder nyckeln "reservtypsnitt om huvudtypsnittet saknas".

## Tillgångar - assets

Tre filer används automstiskt så länge de finns.

| Fil                     | Styr                                      | Gäller          |
| ----------------------- | ----------------------------------------- | --------------- |
| `custom-reference.docx` | stilmall (typsnitt, marginaler, rubriker) | docx, odt, pptx |
| `vit-bakgrund.css`      | vit bakgrund                              | html, epub      |
| `swedish-quotes.lua`    | svenska citattecken (`”`) på båda sidor   | alla format     |

Pandocs förvalda stilmall sätter `html { background-color: #fdfdfd }` — inte
riktigt vitt, vilket läses som en grå ton i e-boksläsare. `vit-bakgrund.css`
läggs efter pandocs egen och vinner. Den rör ingenting annat än bakgrunden;
typsnitt och marginaler lämnas som de är.

## Stilmallen

Du kan skapa en stilmall genom att redigera dokumentet `custom-referene.docx`
som ligger i mappen assets. Ändra typsnitt för brödtext och titlar, och
linjeavstånd så har du kommit långt. Den medföljande filen är Pandocs egen
standardfil. Lägg förslagsvis din egen uppdaterade stilmall i 
`./.pandoc/custom-regence.docx`

Filen används automatiskt. Du behöver inte göra något. Men två villkor gäller:

1. Filen måste heta **exakt** `custom-reference.docx`
2. Utformatet måste vara docx, odt eller pptx — Pandoc struntar tyst i
   stilmallen för PDF och EPUB, så samma kommando fungerar för alla format

`manus bygg` skriver ut vad den hittade innan Pandoc kör, så du ser direkt
vilken mall den valde:

```
Använder:
  stilmall:  ./bygg/custom-reference.docx
```

### Var ska den ligga?

Det finn fyra giltiga platser, och de tillämpas i prioritetsordning. Om du
lägger en kopia direkt i bokens katalog så är det alltid den som vinner.

```
./custom-reference.docx              ← bokens egen
./bygg/custom-reference.docx
./.pandoc/custom-reference.docx
assets/                              ← den allmänna, i det här repot
```

Den allmänna ligger redan på plats, så om du inte gör något så används den
för alla böcker.

### Kan jag ha fler än en

Ja, det kan du.

**En egen per bok.** Lägg en `custom-reference.docx` i bokens katalog eller
i `bygg/`. Den slår den allmänna automatiskt, utan flaggor. Bra när böcker
ska se olika ut. Kanske när du skickar ett manus till olika förlag.?

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

Du kan be pandoc att skriva ut sin egen standardmall som du kan ha som
utgångspunkt:

```bash
pandoc --print-default-data-file reference.docx > custom-reference.docx
```

Öppna den i Word, ändra formatmallarna (`Body Text`, `Heading 1` …), och
spara. Ändra inte texten - bara stilarna kommer användas.

Den bifogade filen i projektet är pandocs standard. Det är bara att formatera
om den och jobba vidare.

## Projektets katalogstruktur

```
bin/manus              vägvisaren: manus lint / pratminus / bygg
lib/lint.sh            städaren
lib/pratminus.sh       replikomvandlaren
lib/bygg.sh            pandoc-körningen
assets/                stilmallar och lua-filter
```

Fullständig hjälp finns i verktygen själva: `manus hjälp`,
`manus lint --help`, `manus bygg --help`.
