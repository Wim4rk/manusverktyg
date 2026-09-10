#!/usr/bin/env bash
set -euo pipefail

# manus lint — normaliserar Markdown till ren, portabel Pandoc-Markdown.
#
# Det enda skriptet gör som Pandoc inte gör: lägger varje mening på en egen rad.
# Markdown läser en ensam radbrytning inuti ett stycke som ett mellanslag, så
# det renderade resultatet blir exakt detsamma — men källfilen blir mycket
# lättare att revidera, och en diff pekar på den mening som ändrats i stället
# för på hela stycket.
#
# Stycken följer vanliga Markdown-regler: rader som följer på varandra utan
# tomrad hör till samma stycke, en tomrad börjar ett nytt. Det är det som gör
# skriptet idempotent — kör man det två gånger fogas meningsraderna ihop till
# ett stycke igen och delas sedan på exakt samma ställen.
#
# Vad den gör, per fil:
#   1. Lämnar ett YAML-frontmatter (--- ... ---) högst upp helt orört.
#   2. Lämnar kodblock (``` eller ~~~) och HTML-kommentarer (<!-- ... -->)
#      orörda, även kommentarer som sträcker sig över flera rader.
#   3. Lämnar strukturrader i fred, en per rad precis som de redan står:
#      rubriker, listpunkter, blockcitat, tabeller och tematiska brytningar.
#   4. Delar upp alla andra stycken så att varje mening börjar på en ny rad,
#      och skiljer stycken åt med exakt en tomrad.
#
# Vad den medvetet INTE gör: bryter om eller radbryter texten på nytt, ändrar
# ordval, eller tillämpar Pandocs egna formateringsregler — kör resultatet
# genom `pandoc -f markdown -t markdown` själv om du vill ha även det.

# Namnet som visas i hjälp och felmeddelanden. Sätts av "manus"-vägvisaren
# så texten stämmer med hur kommandot faktiskt anropas.
readonly PROGNAME="${MANUS_KOMMANDO:-manus lint}"

# Ord som slutar på punkt utan att avsluta en mening. Jämförs gemena, så de
# behöver bara stå med en gång. Delaren vägrar dessutom bryta efter en ensam
# bokstav, vilket täcker initialer som "J. R. R. Tolkien" utan att de räknas upp.
readonly FORKORTNINGAR="\
t.ex ex bl.a bla d.v.s dvs o.s.v osv m.m mm m.fl mfl fr.o.m t.o.m tom \
s.k sk p.g.a pga m.a.o t.h t.v i.o.m ca cirka kl nr st resp ev jfr obs \
e.kr f.kr ang avd avs inkl exkl enl ung milj mdr kr proc vol kap fig \
tab sid s dr prof tel adr forts ff \
mr mrs ms st jr sr inc ltd co etc e.g i.e vs cf al no fig approx dept est \
jan feb mar apr jun jul aug sep sept oct okt nov dec \
mon tue wed thu fri sat sun mån tis ons tors fre lör sön"

