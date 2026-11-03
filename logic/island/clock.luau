return function()
    local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

    pcall(function()
        sys.watch("clock", function(c)
            if not c or type(c) ~= "table" then return end
            if c.month and c.day then
                local m = tonumber(c.month) or 1
                local d = tonumber(c.day) or 1
                local name = MONTHS[m] or "Jan"
                text.island_date = string.format("%s %d", name, d)
            end
        end)
    end)
end
