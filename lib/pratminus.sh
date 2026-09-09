#!/usr/bin/env bash
set -euo pipefail

# manus pratminus — gör om citatrepliker till pratminus.
#
#     ”Heter du Elof?” frågade Eva.   ->   -- Heter du Elof? frågade Eva.
#
# Svensk skönlitteratur sätter oftast repliker med pratminus i stället för
# citattecken. Den som skrivit ett helt manus med citattecken, eller fått
# text ur ett program som sätter dem automatiskt, vill inte gå igenom varje
# replik för hand.
#
# Bara rader som BÖRJAR med ett citattecken räknas, och bara om det finns
# ett avslutande citattecken på samma rad. Vid minsta tvekan lämnas raden
# orörd — precis som i manus lint. En missad replik kostar en handgrepp,
# en felaktig konvertering kostar text.
#
# Verktyget arbetar på STYCKEN, inte på rader. Ett stycke är samma sak före
# och efter manus lint — lint ombryter inom stycket och rör aldrig
# tomraderna — så ordningen mellan verktygen spelar ingen roll. Redan
# lintade filer fungerar lika bra som orörda.
#
# OBS om awk: de svenska citattecknen är flera byte, och mawk räknar byte.
# En teckenklass [”“] matchar därför EN BYTE och slaktar tecknet. Därför
# används alternation (”|“) genomgående här, aldrig klasser.

readonly PROGNAME="${MANUS_KOMMANDO:-manus pratminus}"

