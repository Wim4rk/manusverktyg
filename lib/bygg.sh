#!/usr/bin/env bash
set -euo pipefail

# bygg-bok.sh — kör Pandoc på alla numrerade dokument i katalogträdet.
#
# Tar med varje fil vars NAMN inleds med tre siffror (001_kapitel.md,
# 010_efterord.md ...), i den här katalogen och alla underkataloger. Filerna
# sorteras på hela sökvägen, så numret styr ordningen — och numrerade
# underkataloger sorteras före sitt innehåll, precis som man vill ha det:
#
#     010_del_ett/001_kapitel.md
#     010_del_ett/002_kapitel.md
#     020_del_tva/001_kapitel.md
#
# Som förval slås alla filer ihop till ETT dokument, eftersom numreringen
# nästan alltid finns där för att ge en läsordning. Med --separat renderas
# varje fil för sig i stället.
#
# Utformatet följer av utfilens ändelse, precis som i Pandoc självt:
# bok.epub ger EPUB, bok.pdf ger PDF, bok.docx ger DOCX.

# Namnet som visas i hjälp och felmeddelanden. Sätts av "manus"-vägvisaren
# så texten stämmer med hur kommandot faktiskt anropas.
readonly PROGNAME="${MANUS_KOMMANDO:-manus bygg}"

# Följ symlänken hela vägen hem. Skriptet är tänkt att kunna ligga som en
# länk i ~/.local/bin, och då pekar $BASH_SOURCE på länken — inte på
# arkivet där manus lint och stilmallen faktiskt ligger.
readonly SCRIPT_FIL="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FIL")" && pwd)"

# Projektets rot, satt av "manus". Körs bygg.sh direkt ligger roten en
# nivå upp från lib/.
readonly ROT="${MANUS_ROT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
readonly TILLGANGAR="$ROT/tillgangar"

