#!/usr/bin/env bash
set -euo pipefail

# bygg-bok.sh - kör Pandoc på alla numrerade dokument i katalogträdet.
#
# Tar med varje fil vars NAMN inleds med tre siffror (001_kapitel.md,
# 010_efterord.md ...), i den här katalogen och alla underkataloger. Filerna
# sorteras på hela sökvägen, så numret styr ordningen - och numrerade
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
readonly PROGNAME="${MANUS_COMMAND:-manus bygg}"

# Följ symlänken hela vägen hem. Skriptet är tänkt att kunna ligga som en
# länk i ~/.local/bin, och då pekar $BASH_SOURCE på länken - inte på
# arkivet där manus lint och stilmallen faktiskt ligger.
readonly SCRIPT_FILE="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_FILE")" && pwd)"

# Projektets rot, satt av "manus". Körs bygg.sh direkt ligger roten en
# nivå upp från lib/.
readonly ROOT="${MANUS_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
readonly ASSETS_DIR="$ROOT/assets"

show_help() {
    cat <<EOF
$PROGNAME - kör Pandoc på alla numrerade dokument i katalogträdet.

ANVÄNDNING
    $PROGNAME [FLAGGOR] [-- PANDOC-FLAGGOR...]

    Letar upp varje .md- och .txt-fil vars namn börjar med tre siffror, i
    nuvarande katalog och alla underkataloger, sorterar dem på sökväg och
    kompilerar dem med Pandoc.

FLAGGOR
    -o, --ut MÅL     Utfil (förval: bok.epub). Formatet följer av ändelsen.
                     Tillsammans med --separat är MÅL en KATALOG i stället
                     (förval: ut).
    -m, --manifest FIL
                     Bygger filerna som räknas upp i FIL, i den ordning de
                     står där, i stället för att leta efter numrerade namn.
                     Se MANIFEST nedan.
    -s, --separat    Renderar varje dokument för sig i stället för att slå
                     ihop dem till ett.
    -l, --lint       Kör manus lint på filerna först, till en tillfällig
                     katalog. Originalen rörs inte. Ger en mening per rad
                     och städade mellanslag innan Pandoc ser texten.
    -n, --lista      Visar bara vilka filer som skulle tas med, i ordning,
                     och kör ingenting. Kör alltid detta först för att
                     granska ordningen.
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

TILLGÅNGAR - ASSETS
    Tre filer används automatiskt om de finns, och skriptet skriver ut
    vilka som kommer användas innan Pandoc kör:

        custom-reference.docx   stilmall för DOCX-utdata
        vit-bakgrund.css        vit bakgrund i HTML och EPUB
        swedish-quotes.lua      svenska citattecken (”) på båda sidor

STILMALLAR
    De letas upp i den här ordningen, så en enskild bok kan ha en egen
    stilmall utan att den allmänna behöver röras:

        ./custom-reference.docx
        ./bygg/custom-reference.docx
        ./.pandoc/custom-reference.docx
        manusverktygets assets/       <- den allmänna

    Båda stilmallarna skickas med oavsett utformat. Pandoc struntar tyst i
    dem för de format de inte gäller, så samma kommando fungerar överallt.

    vit-bakgrund.css finns för att Pandocs förvalda stilmall sätter
    html { background-color: #fdfdfd } - inte riktigt vitt, vilket läses
    som en grå ton. Vår CSS hamnar nedanför och vinner.

MANIFEST
    Filernas inledande nummersortering är det förvalda sättet att sortera
    texter som ska med i boken. Bara numrerade kapitel kommer användas.
    Om du vill använda en annan ordning skriver du den i en yaml-fil.

    Manifestet är en vanlig Pandoc-defaults-fil, här ett exempel (urval.yaml):

        input-files:
          - inledning.md
          - "kapitel med mellanslag.md"
          - "#udda namn.md"
        reference-doc: /sokvag/till/custom-reference.docx
        metadata:
          manus-uteslut:
            - "anteckningar/*"
            - makulatur.md

    Listan gäller precis som den står. Filnamn med mellanslag, brädgård
    eller kolon måste citeras.

    Samma fil går också att köra rakt igenom Pandoc, utan manusverktyget:

        pandoc --defaults=urval.yaml -o ut.docx

    Manus-uteslut räknar upp filer som inte ska vara med. Posterna får
    vara glob-mönster. Varje byggbar fil som varken står i input-files
    eller matchar ett uteslutningsmönster räknas upp som en varning -
    det är det som hindrar ett glömt kapitel från att tyst ignoreras.

VILKA FILER TAS MED
    Sökningen går REKURSIVT genom hela trädet under katalogen du står i,
    men bara genom numrerade kataloger.

    FILER behöver TRE siffror först i namnet, och ändelsen .md eller .txt:
        010_prolog.md               tas med
        021_kapitel.md              tas med
        0001_prolog.md              tas med (börjar med tre siffror)
        kapitel_001.md              tas INTE med (siffrorna sitter inte först)
        01_utkast.md                tas INTE med (bara två siffror)

    KATALOGER behöver bara EN siffra först. Kapitel är många och behöver
    luft i numreringen; delar är få.
        01_del_ett/                 gås igenom
        02_del_tva/                 gås igenom
        research/                   hoppas över HELT
        skisser/                    hoppas över HELT

    En katalog som inte börjar med en siffra betyder att innehållet inte
    hör till bygget. Anteckningar, makulatur och skisser hålls alltså
    utanför även om filerna i dem är numrerade.

    Katalogen du STÅR I räknas alltid, oavsett vad den heter. Ett eget
    bygge av anteckningarna görs alltså så här:
        cd anteckningar && $PROGNAME -o anteckningar.pdf

ORDNING
    Filerna sorteras på hela sökvägen. En numrerad katalog hamnar därmed
    före sitt eget innehåll, och delarna kommer i nummerordning:

        001_forord.md
        01_del_ett/010_prolog.md
        01_del_ett/020_kapitel.md
        02_del_tva/010_kapitel.md
        09_epilog/010_slutet.md

    Numren måste vara lika många siffror inom varje nivå. 2_ sorterar
    efter 10_, medan 02_ sorterar före. Kör alltid --lista först.

    Dolda filer och kataloger hoppas över, liksom .pandoc.md - det senare är
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

    Bygg ett urval ur ett manifest, med stilmallen som vanligt:
        $PROGNAME --manifest urval.yaml -o urval.docx
EOF
}

usage_error() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

# ---------------------------------------------------------------------
# Typsnitt: mainfont med reserver
#
# xelatex kraschar om mainfont pekar på ett typsnitt som inte är installerat
# - den försöker generera ett METAFONT-typsnitt, misslyckas, och det blir
# ingen PDF alls. Ett manus som byggs på en annan dator än där det skrevs
# ska inte stupa på det.
#
# Därför läses mainfont och mainfontfallback ur metadatan, och det första
# typsnitt som FAKTISKT finns installerat används. Finns inget av dem alls
# tas mainfont bort helt, och Pandoc får använda sitt vanliga typsnitt.
#
# OBS: pandoc har sedan 3.2 en egen variabel som också heter
# mainfontfallback, men den betyder något annat - den fyller i enstaka
# glyfer som saknas i huvudtypsnittet, och bara för lualatex. Här används
# nyckeln som "reservtypsnitt om huvudtypsnittet saknas".
# ---------------------------------------------------------------------

# Sant om typsnittsfamiljen finns installerad. fc-list ger exakt matchning;
# fc-match duger inte - den svarar med ett ersättningstypsnitt och påstår
# därmed att allt finns.
font_exists() {
    [ -n "$1" ] || return 1

    # Inget grep -q här. Med -q avslutar grep vid första träffen, då får
    # fc-list och tr SIGPIPE, och 'set -o pipefail' gör att hela röret
    # rapporterar fel - alltså "typsnittet saknas" trots att det finns.
    # -F och -- behövs för att typsnittsnamn med regex-tecken eller
    # inledande bindestreck inte ska tolkas som mönster eller flaggor.
    local hits
    hits=$(fc-list : family 2>/dev/null | tr ',' '\n' | grep -Fixc -- "$1" || true)

    [ "${hits:-0}" -gt 0 ]
}

# Plockar ut mainfont och mainfontfallback ur ett YAML-block. Skriver ett
# typsnitt per rad, i den ordning de ska provas.
read_fonts() {
    awk '
        function unquote(v) {
            sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
            sub(/^["\047]/, "", v); sub(/["\047]$/, "", v)
            return v
        }

        # Ett YAML-block börjar och slutar med --- (eller ... på slutet).
        # Slutstrecket måste kännas igen FÖRE listraderna nedan, annars
        # läses "---" som listpunkten "--" och blir ett typsnittsnamn.
        NR == 1 && /^---[ \t]*$/ { in_block = 1; next }
        in_block && /^(---|\.\.\.)[ \t]*$/ { exit }

        /^mainfont[ \t]*:/ {
            v = unquote(substr($0, index($0, ":") + 1))
            if (v != "") print v
            in_list = 0
            next
        }
        /^mainfontfallback[ \t]*:/ {
            v = unquote(substr($0, index($0, ":") + 1))
            if (v != "") { print v; in_list = 0 } else in_list = 1
            next
        }

        # En listpunkt måste ha något efter bindestrecket. Det utesluter
        # rader som bara består av streck.
        in_list && /^[ \t]*-[ \t]+[^ \t]/ {
            v = $0
            sub(/^[ \t]*-[ \t]+/, "", v)
            v = unquote(v)
            if (v != "") print v
            next
        }
        in_list && /^[^ \t-]/ { in_list = 0 }
    ' "$1"
}

# ---------------------------------------------------------------------
# Manifest
#
# Ett manifest är en vanlig Pandoc-defaults-fil. Ordningen kommer ur
# input-files-listan i stället för ur filnamnen, så filerna kan heta vad
# som helst. Samma fil går att köra rakt igenom Pandoc:
#
#     pandoc --defaults=urval.yaml -o ut.docx
#
# Pandoc vägrar okända nycklar på toppnivå, men släpper igenom vad som
# helst under metadata:. Uteslutningslistan bor därför där, och filen
# förblir giltig för Pandoc själv.
# ---------------------------------------------------------------------

# Plockar ut en lista ur manifestet. Nyckeln kan ligga på vilken nivå som
# helst, så samma funktion klarar både input-files på toppnivån och
# manus-uteslut nästlad under metadata:.
read_manifest_list() {
    awk -v key="$2" '
        function unquote(v,   forsta, slut) {
            sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)

            # Citerade värden tas ordagrant. Filnamn får innehålla både #
            # och kolon, och då är citaten det enda som räddar dem.
            # Klipps vid det AVSLUTANDE citattecknet, inte vid radslutet -
            # efter det kan det stå en kommentar.
            forsta = substr(v, 1, 1)
            if (forsta == "\"" || forsta == "\047") {
                v = substr(v, 2)
                slut = index(v, forsta)
                if (slut > 0) v = substr(v, 1, slut - 1)
                return v
            }

            # Ociterat: en kommentar börjar först vid blanktecken-brädgård.
            sub(/[ \t]+#.*$/, "", v)
            sub(/[ \t]+$/, "", v)
            return v
        }

        $0 ~ "^[ \t]*" key "[ \t]*:[ \t]*(#.*)?$" { in_list = 1; next }

        # Nästa nyckel avslutar listan. Listrader börjar med bindestreck
        # och fastnar därför inte här.
        in_list && /^[ \t]*[^ \t#-][^:]*:/ { in_list = 0 }

        in_list && /^[ \t]*-[ \t]+/ {
            v = $0
            sub(/^[ \t]*-[ \t]+/, "", v)
            v = unquote(v)
            if (v != "") print v
        }
    ' "$1"
}

# Letar upp en byggtillgång (stilmall, lua-filter) i tur och ordning:
# bokens egen katalog först, skriptets katalog sist. Så kan en enskild bok
# ha sin egen stilmall utan att den allmänna behöver ändras.
find_asset() {
    local asset_name="$1" candidate
    for candidate in "./$asset_name" "./bygg/$asset_name" "./.pandoc/$asset_name" "$ASSETS_DIR/$asset_name"; do
        if [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

separate=0
lint=0
list_only=0
no_template=0
target=""
manifest=""
reference=""
css_file=""
lua_filters=()
pandoc_flags=()

while [ $# -gt 0 ]; do
    case "$1" in
        -o|--ut)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver ett mål"
            target="$2"
            shift
            ;;
        --ut=*)         target="${1#*=}" ;;
        -m|--manifest)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en fil"
            manifest="$2"
            shift
            ;;
        --manifest=*)   manifest="${1#*=}" ;;
        -r|--referens)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en fil"
            reference="$2"
            shift
            ;;
        --referens=*)   reference="${1#*=}" ;;
        -f|--filter)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en fil"
            lua_filters+=("$2")
            shift
            ;;
        --filter=*)     lua_filters+=("${1#*=}") ;;
        --css)
            [ $# -ge 2 ] || usage_error "flaggan $1 kräver en fil"
            css_file="$2"
            shift
            ;;
        --css=*)        css_file="${1#*=}" ;;
        --utan-mall)    no_template=1 ;;
        -s|--separat)   separate=1 ;;
        -l|--lint)      lint=1 ;;
        -n|--lista)     list_only=1 ;;
        -h|--help)      show_help; exit 0 ;;
        --)             shift; pandoc_flags=("$@"); break ;;
        -*)             usage_error "okänd flagga '$1'" ;;
        *)              usage_error "oväntat argument '$1' (filerna hittas automatiskt)" ;;
    esac
    shift