visa_hjalp() {
    cat <<EOF
$PROGNAME — gör om citatrepliker till pratminus.

ANVÄNDNING
    $PROGNAME [FLAGGOR] FIL...

    Som förval läses varje FIL.md och en omgjord kopia skrivs bredvid den
    som FIL.pratminus.md. Originalet ändras aldrig om du inte ger
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
                     aldrig över — den är från första körningen och är den
                     enda kvarvarande kopian av originalet.
    -t, --tankstreck Skriver ett riktigt tankstreck (–) i stället för två
                     bindestreck. Se nedan om vilket du vill ha.
    -n, --lista      Visar varje stycke som skulle ändras, före och efter,
                     och skriver ingen fil. Kör alltid detta först.
    -R, --rapport FIL
                     Skriver arbetslistan över obalanserade stycken till
                     FIL som en markdown-checklista att beta av. Listan
                     skrivs ut i terminalen ändå, med eller utan flaggan.
    -h, --help       Visar den här hjälpen och avslutar.

VILKA RADER RÄKNAS
    En rad räknas som en replik när den, bortsett från indrag, BÖRJAR med
    ett citattecken och har ett till någonstans senare på raden:

    En rad görs om bara när ALLA tre stämmer: den börjar med ett
    citattecken, har ett avslutande på samma rad, och ser ut som en replik
    — alltså slutar med skiljetecken innanför citatet ELLER följs av ett
    kommatecken utanför det.

        ”Heter du Elof?” frågade Eva.       görs om (? innanför)
        ”Jag känner en Elof”, sa hon.       görs om (, utanför)
        Han teg. ”Kanske det”, sa han.      görs INTE (citatet står inte först)
        ”Ett citat utan slut                görs INTE (inget avslutande tecken)
        ”Nomen libri” är arbetsnamnet.      görs INTE (varken eller: en titel)
        ”Han sa ”hej” till mig”, sa hon.    görs INTE (nästlade citat av samma sort)

    De två sista är hela skälet till att regeln finns. Ett citat först på
    raden är inte alltid en replik, och nästlade citat av samma sort går
    inte att skilja åt på ett tryggt sätt. Hellre en replik du får göra om
    för hand än en mening som tyst blir förvanskad.

    Raka ("), svenska (”), engelska (“) och vinkelcitattecken (» «) känns
    igen.

FLER ÄN EN REPLIK I STYCKET
    Det vanligaste mönstret i svensk dialog är replik, berättande, replik —
    allt i ett stycke:

        ”Jag gjorde det.” Han såg bort. ”Det var nödvändigt.”

    Ett manus satt med pratminus har i princip inga citattecken alls, utom
    vid äkta citat. Därför görs alla replikerna om, inte bara den första,
    och stycket delas framför varje ny replik:

        -- Jag gjorde det. Han såg bort.

        -- Det var nödvändigt.

    Berättandet stannar hos repliken det följer på.

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

HANDPÅLÄGGNING
    Varje körning avslutas med en lista över de stycken som lämnades
    orörda, med fil, radnummer och texten. Det gäller även en skarp
    konvertering — den som just gjort om hela boken måste få veta vad som
    INTE blev gjort.

    Ett obalanserat stycke är nästan alltid ett skrivfel i manuset. Vilket
    tecken som fattas går inte att gissa, så verktyget gissar inte.

    --rapport FIL skriver samma lista som en markdown-checklista:

        - [ ] \`02_urtid/010_en_svår_födelse.md\` rad 85

          > Yhla suckade. ”Var gömde du honom? Frågade hon hest.

    Den kan läggas i manusets katalog och betas av som vilken att-göra-lista
    som helst.

VAD SOM LÄMNAS I FRED
    YAML-frontmatter högst upp i filen, kodblock (\`\`\` eller ~~~) och
    HTML-kommentarer (<!-- ... -->, även över flera rader) kopieras rakt
    igenom. Citattecken inuti dem är inte repliker — och i anteckningar är
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

    Skriv ALDRIG pratminus som ETT bindestreck. "- Vart är vi på väg?" är
    listpunkt-syntax i Markdown och renderas som en punktlista.

EXEMPEL
    Se efter vad som skulle ändras, rad för rad, utan att röra något:
        $PROGNAME --lista kapitel/*.md

    Gör om ett kapitel, skriver Kapitel05.pratminus.md bredvid:
        $PROGNAME Kapitel05.md

    Hela boken på plats, med säkerhetskopior:
        $PROGNAME --in-place kapitel/*.md

    Repliker och sedan städning. Ordningen är fri, men lint efteråt ger
    en mening per rad igen efter att stycken fogats ihop:
        $PROGNAME --in-place kapitel/*.md
        manus lint --in-place kapitel/*.md
EOF
}

fel_anvandning() {
    echo "$PROGNAME: $1" >&2
    echo "Kör '$PROGNAME --help' för mer information." >&2
    exit 1
}

in_place=0
bara_lista=0
tankstreck=0
ut_katalog=""
rapport_fil=""
filer=()

while [ $# -gt 0 ]; do
    case "$1" in
        -i|--in-place)  in_place=1 ;;
        -t|--tankstreck) tankstreck=1 ;;
        -n|--lista)     bara_lista=1 ;;
        -h|--help)      visa_hjalp; exit 0 ;;
        -o|--out-dir)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en katalog"
            ut_katalog="$2"
            shift
            ;;
        --out-dir=*)    ut_katalog="${1#*=}" ;;
        -R|--rapport)
            [ $# -ge 2 ] || fel_anvandning "flaggan $1 kräver en fil"
            rapport_fil="$2"
            shift
            ;;
        --rapport=*)    rapport_fil="${1#*=}" ;;
        -*)             fel_anvandning "okänd flagga '$1'" ;;
        *)              filer+=("$1") ;;
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

streck="--"
[ "$tankstreck" -eq 1 ] && streck="–"

# Obalanserade stycken samlas här under körningen, ett per rad som
# FIL <tab> RAD <tab> texten. Rapporten skrivs ut när alla filer är klara,
# så arbetslistan står samlad i stället för utspridd mellan filnamnen.
rapport_tmp=$(mktemp)
rensa_rapport() { rm -f "$rapport_tmp"; }
trap rensa_rapport EXIT

# ---------------------------------------------------------------------
# Kärnan — arbetar på STYCKEN, inte på rader.
#
# Ett stycke är samma sak före och efter manus lint: lint ombryter inom
# stycket och rör aldrig tomraderna. Genom att arbeta på stycken blir det
# här verktyget okänsligt för om filen är lintad eller inte, och ordningen
# mellan verktygen slutar spela roll.
#
# Framåtläsningen stannar ALLTID vid tomraden. Ett stycke med udda antal
# citattecken är obalanserat — ett saknat avslutande tecken — och lämnas
# helt orört. Utan det taket skulle ett skrivfel svälja text ända fram
# till nästa citattecken, kanske flera stycken bort.
#
# Antalet omgjorda repliker och antalet obalanserade stycken skrivs på
# stderr, så att texten på stdout inte blandas ihop med siffrorna.
# ---------------------------------------------------------------------
konvertera() {
    awk -v streck="$streck" -v lista="${2:-0}" \
        -v filnamn="$1" -v rapport="$rapport_tmp" '
        BEGIN {
            # Alternation, inte teckenklass. mawk räknar byte, och en klass
            # skulle matcha en ensam byte ur ett flerbytetecken.
            CITAT = "(\"|”|“|»|«)"
            antal = 0; obalans = 0; n_rader = 0
        }

        function ut(s) { if (!lista) print s }

        function trimma(s) {
            sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s)
            return s
        }

        # Skriver stycket orört, precis som det stod i källan.
        function ut_orort(   i) {
            for (i = 1; i <= n_rader; i++) ut(rader[i])
        }

        # Kärnan i kärnan. Går igenom ett hopfogat stycke från vänster,
        # spann för spann, och avgör för varje citatpar om det är en replik
        # eller ett äkta citat.
        function bearbeta_stycke(text, indrag,
                                 rest, fore, oc, inner, cc, efter, ar_replik,
                                 sn, styck, i, n_citat, kopia, resultat) {
            kopia = text
            n_citat = gsub(CITAT, "&", kopia)

            # Inga citattecken alls, eller ett udda antal: rör ingenting.
            if (n_citat == 0) return ""
            if (n_citat % 2) { obalans++; return "OBALANS" }

            sn = 1; styck[1] = ""
            rest = text
            resultat = 0

            while (match(rest, CITAT)) {
                fore = substr(rest, 1, RSTART - 1)
                oc   = substr(rest, RSTART, RLENGTH)
                rest = substr(rest, RSTART + RLENGTH)

                if (!match(rest, CITAT)) { styck[sn] = styck[sn] fore oc; break }

                inner = substr(rest, 1, RSTART - 1)
                cc    = substr(rest, RSTART, RLENGTH)
                rest  = substr(rest, RSTART + RLENGTH)

                # En replik slutar med skiljetecken innanför citattecknet,
                # ELLER följs av ett kommatecken utanför det. Saknas båda är
                # det ett äkta citat — en titel, ett citerat ord — och det
                # ska behålla sina citattecken. I ett pratminusmanus är det
                # de enda citattecken som blir kvar.
                # rest är nu texten EFTER det avslutande citattecknet.
                ar_replik = (inner ~ /(\.|!|\?|…)[ \t]*$/) ||
                            (substr(rest, 1, 1) == ",")

                if (!ar_replik) {
                    styck[sn] = styck[sn] fore oc inner cc
                    continue
                }

                # Texten före repliken hör till föregående stycke. Fanns det
                # något där måste repliken börja ett nytt — berättandet
                # stannar hos repliken det följer på.
                styck[sn] = styck[sn] fore
                if (trimma(styck[sn]) != "") { sn++; styck[sn] = "" }

                styck[sn] = styck[sn] streck " " inner
                antal++
                resultat = 1
            }

            styck[sn] = styck[sn] rest

            if (!resultat) return ""

            # Bygg ihop styckena med tomrad emellan.
            text = ""
            for (i = 1; i <= sn; i++) {
                if (trimma(styck[i]) == "") continue
                if (text != "") text = text "\n\n"
                text = text indrag trimma(styck[i])
            }
            return text
        }

        function spola_stycke(   i, joined, indrag, resultat) {
            if (n_rader == 0) return

            match(rader[1], /^[ \t]*/)
            indrag = substr(rader[1], 1, RLENGTH)

            # Fog ihop raderna. En ensam radbrytning inuti ett stycke är en
            # mjuk brytning i Markdown och betyder mellanslag — samma regel
            # som manus lint bygger på.
            joined = trimma(rader[1])
            for (i = 2; i <= n_rader; i++) joined = joined " " trimma(rader[i])

            resultat = bearbeta_stycke(joined, indrag)

            if (resultat == "OBALANS") {
                # Samlas till arbetslistan oavsett läge. Den som kör en
                # skarp konvertering behöver veta vad som INTE gjordes.
                if (rapport != "")
                    printf "%s\t%d\t%s\n", filnamn, start_rad, joined >> rapport

                if (lista) {
                    # Hela stycket, inte bara första raden — det saknade
                    # citattecknet kan sitta var som helst i det.
                    obal_rad[obalans] = sprintf("  rad %d:", start_rad)
                    for (i = 1; i <= n_rader; i++)
                        obal_rad[obalans] = obal_rad[obalans] sprintf("\n      %s", rader[i])
                } else ut_orort()
            } else if (resultat == "") {
                ut_orort()
            } else if (lista) {
                printf "  rad %d:\n", start_rad
                for (i = 1; i <= n_rader; i++) printf "      %s\n", rader[i]
                printf "    →\n"
                gsub(/\n/, "\n      ", resultat)
                print "      " resultat
            } else {
                print resultat
            }

            n_rader = 0
        }

        function samla(rad) {
            if (n_rader == 0) start_rad = FNR
            rader[++n_rader] = rad
        }

        # YAML-frontmatter högst upp lämnas orört.
        NR == 1 && /^---[ \t]*$/ { i_fm = 1; ut($0); next }
        i_fm {
            ut($0)
            if (/^(---|\.\.\.)[ \t]*$/) i_fm = 0
            next
        }

        # Kodblock lämnas orörda. Citattecken i dem är inte repliker.
        /^[ \t]*(```|~~~)/ { spola_stycke(); i_kod = !i_kod; ut($0); next }
        i_kod { ut($0); next }

        # HTML-kommentarer likaså. Där ligger arbetsanteckningar, och ett
        # citerat ord i en anteckning är ingen replik — dessutom är citaten
        # där ofta obalanserade med flit.
        i_kommentar { ut($0); if (/-->/) i_kommentar = 0; next }
        /<!--/ {
            spola_stycke()
            ut($0)
            if (!/-->/) i_kommentar = 1
            next
        }

        # Tomraden är styckegränsen, och taket för all framåtläsning.
        /^[ \t]*$/ { spola_stycke(); ut($0); next }

        # Strukturrader står för sig själva och fogas aldrig ihop med
        # brödtext: rubriker, listpunkter, blockcitat, tabeller, avdelare.
        /^[ \t]*(#+[ \t]|>|([-*+]|[0-9]+[.)])[ \t]|\|)/ ||
        /^[ \t]*([-*_][ \t]*){3,}$/ { spola_stycke(); ut($0); next }

        { samla($0) }

        END {
            spola_stycke()
            if (lista && obalans > 0) {
                print "  -- obalanserade citat, lämnas orörda:"
                for (n = 1; n <= obalans; n++) print obal_rad[n]
            }
            print antal, obalans + 0 > "/dev/stderr"
        }
    ' "$1"
}

# Visar vilka rader som skulle ändras, utan att skriva någon fil.
# Antalet kommer på stderr och fångas separat av anroparen.
forhandsvisa() {
    konvertera "$1" 1
}

behandla_en_fil() {
    local input="$1"
    local tmp_ut antal flera

    if [ "$bara_lista" -eq 1 ]; then
        local tmp_rader
        tmp_rader=$(mktemp)
        read -r antal flera < <(forhandsvisa "$input" 2>&1 >"$tmp_rader")
        if [ "${antal:-0}" -gt 0 ] || [ "${flera:-0}" -gt 0 ]; then
            if [ "${flera:-0}" -gt 0 ]; then
                echo "$input ($antal repliker, $flera obalanserade stycken):"
            else
                echo "$input ($antal repliker):"
            fi
            cat "$tmp_rader"
        else
            echo "$input: inga repliker att göra om"
        fi
        rm -f "$tmp_rader"
        return 0
    fi

    tmp_ut=$(mktemp)
    trap 'rm -f "$tmp_ut"' RETURN

    read -r antal flera < <(konvertera "$input" 2>&1 >"$tmp_ut")

    if [ "$in_place" -eq 1 ]; then
        # Är filen redan omgjord händer ingenting alls. Annars hade en andra
        # körning skrivit över säkerhetskopian med den redan omgjorda texten.
        if cmp -s "$input" "$tmp_ut"; then
            echo "Oförändrad: $input"
            return 0
        fi

        # Rör inte heller en .bak som redan finns — den är från första
        # körningen och är den enda kvarvarande kopian av originalet.
        if [ -e "$input.bak" ]; then
            cp "$tmp_ut" "$input"
            echo "Uppdaterad: $input ($antal repliker, $flera obalanserade, befintlig $input.bak lämnad orörd)"
        else
            cp "$input" "$input.bak"
            cp "$tmp_ut" "$input"
            echo "Uppdaterad: $input ($antal repliker, $flera obalanserade, säkerhetskopia: $input.bak)"
        fi
    elif [ -n "$ut_katalog" ]; then
        local ut="$ut_katalog/$(basename "$input")"

        # Skriv aldrig över källan. Det skulle hända om --out-dir pekar på
        # den katalog filen redan ligger i, och då vore originalet borta.
        if [ "$(readlink -f "$ut" 2>/dev/null)" = "$(readlink -f "$input" 2>/dev/null)" ]; then
            echo "$PROGNAME: hoppar över $input — utdata skulle skriva över källan" >&2
            return 0
        fi

        cp "$tmp_ut" "$ut"
        echo "Skrev: $ut ($antal repliker)"
    else
        local ut="${input%.md}.pratminus.md"
        cp "$tmp_ut" "$ut"
        echo "Skrev: $ut ($antal repliker)"
    fi
}

for f in "${filer[@]}"; do
    if [ ! -f "$f" ]; then
        echo "$PROGNAME: hoppar över (inte en fil): $f" >&2
        continue
    fi
    behandla_en_fil "$f"
done

# ---------------------------------------------------------------------
# Arbetslistan
#
# Ett obalanserat stycke är nästan alltid ett skrivfel i manuset: ett
# citattecken saknas, eller ett står för mycket. Verktyget kan inte gissa
# vilket, och gissar därför inte alls. Men den som just konverterat hela
# boken måste få veta vad som INTE blev gjort, och var.
# ---------------------------------------------------------------------
if [ -s "$rapport_tmp" ]; then
    antal_kvar=$(wc -l < "$rapport_tmp")
    if [ "$antal_kvar" -eq 1 ]; then
        ord_stycke="stycke lämnades"
        ord_rapport="stycke som \`$PROGNAME\` lämnade orört."
    else
        ord_stycke="stycken lämnades"
        ord_rapport="stycken som \`$PROGNAME\` lämnade orörda."
    fi

    echo
    echo "HANDPÅLÄGGNING"
    echo "    $antal_kvar $ord_stycke orörda för att citattecknen inte går ihop."
    echo "    Ett tecken saknas, eller ett står för mycket. Rätta i källan och kör igen."
    echo

    # Ett stycke utan tomrader omkring sig kan vara ett helt kapitel. Det
    # som är användbart i listan är fil och radnummer; texten är där för
    # att känna igen stället, inte för att läsas i sin helhet.
    korta() {
        if [ "${#1}" -gt 240 ]; then
            printf '%s…' "${1:0:240}"
        else
            printf '%s' "$1"
        fi
    }

    while IFS=$'\t' read -r r_fil r_rad r_text; do
        echo "    $r_fil, rad $r_rad:"
        korta "$r_text" | fold -s -w 68 | sed 's/^/        /'
        echo
    done < "$rapport_tmp"

    if [ -n "$rapport_fil" ]; then
        {
            echo "# Handpåläggning — obalanserade citat"
            echo
            echo "$antal_kvar $ord_rapport"
            echo "Citattecknen går inte ihop: ett saknas, eller ett står för mycket."
            echo
            while IFS=$'\t' read -r r_fil r_rad r_text; do
                echo "- [ ] \`$r_fil\` rad $r_rad"
                echo
                echo "  > $(korta "$r_text")"
                echo
            done < "$rapport_tmp"
        } > "$rapport_fil"
        echo "    Arbetslistan skriven till: $rapport_fil"
        echo
    fi
elif [ -n "$rapport_fil" ]; then
    {
        echo "# Handpåläggning — obalanserade citat"
        echo
        echo "Inga. Alla citattecken går ihop."
    } > "$rapport_fil"
    echo
    echo "Inga obalanserade stycken. Tom arbetslista skriven till: $rapport_fil"
fi
