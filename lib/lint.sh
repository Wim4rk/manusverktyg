#!/usr/bin/env bash
set -euo pipefail

# manus lint - normaliserar Markdown till ren, portabel Pandoc-Markdown.
#
# Det enda skriptet gör som Pandoc inte gör: lägger varje mening på en egen rad.
# Markdown läser en ensam radbrytning inuti ett stycke som ett mellanslag, så
# det renderade resultatet blir exakt detsamma - men källfilen blir mycket
# lättare att revidera, och en diff pekar på den mening som ändrats i stället
# för på hela stycket.
#
# Stycken följer vanliga Markdown-regler: rader som följer på varandra utan
# tomrad hör till samma stycke, en tomrad börjar ett nytt. Det är det som gör
# skriptet idempotent - kör man det två gånger fogas meningsraderna ihop till
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
# ordval, eller tillämpar Pandocs egna formateringsregler - kör resultatet
# genom `pandoc -f markdown -t markdown` själv om du vill ha även det.

# Namnet som visas i hjälp och felmeddelanden. Sätts av "manus"-vägvisaren
# så texten stämmer med hur kommandot faktiskt anropas.
readonly PROGNAME="${MANUS_COMMAND:-manus lint}"

# Ord som slutar på punkt utan att avsluta en mening. Jämförs gemena, så de
# behöver bara stå med en gång. Delaren vägrar dessutom bryta efter en ensam
# bokstav, vilket täcker initialer som "J. R. R. Tolkien" utan att de räknas upp.
readonly ABBREVIATIONS="\
t.ex ex bl.a bla d.v.s dvs o.s.v osv m.m mm m.fl mfl fr.o.m t.o.m tom \
s.k sk p.g.a pga m.a.o t.h t.v i.o.m ca cirka kl nr st resp ev jfr obs \
e.kr f.kr ang avd avs inkl exkl enl ung milj mdr kr proc vol kap fig \
tab sid s dr prof tel adr forts ff \
mr mrs ms st jr sr inc ltd co etc e.g i.e vs cf al no fig approx dept est \
jan feb mar apr jun jul aug sep sept oct okt nov dec \
mon tue wed thu fri sat sun mån tis ons tors fre lör sön"

show_help() {
    cat <<EOF
$PROGNAME - normaliserar Markdown för Pandoc.
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
                     aldrig över - den är från första körningen och är den
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

    Avslutande blanksteg tas bort.
        Det gäller brödtext, rubriker, listpunkter och blockcitat. Kodblock
        undantas - där kan blanksteg betyda något.

        OBS ATT DET ÄR ETT MEDVETET VAL. Två blanksteg sist på en rad är i
        Markdown en HÅRD RADBRYTNING (<br>) inuti stycket. Den formen stöds
        alltså inte här, och lint tar bort den.

        Skälet: ett osynligt tecken ska inte styra hur texten bryts. Två
        blanksteg efter varandra är nästan alltid ett skrivfel, och de
        överlever varken kopiering mellan program eller en editor som
        trimmar rader. Bara en TOM RAD avgör var ett nytt stycke börjar.

        Behöver du bevara exakta radbrytningar, använd radblock: börja
        varje rad med "| ". Det syns i källfilen och fungerar i alla
        format. Ett utskrivet <br> fungerar i EPUB men försvinner i DOCX.

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
    blanktecken - UTOM när:
      - ordet före är en känd förkortning (t.ex., bl.a., kl. och så vidare),
      - det står efter en ensam bokstav, alltså en initial som "J. R. R.",
      - nästa ord börjar med liten bokstav, vilket i regel betyder att
        meningen fortsätter.
    Decimaltal som 3.14 delas aldrig, eftersom inget mellanslag följer.

    Den sista regeln är det som håller ihop anföringar. I
        ”Heter du Elof?” frågade Eva. ”Jag känner en Elof!”
    visar det gemena "frågade" att frågan ingår i en längre mening, så
    brytningen hamnar efter "Eva." - där den hör hemma - och sedan igen före
    nästa replik.

    Tumregeln är medvetet försiktig: vid minsta tvekan lämnas raden hopfogad.
    Ingenting tas någonsin bort, så en missad brytning kostar dig en lång rad
    och ingenting annat.

REPLIKER OCH TALSTRECK
    Skriv talstreck som TVÅ bindestreck:
        -- Vart är vi på väg? frågade hon.
    Pandoc gör om -- till ett riktigt tankstreck (–) åt dig. Anföringen hålls
    ihop med repliken av gemen-regeln ovan, precis som med citattecken, så
    raden delas inte mellan "väg?" och "frågade".

    Skriv INTE talstreck som ett ensamt bindestreck. "- Vart är vi på väg?"
    är listpunkt-syntax i Markdown, och Pandoc renderar den som en punktlista
    - inte som en replik. Skriptet låter den stå kvar orörd just därför: den
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

    Hela boken till en byggkatalog, och sedan till EPUB - originalen i
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
    på nytt efter mening. Det ändrar inte hur texten renderas - den var redan
    ett stycke - men källfilen ser annorlunda ut efteråt. Titta igenom
    resultatet, och behåll .bak-filen om du kör med --in-place.
EOF
}

