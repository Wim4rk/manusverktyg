# Kvickguide

Kommandona, så länge allt går rätt. Går något fel, eller vill du veta
varför: [HANDBOK.md](HANDBOK.md).

Öppna terminalen och gå till bokens mapp. Verktyget arbetar med mappen du
står i. Vill du veta var du står: skriv `pwd` och tryck retur.

## Installation

Ställ dig i mappen med verktygen och skriv `make install`.

## Formatet bestäms av filändelsen

| Skriver du    | Får du                           |
| ------------- | -------------------------------- |
| `-o bok.docx` | Word-fil, för förlag och agenter |
| `-o bok.epub` | e-bok, för läsplattor            |
| `-o bok.pdf`  | PDF, för utskrift                |

---

## 1. Hela boken

Kontrollera ordningen först. Det skriver bara ut vilka filer som kommer
med, och bygger ingenting:

```bash
manus bygg --lista
```

Bygg sedan:

```bash
manus bygg -o bok.docx
manus bygg -o bok.pdf -- --pdf-engine=xelatex --toc   # PDF med innehåll
```

Formatmallen kommer med automatiskt.

---

## 2. Ett enda kapitel

Gå in i kapitlets mapp och kör samma kommando:

```bash
cd 01_del_ett
manus bygg -o kapitel.docx
```

---

## 3. Några utvalda filer

Räkna upp dem själv, i den ordning du vill ha dem. Då används Pandoc direkt,
och formatmallen måste pekas ut:

```bash
pandoc 001_forord.md 02_del_tva/010_kapitel.md \
  --reference-doc ~/sökväg/till/manusverktyg/assets/custom-reference.docx \
  -o urval.docx
```

Ska samma urval byggas fler gånger, lägg filerna i `urval.yaml`:

```yaml
input-files:
  - 001_forord.md
  - 02_del_tva/010_kapitel.md
```

```bash
manus bygg --manifest urval.yaml -o urval.docx
```

---

## 4. Byta citattecken mot talstreck

Titta först. Ingenting skrivs; du ser varje stycke före och efter:

```bash
manus talstreck --lista
```

Gör om när du är nöjd. Varje ändrad fil får en `.bak` bredvid sig:

```bash
manus talstreck --in-place
manus talstreck --in-place 01_del_ett/010_kapitel.md   # en enda fil
```

Skriv inre citat med enkla tecken, `'så här'`. De blir rätt vid bygget.

---

## 5. En mening per rad

Gör det en gång, innan du börjar redigera. Sedan behöver du inte tänka på
det:

```bash
manus lint --in-place 01_del_ett/*.md
```
