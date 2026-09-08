#!/bin/bash

if [ -z "$1" ]; then
    echo "Användning: $0 <fil.md>"
    exit 1
fi

file="$1"

# Vi använder ett litet Python-skript inuti Bash för att säkert matcha citatpar per rad
python3 -c "
import sys, re

with open('$file', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    # Matchar text som har \" text \". Vi fångar det som är inuti och det som kommer efter.
    # Den hanterar både raka (\") och typografiska (” eller “) citattecken.
    match = re.match(r'^([ \t]*)[肢\"”“](.*?)[肢\"”“](.*)$', line)

    if match:
        indent = match.group(1)   # Eventuella tabbar/mellanslag i början
        dialog = match.group(2)   # Själva repliken
        after = match.group(3)    # Det som kommer efter (t.ex. ' sa hon.')

        # Om repliken slutar med ett frågetecken eller utropstecken tas inget kommatecken bort.
        # Men om meningen fortsätter efter citatet, lägger vi till ett mellanslag före anföringssatsen.
        new_line = f'{indent}– {dialog}{after}\n'
        new_lines.append(new_line)
    else:
        new_lines.append(line)

with open('$file', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
"

echo "Konvertering klar för $file!"