usage_error() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

in_place=0
check=0
out_dir=""
files=()

while [ $# -gt 0 ]; do
    case "$1" in
        -i|--in-place) in_place=1 ;;
        -c|--check)    check=1 ;;
        -h|--help)     show_help; exit 0 ;;
        -o|--out-dir)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en katalog"
            out_dir="$2"
            shift
            ;;
        --out-dir=*)   out_dir="${1#*=}" ;;
        -*)            usage_error "okänd flagga '$1'" ;;
        *)             files+=("$1") ;;
    esac
    shift
done

[ "${#files[@]}" -eq 0 ] && usage_error "inga filer angivna"

if [ "$in_place" -eq 1 ] && [ -n "$out_dir" ]; then
    usage_error "--in-place och --out-dir går inte att kombinera"
fi

if [ -n "$out_dir" ] && ! mkdir -p "$out_dir"; then
    usage_error "kunde inte skapa katalogen '$out_dir'"
fi

# Skiljer ut ett eventuellt YAML-frontmatter (--- ... ---) från resten av
# dokumentet, och skriver frontmatter respektive brödtext till de två
# angivna filerna.
split_frontmatter() {
    local input="$1" fm_ut="$2" brod_ut="$3"
    local first_line
    first_line=$(head -n1 "$input" || true)

    if [ "$first_line" = "---" ]; then
        awk '
            NR==1 { print; in_fm=1; next }
            in_fm && /^---[ \t]*$/ { print; in_fm=0; next }
            in_fm { print }
        ' "$input" > "$fm_ut"

        # Allt efter frontmatter-blockets avslutande "---"
        local fm_lines
        fm_lines=$(wc -l < "$fm_ut")
        tail -n +"$((fm_lines + 1))" "$input" > "$brod_ut"
    else
        : > "$fm_ut"
        cp "$input" "$brod_ut"
    fi
}

