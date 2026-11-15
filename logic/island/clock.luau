return function()
    local WEEKDAYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
    local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

    local function update(c)
        if not c or type(c) ~= "table" then
            return
        end
        local h = tonumber(c.hour)
        local m = tonumber(c.minute)
        if h and m then
            text.clock_time = string.format("%02d:%02d", h, m)
        end
        local d = tonumber(c.day)
        local mo = tonumber(c.month)
        local w = tonumber(c.weekday)
        if d and mo and w then
            text.clock_date = (WEEKDAYS[w + 1] or "") .. " " .. d .. " " .. (MONTHS[mo] or "")
        end
    end

    pcall(function()
        sys.watch("clock", update)
    end)
end