visa_hjalp() {
    cat <<EOF
$PROGNAME — kör Pandoc på alla numrerade dokument i katalogträdet.

ANVÄNDNING
    $PROGNAME [FLAGGOR] [-- PANDOC-FLAGGOR...]

    Letar upp varje .md- och .txt-fil vars namn börjar med tre siffror, i
    nuvarande katalog och alla underkataloger, sorterar dem på sökväg och
    kör Pandoc på alltihop.

FLAGGOR
    -o, --ut MÅL     Utfil (förval: bok.epub). Formatet följer av ändelsen.
                     Tillsammans med --separat är MÅL en KATALOG i stället
                     (förval: ut).
    -s, --separat    Renderar varje dokument för sig i stället för att slå
                     ihop dem till ett.
    -l, --lint       Kör manus lint på filerna först, till en tillfällig
                     katalog. Originalen rörs inte. Ger en mening per rad
                     och städade mellanslag innan Pandoc ser texten.
    -n, --lista      Visar bara vilka filer som skulle tas med, i ordning,
                     och kör ingenting. Kör alltid detta först när ordningen
                     spelar roll.
    -r, --referens FIL
                     Stilmall för DOCX (--reference-doc). Hittas normalt av
                     sig själv, se nedan.
    -f, --filter FIL Lua-filter. Kan anges flera gånger. Anges den här
                     flaggan alls letas inget filter upp automatiskt.
    --css FIL        Stilmall för HTML och EPUB. Hittas normalt av sig
                     själv, se nedan.
    --utan-mall      Stänger av den automatiska sökningen efter stilmall och
                     lua-filter. En uttrycklig -r eller -f gäller ändå.
    -h, --help       Visar den här hjälpen.

    Allt efter -- skickas vidare orört till Pandoc:
        $PROGNAME -o bok.pdf -- --toc --pdf-engine=xelatex

BYGGTILLGÅNGAR
    Tre filer plockas upp automatiskt om de finns, och skriptet skriver ut
    vilka det blev innan Pandoc kör:

        custom-reference.docx   stilmall för DOCX-utdata
        vit-bakgrund.css        vit bakgrund i HTML och EPUB
        swedish-quotes.lua      svenska citattecken (”) på båda sidor

    De letas upp i den här ordningen, så en enskild bok kan ha en egen
    stilmall utan att den allmänna behöver röras:

        ./custom-reference.docx
        ./bygg/custom-reference.docx
        ./.pandoc/custom-reference.docx
        manusverktygets tillgangar/   <- den allmänna

    Båda stilmallarna skickas med oavsett utformat. Pandoc struntar tyst i
    dem för de format de inte gäller, så samma kommando fungerar överallt.

    vit-bakgrund.css finns för att Pandocs förvalda stilmall sätter
    html { background-color: #fdfdfd } — inte riktigt vitt, vilket läses
    som en grå ton. Vår CSS läggs efter och vinner.

VILKA FILER TAS MED
    Sökningen går REKURSIVT genom hela trädet under katalogen du står i,
    men bara genom numrerade kataloger.

    FILER behöver TRE siffror först i namnet, och ändelsen .md eller .txt:
        010_prolog.md               tas med
        021_nya_lardomar.md         tas med
        0001_prolog.md              tas med (börjar med tre siffror)
        kapitel_001.md              tas INTE med (siffrorna sitter inte först)
        01_utkast.md                tas INTE med (bara två siffror)

    KATALOGER behöver bara EN siffra först. Kapitel är många och behöver
    luft i numreringen; delar är få.
        01_borjan/                  gås igenom
        02_urtid/                   gås igenom
        research/                   hoppas över HELT
        skisser/                    hoppas över HELT

    En katalog som inte börjar med en siffra betyder att innehållet inte
    hör till bygget. Anteckningar, makulatur och skisser hålls alltså
    utanför även om filerna i dem är numrerade.

    Katalogen du STÅR I räknas alltid, oavsett vad den heter. Ett eget
    bygge av anteckningarna görs alltså så här:
        cd research && $PROGNAME -o anteckningar.pdf

ORDNING
    Filerna sorteras på hela sökvägen. En numrerad katalog hamnar därmed
    före sitt eget innehåll, och delarna kommer i nummerordning:

        001_forord.md
        01_borjan/010_prolog.md
        01_borjan/020_staden.md
        02_urtid/010_uppvaxt.md
        09_epilog/010_slutet.md

    Numren måste vara lika många siffror inom varje nivå. 2_ sorterar
    efter 10_, medan 02_ sorterar före. Kör alltid --lista först.

    Dolda filer och kataloger hoppas över, liksom .pandoc.md — det senare är
    byggresultat från manus lint och inget källdokument.

EXEMPEL
    Se efter att ordningen stämmer innan något byggs:
        $PROGNAME --lista

    Bygg en EPUB av hela trädet:
        $PROGNAME

    Städa texten först och bygg en PDF med innehållsförteckning:
        $PROGNAME --lint -o bok.pdf -- --toc

    Rendera varje kapitel för sig till katalogen 'korrektur':
        $PROGNAME --separat -o korrektur
EOF
}

fel_anvandning() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

# ---------------------------------------------------------------------
# Typsnitt: mainfont med reserver
#
# xelatex kraschar om mainfont pekar på ett typsnitt som inte är installerat
# — den försöker generera ett METAFONT-typsnitt, misslyckas, och det blir
# ingen PDF alls. Ett manus som byggs på en annan dator än där det skrevs
# ska inte stupa på det.
#
# Därför läses mainfont och mainfontfallback ur metadatan, och det första
# typsnitt som FAKTISKT finns installerat används. Finns inget av dem alls
# tas mainfont bort helt, och Pandoc får använda sitt vanliga typsnitt.
#
# OBS: pandoc har sedan 3.2 en egen variabel som också heter
# mainfontfallback, men den betyder något annat — den fyller i enstaka
# glyfer som saknas i huvudtypsnittet, och bara för lualatex. Här används
# nyckeln som "reservtypsnitt om huvudtypsnittet saknas".
# ---------------------------------------------------------------------

# Sant om typsnittsfamiljen finns installerad. fc-list ger exakt matchning;
# fc-match duger inte — den svarar med ett ersättningstypsnitt och påstår
# därmed att allt finns.
typsnitt_finns() {
    [ -n "$1" ] || return 1

    # Inget grep -q här. Med -q avslutar grep vid första träffen, då får
    # fc-list och tr SIGPIPE, och 'set -o pipefail' gör att hela röret
    # rapporterar fel — alltså "typsnittet saknas" trots att det finns.
    # -F och -- behövs för att typsnittsnamn med regex-tecken eller
    # inledande bindestreck inte ska tolkas som mönster eller flaggor.
    local traffar
    traffar=$(fc-list : family 2>/dev/null | tr ',' '\n' | grep -Fixc -- "$1" || true)

    [ "${traffar:-0}" -gt 0 ]
}

# Plockar ut mainfont och mainfontfallback ur ett YAML-block. Skriver ett
# typsnitt per rad, i den ordning de ska provas.
las_typsnitt() {
    awk '
        function skala(v) {
            sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
            sub(/^["\047]/, "", v); sub(/["\047]$/, "", v)
            return v
        }

        # Ett YAML-block börjar och slutar med --- (eller ... på slutet).
        # Slutstrecket måste kännas igen FÖRE listraderna nedan, annars
        # läses "---" som listpunkten "--" och blir ett typsnittsnamn.
        NR == 1 && /^---[ \t]*$/ { i_block = 1; next }
        i_block && /^(---|\.\.\.)[ \t]*$/ { exit }

        /^mainfont[ \t]*:/ {
            v = skala(substr($0, index($0, ":") + 1))
            if (v != "") print v
            i_lista = 0
            next
        }
        /^mainfontfallback[ \t]*:/ {
            v = skala(substr($0, index($0, ":") + 1))
            if (v != "") { print v; i_lista = 0 } else i_lista = 1
            next
        }

        # En listpunkt måste ha något efter bindestrecket. Det utesluter
        # rader som bara består av streck.
        i_lista && /^[ \t]*-[ \t]+[^ \t]/ {
            v = $0
            sub(/^[ \t]*-[ \t]+/, "", v)
            v = skala(v)
            if (v != "") print v
            next
        }
        i_lista && /^[^ \t-]/ { i_lista = 0 }
    ' "$1"
}

# Letar upp en byggtillgång (stilmall, lua-filter) i tur och ordning:
# bokens egen katalog först, skriptets katalog sist. Så kan en enskild bok
# ha sin egen stilmall utan att den allmänna behöver ändras.
hitta_tillgang() {
    local namn="$1" kandidat
    for kandidat in "./$namn" "./bygg/$namn" "./.pandoc/$namn" "$TILLGANGAR/$namn"; do
        if [ -f "$kandidat" ]; then
            printf '%s' "$kandidat"
            return 0
        fi
    done
    return 1
}

separat=0
lint=0
bara_lista=0
utan_mall=0
mal=""
referens=""
css_fil=""
lua_filter=()
pandoc_flaggor=()

while [ $# -gt 0 ]; do
    case "$1" in
        -o|--ut)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver ett mål"
            mal="$2"
            shift
            ;;
        --ut=*)         mal="${1#*=}" ;;
        -r|--referens)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en fil"
            referens="$2"
            shift
            ;;
        --referens=*)   referens="${1#*=}" ;;
        -f|--filter)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en fil"
            lua_filter+=("$2")
            shift
            ;;
        --filter=*)     lua_filter+=("${1#*=}") ;;
        --css)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en fil"
            css_fil="$2"
            shift
            ;;
        --css=*)        css_fil="${1#*=}" ;;
        --utan-mall)    utan_mall=1 ;;
        -s|--separat)   separat=1 ;;
        -l|--lint)      lint=1 ;;
        -n|--lista)     bara_lista=1 ;;
        -h|--help)      visa_hjalp; exit 0 ;;
        --)             shift; pandoc_flaggor=("$@"); break ;;
        -*)             fel_anvandning "okänd flagga '$1'" ;;
        *)              fel_anvandning "oväntat argument '$1' (filerna hittas automatiskt)" ;;
    esac
    shift