# Kärnan: bygger om brödtexten enligt reglerna i huvudkommentaren överst.
normalize_body() {
    awk -v abbreviations="$ABBREVIATIONS" '
        function is_blank(r)      { return (r ~ /^[ \t]*$/) }
        function is_fence(r)   { return (r ~ /^[ \t]*(```|~~~)/) }
        function is_blockquote(r)    { return (r ~ /^[ \t]*>/) }
        function is_heading(r)   { return (r ~ /^[ \t]*#+([ \t]|$)/) }
        function is_table(r)   { return (r ~ /^[ \t]*\|/) }
        function is_rule(r) { return (r ~ /^[ \t]*([-*_][ \t]*){3,}$/) }
        function is_list(r)    { return (r ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/) }

        # Drar ihop dubbla mellanslag inuti en rad, men lämnar indraget i
        # början orört - det bär listnivåer och indragna block.
        function squeeze_spaces(rad,   indent) {
            match(rad, /^[ \t]*/)
            indent = substr(rad, 1, RLENGTH)
            rad = substr(rad, RLENGTH + 1)

            gsub(/[ \t][ \t]+/, " ", rad)
            sub(/[ \t]+$/, "", rad)

            return indent rad
        }

        # En tomrad före nästa block, men aldrig en inledande.
        function separator() {
            if (started) print ""
            started = 1
        }

        # Kopierar en rad rakt igenom. Rader av samma slag hålls ihop (en
        # lista slits inte isär); ett byte av slag börjar ett nytt block.
        function emit_line(rad, kind) {
            if (kind != block_kind) { separator(); block_kind = kind }
            print rad
        }

        # Avgör om skiljetecknet vi just läste verkligen avslutar en mening.
        # "hittills" är meningen så långt, "resten" det som följer efter den.
        function sentence_ends(so_far, tail,   word) {
            word = so_far
            sub(END_AND_CLOSERS, "", word)  # bort med skiljetecken och citattecken
            sub(/^.*[ \t]/, "", word)          # behåll bara sista ordet

            if (word == "") return 1

            # En ensam bokstav är en initial ("J. R. R."), inte en mening. En
            # ensam siffra är det inte: "Vi var 3. Sedan kom fler." är två
            # meningar på riktigt.
            if (word ~ /^[A-Za-zÅÄÖåäö]$/) return 0
            if (tolower(word) in ABBR) return 0

            sub(/^[ \t]+/, "", tail)
            if (tail == "") return 1

            # Ett gement ord efter punkten betyder att meningen fortsätter.
            if (tail ~ /^[abcdefghijklmnopqrstuvwxyz]/) return 0
            return 1
        }

        # Skriver ut det buffrade stycket, en mening per rad.
        function emit_paragraph(   text, len_, i, ch, next_ch, so_far, tail) {
            if (para == "") return

            separator()
            block_kind = ""

            text = para
            para = ""
            so_far = ""
            len_ = length(text)

            for (i = 1; i <= len_; i++) {
                ch = substr(text, i, 1)
                so_far = so_far ch

                if (ch != "." && ch != "!" && ch != "?") continue

                # Svälj en hel följd av skiljetecken, t.ex. "..." eller "?!"
                while (i < len_) {
                    next_ch = substr(text, i + 1, 1)
                    if (next_ch == "." || next_ch == "!" || next_ch == "?") { so_far = so_far next_ch; i++ }
                    else break
                }

                # Svälj avslutande citattecken och parenteser som hör till
                # meningen, så att ”Sa hon!” Han log. bryts EFTER citatet och
                # inte före det. Matchas ett tecken i taget mot AVSLUTARE i
                # stället för med index(), eftersom de svenska citattecknen
                # består av flera byte och mawk räknar byte - slingan äter dem
                # då byte för byte och hamnar på samma ställe.
                while (i < len_) {
                    next_ch = substr(text, i + 1, 1)
                    if (next_ch ~ CLOSERS) { so_far = so_far next_ch; i++ }
                    else break
                }

                tail = substr(text, i + 1)

                # Inget blanktecken efter: 3.14, utkast.md, exempel.se/a.b
                if (tail !~ /^[ \t]/) continue
                if (!sentence_ends(so_far, tail)) continue

                sub(/^[ \t]+/, "", so_far)
                print so_far
                so_far = ""

                # Kliv förbi blanktecknen som skilde meningarna åt
                while (i < len_) {
                    next_ch = substr(text, i + 1, 1)
                    if (next_ch == " " || next_ch == "\t") i++
                    else break
                }
            }

            sub(/^[ \t]+/, "", so_far)
            sub(/[ \t]+$/, "", so_far)
            if (so_far != "") print so_far
        }

        BEGIN {
            n = split(abbreviations, parts, /[ \t\n]+/)
            for (i = 1; i <= n; i++)
                if (parts[i] != "") ABBR[parts[i]] = 1

            # Skiljetecken som avslutar en mening tillsammans med . ! eller ?.
            # De svenska citattecknen ” ’ » « finns med - repliker är hela
            # skälet till att det spelar roll: utan dem skulle
            # ”Sa hon!” Han log. bli kvar på en enda rad.
            CLOSERS = "[\"\047)\\]}*_”’»«›‹]"
            END_AND_CLOSERS = "[.!?\"\047)\\]}*_”’»«›‹]+$"

            started = 0; in_code = 0; in_comment = 0
            para = ""; block_kind = ""
        }

        {
            rad = $0

            # Inuti ett kodblock eller en HTML-kommentar: kopiera ordagrant.
            if (in_code) {
                print rad
                if (is_fence(rad)) in_code = 0
                next
            }
            if (in_comment) {
                print rad
                if (rad ~ /-->/) { in_comment = 0; block_kind = "kommentar" }
                next
            }

            if (is_fence(rad)) {
                emit_paragraph()
                separator()
                block_kind = ""
                print rad
                in_code = 1
                next
            }

            # HTML-kommentarer skrivs för hand numera, så rör dem aldrig.
            if (rad ~ /<!--/) {
                emit_paragraph()
                emit_line(rad, "kommentar")
                if (rad !~ /-->/) in_comment = 1
                next
            }

            if (is_blank(rad)) {
                emit_paragraph()
                block_kind = ""
                next
            }

            if (is_heading(rad)) {
                emit_paragraph()
                sub(/^[ \t]+/, "", rad)
                sub(/[ \t]+$/, "", rad)
                separator()
                block_kind = ""
                print rad
                next
            }

            # Strukturrader står redan en per rad: skicka dem rakt igenom.
            # Tabeller undantas från mellanslagsstädningen - där är
            # uppställningen till för att gå att läsa i källfilen.
            if (is_rule(rad)) { emit_paragraph(); emit_line(rad, "avdelare"); next }
            if (is_blockquote(rad))    { emit_paragraph(); emit_line(squeeze_spaces(rad), "citat"); next }
            if (is_table(rad))   { emit_paragraph(); emit_line(rad, "tabell");   next }
            if (is_list(rad))    { emit_paragraph(); emit_line(squeeze_spaces(rad), "lista"); next }

            # Vanlig brödtext: samla ihop stycket, dela det när det tar slut.
            # Dubbla mellanslag mitt i en mening eller efter en punkt är
            # slinttryck och renderas ändå som ett enda - bort med dem. Bara
            # brödtext städas; kodblock, tabeller, listor och citat gick redan
            # sin egen väg ovan och rörs inte.
            sub(/^[ \t]+/, "", rad)
            sub(/[ \t]+$/, "", rad)
            gsub(/[ \t][ \t]+/, " ", rad)
            para = (para == "") ? rad : para " " rad
        }

        END { emit_paragraph() }
    '
}

process_file() {
    local input="$1"
    local tmp_fm tmp_body tmp_out tmp_err
    tmp_fm=$(mktemp)
    tmp_body=$(mktemp)
    tmp_out=$(mktemp)
    tmp_err=$(mktemp)
    trap 'rm -f "$tmp_fm" "$tmp_body" "$tmp_out" "$tmp_err"' RETURN

    split_frontmatter "$input" "$tmp_fm" "$tmp_body"

    if [ -s "$tmp_fm" ]; then
        cat "$tmp_fm" > "$tmp_out"
        echo "" >> "$tmp_out"
    fi
    normalize_body < "$tmp_body" >> "$tmp_out"

    if [ "$check" -eq 1 ]; then
        if command -v pandoc >/dev/null 2>&1; then
            if ! pandoc -f markdown -t markdown "$tmp_out" -o /dev/null 2>"$tmp_err"; then
                echo "$PROGNAME: pandoc-fel i $input:" >&2
                cat "$tmp_err" >&2
            fi
        else
            echo "$PROGNAME: pandoc är inte installerat, hoppar över --check för $input" >&2
        fi
    fi

    if [ "$in_place" -eq 1 ]; then
        # Är filen redan normaliserad händer ingenting alls. Annars hade en
        # andra körning skrivit över säkerhetskopian med den redan omgjorda
        # texten, och originalets radbrytningar vore borta för gott.
        if cmp -s "$input" "$tmp_out"; then
            echo "Oförändrad: $input"
            return 0
        fi

        # Rör inte heller en .bak som redan finns - den är från första
        # körningen och är den enda kvarvarande kopian av originalet.
        if [ -e "$input.bak" ]; then
            cp "$tmp_out" "$input"
            echo "Uppdaterad: $input (befintlig $input.bak lämnad orörd)"
        else
            cp "$input" "$input.bak"
            cp "$tmp_out" "$input"
            echo "Uppdaterad: $input (säkerhetskopia: $input.bak)"
        fi
    elif [ -n "$out_dir" ]; then
        # Egen utkatalog: behåll filnamnet som det är. Då fungerar
        # 'pandoc bygge/*.md' rakt av, och nollutfyllda kapitelnummer
        # sorterar fortfarande rätt.
        local out="$out_dir/$(basename "$input")"

        # Skriv aldrig över källan. Det skulle hända om --out-dir pekar på
        # den katalog filen redan ligger i, och då vore originalet borta.
        if [ "$(readlink -f "$out" 2>/dev/null)" = "$(readlink -f "$input" 2>/dev/null)" ]; then
            echo "$PROGNAME: hoppar över $input - utdata skulle skriva över källan" >&2
            return 0
        fi

        cp "$tmp_out" "$out"
        echo "Skrev: $out"
    else
        local out="${input%.md}.pandoc.md"
        cp "$tmp_out" "$out"
        echo "Skrev: $out"
    fi
}

for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
        echo "$PROGNAME: hoppar över (inte en fil): $f" >&2
        continue
    fi
    process_file "$f"
done
