# Kvickguide

Öppna terminalen och gå till bokens mapp.  Verktyget arbetar
med mappen du står i just nu.

Vill du veta var du står: skriv `pwd` och tryck retur.

## Snabbstart

Om du vill skapa en PDF: ställ dig i bokens katalog:

```bash
manus bygg -o bok.pdf -- --pdf-engine=xelatex --toc
```

Om du vill skapa en annan sorts fil byter du bara filändelse
på dokumentet du skapar.

**Formatet bestäms av filändelsen** på det du ber om:

| Skriver du    | Får du                               |
| ------------- | ------------------------------------ |
| `-o bok.docx` | Word-fil, för förlag och agenter     |
| `-o bok.epub` | e-bok, för läsplattor                |
| `-o bok.pdf`  | PDF, för utskrift                    |

---

## 1. Hela boken

```bash
manus bygg -o bok.docx
```

Det är allt. Verktyget letar upp alla kapitel i mappen och undermapparna,
lägger dem i nummerordning och sätter ihop dem till en fil.

**Kontrollera ordningen först.** Fel kapitelordning är ett fel som
inte syns förrän någon läser boken:

```bash
manus bygg --lista
```

Det skriver bara ut vilka filer som skulle komma med, i ordning, och bygger
ingenting.

**En variant värd att kunna:**

```bash
manus bygg -o bok.pdf -- --pdf-engine=xelatex --toc  # PDF med innehållslista
```

---

## 2. Ett enda kapitel

Gå in i kapitlets mapp och kör samma kommando:

```bash
manus bygg -o kapitel.docx
```

Mappen du står i räknas alltid, oavsett vad den heter. Alla numrerade filer
i den kommer med, i ordning. Formatmallen följer med precis som vanligt.

---

## 3. Några utvalda filer - utan lista

Ska du skicka tre kapitel till en agent, eller ett utdrag till en tävling,
räknar du upp filerna själv. Då används [Pandoc](https://pandoc.org/) direkt:

```bash
pandoc 001_forord.md 02_del_tva/010_kapitel.md \
  --reference-doc ~/sökväg/till/manusverktyg/assets/custom-reference.docx \
  -o urval.docx
```

Ordningen du skriver filerna i är ordningen de hamnar i. Numreringen spelar
ingen roll här.

Den långa raden i mitten är formatmallen. Här måste du peka ut den själv -
det är priset för att välja filerna för hand. Skriv `\` sist på raden för
att fortsätta på nästa, som ovan.

---

## 4. Några utvalda filer - med lista

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
Det här är ett lämpligt sätt att bygga upp din bok, så länge du inte tappar
bort kapitel.

Filnamn med mellanslag måste stå inom citattecken: `"mitt kapitel.md"`.


Det betyder "allt annat är utanför med flit". Använd det för utdrag - inte
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

Utan filnamn tas hela boken, med samma regler som `manus bygg` - bara
numrerade filer, bara numrerade mappar. Anteckningarna lämnas i fred.

### Det som lämnas orört

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

Står repliken mitt i ett stycke bryts stycket, eftersom en ny talare tar
vid och pratminus måste inleda stycket:

```
Hon vände sig om. ”Vad gör du?” frågade hon.
```
```
Hon vände sig om.

-- Vad gör du? frågade hon.
```

En sak lämnas helt åt dig: om ett citattecken saknas någonstans, för då går
det inte att gissa vilket. De ställena samlas i en att-göra-lista,
`CITAT_PROBLEM.md`, i mappen du står i:

```markdown
- [ ] `02_urtid/010_kapitel.md` rad 85 - ett citattecken saknas, eller ett står för mycket

  > Yhla suckade. ”Var gömde du honom? Frågade hon hest.
```

Rätta i din text och kör om, så uppdateras listan. När allt är fixat
försvinner filen av sig själv.

---

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

Mer finns att läsa i [README.md](README.md).
