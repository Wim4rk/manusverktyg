# Pandoc – fusklapp för manusrendering

I projektets grund ligger Pandoc. Det är ett program för att konvertera
olika dokument från ett filformat till ett annat.

Så här går du från
[markdown](https://pandoc.org/MANUAL.html#pandocs-markdown) till format
som är enkla att läsa(EPUB/PDF) eller till ett inlämningsklart romanmanus
(DOCX).
[Pandoc](https://pandoc.org/) gör jobbet; `manus` gör bara det Pandoc inte
kan - hittar filerna, håller ordningen, och väljer typsnitt som faktiskt
finns i datorn.

Allt nedan är valt för skönlitterär text. Pandoc kan mycket mer - register,
källhänvisningar, korsreferenser - men det hör till facklitteratur och tas
inte upp här.

Installera Pandoc (en gång): `sudo apt install pandoc`. Kontrollera med
`pandoc --version`.

---

## 1. Städa texten - en gång, innan du börjar skriva

**Katalog-/filnamn måste vara nollutfyllda** (`010_`, `020_`, … `100_`) för att
sorteringen ovan (och globbningen nedan) ska ge rätt läsordning. `2_` sorterar
annars efter `10_`. Filnamn måste ha tre siffror först. Kataloger behöver bara
två.

`manus lint` lägger varje mening på en egen rad och skiljer stycken åt med
exakt en tomrad. Kör `manus lint --help` för hela beskrivningen.

**Lint behövs inte för bygget.** Pandoc renderar en ostädad fil precis
likadant: flera meningar på en rad, dubbla mellanslag och extra tomrader
ger identiskt resultat. Det är kontrollerat genom att bygga samma text med
och utan lint och jämföra utdata.

Lint är alltså till för **källfilen**, inte för boken. Kör den en gång
innan du börjar redigera, så slipper du tänka på den mer. Den är
idempotent — att köra om den ändrar ingenting.

Markdown läser enkla returer `\n` som ett mellanslag. Om du vill ha ett
nytt stycke måste du lägga till en tom rad mellan: `\n\n`. Det kan vi
utnyttja genom att lägga varje _mening_ på en egen rad. En tom rad visar
var ett nytt stycke börjar. `manus lint` ändrar detta åt dig.

**Bara en tom rad avgör var ett stycke börjar.** Markdown har också en
hård radbrytning: två blanksteg sist på en rad. Den formen stöds inte
här — `manus lint` tar bort avslutande blanksteg. Ett osynligt tecken ska
inte styra hur texten bryts, och två blanksteg efter varandra är nästan
alltid ett skrivfel. Behöver du bevara exakta radbrytningar, som i en
dikt, använd radblock: börja varje rad med `| `.

Vinsten får vi vid redigeringen: en ändrad mening syns som en ändrad rad
i `git diff`, i stället för att hela stycket lyser upp.

Skriv gärna resultatet till en egen byggkatalog med `-o`. Filnamnen behålls
oförändrade, så nollutfyllningen sorterar rätt och `pandoc bygge/*.md` fungerar
rakt av.

```bash
manus lint -o bygge MinBok/*.md
```

Originalen rörs aldrig. Om du vill ändar filen du jobbar med använder du
flaggan `--in-place`, men oftast är det bättre att skapa kopior av dokumenten
som du kan läsa igenom. Behåll den fil du godkänner, radera den andra.

Utan `-o` skrivs i stället `X.pandoc.md` bredvid varje `X.md`. Det duger för
en enstaka fil, men lägger resultatet i skrivkatalogen:

```bash
manus lint Kapitel05.md
```

`manus bygg` hoppar över `*.pandoc.md`, så byggresultat råkar aldrig komma
med som källdokument. 



---

## 2. Rendera ett enda kapitel för korrektur

Inget bokbygge behövs - en fil in, en fil ut:
```bash
pandoc Kapitel05.pandoc.md -o Kapitel05-korr.pdf
```

---

## 3. Rendera en hel bok

Ställ dig i bokens katalog och kör `manus bygg`. Den letar själv upp alla
filer vars namn börjar med tre siffror, i katalogen och alla underkataloger,
sorterar dem på sökväg och kör Pandoc på alltihop. Kapitelordningen kommer
alltså ur numreringen:

```
001_forord.md
010_del_ett/001_kapitel.md
010_del_ett/002_kapitel.md
020_del_tva/001_kapitel.md
099_efterord.md
```

**Kontrollera alltid ordningen först.** Fel kapitelordning är det enda felet
som inte syns förrän någon läser boken:

```bash
manus bygg --lista
```

### PDF - det vanligaste

```bash
manus bygg --lint -o MinBok.pdf -- \
  --pdf-engine=xelatex \
  --toc \
  -V lang=sv \
  -V mainfont="Liberation Serif" \
  -V fontsize=12pt \
  -V geometry:margin=1in \
  --metadata title="Nomen libri" \
  --metadata author="Scriptor Sum"
```

Testat och verifierat i sin helhet. Några ord om varje del:

* `--lint` kör `manus lint` på filerna först, till en temp-katalog som
  städas bort efteråt. Källfilerna rörs aldrig och inga `.pandoc.md` blir
  liggande i skrivkatalogen.
* Allt efter `--` går rakt vidare till Pandoc.
* `--pdf-engine=xelatex` behövs för att `mainfont` ska fungera alls. Utan
  flaggan används `pdflatex`, som klarar åäö men inte låter dig välja
  typsnitt. Alla tre motorerna (`pdflatex`, `xelatex`, `lualatex`) finns
  installerade.
* `-V lang=sv` ger svensk avstavning och översätter Pandocs egna rubriker -
  innehållsförteckningen får rubriken "Innehåll" i stället för "Contents".
* `mainfont` måste vara ett typsnitt som verkligen finns på maskinen du
  renderar på. Kontrollera med `fc-list : family | sort -u | grep -i namn`.
  "Liberation Serif" är metrikkompatibelt med Times New Roman och ingår i
  `fonts-liberation`, som redan finns på de flesta Debian/Ubuntu-system.
  ("Georgia" testades och finns INTE som standard - ett exempel på vad som
  går fel om man inte kollar `fc-list` först.)
* Ligger metadata i en YAML-fil i stället går det lika bra:
  `-- --metadata-file=metadata.yaml` (se avsnitt 4).

Stilmallen `custom-reference.docx` och `swedish-quotes.lua` plockas upp
automatiskt - se avsnitt 3.1. För PDF spelar bara filtret roll.

### EPUB - för alfa-/betaläsare. Eller självpublicering...

```bash
manus bygg --lint -o MinBok.epub -- --toc --metadata title="Nomen libri"
```

EPUB behöver ingen PDF-motor och inget typsnitt; läsarens app bestämmer
utseendet. Ger Pandoc en varning om tom `<title>` betyder det bara att du
inte satt någon titel - sätt `--metadata title=` eller använd en
metadata-fil.

### DOCX - inlämning till förlag eller agent

```bash
manus bygg --lint -o MinBok-inlamning.docx
```

Stilmallen används automatiskt, så `--reference-doc` behöver inte skrivas ut.

### Varje kapitel för sig - korrektur

```bash
manus bygg --separat -o korrektur -- -t html
```

Katalogstrukturen behålls i utkatalogen, så två kapitel som heter samma sak
i olika delar av boken inte skriver över varandra.

---

## 3.1 Byggtillgångar - stilmall och citattecken

Två filer plockas upp av `manus bygg` automatiskt om de finns, och skriptet
skriver ut vilka det blev innan Pandoc kör:

| Fil | Gör vad | Gäller |
| --- | --- | --- |
| `custom-reference.docx` | stilmall (typsnitt, marginaler, rubriker) | docx, odt, pptx |
| `swedish-quotes.lua` | svenska citattecken (`”`) på båda sidor | alla format |

De letas upp i den här ordningen, så en enskild bok kan ha en egen stilmall
utan att den allmänna behöver röras:

```
./custom-reference.docx
./bygg/custom-reference.docx
./.pandoc/custom-reference.docx
manusverktyg/assets/       ← den allmänna
```

Stilmallen skickas med oavsett utformat - Pandoc struntar tyst i den för
allt utom docx, odt och pptx, så samma kommando fungerar för alla format.

Vill du styra dem för hand: `-r FIL` för stilmallen, `-f FIL` för ett
lua-filter (kan upprepas), `--utan-mall` för att strunta i båda.

### Gör skripten till riktiga kommandon

```bash
cd ~/Dropbox/Github/manusverktyg
make install
```

Det lägger en symlänk `~/.local/bin/manus` till repot - inte en kopia, så
ändringar slår igenom direkt. `make uninstall` tar bort den igen.

### Utan skripten, för hand

Om du hellre kör Pandoc direkt: aktivera `globstar` en gång per skal-session
så `**` letar rekursivt, och skriv ut allt själv.

```bash
shopt -s globstar
pandoc MinBok/**/*.md \
  --metadata-file=MinBok/metadata.yaml \
  --toc --pdf-engine=xelatex \
  -V lang=sv -V mainfont="Liberation Serif" \
  --lua-filter ~/Dropbox/Github/manusverktyg/assets/swedish-quotes.lua \
  -o MinBok.pdf
```

Skillnaden mot `manus bygg` är att `**/*.md` tar med *alla* markdown-filer,
även utkast och anteckningar som inte hör till boken. Det är därför
tresiffriga prefix finns.

---

## 4. Metadata (front matter)

Ett `metadata.yaml` i bokens rotkatalog:
```yaml
---
title: "Nomen libri"
author: "Scriptor Sum"
lang: sv
---
```
Peka på filen med `--metadata-file=` som i exemplen ovan. Du kan också skriva
samma block överst i EN av kapitelfilerna istället, men en gemensam fil för
hela boken är enklare att hålla koll på.

---

## 5. Skapa manus-mallen (`manus-mall.docx`) - en gång

Pandoc kan inte styras att skriva "rent" manusformat via flaggor allena - det
är en Word-mall vars stilar Pandoc målar om till. Generera en startmall:
```bash
pandoc -o manus-mall.docx --print-default-data-file reference.docx
```
Öppna den i Word/LibreOffice och justera dessa stilar (bara dessa spelar
roll för Pandocs output):

| Stil            | Vad den styr                          | Förslag |
|-----------------|----------------------------------------|---------|
| `Normal`        | Brödtext                              | Times New Roman 12pt, dubbelt radavstånd, indragen första rad |
| `Title`         | Bokens titel (från metadata)          | Centrerad, egen sida |
| `Heading 1`     | Kapitelrubriker                        | Ny sida, enkel, ej dekorerad |
| `First Paragraph` | Första stycket efter en rubrik (ska ofta INTE vara indraget) | Ingen indragning |

Spara - mallen återanvänds sedan av alla framtida `--reference-doc`-anrop,
ingen anledning att röra skriptet eller kommandona igen.

---

## 6. Snabbreferens över flaggor som används ovan

* `--toc` - infoga innehållsförteckning.
* `--metadata-file=fil.yaml` - titel/författare/språk m.m.
* `--reference-doc=fil.docx` - stilmall för DOCX-utdata.
* `-V namn=värde` - sätt en mallvariabel (typsnitt, marginaler, m.m. för PDF).
* `--pdf-engine=xelatex` - krävs för egna typsnitt i PDF.
* `-o fil.ext` - Pandoc gissar format från filändelsen (`.epub`, `.docx`, `.pdf`).

---

## 7. Dolda kommentarer

Skriv `<!-- anteckning -->`. Det fungerar både på en egen rad och mitt inne
i ett stycke, och är osynligt i alla Pandoc-format.

En kommentar får gå över flera rader - `manus lint` lämnar allt mellan
`<!--` och `-->` orört och delar aldrig upp det i meningar.

---

## 8. Svenska citattecken

Pandocs smart-typografi ger engelska citattecken (`“hej”` - olika tecken
för öppning/stängning). Svensk typografi använder samma tecken på båda
sidor (`”hej”`). Löst med ett Lua-filter, `~/Dropbox/Github/manusverktyg/assets/swedish-quotes.lua`,
som fångar citattecken i Pandocs interna representation innan något
utformat väljs - funkar därför likadant för EPUB/DOCX/PDF, testat mot
alla tre. Lägg till på vilket kommando som helst:
```bash
pandoc ... --lua-filter ~/Dropbox/Github/manusverktyg/assets/swedish-quotes.lua -o MinBok.epub
```

Skriv sökvägen med **mellanslag** efter flaggan, inte `--lua-filter=~/...`.
Bash expanderar inte `~` efter ett likhetstecken i ett vanligt kommandoord, så
Pandoc får en bokstavlig tilde och avbryter med *cannot open*. Formen
`--lua-filter=$HOME/...` fungerar också, eftersom `$HOME` expanderar överallt.

## 9. Pandocs Markdown - vad som skiljer sig från "vanlig" markdown

Pandoc parsar inte CommonMark rakt av - det är en egen, utökad dialekt.
Det som faktiskt spelar roll för skönlitterär text:

* **Smart typografi (på som standard):** `--` blir en tankstreck (–), `---`
  blir em-streck (-), `...` blir ellips (…), raka citattecken blir kurviga
  - men **engelska** kurviga citattecken (`“hej”`), inte svenska (`”hej”`).
  `lang: sv` ändrar inte detta. Här är det löst med `assets/swedish-quotes.lua`,
  som `manus bygg` skickar med automatiskt.
  Skriv `--`, `---` och `...` rakt av och lita på att Pandoc gör om dem vid
  rendering. Vill du stänga av HELA smart-typografin: `-f markdown-smart`
  (minustecken före tillägget stänger av det).
* **Genomstruken text:** `~~struket~~` →~~struket~~.
* **Fotnoter:** `Text med fotnot.[^1]` och längre ner `[^1]: Fotnotens
  innehåll.` - fungerar i alla tre formaten.
* **Radblock (för dikter/sånger där radbrytningen är meningsfull):** börja
  varje rad med `| ` så bevaras exakta radbrytningar utan att det tolkas
  som separata stycken.
* **Betoning är striktare än du kanske väntar dig:** `ord_med_understreck_i`
  triggar INTE kursivering mitt i ett ord (till skillnad från vissa andra
  markdown-varianter) - bra att veta om du använder `_`.
* **Rå HTML/LaTeX slinker igenom orört** till format som stödjer det - det
  är exakt detta som gör att `<!-- kommentarer -->` fungerar överallt.
* Tabeller, definitionslistor och rubrik-attribut (`{#id .klass}`) finns
  också, men är sällan relevanta för ett romanmanus - nämns bara så du vet
  att de finns om behovet dyker upp.

## 10. Front matter - djupdykning

Metadatablocket är YAML mellan två `---` (den avslutande raden kan även
vara `...` - båda är giltiga, `---` är vanligast).

**Vanliga fält och vad de faktiskt påverkar:**

| Fält | Effekt |
|---|---|
| `title` | Titelsida (PDF/DOCX), boktitel i läsarens bibliotek (EPUB) |
| `author` | Samma som ovan, kan vara en lista: `author: ["Namn Ett", "Namn Två"]` |
| `lang` | Sätter dokumentspråk - påverkar avstavning i PDF och skärmläsarspråk i EPUB. Sätt till `sv`. |
| `date` | Valfri, visas på titelsidan om mallen använder den |
| `cover-image` | **EPUB-specifikt** - `cover-image: omslag.jpg` ger boken ett riktigt omslag i läsarens bibliotek (Kindle, Apple Books, Calibre m.fl.) |
| `rights` / `description` / `subject` | EPUB-metadata, visas i vissa läsarbibliotek men syns aldrig i själva texten |

**Egna fält funkar också** - Pandoc ignorerar tyst allt det inte känner
igen, så du kan lägga till t.ex. `series: "Bok 1"` redan nu. De gör
ingenting förrän du bygger en egen mall som refererar `$series$`, men
ingen skada i att ha dem på plats i förväg.

**Viktig fallgrop vid flerfils-rendering:** om FLERA av dina filer råkar ha
varsitt metadatablock, vinner det SISTA värdet för fält som bara kan ha
ett värde (som `title`). Håll dig till EN `metadata.yaml` för hela boken
(som i exemplen ovan) - lägg aldrig `title`/`author` i enskilda
kapitelfiler.

**Tre sätt att skicka in metadata**, om `metadata.yaml` inte räcker:
```bash
--metadata-file=metadata.yaml     # en fil, det vi använder ovan
--metadata title="Bokens titel"   # enstaka fält direkt på kommandoraden
```
eller skriv blocket direkt överst i en av markdown-filerna - alla tre går
att kombinera, kommandoradsflaggor vinner över filer.

*Dokumentet skapat 2026-09-01.*