done

if [ -z "$target" ]; then
    target=$([ "$separate" -eq 1 ] && echo "out" || echo "bok.epub")
fi

# ---------------------------------------------------------------------
# Leta upp filerna
#
# Rekursivt genom hela trädet, men bara genom NUMRERADE kataloger. En
# katalog som inte börjar med en siffra betyder att innehållet inte hör
# till bygget - anteckningar, makulatur, skisser - och klipps bort med
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
files=()
excludes=()

if [ -n "$manifest" ]; then
    # Manifestläge: ordningen står i filen, inte i filnamnen. Ingen
    # sortering - listan gäller som den är skriven.
    [ -f "$manifest" ] || usage_error "hittar inte manifestet '$manifest'"

    while IFS= read -r rad; do
        [ -n "$rad" ] && files+=("$rad")
    done < <(read_manifest_list "$manifest" input-files)

    while IFS= read -r rad; do
        [ -n "$rad" ] && excludes+=("$rad")
    done < <(read_manifest_list "$manifest" manus-uteslut)

    if [ "${#files[@]}" -eq 0 ]; then
        echo "$PROGNAME: '$manifest' innehåller ingen input-files-lista." >&2
        echo "Kör '$PROGNAME --help' för hur ett manifest ser ut." >&2
        exit 1
    fi

    # En fil som står i listan men inte finns är alltid ett fel. Pandoc
    # säger 'withBinaryFile: does not exist' och nämner inte varför; här
    # räknas alla upp på en gång, med den vanliga orsaken utskriven.
    missing_files=()
    for f in "${files[@]}"; do
        [ -f "$f" ] || missing_files+=("$f")
    done
    if [ "${#missing_files[@]}" -gt 0 ]; then
        echo "$PROGNAME: manifestet pekar på filer som inte finns:" >&2
        for f in "${missing_files[@]}"; do
            echo "    $f" >&2
        done
        echo >&2
        echo "Sökvägarna räknas från katalogen du STÅR I, inte från manifestets" >&2
        echo "egen katalog. Det är Pandocs regel för --defaults, och den gäller" >&2
        echo "här också. Du står i: $PWD" >&2
        exit 1
    fi
