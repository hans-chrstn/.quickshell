fact.clicks = 0
text.island_date = ""

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

pcall(function()
    sys.watch("clock", function(c)
        if c and c.month and c.day then
            local m_idx = tonumber(c.month)
            local d = tonumber(c.day)
            if m_idx and d and MONTHS[m_idx] then
                text.island_date = string.format("%s %d", MONTHS[m_idx], d)
            end
        end
    end)
end)

on("compact_click", function()
    fact.clicks = (fact.clicks or 0) + 1
end)
