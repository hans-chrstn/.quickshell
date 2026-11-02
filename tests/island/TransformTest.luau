fact.phase = 0
fact.playing = false
fact.media_progress = 0
fact.sel = 0

text.track_title = ""
text.track_artist = ""
text.time_elapsed = ""
text.time_remaining = ""
text.island_date = ""
text.query = ""

model.hits = {}

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

local all_apps = {}
local current_pos = 0
local total_len = 0
local is_playing = false
local is_scrubbing = false

local function format_time(sec)
    if not sec or sec <= 0 then
        return "0:00"
    end
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%d:%02d", m, s)
end

local function filter_apps()
    local q = (text.query or ""):lower()
    local matched = {}
    for _, app in ipairs(all_apps) do
        if app and type(app.name) == "string" then
            if q == "" or app.name:lower():find(q, 1, true) then
                matched[#matched + 1] = {
                    name = app.name,
                    icon = app.icon,
                    exec = app.exec or ""
                }
                if #matched >= 5 then
                    break
                end
            end
        end
    end
    model.hits = matched
    fact.sel = 0
end

pcall(function()
    sys.watch("apps", function(list)
        if type(list) == "table" then
            all_apps = list
            filter_apps()
        end
    end)
end)

on("text:query", function()
    filter_apps()
end)

on("pop_search", function()
    if fact.phase == 1 then
        fact.phase = 3
        text.query = ""
        filter_apps()
        pcall(function()
            focus("query")
        end)
    end
end)

on("search_closed", function()
    if fact.phase == 3 then
        fact.phase = 1
        text.query = ""
        filter_apps()
        pcall(function()
            focus()
        end)
    end
end)

on("blur", function()
    if fact.phase == 3 then
        fact.phase = 1
        text.query = ""
        filter_apps()
        pcall(function()
            focus()
        end)
    end
end)

on("key", function(combo, typed)
    if fact.phase == 1 then
        if typed and type(typed) == "string" and #typed > 0 then
            local b = string.byte(typed, 1)
            if b and b >= 32 and b <= 126 then
                fact.phase = 3
                text.query = typed
                filter_apps()
                pcall(function()
                    focus("query")
                end)
                return
            end
        end
    end

    if fact.phase == 3 then
        if combo == "Escape" or combo == "escape" then
            fact.phase = 1
            text.query = ""
            filter_apps()
            pcall(function()
                focus()
            end)
            return
        elseif combo == "Down" then
            local count = #model.hits
            if count > 0 then
                fact.sel = math.min(fact.sel + 1, count - 1)
            end
            return
        elseif combo == "Up" then
            fact.sel = math.max(fact.sel - 1, 0)
            return
        end
    end

    if combo == "Escape" or combo == "escape" then
        if fact.phase == 2 then
            fact.phase = 1
        elseif fact.phase == 1 then
            fact.phase = 0
        end
    end
end)

on("launch", function(i)
    if fact.phase ~= 3 then
        return
    end

    local idx = tonumber(i)
    if not idx or idx < 0 then
        idx = 0
    end

    local hit = model.hits[idx + 1]
    if hit and hit.exec and type(hit.exec) == "string" and #hit.exec > 0 then
        pcall(function()
            sys.call("apps.launch", hit.exec)
        end)
    end

    fact.phase = 1
    text.query = ""
    filter_apps()
    pcall(function()
        focus()
    end)
end)

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

pcall(function()
    sys.watch("media", function(m)
        if m and m.title and m.title ~= "" then
            text.track_title = m.title
            local artist = m.artist or ""
            if artist == "" and m.player and m.player ~= "" then
                artist = m.player
            end
            text.track_artist = (artist ~= "") and artist or "Unknown Artist"
            is_playing = m.playing or false
            fact.playing = is_playing

            total_len = tonumber(m.length) or 0
            if not is_scrubbing then
                current_pos = tonumber(m.position) or 0
                if total_len > 0 then
                    text.time_elapsed = format_time(current_pos)
                    text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
                    fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
                else
                    text.time_elapsed = "0:00"
                    text.time_remaining = "--:--"
                    fact.media_progress = 0
                end
            end
        else
            is_playing = false
            fact.playing = false
            current_pos = 0
            total_len = 0
            text.track_title = "Desktop Audio"
            text.track_artist = "Nacre Shell"
            text.time_elapsed = "0:00"
            text.time_remaining = "--:--"
            fact.media_progress = 0
        end
    end)
end)

every(1000, function()
    if is_playing and total_len > 0 and not is_scrubbing then
        current_pos = math.min(current_pos + 1, total_len)
        text.time_elapsed = format_time(current_pos)
        text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
        fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
    end
end)

on("media_seek", function(ratio)
    local r = tonumber(ratio) or 0
    r = math.clamp(r, 0, 1)
    if total_len > 0 then
        is_scrubbing = true
        current_pos = r * total_len
        text.time_elapsed = format_time(current_pos)
        text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
        fact.media_progress = r

        pcall(function()
            sys.call("media.seek", current_pos)
        end)

        after(400, function()
            is_scrubbing = false
        end)
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

on("media_toggle", function()
    is_playing = not is_playing
    fact.playing = is_playing
    pcall(function()
        sys.call("media.toggle")
    end)
end)

on("media_prev", function()
    pcall(function()
        sys.call("media.previous")
    end)
end)

on("media_next", function()
    pcall(function()
        sys.call("media.next")
    end)
end)