else
    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(
        find . \
            \( -type d ! -name '.' ! -name '[0-9]*' -prune \) -o \
            \( -type f \
               \( -name '[0-9][0-9][0-9]*.md' -o -name '[0-9][0-9][0-9]*.txt' \) \
               ! -name '*.pandoc.md' \
               -print0 \) \
            2>/dev/null | LC_ALL=C sort -z
    )

    if [ "${#files[@]}" -eq 0 ]; then
        echo "$PROGNAME: hittade inga filer som börjar med tre siffror här." >&2
        echo "Kör '$PROGNAME --help' för vilka namn som räknas." >&2
        exit 1
    fi
fi

# Sökvägen relativt katalogen vi står i. Behövs även efter en lint, då
# 'filer' pekar in i en temp-katalog i stället.
rel_paths=()
for f in "${files[@]}"; do
    rel_paths+=("${f#./}")
done

echo "Hittade ${#files[@]} dokument, i den här ordningen:"
i=1
for rel in "${rel_paths[@]}"; do
    printf "  %3d. %s\n" "$i" "$rel"
    i=$((i + 1))
done

# ---------------------------------------------------------------------
# Manifestets svaga punkt: filer som glider ur listan
#
# Numreringen har en sanningskälla - trädet. Ett manifest har två, och då
# kan de glida isär. Ett kapitel du skrivit men glömt lägga till byggs
# tyst bort, och det syns inte förrän någon läser boken.
#
# Därför räknas varje byggbar fil i trädet som varken står i listan eller
# är uttryckligen utesluten upp här. Att tysta en fil görs genom att
# skriva in den under manus-uteslut, alltså genom att bestämma sig.
# ---------------------------------------------------------------------
if [ -n "$manifest" ]; then
    unlisted=()
    while IFS= read -r -d '' f; do
        rel="${f#./}"

        for listed in "${rel_paths[@]}"; do
            [ "$listed" = "$rel" ] && continue 2
        done

        for pattern in ${excludes+"${excludes[@]}"}; do
            # Omönstrat med flit: uteslutningarna får vara glob.
            case "$rel" in $pattern) continue 2 ;; esac
        done

        unlisted+=("$rel")
    done < <(
        find . \
            \( -type d -name '.*' ! -name '.' -prune \) -o \
            \( -type f \( -name '*.md' -o -name '*.txt' \) \
               ! -name '*.pandoc.md' ! -name '.*' \
               -print0 \) \
            2>/dev/null | LC_ALL=C sort -z
    )

    if [ "${#unlisted[@]}" -gt 0 ]; then
        echo
        echo "VARNING: ${#unlisted[@]} fil(er) i trädet står varken i manifestet"
        echo "         eller under manus-uteslut:"
        for rel in "${unlisted[@]}"; do
            echo "             $rel"
        done
        echo "         De byggs INTE. Lägg dem i input-files om de ska med,"
        echo "         eller under manus-uteslut för att slippa varningen."
    fi
