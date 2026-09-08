-- swedish-quotes.lua
--
-- Pandocs inbyggda "smart typografi" gör raka citattecken kurviga, men på
-- engelskt vis: “öppning” och ”stängning” är OLIKA tecken. Svensk
-- typografi använder samma tecken (”) på båda sidor. Det här filtret
-- fångar Pandocs interna Quoted-element (byggda av smart-typografin,
-- INNAN något outputformat väljs) och skriver ut svenska citattecken
-- direkt istället för att låta varje format (HTML/DOCX/LaTeX) rendera
-- dem på sitt engelska standardvis.
--
-- Användning: lägg till --lua-filter=swedish-quotes.lua på valfritt
-- pandoc-anrop, oavsett utformat (epub/docx/pdf) — samma filter fungerar
-- för alla tre eftersom det verkar på strukturen, inte på slutformatet.

function Quoted(el)
    local mark
    if el.quotetype == "DoubleQuote" then
        mark = "”"
    else
        mark = "’"
    end

    local result = { pandoc.Str(mark) }
    for _, item in ipairs(el.content) do
        table.insert(result, item)
    end
    table.insert(result, pandoc.Str(mark))
    return result
end
