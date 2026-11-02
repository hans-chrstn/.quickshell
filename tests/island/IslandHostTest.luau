-- IslandHostTest.luau — State management & event handling for IslandHostTest

fact.phase = 0
fact.playing = true

text.track_title = "Color Your Night"
text.track_artist = "Persona 3 Reload · Lotus Juice"
text.time_elapsed = "1:42"
text.time_remaining = "-2:18"
text.short_date = "Nov 2"

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

sys.watch("clock", function(c)
    if c and c.month and c.day then
        local m_idx = tonumber(c.month) or 11
        local m_str = MONTHS[m_idx] or "Nov"
        local d = tonumber(c.day) or 2
        text.short_date = string.format("%s %d", m_str, d)
    end
end)

on("open_wide", function()
    fact.phase = 2
end)

on("fold_compact", function()
    fact.phase = 1
end)

on("dismiss", function()
    fact.phase = 0
end)

-- Keyboard shortcuts: Escape folds or dismisses the island
on("key", function(name)
    if name == "Escape" or name == "escape" then
        if fact.phase == 2 then
            fact.phase = 1
        elseif fact.phase == 1 then
            fact.phase = 0
        end
    end
end)