done

if [ -z "$mal" ]; then
    mal=$([ "$separat" -eq 1 ] && echo "ut" || echo "bok.epub")
fi

# ---------------------------------------------------------------------
# Leta upp filerna
#
# Rekursivt genom hela trädet, men bara genom NUMRERADE kataloger. En
# katalog som inte börjar med en siffra betyder att innehållet inte hör
# till bygget — anteckningar, makulatur, skisser — och klipps bort med
# -prune. Katalogen man står i räknas alltid, oavsett vad den heter, så
# ett anteckningsbygge görs genom att ställa sig i den katalogen.
#
# Filer kräver TRE siffror, kataloger räcker med en. Kapitel är många och
# behöver luft i numreringen (010, 020, 021); delar är få.
#
# Sorteringen går på hela sökvägen med LC_ALL=C, så en numrerad katalog
# hamnar före sitt eget innehåll och delarna kommer i ordning.
#
# -name matchar mot NAMNET, inte sökvägen. -print0 och sort -z klarar
# mellanslag och andra tecken i namnen.
# ---------------------------------------------------------------------
filer=()
while IFS= read -r -d '' f; do
    filer+=("$f")
done < <(
    find . \
        \( -type d ! -name '.' ! -name '[0-9]*' -prune \) -o \
        \( -type f \
           \( -name '[0-9][0-9][0-9]*.md' -o -name '[0-9][0-9][0-9]*.txt' \) \
           ! -name '*.pandoc.md' \
           -print0 \) \
        2>/dev/null | LC_ALL=C sort -z
)

