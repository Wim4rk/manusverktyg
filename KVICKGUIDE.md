# Kvickguide

**För skönlitteratur.** De fem saker man faktiskt gör med ett romanmanus.
Ingen kodning krävs — du skriver ett kommando och trycker retur.

## Innan du börjar

Öppna terminalen och gå till bokens mapp. Det gör du med `cd`, som betyder
"gå till":

```bash
cd ~/Dropbox/MinBok
```

Alla kommandon nedan utgår från att du **står i** den mappen. Det är hela
knepet: verktyget arbetar med mappen du står i just nu.

Vill du veta var du står: skriv `pwd` och tryck retur.

**Formatet bestäms av filändelsen** på det du ber om:

| Skriver du | Får du |
| --- | --- |
| `-o bok.docx` | Word-fil, för förlag och agenter |
| `-o bok.epub` | e-bok, för läsplattor och provläsare |
| `-o bok.pdf` | PDF, för utskrift |

---

## 1. Hela boken

```bash
manus bygg -o bok.docx
```

Det är allt. Verktyget letar upp alla kapitel i mappen och undermapparna,
lägger dem i nummerordning och sätter ihop dem till en fil.

**Din formatmall kommer med automatiskt.** Du behöver inte nämna den. Innan
bygget skriver verktyget ut vad det hittade, så du ser att den kom med:

```
Använder:
  docx-mall:  .../assets/custom-reference.docx
```

**Kontrollera ordningen först.** Fel kapitelordning är det enda felet som
inte syns förrän någon läser boken:

```bash
manus bygg --lista
```

Det skriver bara ut vilka filer som skulle komma med, i ordning, och bygger
ingenting.

**Två varianter värda att kunna:**

```bash
manus bygg --lint -o bok.docx                        # städa texten först
manus bygg -o bok.pdf -- --pdf-engine=xelatex --toc  # PDF med innehåll
```

`--lint` lägger varje mening på egen rad i en tillfällig kopia innan bygget.
Dina egna filer rörs inte. För PDF behövs `--pdf-engine=xelatex` om du valt
ett eget typsnitt.

---

## 2. Ett enda kapitel

Gå in i kapitlets mapp och kör samma kommando:

```bash
cd 01_del_ett
manus bygg -o kapitel.docx
```

Mappen du står i räknas alltid, oavsett vad den heter. Alla numrerade filer
i den kommer med, i ordning. Formatmallen följer med precis som vanligt.

Tillbaka en nivå igen: `cd ..`

---

## 3. Några utvalda filer — utan lista

Ska du skicka tre kapitel till en agent, eller ett utdrag till en tävling,
räknar du upp filerna själv. Då används Pandoc direkt:

```bash
pandoc 001_forord.md 02_del_tva/010_kapitel.md \
  --reference-doc ~/Dropbox/Github/manusverktyg/assets/custom-reference.docx \
  -o urval.docx
```

Ordningen du skriver filerna i är ordningen de hamnar i. Numreringen spelar
ingen roll här.

Den långa raden i mitten är formatmallen. Här måste du peka ut den själv —
det är priset för att välja filerna för hand. Skriv `\` sist på raden för
att fortsätta på nästa, som ovan.

---

## 4. Några utvalda filer — med lista

Ska samma urval byggas mer än en gång är det bökigt att skriva om raden
varje gång. Lägg filerna i en lista i stället. Skapa en fil som heter
`urval.yaml`:

```yaml
input-files:
  - 001_forord.md
  - 02_del_tva/010_kapitel.md
```

Och bygg med:

```bash
manus bygg --manifest urval.yaml -o urval.docx
```

Ordningen i listan är ordningen i dokumentet. Nu kommer formatmallen med
automatiskt igen, och du kan spara listan och köra om den när som helst.

Filnamn med mellanslag måste stå inom citattecken: `"mitt kapitel.md"`.

**Verktyget varnar för filer som inte står i listan:**

```
VARNING: 12 fil(er) i trädet står varken i manifestet
         eller under manus-uteslut
