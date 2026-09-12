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
-- CITAT I CITAT. I källan skrivs inre citat alltid med enkla tecken, '...'.
-- Hur de renderas beror på hur dialogen är satt:
--
--   Dialog med citattecken   ”Han sa ’hej’ till mig”, sa hon.   ' -> ’
--   Dialog med talstreck     -- Han sa ”hej” till mig, sa hon.  ' -> ”
--
-- I en talstreckstext finns ingen yttre citatnivå, så det som skrevs som
-- inre citat är den enda nivån och får det dubbla tecknet. Källan behåller
-- sin ' - skillnaden är betydelsebärande där, och manus talstreck rör den
-- aldrig. Formen bestäms här, vid rendering, och ingen annanstans.
--
-- Talstreck känns igen på att något stycke börjar med -- eller ett riktigt
-- streck. Det räcker med ett; en text blandar inte formerna.
--
-- Användning: --lua-filter=swedish-quotes.lua på valfritt pandoc-anrop,
-- oavsett utformat. Filtret verkar på strukturen, inte på slutformatet.

local uses_talstreck = false

-- Första passet: finns det talstreck i texten?
local function detect(doc)
    for _, block in ipairs(doc.blocks) do
        if block.t == "Para" or block.t == "Plain" then
            local first = block.content[1]
            if first and first.t == "Str" then
                local s = first.text
                if s:sub(1, 2) == "--"
                    or s:sub(1, 3) == "\u{2013}"
                    or s:sub(1, 3) == "\u{2014}" then
                    uses_talstreck = true
                    return
                end
            end
        end
    end
end

-- Andra passet: sätt tecknen.
local function quoted(el)
    local mark
    if el.quotetype == "DoubleQuote" then
        mark = "”"
    elseif uses_talstreck then
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

return {
    { Pandoc = function(doc) detect(doc); return doc end },
    { Quoted = quoted },
}