visa_hjalp() {
    cat <<EOF
$PROGNAME — normaliserar Markdown för Pandoc.
För skönlitteratur: brödtext och repliker, inte facklitteratur.

ANVÄNDNING
    $PROGNAME [FLAGGOR] FIL...

    Som förval läses varje FIL.md och en normaliserad kopia skrivs bredvid den
    som FIL.pandoc.md. Originalet ändras aldrig om du inte ger --in-place.

    Med -o hamnar kopiorna i stället i en egen katalog, skilda från texten du
    skriver i. Det är oftast det du vill: resultatet är ett byggsteg på väg
    mot EPUB eller PDF, inte ett dokument att fortsätta skriva i.

FLAGGOR
    -o, --out-dir DIR
                     Skriver de normaliserade kopiorna till DIR i stället för
                     bredvid källfilerna, och behåller filnamnen oförändrade.
                     Katalogen skapas om den inte finns. Går inte att
                     kombinera med --in-place, och skriver aldrig över en
                     källfil.
    -i, --in-place   Skriver om varje fil på plats och sparar FIL.md.bak som
                     säkerhetskopia. Är filen redan normaliserad rörs den
                     inte alls, och en FIL.md.bak som redan finns skrivs
                     aldrig över — den är från första körningen och är den
                     enda kvarvarande kopian av originalet.
    -c, --check      Kör dessutom resultatet genom pandoc för att kontrollera
                     att det går att tolka. Hoppas över med en varning om
                     pandoc inte är installerat.
    -h, --help       Visar den här hjälpen och avslutar.

VAD DEN ÄNDRAR
    En mening per rad.
        Varje stycke skrivs om så att varje mening börjar på en ny rad.
        Markdown renderar en ensam radbrytning inuti ett stycke som ett
        mellanslag, så det här ändrar bara källfilen, aldrig resultatet.
        Vinsten är att revidera och jämföra: en ändrad mening syns som en
        ändrad rad i stället för att hela stycket lyser upp i en diff.

    En tomrad mellan stycken.
        Vanlig Markdown: rader som följer på varandra hör till samma stycke,
        en tomrad börjar ett nytt. Två eller fler tomrader i följd dras ihop
        till exakt en.

VAD DEN LÄMNAR I FRED
    YAML-frontmatter högst upp i filen, kodblock (\`\`\` eller ~~~),
    HTML-kommentarer (<!-- ... -->, även sådana som går över flera rader),
    rubriker, listpunkter, blockcitat, tabeller och tematiska brytningar.
    Inget av det meningsdelas; det kopieras rakt igenom oförändrat.

    Kommentarer skrivs som <!-- så här --> och rörs aldrig. De är osynliga
    i alla utformat, och kan stå på egen rad eller mitt i ett stycke.

SÅ HITTAS MENINGARNA
    En rad bryts efter . ! eller ? (plus eventuella avslutande citattecken
    eller parenteser, inklusive de svenska ” ’ » «) när nästa tecken är ett
    blanktecken — UTOM när:
      - ordet före är en känd förkortning (t.ex., bl.a., kl. och så vidare),
      - det står efter en ensam bokstav, alltså en initial som "J. R. R.",
      - nästa ord börjar med liten bokstav, vilket i regel betyder att
        meningen fortsätter.
    Decimaltal som 3.14 delas aldrig, eftersom inget mellanslag följer.

    Den sista regeln är det som håller ihop anföringar. I
        ”Heter du Elof?” frågade Eva. ”Jag känner en Elof!”
    visar det gemena "frågade" att frågan ingår i en längre mening, så
    brytningen hamnar efter "Eva." — där den hör hemma — och sedan igen före
    nästa replik.

    Tumregeln är medvetet försiktig: vid minsta tvekan lämnas raden hopfogad.
    Ingenting tas någonsin bort, så en missad brytning kostar dig en lång rad
    och ingenting annat.

REPLIKER OCH PRATMINUS
    Skriv pratminus som TVÅ bindestreck:
        -- Vart är vi på väg? frågade hon.
    Pandoc gör om -- till ett riktigt tankstreck (–) åt dig. Anföringen hålls
    ihop med repliken av gemen-regeln ovan, precis som med citattecken, så
    raden delas inte mellan "väg?" och "frågade".

    Skriv INTE pratminus som ett ensamt bindestreck. "- Vart är vi på väg?"
    är listpunkt-syntax i Markdown, och Pandoc renderar den som en punktlista
    — inte som en replik. Skriptet låter den stå kvar orörd just därför: den
    är omöjlig att skilja från en riktig lista, och att gissa fel vore värre.

    Varje replik behöver ett eget stycke, alltså en tomrad emellan. Två
    repliker på rader som följer direkt på varandra är ETT stycke i Markdown
    och flyter ihop till en enda rad i det renderade resultatet. Det gäller
    lika mycket före som efter det här skriptet.

    Riktiga tankstreck (– och —) fungerar förstås också. Kan du inte skriva
    dem på ditt tangentbord duger -- och --- lika bra.

EXEMPEL
    Normalisera ett kapitel, skriver Kapitel05.pandoc.md bredvid:
        $PROGNAME Kapitel05.md

    Hela boken till en byggkatalog, och sedan till EPUB — originalen i
    skrivkatalogen rörs inte alls:
        $PROGNAME -o bygge MinBok/*.md
        pandoc bygge/*.md -o bok.epub

    Skriv om en hel bokkatalog på plats och kontrollera varje resultat:
        find MinBok -name '*.md' ! -name '*.pandoc.md' | sort | \\
            xargs $PROGNAME --in-place --check

OM RADBRYTNINGAR
    En ensam radbrytning inuti ett stycke är en MJUK brytning i Markdown och
    betyder mellanslag. Ett stycke bryts med en TOMRAD.

    Har du filer där varje stycke är en egen rad utan tomrad emellan är de
    raderna alltså ett och samma stycke, och de fogas ihop innan de delas upp
    på nytt efter mening. Det ändrar inte hur texten renderas — den var redan
    ett stycke — men källfilen ser annorlunda ut efteråt. Titta igenom
    resultatet, och behåll .bak-filen om du kör med --in-place.
EOF
}

fel_anvandning() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

in_place=0
check=0
ut_katalog=""
filer=()

while [ $# -gt 0 ]; do
    case "$1" in
        -i|--in-place) in_place=1 ;;
        -c|--check)    check=1 ;;
        -h|--help)     visa_hjalp; exit 0 ;;
        -o|--out-dir)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en katalog"
            ut_katalog="$2"
            shift
            ;;
        --out-dir=*)   ut_katalog="${1#*=}" ;;
        -*)            fel_anvandning "okänd flagga '$1'" ;;
        *)             filer+=("$1") ;;
    esac
    shift
done

[ "${#filer[@]}" -eq 0 ] && fel_anvandning "inga filer angivna"

if [ "$in_place" -eq 1 ] && [ -n "$ut_katalog" ]; then
    fel_anvandning "--in-place och --out-dir går inte att kombinera"
fi

if [ -n "$ut_katalog" ] && ! mkdir -p "$ut_katalog"; then
    fel_anvandning "kunde inte skapa katalogen '$ut_katalog'"
fi

# Skiljer ut ett eventuellt YAML-frontmatter (--- ... ---) från resten av
# dokumentet, och skriver frontmatter respektive brödtext till de två
# angivna filerna.
dela_ut_frontmatter() {
    local input="$1" fm_ut="$2" brod_ut="$3"
    local forsta_raden
    forsta_raden=$(head -n1 "$input" || true)

    if [ "$forsta_raden" = "---" ]; then
        awk '
            NR==1 { print; in_fm=1; next }
            in_fm && /^---[ \t]*$/ { print; in_fm=0; next }
            in_fm { print }
        ' "$input" > "$fm_ut"

        # Allt efter frontmatter-blockets avslutande "---"
        local fm_rader
        fm_rader=$(wc -l < "$fm_ut")
        tail -n +"$((fm_rader + 1))" "$input" > "$brod_ut"
    else
        : > "$fm_ut"
        cp "$input" "$brod_ut"
    fi
}

# Kärnan: bygger om brödtexten enligt reglerna i huvudkommentaren överst.
normalisera_brodtext() {
    awk -v forkortningar="$FORKORTNINGAR" '
        function ar_tom(r)      { return (r ~ /^[ \t]*$/) }
        function ar_staket(r)   { return (r ~ /^[ \t]*(```|~~~)/) }
        function ar_citat(r)    { return (r ~ /^[ \t]*>/) }
        function ar_rubrik(r)   { return (r ~ /^[ \t]*#+([ \t]|$)/) }
        function ar_tabell(r)   { return (r ~ /^[ \t]*\|/) }
        function ar_avdelare(r) { return (r ~ /^[ \t]*([-*_][ \t]*){3,}$/) }
        function ar_lista(r)    { return (r ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/) }

        # Drar ihop dubbla mellanslag inuti en rad, men lämnar indraget i
        # början orört — det bär listnivåer och indragna block.
        function stada_mellanslag(rad,   indrag) {
            match(rad, /^[ \t]*/)
            indrag = substr(rad, 1, RLENGTH)
            rad = substr(rad, RLENGTH + 1)

            gsub(/[ \t][ \t]+/, " ", rad)
            sub(/[ \t]+$/, "", rad)

            return indrag rad
        }

        # En tomrad före nästa block, men aldrig en inledande.
        function avskiljare() {
            if (startat) print ""
            startat = 1
        }

        # Kopierar en rad rakt igenom. Rader av samma slag hålls ihop (en
        # lista slits inte isär); ett byte av slag börjar ett nytt block.
        function skriv_rad(rad, slag) {
            if (slag != blockslag) { avskiljare(); blockslag = slag }
            print rad
        }

        # Avgör om skiljetecknet vi just läste verkligen avslutar en mening.
        # "hittills" är meningen så långt, "resten" det som följer efter den.
        function meningen_slutar(hittills, resten,   ord) {
            ord = hittills
            sub(SLUT_OCH_AVSLUTARE, "", ord)  # bort med skiljetecken och citattecken
            sub(/^.*[ \t]/, "", ord)          # behåll bara sista ordet

            if (ord == "") return 1

            # En ensam bokstav är en initial ("J. R. R."), inte en mening. En
            # ensam siffra är det inte: "Vi var 3. Sedan kom fler." är två
            # meningar på riktigt.
            if (ord ~ /^[A-Za-zÅÄÖåäö]$/) return 0
            if (tolower(ord) in FORK) return 0

            sub(/^[ \t]+/, "", resten)
            if (resten == "") return 1

            # Ett gement ord efter punkten betyder att meningen fortsätter.
            if (resten ~ /^[abcdefghijklmnopqrstuvwxyz]/) return 0
            return 1
        }

        # Skriver ut det buffrade stycket, en mening per rad.
        function skriv_stycke(   text, langd, i, tkn, nasta, hittills, resten) {
            if (stycke == "") return

            avskiljare()
            blockslag = ""

            text = stycke
            stycke = ""
            hittills = ""
            langd = length(text)

            for (i = 1; i <= langd; i++) {
                tkn = substr(text, i, 1)
                hittills = hittills tkn

                if (tkn != "." && tkn != "!" && tkn != "?") continue

                # Svälj en hel följd av skiljetecken, t.ex. "..." eller "?!"
                while (i < langd) {
                    nasta = substr(text, i + 1, 1)
                    if (nasta == "." || nasta == "!" || nasta == "?") { hittills = hittills nasta; i++ }
                    else break
                }

                # Svälj avslutande citattecken och parenteser som hör till
                # meningen, så att ”Sa hon!” Han log. bryts EFTER citatet och
                # inte före det. Matchas ett tecken i taget mot AVSLUTARE i
                # stället för med index(), eftersom de svenska citattecknen
                # består av flera byte och mawk räknar byte — slingan äter dem
                # då byte för byte och hamnar på samma ställe.
                while (i < langd) {
                    nasta = substr(text, i + 1, 1)
                    if (nasta ~ AVSLUTARE) { hittills = hittills nasta; i++ }
                    else break
                }

                resten = substr(text, i + 1)

                # Inget blanktecken efter: 3.14, utkast.md, exempel.se/a.b
                if (resten !~ /^[ \t]/) continue
                if (!meningen_slutar(hittills, resten)) continue

                sub(/^[ \t]+/, "", hittills)
                print hittills
                hittills = ""

                # Kliv förbi blanktecknen som skilde meningarna åt
                while (i < langd) {
                    nasta = substr(text, i + 1, 1)
                    if (nasta == " " || nasta == "\t") i++
                    else break
                }
            }

            sub(/^[ \t]+/, "", hittills)
            sub(/[ \t]+$/, "", hittills)
            if (hittills != "") print hittills
        }

        BEGIN {
            n = split(forkortningar, delar, /[ \t\n]+/)
            for (i = 1; i <= n; i++)
                if (delar[i] != "") FORK[delar[i]] = 1

            # Skiljetecken som avslutar en mening tillsammans med . ! eller ?.
            # De svenska citattecknen ” ’ » « finns med — repliker är hela
            # skälet till att det spelar roll: utan dem skulle
            # ”Sa hon!” Han log. bli kvar på en enda rad.
            AVSLUTARE = "[\"\047)\\]}*_”’»«›‹]"
            SLUT_OCH_AVSLUTARE = "[.!?\"\047)\\]}*_”’»«›‹]+$"

            startat = 0; i_kod = 0; i_kommentar = 0
            stycke = ""; blockslag = ""
        }

        {
            rad = $0

            # Inuti ett kodblock eller en HTML-kommentar: kopiera ordagrant.
            if (i_kod) {
                print rad
                if (ar_staket(rad)) i_kod = 0
                next
            }
            if (i_kommentar) {
                print rad
                if (rad ~ /-->/) { i_kommentar = 0; blockslag = "kommentar" }
                next
            }

            if (ar_staket(rad)) {
                skriv_stycke()
                avskiljare()
                blockslag = ""
                print rad
                i_kod = 1
                next
            }

            # HTML-kommentarer skrivs för hand numera, så rör dem aldrig.
            if (rad ~ /<!--/) {
                skriv_stycke()
                skriv_rad(rad, "kommentar")
                if (rad !~ /-->/) i_kommentar = 1
                next
            }

            if (ar_tom(rad)) {
                skriv_stycke()
                blockslag = ""
                next
            }

            if (ar_rubrik(rad)) {
                skriv_stycke()
                sub(/^[ \t]+/, "", rad)
                avskiljare()
                blockslag = ""
                print rad
                next
            }

            # Strukturrader står redan en per rad: skicka dem rakt igenom.
            # Tabeller undantas från mellanslagsstädningen — där är
            # uppställningen till för att gå att läsa i källfilen.
            if (ar_avdelare(rad)) { skriv_stycke(); skriv_rad(rad, "avdelare"); next }
            if (ar_citat(rad))    { skriv_stycke(); skriv_rad(stada_mellanslag(rad), "citat"); next }
            if (ar_tabell(rad))   { skriv_stycke(); skriv_rad(rad, "tabell");   next }
            if (ar_lista(rad))    { skriv_stycke(); skriv_rad(stada_mellanslag(rad), "lista"); next }

            # Vanlig brödtext: samla ihop stycket, dela det när det tar slut.
            # Dubbla mellanslag mitt i en mening eller efter en punkt är
            # slinttryck och renderas ändå som ett enda — bort med dem. Bara
            # brödtext städas; kodblock, tabeller, listor och citat gick redan
            # sin egen väg ovan och rörs inte.
            sub(/^[ \t]+/, "", rad)
            sub(/[ \t]+$/, "", rad)
            gsub(/[ \t][ \t]+/, " ", rad)
            stycke = (stycke == "") ? rad : stycke " " rad
        }

        END { skriv_stycke() }
    '
}

behandla_en_fil() {
    local input="$1"
    local tmp_fm tmp_brod tmp_ut tmp_fel
    tmp_fm=$(mktemp)
    tmp_brod=$(mktemp)
    tmp_ut=$(mktemp)
    tmp_fel=$(mktemp)
    trap 'rm -f "$tmp_fm" "$tmp_brod" "$tmp_ut" "$tmp_fel"' RETURN

    dela_ut_frontmatter "$input" "$tmp_fm" "$tmp_brod"

    if [ -s "$tmp_fm" ]; then
        cat "$tmp_fm" > "$tmp_ut"
        echo "" >> "$tmp_ut"
    fi
    normalisera_brodtext < "$tmp_brod" >> "$tmp_ut"

    if [ "$check" -eq 1 ]; then
        if command -v pandoc >/dev/null 2>&1; then
            if ! pandoc -f markdown -t markdown "$tmp_ut" -o /dev/null 2>"$tmp_fel"; then
                echo "$PROGNAME: pandoc-fel i $input:" >&2
                cat "$tmp_fel" >&2
            fi
        else
            echo "$PROGNAME: pandoc är inte installerat, hoppar över --check för $input" >&2
        fi
    fi

    if [ "$in_place" -eq 1 ]; then
        # Är filen redan normaliserad händer ingenting alls. Annars hade en
        # andra körning skrivit över säkerhetskopian med den redan omgjorda
        # texten, och originalets radbrytningar vore borta för gott.
        if cmp -s "$input" "$tmp_ut"; then
            echo "Oförändrad: $input"
            return 0
        fi

        # Rör inte heller en .bak som redan finns — den är från första
        # körningen och är den enda kvarvarande kopian av originalet.
        if [ -e "$input.bak" ]; then
            cp "$tmp_ut" "$input"
            echo "Uppdaterad: $input (befintlig $input.bak lämnad orörd)"
        else
            cp "$input" "$input.bak"
            cp "$tmp_ut" "$input"
            echo "Uppdaterad: $input (säkerhetskopia: $input.bak)"
        fi
    elif [ -n "$ut_katalog" ]; then
        # Egen utkatalog: behåll filnamnet som det är. Då fungerar
        # 'pandoc bygge/*.md' rakt av, och nollutfyllda kapitelnummer
        # sorterar fortfarande rätt.
        local ut="$ut_katalog/$(basename "$input")"

        # Skriv aldrig över källan. Det skulle hända om --out-dir pekar på
        # den katalog filen redan ligger i, och då vore originalet borta.
        if [ "$(readlink -f "$ut" 2>/dev/null)" = "$(readlink -f "$input" 2>/dev/null)" ]; then
            echo "$PROGNAME: hoppar över $input — utdata skulle skriva över källan" >&2
            return 0
        fi

        cp "$tmp_ut" "$ut"
        echo "Skrev: $ut"
    else
        local ut="${input%.md}.pandoc.md"
        cp "$tmp_ut" "$ut"
        echo "Skrev: $ut"
    fi
}

for f in "${filer[@]}"; do
    if [ ! -f "$f" ]; then
        echo "$PROGNAME: hoppar över (inte en fil): $f" >&2
        continue
    fi
    behandla_en_fil "$f"
done
