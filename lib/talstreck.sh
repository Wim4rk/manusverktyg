#!/usr/bin/env bash
set -euo pipefail

# manus talstreck - gör om citatrepliker till talstreck.
#
#     ”Heter du Elof?” frågade Eva.   ->   -- Heter du Elof? frågade Eva.
#
# Svensk skönlitteratur sätter oftast repliker med talstreck i stället för
# citattecken. Den som skrivit ett helt manus med citattecken, eller fått
# text ur ett program som sätter dem automatiskt, vill inte gå igenom varje
# replik för hand.
#
# Bara rader som BÖRJAR med ett citattecken räknas, och bara om det finns
# ett avslutande citattecken på samma rad. Vid minsta tvekan lämnas raden
# orörd - precis som i manus lint. En missad replik kostar en handgrepp,
# en felaktig konvertering kostar text.
#
# Verktyget arbetar på STYCKEN, inte på rader. Ett stycke är samma sak före
# och efter manus lint - lint ombryter inom stycket och rör aldrig
# tomraderna - så ordningen mellan verktygen spelar ingen roll. Redan
# lintade filer fungerar lika bra som orörda.
#
# OBS om awk: de svenska citattecknen är flera byte, och mawk räknar byte.
# En teckenklass [”“] matchar därför EN BYTE och slaktar tecknet. Därför
# används alternation (”|“) genomgående här, aldrig klasser.

readonly PROGNAME="${MANUS_COMMAND:-manus talstreck}"

