# Handbok

Referensen för `manus`. Kvickguiden räcker så länge allt går rätt; det här
är för när du vill veta varför, eller när något inte gjorde som du tänkte.

- [Vilka filer tas med, och i vilken ordning](#vilka-filer-tas-med-och-i-vilken-ordning)
- [Städa texten: manus lint](#städa-texten-manus-lint)
- [Repliker: citattecken till talstreck](#repliker-citattecken-till-talstreck)
- [Manifest](#manifest---när-numreringen-inte-passar)
- [Typsnitt som kanske inte finns](#typsnitt-som-kanske-inte-finns)
- [Tillgångar och stilmall](#tillgångar---assets)
- [Om något går fel](#om-något-går-fel)

Pandocs egna flaggor, format och markdown-dialekt står i [PANDOC.md](PANDOC.md).

## Vilka filer tas med, och i vilken ordning

Sökningen går **rekursivt** genom hela trädet under katalogen du står i -
men bara genom **numrerade** kataloger.

|               | Krav                  | Förslag |
| ------------- | --------------------- | --------------------------------------- |
| **Filer**     | minst en siffra först | tre siffror ger luft att skjuta in ett kapitel: `010`, `020`, `021` |
| **Kataloger** | minst en siffra först | två räcker, delar är få: `01_kapitel_ett`, `02_kapitel_tva` |

**Det som måste stämma är att numren har lika många siffror inom samma
katalog.** Sorteringen är lexikografisk, inte numerisk, så `2_` hamnar
efter `10_` medan `02_` hamnar före. Blandar du bredder **byggs ingenting**
förrän du rättat det:

```
BLANDADE SIFFBREDDER. Sorteringen är lexikografisk, inte numerisk,
så 2_ hamnar EFTER 10_. Nollutfyll till samma bredd inom varje
katalog:
    katalogen du står i (filer): 10_kap.md, 1_kap.md

manus bygg: bygger inte förrän numreringen är enhetlig.
```

Fel kapitelordning är det enda felet som inte syns förrän någon läser
boken, så bygget stoppas hellre än ger en bok med kapitlen om varandra.
`manus bygg --lista` visar ändå listan, så du ser vad som blivit fel.

Filer och kataloger jämförs var för sig, så tre siffror på kapitlen och två
på delarna är helt i sin ordning.

**En katalog som inte börjar med en siffra betyder att innehållet inte hör
till bygget.** Anteckningar, makulatur och skisser hålls utanför även om
filerna i dem är numrerade - vilket de gärna är, eftersom man vill kunna
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

`kapitel_001.md` tas inte med - siffrorna måste sitta först. Dolda
kataloger och `*.pandoc.md` hoppas över.

## Städa texten: manus lint

`manus lint` lägger varje mening på en egen rad och skiljer stycken åt med
exakt en tomrad.

**Lint behövs inte för bygget.** Pandoc renderar en ostädad fil precis
likadant - flera meningar på en rad, dubbla mellanslag och extra tomrader
ger identiskt resultat. Kontrollerat genom att bygga samma text med och
utan lint och jämföra.

Lint är till för **källfilen**: en ändrad mening syns som en ändrad rad i
`git diff` i stället för att hela stycket lyser upp. Kör den en gång innan
du börjar redigera. Den är idempotent - att köra om den ändrar ingenting.

```bash
manus lint -o bygge MinBok/*.md   # kopior i egen katalog
manus lint Kapitel05.md           # skriver Kapitel05.pandoc.md bredvid
manus lint --in-place MinBok/*.md # på plats, med .bak
```

Originalen rörs aldrig utan `--in-place`. `manus bygg` hoppar över
`*.pandoc.md`, så byggresultat kommer aldrig med som källdokument.

**Bara en tom rad avgör var ett stycke börjar.** Markdown har också en hård
radbrytning - två blanksteg sist på en rad - men den formen stöds inte här:
lint tar bort avslutande blanksteg. Ett osynligt tecken ska inte styra hur
texten bryts. Behöver du exakta radbrytningar, som i en dikt, använd
radblock: börja varje rad med `| `. Ett utskrivet `<br>` fungerar i EPUB men
försvinner i DOCX.

## Repliker: citattecken till talstreck

Svensk skönlitteratur sätter oftast repliker med talstreck. Har du ett
manus skrivet med citattecken gör `manus talstreck` om dem:

```
”Heter du Elof?” frågade Eva.   →   -- Heter du Elof? frågade Eva.
```

**Vilka filer.** Utan filargument gäller samma regler som för `manus bygg`:
bara namn som börjar med en siffra, och bara genom numrerade kataloger.
Anteckningar, research och makulatur hålls utanför här också.

```bash
manus talstreck --lista              # hela boken, bygg-reglerna
manus talstreck skisser/utkast.md    # en utpekad fil, oavsett namn
```

Pekar du ut en fil gäller precis den, oavsett vad den heter - ett utpekat
namn är ett medvetet val.

Originalet rörs aldrig utan `--in-place`, och då sparas en `.bak`. `--lista`
visar varje stycke som skulle ändras, före och efter, utan att röra någon
textfil - kör alltid det först.

Ett stycke görs om bara när tre saker stämmer: det **börjar** med ett
citattecken, har ett avslutande, och ser ut som en replik - alltså slutar
med skiljetecken innanför citatet, eller följs av ett kommatecken utanför.
Kommatecknet räknas åt båda hållen, eftersom båda skrivsätten förekommer:

```
”Det blir bra”, säger Ulf.        →  -- Det blir bra, säger Ulf.
”Vilket väder,” säger Sara.       →  -- Vilket väder, säger Sara.
”Nomen libri” är arbetsnamnet.       orörd - en titel, inte en replik
”Han sa ”hej” till mig”, sa hon.     orörd - nästlade citat
```

Hellre en replik du får göra om för hand än en mening som tyst förvanskas.

**Fler än en replik i stycket.** Det vanligaste mönstret i svensk dialog är
replik, berättande, replik i ett och samma stycke:

```
”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
```
```
-- Jag gjorde det. Han såg bort. Det var nödvändigt.
```

Talstrecket markerar en **replikväxling**, inte varje yttrande. Samma person
talar, berättar, fortsätter - en och samma tur. Därför ett enda talstreck
först i stycket, inga inre citattecken, ingen delning. En delning skulle
påstå att någon annan tar över.

**Står repliken inte först** bryts stycket i stället:

```
Hon vände sig om. ”Vad gör du?” frågade hon.
```
```
Hon vände sig om.

-- Vad gör du? frågade hon.
```

Här börjar en **ny** talartur, till skillnad från fallet ovan. Berättandet
blir ett eget stycke.

### Citat i citat

Inre citat skrivs **alltid** med enkla tecken i källan: `'så här'`. Hur de
renderas beror på hur dialogen är satt, och avgörs av filtret vid bygget:

```
”Han sa 'hej' till mig”, sa hon.    →   ”Han sa ’hej’ till mig”, sa hon.
-- Han sa 'hej' till mig, sa hon.   →   – Han sa ”hej” till mig, sa hon.
```

I en talstreckstext finns ingen yttre nivå, så det inre citatet är det enda
och får dubbla tecken. Källan behåller sin `'` - `manus talstreck` rör den
aldrig. Det gör verktyget säkert att köra om: i en talstreckstext är varje
`"` en replik som råkat skrivas med citattecken, och exakt de görs om.

Apostrofer (`nå'n`, `Lars'`) påverkas inte - Pandoc skiljer dem från
citattecken på sammanhang.

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

Listan gäller **körningen**, inte en katalog, och stämmer därför alltid -
oavsett hur många filer som lästes. Står du i bokens rot och kör utan
filargument får du hela bokens problem i en lista där; står du i ett kapitel
får du kapitlets. Sökvägarna skrivs relativt samma katalog som listan ligger
i.

Rätta i källfilen och kör igen, så uppdateras listan. Hittar körningen inga
problem **tas filen bort** - en lista som ligger kvar tom läses som att det
finns något ogjort.

Filen är genererad och skrivs över varje gång, så egna anteckningar i den
överlever inte. Den läses aldrig in som källtext och kan alltså inte råka bli
manus.

`--rapport FIL` lägger listan någon annanstans. `--ingen-rapport` rör ingen
lista alls.

> **Ordningen mot `manus lint` spelar ingen roll.** Båda arbetar på
> stycken, och ett stycke är samma sak före och efter lint. Vill du ha en
> mening per rad även i de omgjorda replikerna, kör lint sist - `manus talstreck`
> fogar ihop stycket det skrivit om till en rad.

Förvalet är två bindestreck, eftersom Pandoc gör om `--` till ett riktigt
tankstreck vid rendering och `manus lint` känner igen formen. Vill du ha
tecknet direkt i källfilen ger `--tankstreck` det i stället.

## Manifest - när numreringen inte passar

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

`input-files` ger ordningen - ingen sortering sker. Filnamn med mellanslag,
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
med numrerade kataloger, och filnamnen måste börja med en siffra för att
komma med.

Ett manifest har **två** källor, och dåvkan de glida isär. Ett kapitel du
skrivit men glömt lägga till i listan byggs tyst bort - och det märks
först när någon läser boken.

Med manifrestet räknas därför varje byggbar fil i trädet som inte står i
`input-files` eller matchar ett mönster i `manus-uteslut` upp som en varning:

```
VARNING: 1 fil(er) i trädet står varken i manifestet
         eller under manus-uteslut:
             bortglömd.md
```

Att tysta en fil kräver alltså att du skriver in den - du bestämmer, men
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
Typsnitt: Garamond saknas - använder EB Garamond i stället.
```

Finns inget av dem tas `mainfont` bort helt och Pandoc bygger med sitt
vanliga typsnitt - hellre en PDF med fel typsnitt än ingen PDF alls.

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

Pandocs förvalda stilmall sätter `html { background-color: #fdfdfd }` - inte
riktigt vitt, vilket läses som en grå ton i e-boksläsare. `vit-bakgrund.css`
läggs efter pandocs egen och vinner. Den rör ingenting annat än bakgrunden;
typsnitt och marginaler lämnas som de är.

## Stilmallen

Du skapar en stilmall genom att redigera `custom-reference.docx` i mappen
`assets`. Ändra typsnitt för brödtext och rubriker, och linjeavstånd, så har
du kommit långt. Den medföljande filen är Pandocs egen standardfil.

Lägg din egen i bokens katalog. Namnet måste vara exakt
`custom-reference.docx` - se nedan om var den kan ligga.

Filen används automatiskt. Du behöver inte göra något. Men två villkor gäller:

1. Filen måste heta **exakt** `custom-reference.docx`
2. Utformatet måste vara docx, odt eller pptx - Pandoc struntar tyst i
   stilmallen för PDF och EPUB, så samma kommando fungerar för alla format

`manus bygg` skriver ut vad den hittade innan Pandoc kör, så du ser direkt
vilken mall den valde:

```
Använder:
  stilmall:  ./bygg/custom-reference.docx
```

### Var ska den ligga?

Det finns fyra giltiga platser, och de tillämpas i prioritetsordning. Om du
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
`-r` vinner `-r` - en uttrycklig flagga går före ett avstängt automatläge.

Vill du börja från Pandocs egen standardmall i stället för den medföljande,
se [PANDOC.md](PANDOC.md#5-skapa-manus-mallen-manus-malldocx---en-gång).

## Om något går fel

**"hittade inga filer som börjar med en siffra"** - du står i fel mapp,
eller så saknar filnamnen sin numrering.

**"blandade siffbredder"** - du har till exempel `2_kap.md` och `10_kap.md`
i samma mapp. Sorteringen är bokstavsordning, så `10_` hamnar före `2_`.
Inget byggs förrän du nollutfyllt till samma bredd: `02_` och `10_`.

**Fel kapitel kom med, eller i fel ordning** - kör `manus bygg --lista`
och läs igenom. Ordningen beror på filnamnen.

**Formatmallen kom inte med** - verktyget skriver ut vad det hittade innan
bygget. Står det ingen `docx-mall:` där, kontrollera att filen heter exakt
`custom-reference.docx`.

**Ett citat blev en replik** - se [Citat i citat](#citat-i-citat). Skriv
inre citat med `'`, så rörs de aldrig.