fi

if [ "$list_only" -eq 1 ]; then
    exit 0
fi

command -v pandoc >/dev/null 2>&1 || usage_error "pandoc är inte installerat"

# ---------------------------------------------------------------------
# Byggtillgångar: stilmall för DOCX och lua-filtret för svenska citattecken
# ---------------------------------------------------------------------
if [ "$no_template" -eq 0 ]; then
    if [ -z "$reference" ]; then
        reference="$(find_asset custom-reference.docx || true)"
    fi
    if [ "${#lua_filters[@]}" -eq 0 ]; then
        found_filter="$(find_asset swedish-quotes.lua || true)"
        [ -n "$found_filter" ] && lua_filters=("$found_filter")
    fi
    if [ -z "$css_file" ]; then
        css_file="$(find_asset vit-bakgrund.css || true)"
    fi
fi

# --reference-doc påverkar bara docx/odt/pptx. Övriga format struntar i den
# utan att klaga, så den kan skickas med oavsett utformat.
asset_flags=()
[ -n "$reference" ] && asset_flags+=(--reference-doc="$reference")

# --css gäller HTML och EPUB. Övriga format struntar i den utan att klaga,
# precis som med stilmallen, så den kan skickas med oavsett utformat.
[ -n "$css_file" ] && asset_flags+=(--css="$css_file")
for lf in ${lua_filters+"${lua_filters[@]}"}; do
    asset_flags+=(--lua-filter="$lf")