show_help() {
    cat <<EOF
$PROGNAME - gör om citatrepliker till talstreck.
För skönlitteratur: dialog i en roman, inte citat i en fackbok.

ANVÄNDNING
    $PROGNAME [FLAGGOR] [FIL...]

    Utan FIL letas filerna upp med SAMMA regler som 'manus bygg': bara
    namn som börjar med en siffra, och bara genom numrerade kataloger.
    Anteckningar, research och makulatur hålls därmed utanför, precis som
    de hålls utanför bygget.

    Med FIL gäller precis de filerna, oavsett vad de heter - ett utpekat
    namn är ett medvetet val och går alltid att köra.

    Som förval läses varje FIL.md och en omgjord kopia skrivs bredvid den
    som FIL.talstreck.md. Originalet ändras aldrig om du inte ger
    --in-place.

        ”Heter du Elof?” frågade Eva.
        -- Heter du Elof? frågade Eva.

FLAGGOR
    -o, --out-dir DIR
                     Skriver kopiorna till DIR i stället för bredvid
                     källfilerna, och behåller filnamnen oförändrade.
                     Katalogen skapas om den inte finns. Går inte att
                     kombinera med --in-place, och skriver aldrig över en
                     källfil.
    -i, --in-place   Skriver om varje fil på plats och sparar FIL.md.bak
                     som säkerhetskopia. Är filen redan omgjord rörs den
                     inte alls, och en FIL.md.bak som redan finns skrivs
                     aldrig över - den är från första körningen och är den
                     enda kvarvarande kopian av originalet.
    -t, --tankstreck Skriver ett riktigt tankstreck (–) i stället för två
                     bindestreck. Se nedan om vilket du vill ha.
    -n, --lista      Visar varje stycke som skulle ändras, före och efter,
                     utan att röra någon textfil. Kör alltid detta först.
                     Arbetslistorna uppdateras ändå, se ARBETSLISTA.
    -R, --rapport FIL
                     Lägger arbetslistan på FIL i stället för i
                     ./$REPORT_NAME.
    --ingen-rapport  Rör ingen arbetslista alls. Varken skriver eller tar
                     bort $REPORT_NAME.
    -h, --help       Visar den här hjälpen och avslutar.

VILKA STYCKEN RÄKNAS
    Ett stycke görs om bara när ALLA tre stämmer: det börjar med ett
    citattecken, har ett avslutande på samma rad, och ser ut som en replik
    - alltså slutar med skiljetecken innanför citatet ELLER följs av ett
    kommatecken utanför det.

        ”Heter du Elof?” frågade Eva.       görs om (? innanför)
        ”Jag känner en Elof”, sa hon.       görs om (, utanför)
        ”Vilket väder,” säger Sara.         görs om (, innanför)
        Han teg. ”Kanske det”, sa han.      görs om (stycket bryts före repliken)
        ”Ett citat utan slut                görs INTE (inget avslutande tecken)
        ”Nomen libri” är arbetsnamnet.      görs INTE (varken eller: en titel)
        ”Han sa ”hej” till mig”, sa hon.    görs INTE (nästlade citat av samma sort)

    De två sista är hela skälet till att regeln finns. Ett citat först i
    stycket är inte alltid en replik, och nästlade citat av samma sort går
    inte att skilja åt på ett tryggt sätt. Hellre en replik du får göra om
    för hand än en mening som tyst blir förvanskad.

    Kommatecknet räknas åt BÅDA hållen. Korrekt svenska sätter det utanför
    citattecknet, men innanför är vanligt i praktiken, och när mönstret
    dyker upp är det med säkerhet en replik. Båda ger samma resultat,
    eftersom kommat hamnar rätt av sig självt när citattecknen faller bort.

    Raka ("), svenska (”), engelska (“) och vinkelcitattecken (» «) känns
    igen.

FLER ÄN EN REPLIK I STYCKET
    Det vanligaste mönstret i svensk dialog är replik, berättande, replik -
    allt i ett stycke:

        ”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
        -- Jag gjorde det. Han såg bort. Det var nödvändigt.

    Talstrecket markerar en REPLIKVÄXLING, inte varje yttrande. Samma person
    talar, det kommer en berättande beat, samma person fortsätter - allt är
    en och samma tur. Därför sätts ett enda talstreck först i stycket, de
    inre citattecknen faller bort, och stycket delas INTE. En delning
    skulle påstå att någon annan tar över.

    STÅR REPLIKEN INTE FÖRST i stycket bryts stycket i stället:

        Hon vände sig om. ”Vad gör du?” frågade hon.

        Hon vände sig om.

        -- Vad gör du? frågade hon.

    Talstrecket måste inleda stycket, och här är det en NY talartur som
    börjar - till skillnad från fallet ovan, där samma tur fortsätter
    efter en beat. Berättandet blir ett eget stycke.

STYCKET ÄR ENHETEN, INTE RADEN
    Framåtläsningen går över radgränser men stannar ALLTID vid tomraden.
    Det gör två saker.

    Dels fungerar redan lintade filer. En replik som lint delat över flera
    rader är fortfarande ett stycke, och känns igen som en hel replik:

        ”Hej. Jag heter Eva.
        Vad heter du?” frågade hon.     ->  -- Hej. Jag heter Eva. Vad heter du? frågade hon.

    Ordningen mot manus lint spelar därför ingen roll längre. Lint ombryter
    inom stycket och rör aldrig tomraderna, så ett stycke är samma sak före
    och efter. Kör lint efteråt om du vill ha en mening per rad igen.

    Dels blir ett saknat citattecken ofarligt. Ett stycke med udda antal
    citattecken är obalanserat och lämnas HELT orört:

        Yhla suckade. ”Var gömde du honom? frågade hon.

    Utan taket vid tomraden skulle det citatet svälja text ända fram till
    nästa citattecken, kanske flera stycken bort.

ARBETSLISTA
    Varje körning skriver en att-göra-lista, $REPORT_NAME, i katalogen DÄR
    DU STÅR. Den gäller körningen, inte en katalog, och stämmer därför
    alltid - oavsett hur många filer som lästes:

        # Citatproblem

        - [ ] \`02_urtid/010_en_svår_födelse.md\` rad 85

          > Yhla suckade. ”Var gömde du honom? Frågade hon hest.

        ---

        1 stycke kvar. Senast genomsökt 2026-09-10.

    Sökvägarna står som de angavs, alltså relativt samma katalog som
    listan ligger i. Står du i bokens rot och kör utan filargument får du
    hela bokens problem i en lista där.

    Rätta i källfilen och kör igen, så uppdateras listan. Hittar körningen
    inga problem TAS $REPORT_NAME BORT - en lista som ligger kvar tom läses
    som att det finns något ogjort.

    Dit hamnar stycken med udda antal citattecken. Det är ett skrivfel,
    och vilket tecken som fattas går inte att gissa - därför gissas inte.

    Filen är GENERERAD och skrivs över varje gång. Egna anteckningar i den
    överlever inte. Den läses aldrig in som källtext, så '$PROGNAME *.md'
    tar inte med sin egen rapport.

    --rapport FIL lägger listan någon annanstans, med valfritt namn.
    --ingen-rapport rör ingen lista alls.

VAD SOM LÄMNAS I FRED
    YAML-frontmatter högst upp i filen, kodblock (\`\`\` eller ~~~) och
    HTML-kommentarer (<!-- ... -->, även över flera rader) kopieras rakt
    igenom. Citattecken inuti dem är inte repliker - och i anteckningar är
    de dessutom ofta obalanserade med flit.

    Rubriker, listpunkter, blockcitat, tabeller och avdelare står för sig
    själva och fogas aldrig ihop med brödtext.

-- ELLER –
    Förval är två bindestreck, eftersom det är vad resten av verktygen
    förutsätter: Pandoc gör om -- till ett riktigt tankstreck (–) vid
    rendering, och manus lint känner igen formen när den delar meningar.
    Texten går då att skriva på vilket tangentbord som helst.

    Vill du ha tecknet direkt i källfilen ger --tankstreck det. Resultatet
    renderas likadant; skillnaden syns bara i .md-filen.

    Skriv ALDRIG talstreck som ETT bindestreck. "- Vart är vi på väg?" är
    listpunkt-syntax i Markdown och renderas som en punktlista.

EXEMPEL
    Se efter vad som skulle ändras, rad för rad, utan att röra något:
        $PROGNAME --lista kapitel/*.md

    Gör om ett kapitel, skriver Kapitel05.talstreck.md bredvid:
        $PROGNAME Kapitel05.md

    Hela boken på plats, med säkerhetskopior:
        $PROGNAME --in-place kapitel/*.md

    Repliker och sedan städning. Ordningen är fri, men lint efteråt ger
    en mening per rad igen efter att stycken fogats ihop:
        $PROGNAME --in-place kapitel/*.md
        manus lint --in-place kapitel/*.md
EOF
}

usage_error() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

# Namnet på arbetslistan som läggs i varje katalog med problem. Filen är
# genererad och skrivs över vid varje körning, så den läses aldrig in som
# källtext ens när man globbar *.md.
readonly REPORT_NAME="CITAT_PROBLEM.md"

in_place=0
list_only=0
use_endash=0
no_report=0
out_dir=""
report_file=""
files=()

while [ $# -gt 0 ]; do
    case "$1" in
        -i|--in-place)  in_place=1 ;;
        -t|--tankstreck) use_endash=1 ;;
        -n|--lista)     list_only=1 ;;
        -h|--help)      show_help; exit 0 ;;
        -o|--out-dir)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en katalog"
            out_dir="$2"
            shift
            ;;
        --out-dir=*)    out_dir="${1#*=}" ;;
        -R|--rapport)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en fil"
            report_file="$2"
            shift
            ;;
        --rapport=*)    report_file="${1#*=}" ;;
        --ingen-rapport) no_report=1 ;;
        -*)             usage_error "okänd flagga '$1'" ;;
        *)              files+=("$1") ;;
    esac
    shift
done

# ---------------------------------------------------------------------
# Vilka filer
#
# Utan FIL-argument letas de upp med SAMMA regler som manus bygg: bara
# filer vars namn börjar med en siffra, och bara genom numrerade
# kataloger. Anteckningar, research och makulatur hålls därmed utanför,
# precis som de hålls utanför bygget.
#
# Med FIL-argument gäller precis de filerna, oavsett vad de heter. Ett
# utpekat namn är ett medvetet val och ska alltid gå att köra.
# ---------------------------------------------------------------------
explicit=1
if [ "${#files[@]}" -eq 0 ]; then
    explicit=0
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(
        find . \
            \( -type d ! -name '.' ! -name '[0-9]*' -prune \) -o \
            \( -type f \
               \( -name '[0-9]*.md' -o -name '[0-9]*.txt' \) \
               ! -name '*.pandoc.md' ! -name '*.talstreck.md' \
               -print0 \) \
            2>/dev/null | LC_ALL=C sort -z
    )

    if [ "${#files[@]}" -eq 0 ]; then
        echo "$PROGNAME: hittade inga filer som börjar med en siffra här." >&2
        echo "Ange en fil uttryckligen, eller kör '$PROGNAME --help'." >&2
        exit 1
    fi

    echo "Hittade ${#files[@]} dokument."
fi

if [ "$in_place" -eq 1 ] && [ -n "$out_dir" ]; then
    usage_error "--in-place och --out-dir går inte att kombinera"
fi

if [ -n "$out_dir" ] && ! mkdir -p "$out_dir"; then
    usage_error "kunde inte skapa katalogen '$out_dir'"
fi

dash="--"
[ "$use_endash" -eq 1 ] && dash="–"

# Obalanserade stycken samlas här under körningen, ett per rad som
# FIL <tab> RAD <tab> texten. Rapporten skrivs ut när alla filer är klara,
# så arbetslistan står samlad i stället för utspridd mellan filnamnen.
report_tmp=$(mktemp)

cleanup_report() { rm -f "$report_tmp"; }
trap cleanup_report EXIT

# ---------------------------------------------------------------------
# Kärnan - arbetar på STYCKEN, inte på rader.
#
# Ett stycke är samma sak före och efter manus lint: lint ombryter inom
# stycket och rör aldrig tomraderna. Genom att arbeta på stycken blir det
# här verktyget okänsligt för om filen är lintad eller inte, och ordningen
# mellan verktygen slutar spela roll.
#
# Framåtläsningen stannar ALLTID vid tomraden. Ett stycke med udda antal
# citattecken är obalanserat - ett saknat avslutande tecken - och lämnas
# helt orört. Utan det taket skulle ett skrivfel svälja text ända fram
# till nästa citattecken, kanske flera stycken bort.
#
# Antalet omgjorda repliker och antalet stycken som lämnats orörda skrivs på
# stderr, så att texten på stdout inte blandas ihop med siffrorna.
# ---------------------------------------------------------------------
convert() {
    awk -v dash="$dash" -v list_mode="${2:-0}" \
        -v filename="$1" -v report="$report_tmp" '
        BEGIN {
            # Alternation, inte teckenklass. mawk räknar byte, och en klass
            # skulle matcha en ensam byte ur ett flerbytetecken.
            QUOTE = "(\"|”|“|»|«)"
            count = 0; unbalanced = 0; n_lines = 0
        }

        function out(s) { if (!list_mode) print s }

        function trim(s) {
            sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
            return s
        }

        # Fogar ihop två textbitar där ett citattecken just fallit bort.
        # Saknas mellanslag i källan - ”...röst.”Vi tar det...” - skulle
        # orden annars växa ihop till "röst.Vi". Men ett skiljetecken ska
        # sitta kvar tätt intill: ”Det blir bra”, säger ... blir
        # "Det blir bra, säger", inte "Det blir bra , säger".
        function join_bit(a, b) {
            if (a == "" || b == "") return a b
            if (a ~ /[ \t]$/ || b ~ /^[ \t]/) return a b
            if (b ~ /^(,|\.|;|:|!|\?|…|\)|”|’|»|«)/) return a b
            return a " " b
        }

        # Skriver stycket orört, precis som det stod i källan.
        function emit_unchanged(   i) {
            for (i = 1; i <= n_lines; i++) out(lines[i])
        }

        # Kärnan i kärnan. Går igenom ett hopfogat stycke från vänster,
        # spann för spann, och avgör för varje citatpar om det är en replik
        # eller ett äkta citat.
        function process_para(text, indent,
                                 rest, before, oc, inner, cc, efter, is_speech,
                                 sn, chunks, i, n_quotes, copy_, result,
                                 handled) {
            copy_ = text
            n_quotes = gsub(QUOTE, "&", copy_)

            # Inga citattecken alls, eller ett udda antal: rör ingenting.
            if (n_quotes == 0) return ""
            if (n_quotes % 2) { unbalanced++; return "OBALANS" }

            sn = 1; chunks[1] = ""
            rest = text
            result = 0

            while (match(rest, QUOTE)) {
                before = substr(rest, 1, RSTART - 1)
                oc   = substr(rest, RSTART, RLENGTH)
                rest = substr(rest, RSTART + RLENGTH)

                if (!match(rest, QUOTE)) { chunks[sn] = chunks[sn] before oc; break }

                inner = substr(rest, 1, RSTART - 1)
                cc    = substr(rest, RSTART, RLENGTH)
                rest  = substr(rest, RSTART + RLENGTH)

                # En replik slutar med skiljetecken innanför citattecknet,
                # ELLER följs av ett kommatecken utanför det. Kommatecknet
                # räknas åt båda hållen, eftersom båda skrivsätten är i
                # bruk och blandas ofta i samma manus:
                #
                #     ”Vilket väder,” säger Sara      komma innanför
                #     ”Det blir bra”, säger Ulf       komma utanför
                #
                # Saknas allt detta är det ett äkta citat - en titel, ett
                # citerat ord - och det ska behålla sina citattecken. I ett
                # talstrecksmanus är de de enda som blir kvar.
                # rest är nu texten EFTER det avslutande citattecknet.
                is_speech = (inner ~ /(\.|!|\?|…|,)[ \t]*$/) ||
                            (substr(rest, 1, 1) == ",")

                if (!is_speech) {
                    chunks[sn] = chunks[sn] before oc inner cc
                    handled = 1
                    continue
                }

                if (!handled) {
                    handled = 1

                    # Berättande FÖRE första repliken. Talstrecket måste
                    # inleda stycket, så berättandet blir ett eget stycke
                    # och repliken börjar nästa:
                    #
                    #     Han ser på henne och flinar. ”Känner du dig...?”
                    #
                    #     Han ser på henne och flinar.
                    #
                    #     -- Känner du dig...?
                    #
                    # Det är en NY talartur som inleds, till skillnad från
                    # fallet längre ner där samma tur fortsätter.
                    chunks[sn] = chunks[sn] before
                    if (trim(chunks[sn]) != "") { sn++; chunks[sn] = "" }

                    chunks[sn] = dash " " inner
                    count++
                    result = 1
                    continue
                }

                # Efterföljande replik i SAMMA stycke. Talstrecket markerar en
                # replikväxling, inte varje yttrande: samma person talar,
                # det kommer en berättande beat, samma person fortsätter.
                # Allt är en och samma tur. Citattecknen faller bort, men
                # inget nytt talstreck sätts och stycket delas inte - en
                # delning skulle påstå att någon annan tar över.
                #
                #   ”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”
                #   -- Jag gjorde det. Han såg bort. Det var nödvändigt.
                chunks[sn] = join_bit(join_bit(chunks[sn], before), inner)
                count++
            }

            chunks[sn] = join_bit(chunks[sn], rest)

            if (!result) return ""

            # Bygg ihop styckena med tomrad emellan.
            text = ""
            for (i = 1; i <= sn; i++) {
                if (trim(chunks[i]) == "") continue
                if (text != "") text = text "\n\n"
                text = text indent trim(chunks[i])
            }
            return text
        }

        function flush_para(   i, joined, indent, result) {
            if (n_lines == 0) return

            match(lines[1], /^[ \t]*/)
            indent = substr(lines[1], 1, RLENGTH)

            # Fog ihop raderna. En ensam radbrytning inuti ett stycke är en
            # mjuk brytning i Markdown och betyder mellanslag - samma regel
            # som manus lint bygger på.
            joined = trim(lines[1])
            for (i = 2; i <= n_lines; i++) joined = joined " " trim(lines[i])

            result = process_para(joined, indent)

            if (result == "OBALANS") {
                # Samlas till arbetslistan oavsett läge. Den som kör en
                # skarp konvertering behöver veta vad som INTE gjordes.
                if (report != "")
                    printf "%s\t%d\t%s\n", filename, start_line, joined >> report

                if (list_mode) {
                    # Hela stycket, inte bara första raden - det saknade
                    # citattecknet kan sitta var som helst i det.
                    n_remaining++
                    remaining_lines[n_remaining] = sprintf("  rad %d:", start_line)
                    for (i = 1; i <= n_lines; i++)
                        remaining_lines[n_remaining] = remaining_lines[n_remaining] sprintf("\n      %s", lines[i])
                } else emit_unchanged()
            } else if (result == "") {
                emit_unchanged()
            } else if (list_mode) {
                printf "  rad %d:\n", start_line
                for (i = 1; i <= n_lines; i++) printf "      %s\n", lines[i]
                printf "    →\n"
                gsub(/\n/, "\n      ", result)
                print "      " result
            } else {
                print result
            }

            n_lines = 0
        }

        function collect(rad) {
            if (n_lines == 0) start_line = FNR
            lines[++n_lines] = rad
        }

        # YAML-frontmatter högst upp lämnas orört.
        NR == 1 && /^---[ \t]*$/ { in_fm = 1; out($0); next }
        in_fm {
            out($0)
            if (/^(---|\.\.\.)[ \t]*$/) in_fm = 0
            next
        }

        # Kodblock lämnas orörda. Citattecken i dem är inte repliker.
        /^[ \t]*(```|~~~)/ { flush_para(); in_code = !in_code; out($0); next }
        in_code { out($0); next }

        # HTML-kommentarer likaså. Där ligger arbetsanteckningar, och ett
        # citerat ord i en anteckning är ingen replik - dessutom är citaten
        # där ofta obalanserade med flit.
        in_comment { out($0); if (/-->/) in_comment = 0; next }
        /<!--/ {
            flush_para()
            out($0)
            if (!/-->/) in_comment = 1
            next
        }

        # Tomraden är styckegränsen, och taket för all framåtläsning.
        /^[ \t]*$/ { flush_para(); out($0); next }

        # Strukturrader står för sig själva och fogas aldrig ihop med
        # brödtext: rubriker, listpunkter, blockcitat, tabeller, avdelare.
        /^[ \t]*(#+[ \t]|>|([-*+]|[0-9]+[.)])[ \t]|\|)/ ||
        /^[ \t]*([-*_][ \t]*){3,}$/ { flush_para(); out($0); next }

        { collect($0) }

        END {
            flush_para()
            if (list_mode && n_remaining > 0) {
                print "  -- obalanserade citat, lämnas orörda:"
                for (n = 1; n <= n_remaining; n++) print remaining_lines[n]
            }
            print count, unbalanced + 0 > "/dev/stderr"
        }
    ' "$1"
}

# Visar vilka rader som skulle ändras, utan att skriva någon fil.
# Antalet kommer på stderr och fångas separat av anroparen.
preview() {
    convert "$1" 1
}

process_file() {
    local input="$1"
    local tmp_out count others

    if [ "$list_only" -eq 1 ]; then
        local tmp_lines
        tmp_lines=$(mktemp)
        read -r count others < <(preview "$input" 2>&1 >"$tmp_lines")
        if [ "${count:-0}" -gt 0 ] || [ "${others:-0}" -gt 0 ]; then
            if [ "${others:-0}" -gt 0 ]; then
                echo "$input ($count repliker, $others kvar åt dig):"
            else
                echo "$input ($count repliker):"
            fi
            cat "$tmp_lines"
        else
            echo "$input: inga repliker att göra om"
        fi
        rm -f "$tmp_lines"
        return 0
    fi

    tmp_out=$(mktemp)
    trap 'rm -f "$tmp_out"' RETURN

    read -r count others < <(convert "$input" 2>&1 >"$tmp_out")

    if [ "$in_place" -eq 1 ]; then
        # Är filen redan omgjord händer ingenting alls. Annars hade en andra
        # körning skrivit över säkerhetskopian med den redan omgjorda texten.
        if cmp -s "$input" "$tmp_out"; then
            echo "Oförändrad: $input"
            return 0
        fi

        # Rör inte heller en .bak som redan finns - den är från första
        # körningen och är den enda kvarvarande kopian av originalet.
        if [ -e "$input.bak" ]; then
            cp "$tmp_out" "$input"
            echo "Uppdaterad: $input ($count repliker, $others kvar åt dig, befintlig $input.bak lämnad orörd)"
        else
            cp "$input" "$input.bak"
            cp "$tmp_out" "$input"
            echo "Uppdaterad: $input ($count repliker, $others kvar åt dig, säkerhetskopia: $input.bak)"
        fi
    elif [ -n "$out_dir" ]; then
        local out="$out_dir/$(basename "$input")"

        # Skriv aldrig över källan. Det skulle hända om --out-dir pekar på
        # den katalog filen redan ligger i, och då vore originalet borta.
        if [ "$(readlink -f "$out" 2>/dev/null)" = "$(readlink -f "$input" 2>/dev/null)" ]; then
            echo "$PROGNAME: hoppar över $input - utdata skulle skriva över källan" >&2
            return 0
        fi

        cp "$tmp_out" "$out"
        echo "Skrev: $out ($count repliker)"
    else
        local out="${input%.md}.talstreck.md"
        cp "$tmp_out" "$out"
        echo "Skrev: $out ($count repliker)"
    fi
}

for f in "${files[@]}"; do
    if [ ! -f "$f" ]; then
        echo "$PROGNAME: hoppar över (inte en fil): $f" >&2
        continue
    fi

    # Den egna arbetslistan är genererad text, inte manus. Utan det här
    # skulle 'manus talstreck *.md' läsa in sin egen rapport.
    if [ "$(basename "$f")" = "$REPORT_NAME" ]; then
        continue
    fi

    process_file "$f"
done

# ---------------------------------------------------------------------
# Arbetslistan
#
# Ett obalanserat stycke är nästan alltid ett skrivfel i manuset: ett
# citattecken saknas, eller ett står för mycket. Verktyget kan inte gissa
# vilket, och gissar därför inte alls. Men den som just konverterat hela
# boken måste få veta vad som INTE blev gjort, och var.
#
# Listan hamnar i katalogen DÄR KOMMANDOT KÖRS, som CITAT_PROBLEM.md. Den
# gäller alltså körningen, inte en katalog - och därför stämmer den alltid,
# oavsett hur många filer som lästes. En lista utlagd i varje berörd
# katalog skulle i stället påstå sig gälla hela katalogen, och då måste man
# veta om körningen täckte den. Det gör den här inte.
#
# Sökvägarna skrivs som de angavs, alltså relativt samma katalog som
# listan ligger i.
# ---------------------------------------------------------------------

# Ett stycke utan tomrader omkring sig kan vara ett helt kapitel. Det som
# är användbart i listan är fil och radnummer; texten är där för att känna
# igen stället, inte för att läsas i sin helhet.
truncate() {
    if [ "${#1}" -gt 240 ]; then
        printf '%s…' "${1:0:240}"
    else
        printf '%s' "$1"
    fi
}

if [ "$no_report" -eq 0 ]; then
    target="${report_file:-./$REPORT_NAME}"

    if [ -s "$report_tmp" ]; then
        remaining=$(wc -l < "$report_tmp")
        [ "$remaining" -eq 1 ] && word="stycke" || word="stycken"

        {
            echo "# Citatproblem"
            echo
            echo "<!-- Skapad av \`$PROGNAME\`. Skrivs över vid varje körning."
            echo "     Egna anteckningar här överlever inte nästa körning. -->"
            echo
            echo "Stycken där citattecknen inte går ihop: ett saknas, eller ett står"
            echo "för mycket. De har lämnats **orörda** - vilket tecken som fattas går"
            echo "inte att gissa."
            echo
            echo "Rätta i källfilen och kör \`$PROGNAME\` igen, så uppdateras listan."
            echo
            while IFS=$'\t' read -r r_file r_line r_text; do
                echo "- [ ] \`${r_file#./}\` rad $r_line - ett citattecken saknas, eller ett står för mycket"
                echo
                echo "  > $(truncate "$r_text")"
                echo
            done < "$report_tmp"
            echo "---"
            echo
            echo "$remaining $word kvar. Senast genomsökt $(date +%F)."
        } > "$target"

        echo
        echo "ARBETSLISTA"
        echo "    $target ($remaining $word kvar)"

    elif [ -f "$target" ]; then
        # Körningen hittade inga problem, och listan gäller körningen. Då
        # är den inaktuell. En lista som ligger kvar tom läses som att det
        # finns något ogjort.
        rm -f "$target"
        echo
        echo "ARBETSLISTA"
        echo "    $target borttagen - inga problem kvar"
    fi
fi
