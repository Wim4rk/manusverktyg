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
readonly TILLGANGAR="$ROT/assets"

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
        manusverktygets assets/       <- den allmänna

    Båda stilmallarna skickas med oavsett utformat. Pandoc struntar tyst i
    dem för de format de inte gäller, så samma kommando fungerar överallt.

    vit-bakgrund.css finns för att Pandocs förvalda stilmall sätter
    html { background-color: #fdfdfd } — inte riktigt vitt, vilket läses
    som en grå ton. Vår CSS läggs efter och vinner.

MANIFEST
    Numreringen är förvalet och räcker för en bok som läses rakt igenom.
    Ett manifest är till för de andra jobben: ett urval till en agent, ett
    utdrag till en tävling, en inlämningsversion — sammanställningar där
    filerna inte har någon gemensam numrering och inte ska döpas om.

    Manifestet är en vanlig Pandoc-defaults-fil:

        input-files:
          - inledning.md
          - "kapitel med mellanslag.md"
          - "#udda namn.md"
        reference-doc: /sokvag/till/custom-reference.docx
        metadata:
          manus-uteslut:
            - "anteckningar/*"
            - makulatur.md

    input-files ger ordningen. Ingen sortering sker — listan gäller precis
    som den står. Filnamn med mellanslag, brädgård eller kolon måste
    citeras, annars läser YAML dem som något annat.

    Samma fil går att köra rakt igenom Pandoc, utan det här skriptet:

        pandoc --defaults=urval.yaml -o ut.docx

    Då uteblir bara lint, typsnittskontrollen och den automatiska
    stilmallsupplockningen. manus-uteslut ligger under metadata: just för
    att Pandoc vägrar okända nycklar på toppnivån men släpper igenom vad
    som helst där — så filen förblir giltig åt båda hållen.

    SÖKVÄGARNA RÄKNAS FRÅN KATALOGEN DU STÅR I, inte från manifestets egen
    katalog. Det är Pandocs regel för --defaults och gäller därför här
    också. Står du på fel ställe räknas de saknade filerna upp och bygget
    avbryts.

    manus-uteslut är skriptets eget tillägg och säger vilka filer i trädet
    som medvetet inte hör till bygget. Posterna får vara glob-mönster.
    Varje byggbar fil som varken står i input-files eller matchar ett
    uteslutningsmönster räknas upp som en varning — det är det som hindrar
    ett glömt kapitel från att tyst byggas bort. Numreringen kan inte glida
    isär från verkligheten; en lista kan.

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
        cd research && $PROGNAME -o anteckningar.pdf

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

    Bygg ett urval ur ett manifest, med stilmallen som vanligt:
        $PROGNAME --manifest urval.yaml -o urval.docx
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
las_manifest_lista() {
    awk -v nyckel="$2" '
        function skala(v,   forsta, slut) {
            sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)

            # Citerade värden tas ordagrant. Filnamn får innehålla både #
            # och kolon, och då är citaten det enda som räddar dem.
            # Klipps vid det AVSLUTANDE citattecknet, inte vid radslutet —
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

        $0 ~ "^[ \t]*" nyckel "[ \t]*:[ \t]*(#.*)?$" { i_lista = 1; next }

        # Nästa nyckel avslutar listan. Listrader börjar med bindestreck
        # och fastnar därför inte här.
        i_lista && /^[ \t]*[^ \t#-][^:]*:/ { i_lista = 0 }

        i_lista && /^[ \t]*-[ \t]+/ {
            v = $0
            sub(/^[ \t]*-[ \t]+/, "", v)
            v = skala(v)
            if (v != "") print v
        }
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
manifest=""
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
        -m|--manifest)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en fil"
            manifest="$2"
            shift
            ;;
        --manifest=*)   manifest="${1#*=}" ;;
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
uteslut=()

if [ -n "$manifest" ]; then
    # Manifestläge: ordningen står i filen, inte i filnamnen. Ingen
    # sortering — listan gäller som den är skriven.
    [ -f "$manifest" ] || fel_anvandning "hittar inte manifestet '$manifest'"

    while IFS= read -r rad; do
        [ -n "$rad" ] && filer+=("$rad")
    done < <(las_manifest_lista "$manifest" input-files)

    while IFS= read -r rad; do
        [ -n "$rad" ] && uteslut+=("$rad")
    done < <(las_manifest_lista "$manifest" manus-uteslut)

    if [ "${#filer[@]}" -eq 0 ]; then
        echo "$PROGNAME: '$manifest' innehåller ingen input-files-lista." >&2
        echo "Kör '$PROGNAME --help' för hur ett manifest ser ut." >&2
        exit 1
    fi

    # En fil som står i listan men inte finns är alltid ett fel. Pandoc
    # säger 'withBinaryFile: does not exist' och nämner inte varför; här
    # räknas alla upp på en gång, med den vanliga orsaken utskriven.
    saknade_filer=()
    for f in "${filer[@]}"; do
        [ -f "$f" ] || saknade_filer+=("$f")
    done
    if [ "${#saknade_filer[@]}" -gt 0 ]; then
        echo "$PROGNAME: manifestet pekar på filer som inte finns:" >&2
        for f in "${saknade_filer[@]}"; do
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

# ---------------------------------------------------------------------
# Manifestets svaga punkt: filer som glider ur listan
#
# Numreringen har en sanningskälla — trädet. Ett manifest har två, och då
# kan de glida isär. Ett kapitel du skrivit men glömt lägga till byggs
# tyst bort, och det syns inte förrän någon läser boken.
#
# Därför räknas varje byggbar fil i trädet som varken står i listan eller
# är uttryckligen utesluten upp här. Att tysta en fil görs genom att
# skriva in den under manus-uteslut, alltså genom att bestämma sig.
# ---------------------------------------------------------------------
if [ -n "$manifest" ]; then
    olistade=()
    while IFS= read -r -d '' f; do
        rel="${f#./}"

        for listad in "${rel_sokvagar[@]}"; do
            [ "$listad" = "$rel" ] && continue 2
        done

        for monster in ${uteslut+"${uteslut[@]}"}; do
            # Omönstrat med flit: uteslutningarna får vara glob.
            case "$rel" in $monster) continue 2 ;; esac
        done

        olistade+=("$rel")
    done < <(
        find . \
            \( -type d -name '.*' ! -name '.' -prune \) -o \
            \( -type f \( -name '*.md' -o -name '*.txt' \) \
               ! -name '*.pandoc.md' ! -name '.*' \
               -print0 \) \
            2>/dev/null | LC_ALL=C sort -z
    )

    if [ "${#olistade[@]}" -gt 0 ]; then
        echo
        echo "VARNING: ${#olistade[@]} fil(er) i trädet står varken i manifestet"
        echo "         eller under manus-uteslut:"
        for rel in "${olistade[@]}"; do
            echo "             $rel"
        done
        echo "         De byggs INTE. Lägg dem i input-files om de ska med,"
        echo "         eller under manus-uteslut för att slippa varningen."
    fi
fi

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