if [ "${#filer[@]}" -eq 0 ]; then
    echo "$PROGNAME: hittade inga filer som börjar med tre siffror här." >&2
    echo "Kör '$PROGNAME --help' för vilka namn som räknas." >&2
    exit 1
fi

# Sökvägen relativt katalogen vi står i. Behövs även efter en lint, då
# 'filer' pekar in i en temp-katalog i stället.
rel_sokvagar=()
for f in "${filer[@]}"; do
    rel_sokvagar+=("${f#./}")
done

echo "Hittade ${#filer[@]} dokument, i den här ordningen:"
i=1
for rel in "${rel_sokvagar[@]}"; do
    printf "  %3d. %s\n" "$i" "$rel"
    i=$((i + 1))
done

if [ "$bara_lista" -eq 1 ]; then
    exit 0
fi

command -v pandoc >/dev/null 2>&1 || fel_anvandning "pandoc är inte installerat"

# ---------------------------------------------------------------------
# Byggtillgångar: stilmall för DOCX och lua-filtret för svenska citattecken
# ---------------------------------------------------------------------
if [ "$utan_mall" -eq 0 ]; then
    if [ -z "$referens" ]; then
        referens="$(hitta_tillgang custom-reference.docx || true)"
    fi
    if [ "${#lua_filter[@]}" -eq 0 ]; then
        hittat_filter="$(hitta_tillgang swedish-quotes.lua || true)"
        [ -n "$hittat_filter" ] && lua_filter=("$hittat_filter")
    fi
    if [ -z "$css_fil" ]; then
        css_fil="$(hitta_tillgang vit-bakgrund.css || true)"
    fi
fi

# --reference-doc påverkar bara docx/odt/pptx. Övriga format struntar i den
# utan att klaga, så den kan skickas med oavsett utformat.
tillgangar=()
[ -n "$referens" ] && tillgangar+=(--reference-doc="$referens")

# --css gäller HTML och EPUB. Övriga format struntar i den utan att klaga,
# precis som med stilmallen, så den kan skickas med oavsett utformat.
[ -n "$css_fil" ] && tillgangar+=(--css="$css_fil")
for lf in ${lua_filter+"${lua_filter[@]}"}; do
    tillgangar+=(--lua-filter="$lf")
done