done

# ---------------------------------------------------------------------
# Typsnittsval
#
# Metadatan kan komma från tre håll. Den mest uttryckliga vinner.
# ---------------------------------------------------------------------
metadata_source=""
for ((n = 0; n < ${#pandoc_flags[@]}; n++)); do
    case "${pandoc_flags[n]}" in
        --metadata-file)   metadata_source="${pandoc_flags[n+1]:-}" ;;
        --metadata-file=*) metadata_source="${pandoc_flags[n]#--metadata-file=}" ;;
    esac
done
if [ -z "$metadata_source" ] && [ -f "./metadata.yaml" ]; then
    metadata_source="./metadata.yaml"
fi
# Sista positionen (vinner alltid): YAML-huvudet i det första dokumentet.
if [ -z "$metadata_source" ]; then
    metadata_source="${files[0]}"
fi

font_flags=()
if [ -f "$metadata_source" ]; then
    wanted=()
    while IFS= read -r rad; do
        [ -n "$rad" ] && wanted+=("$rad")
    done < <(read_fonts "$metadata_source")

    if [ "${#wanted[@]}" -gt 0 ]; then
        chosen=""
        missing=()
        for t in "${wanted[@]}"; do
            if font_exists "$t"; then
                chosen="$t"
                break
            fi
            missing+=("$t")
        done

        echo
        if [ -n "$chosen" ]; then
            if [ "${#missing[@]}" -gt 0 ]; then
                echo "Typsnitt: ${missing[0]} saknas - använder $chosen i stället."
                for ((n = 1; n < ${#missing[@]}; n++)); do
                    echo "          (även ${missing[n]} saknas)"
                done
            else
                echo "Typsnitt: $chosen"
            fi
            font_flags+=(-V "mainfont=$chosen")
        else
            echo "Typsnitt: inget av de önskade finns installerat -"
            for t in "${missing[@]}"; do
                echo "          $t saknas"
            done
            echo "          bygger med Pandocs vanliga typsnitt i stället."
            # Tomt värde tar bort mainfont ur mallen. Utan det här skulle
            # xelatex försöka bygga ett typsnitt som inte finns, och dö.
            font_flags+=(-M "mainfont=")
        fi
    fi
fi

if [ "${#asset_flags[@]}" -gt 0 ]; then
    echo
    echo "Använder:"
    [ -n "$reference" ] && echo "  docx-mall:  $reference"
    [ -n "$css_file" ]  && echo "  css:        $css_file"
    for lf in ${lua_filters+"${lua_filters[@]}"}; do
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
cleanup() { [ -n "$tmp_lint" ] && rm -rf "$tmp_lint"; }
trap cleanup EXIT

if [ "$lint" -eq 1 ]; then
    linter="$ROOT/lib/lint.sh"
    [ -x "$linter" ] || usage_error "hittar inte lib/lint.sh i $ROOT"

    tmp_lint=$(mktemp -d)
    echo
    echo "Städar texten med manus lint..."

    linted=()
    for ((n = 0; n < ${#files[@]}; n++)); do
        rel="${rel_paths[n]}"
        "$linter" -o "$tmp_lint/$(dirname "$rel")" "${files[n]}" >/dev/null
        linted+=("$tmp_lint/$rel")
    done
    files=("${linted[@]}")
fi

echo

# ---------------------------------------------------------------------
# Kör Pandoc
# ---------------------------------------------------------------------
if [ "$separate" -eq 1 ]; then
    mkdir -p "$target" || usage_error "kunde inte skapa katalogen '$target'"

    # Utformatet kan inte läsas ur ett katalognamn - ta det från
    # --pandoc-flaggorna om det står ett -t/--to där, annars pdf.
    format="pdf"
    for ((n = 0; n < ${#pandoc_flags[@]}; n++)); do
        case "${pandoc_flags[n]}" in
            -t|--to) format="${pandoc_flags[n+1]:-pdf}" ;;
            --to=*)  format="${pandoc_flags[n]#--to=}" ;;
        esac
    done

    # Ett par format heter inte samma sak som sin vanliga filändelse.
    extension="$format"
    case "$format" in
        plain)          extension="txt" ;;
        markdown*|gfm)  extension="md"  ;;
        latex|beamer)   extension="tex" ;;
    esac

    count=0
    for ((n = 0; n < ${#files[@]}; n++)); do
        # Behåll katalogstrukturen. Två kapitel i olika delar av boken kan
        # mycket väl heta samma sak - bara basnamnet skulle låta det andra
        # skriva över det första, och räkningen nedan skulle ljuga om det.
        rel="${rel_paths[n]}"
        out="$target/${rel%.*}.$extension"

        mkdir -p "$(dirname "$out")"

        if pandoc "${files[n]}" -o "$out" ${asset_flags+"${asset_flags[@]}"} ${font_flags+"${font_flags[@]}"} ${pandoc_flags+"${pandoc_flags[@]}"}; then
            echo "Skrev: $out"
            count=$((count + 1))
        else
            echo "$PROGNAME: Pandoc misslyckades på $rel" >&2
        fi
    done
    echo
    echo "Klart: $count av ${#files[@]} dokument renderade till $target/"
else
    if pandoc "${files[@]}" -o "$target" ${asset_flags+"${asset_flags[@]}"} ${font_flags+"${font_flags[@]}"} ${pandoc_flags+"${pandoc_flags[@]}"}; then
        echo "Klart: ${#files[@]} dokument sammanslagna till $target"
    else
        echo "$PROGNAME: Pandoc misslyckades." >&2
        exit 1
    fi
fi