```

Det är med flit, och det är listans svaga punkt: skriver du ett nytt kapitel
och glömmer lägga in det byggs det tyst bort. Varningen finns för att det
inte ska kunna hända tyst.

Men bygger du ett *utdrag* ur en hel bok är alla andra kapitel med rätta
utanför, och då blir varningen bara lång. Lägg till de här raderna sist i
filen, så tystnar den:

```yaml
metadata:
  manus-uteslut:
    - "*"
    - "*/*"
```

Det betyder "allt annat är utanför med flit". Använd det för utdrag — inte
när du bygger hela boken, för där vill du ha varningen kvar.

---

## 5. Byta citattecken mot pratminus

Svensk skönlitteratur sätter oftast repliker med pratminus i stället för
citattecken. Har du skrivit med citattecken går de att byta:

```
”Heter du Elof?” frågade Eva.   blir   -- Heter du Elof? frågade Eva.
```

**Titta först.** Det här ändrar din text, så börja alltid med att se efter
vad som skulle hända:

```bash
manus pratminus --lista
```

Ingenting skrivs. Du får se varje stycke som skulle ändras, före och efter.

**Gör om på riktigt** när du är nöjd med vad du såg:

```bash
manus pratminus --in-place
```

Varje fil som ändras får en säkerhetskopia bredvid sig, med `.bak` sist i
namnet. Originalet finns alltså kvar.

Vill du hellre titta på resultatet innan du släpper in det i manuset, kör
utan `--in-place`. Då skrivs en kopia bredvid varje fil i stället, med
`.pratminus` i namnet, och dina egna filer rörs inte alls.

**Enstaka fil:** skriv filnamnet efter kommandot.

```bash
manus pratminus --in-place 01_del_ett/010_kapitel.md
```

Utan filnamn tas hela boken, med samma regler som `manus bygg` — bara
numrerade filer, bara numrerade mappar. Anteckningarna lämnas i fred.

### Det som lämnas åt dig

Verktyget rör bara det som säkert är en replik. Är det en boktitel eller
ett citerat ord lämnas det ifred:

```
”Nomen libri” är arbetsnamnet.     ← lämnas orörd, det är ingen replik
```

Talar samma person både före och efter en berättande beat är det en enda
replik, och den behåller ett enda pratminus:

```
”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
-- Jag gjorde det. Han såg bort. Det var nödvändigt.
```

Två saker lämnas helt åt dig. Om ett citattecken saknas någonstans, för då
går det inte att gissa vilket. Och om repliken inte står först i stycket —
då behövs en styckebrytning, och var den ska gå avgör du:

```
Hon vände sig om. ”Vad gör du?” frågade hon.
```

De ställena samlas i en att-göra-lista, `CITAT_PROBLEM.md`, i mappen du
står i, med skälet utskrivet:

```markdown
- [ ] `02_urtid/010_kapitel.md` rad 85 — ett citattecken saknas, eller ett står för mycket

  > Yhla suckade. ”Var gömde du honom? Frågade hon hest.
```

Rätta i din text och kör om, så uppdateras listan. När allt är fixat
försvinner filen av sig själv.

---

## Om något går fel

**"hittade inga filer som börjar med tre siffror"** — du står i fel mapp,
eller så saknar filnamnen sina tre siffror. Skriv `pwd` för att se var du
är, och `ls` för att se vad som finns där.

**Fel kapitel kom med, eller i fel ordning** — kör `manus bygg --lista`
och läs igenom. Ordningen kommer ur filnamnen.

**Formatmallen kom inte med** — verktyget skriver ut vad det hittade innan
bygget. Står det ingen `docx-mall:` där, kontrollera att filen heter exakt
`custom-reference.docx`.

Mer finns i [README.md](README.md), och om Pandoc självt i
[PANDOC.md](PANDOC.md).