# ---------------------------------------------------------------------
# Typsnittsval
#
# Metadatan kan komma från tre håll. Den mest uttryckliga vinner.
# ---------------------------------------------------------------------
metadata_kalla=""
for ((n = 0; n < ${#pandoc_flaggor[@]}; n++)); do
    case "${pandoc_flaggor[n]}" in
        --metadata-file)   metadata_kalla="${pandoc_flaggor[n+1]:-}" ;;
        --metadata-file=*) metadata_kalla="${pandoc_flaggor[n]#--metadata-file=}" ;;
    esac
done
if [ -z "$metadata_kalla" ] && [ -f "./metadata.yaml" ]; then
    metadata_kalla="./metadata.yaml"
fi
# Sista utvägen: YAML-huvudet i det första dokumentet.
if [ -z "$metadata_kalla" ]; then
    metadata_kalla="${filer[0]}"
fi

typsnitt_flaggor=()
if [ -f "$metadata_kalla" ]; then
    onskade=()
    while IFS= read -r rad; do
        [ -n "$rad" ] && onskade+=("$rad")
    done < <(las_typsnitt "$metadata_kalla")

    if [ "${#onskade[@]}" -gt 0 ]; then
        valt=""
        saknade=()
        for t in "${onskade[@]}"; do
            if typsnitt_finns "$t"; then
                valt="$t"
                break
            fi
            saknade+=("$t")
        done

        echo
        if [ -n "$valt" ]; then
            if [ "${#saknade[@]}" -gt 0 ]; then
                echo "Typsnitt: ${saknade[0]} saknas — använder $valt i stället."
                for ((n = 1; n < ${#saknade[@]}; n++)); do
                    echo "          (även ${saknade[n]} saknas)"
                done
            else
                echo "Typsnitt: $valt"
            fi
            typsnitt_flaggor+=(-V "mainfont=$valt")
        else
            echo "Typsnitt: inget av de önskade finns installerat —"
            for t in "${saknade[@]}"; do
                echo "          $t saknas"
            done
            echo "          bygger med Pandocs vanliga typsnitt i stället."
            # Tomt värde tar bort mainfont ur mallen. Utan det här skulle
            # xelatex försöka bygga ett typsnitt som inte finns, och dö.
            typsnitt_flaggor+=(-M "mainfont=")
        fi
    fi
fi

if [ "${#tillgangar[@]}" -gt 0 ]; then
    echo
    echo "Använder:"
    [ -n "$referens" ] && echo "  docx-mall:  $referens"
    [ -n "$css_fil" ]  && echo "  css:        $css_fil"
    for lf in ${lua_filter+"${lua_filter[@]}"}; do
        echo "  lua-filter: $lf"
    done
fi

# ---------------------------------------------------------------------
# Städa texten först, om det begärts
#
# manus lint skriver med -o alla filer till samma katalog och behåller
# bara filnamnet. Här kan två kapitel i olika underkataloger heta likadant,
# så varje fil lintas till sin EGNA relativa plats under temp-katalogen.
# ---------------------------------------------------------------------
tmp_lint=""
rensa() { [ -n "$tmp_lint" ] && rm -rf "$tmp_lint"; }
trap rensa EXIT

if [ "$lint" -eq 1 ]; then
    linter="$ROT/lib/lint.sh"
    [ -x "$linter" ] || fel_anvandning "hittar inte lib/lint.sh i $ROT"

    tmp_lint=$(mktemp -d)
    echo
    echo "Städar texten med manus lint..."

    lintade=()
    for ((n = 0; n < ${#filer[@]}; n++)); do
        rel="${rel_sokvagar[n]}"
        "$linter" -o "$tmp_lint/$(dirname "$rel")" "${filer[n]}" >/dev/null
        lintade+=("$tmp_lint/$rel")
    done
    filer=("${lintade[@]}")
fi

echo

# ---------------------------------------------------------------------
# Kör Pandoc
# ---------------------------------------------------------------------
if [ "$separat" -eq 1 ]; then
    mkdir -p "$mal" || fel_anvandning "kunde inte skapa katalogen '$mal'"

    # Utformatet kan inte läsas ur ett katalognamn — ta det från
    # --pandoc-flaggorna om det står ett -t/--to där, annars pdf.
    format="pdf"
    for ((n = 0; n < ${#pandoc_flaggor[@]}; n++)); do
        case "${pandoc_flaggor[n]}" in
            -t|--to) format="${pandoc_flaggor[n+1]:-pdf}" ;;
            --to=*)  format="${pandoc_flaggor[n]#--to=}" ;;
        esac
    done

    # Ett par format heter inte samma sak som sin vanliga filändelse.
    andelse="$format"
    case "$format" in
        plain)          andelse="txt" ;;
        markdown*|gfm)  andelse="md"  ;;
        latex|beamer)   andelse="tex" ;;
    esac

    antal=0
    for ((n = 0; n < ${#filer[@]}; n++)); do
        # Behåll katalogstrukturen. Två kapitel i olika delar av boken kan
        # mycket väl heta samma sak — bara basnamnet skulle låta det andra
        # skriva över det första, och räkningen nedan skulle ljuga om det.
        rel="${rel_sokvagar[n]}"
        ut="$mal/${rel%.*}.$andelse"

        mkdir -p "$(dirname "$ut")"

        if pandoc "${filer[n]}" -o "$ut" ${tillgangar+"${tillgangar[@]}"} ${typsnitt_flaggor+"${typsnitt_flaggor[@]}"} ${pandoc_flaggor+"${pandoc_flaggor[@]}"}; then
            echo "Skrev: $ut"
            antal=$((antal + 1))
        else
            echo "$PROGNAME: Pandoc misslyckades på $rel" >&2
        fi
    done
    echo
    echo "Klart: $antal av ${#filer[@]} dokument renderade till $mal/"
else
    if pandoc "${filer[@]}" -o "$mal" ${tillgangar+"${tillgangar[@]}"} ${typsnitt_flaggor+"${typsnitt_flaggor[@]}"} ${pandoc_flaggor+"${pandoc_flaggor[@]}"}; then
        echo "Klart: ${#filer[@]} dokument sammanslagna till $mal"
    else
        echo "$PROGNAME: Pandoc misslyckades." >&2
        exit 1
    fi
fi
