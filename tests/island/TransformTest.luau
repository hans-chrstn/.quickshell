fact.phase = 0
fact.playing = false
fact.media_progress = 0
fact.media_can_seek = false
fact.sel = 0

text.track_title = "Desktop Audio"
text.track_artist = "Nacre Shell"
text.time_elapsed = "0:00"
text.time_remaining = "--:--"
text.island_date = ""
text.query = ""

model.hits = {}

require("logic/island/search")()
require("logic/island/clock")()
require("logic/island/media")()

on("open_wide", function()
    fact.phase = 2
end)

on("fold_compact", function()
    fact.phase = 1
end)

on("dismiss", function()
    fact.phase = 0
end)

on("key", function(_, typed)
    if fact.phase ~= 1 or type(typed) ~= "string" or #typed == 0 then
        return
    end
    local first_byte = string.byte(typed, 1)
    if first_byte and first_byte >= 32 and first_byte ~= 127 then
        fact.phase = 3
        text.query = typed
        pcall(function()
            focus("query")
        end)
    end
end)
