local all_apps = {}

local total_len = 0

local function format_time(sec)
    if not sec or sec <= 0 then
        return "0:00"
    end
    local m = math.floor(sec / 60)
    local s = math.floor(sec % 60)
    return string.format("%d:%02d", m, s)
end

local function search_open()
    for i = 0, 3 do
        if fact["isl." .. i .. ".phase"] == 3 then
            return true
        end
    end
    return false
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
                if #matched >= 16 then
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

on("text:query", filter_apps)

on("launch", function(i)
    if not search_open() then
        return
    end
    local count = #model.hits
    if count == 0 then
        return
    end
    local selected = math.clamp(math.floor(tonumber(i) or 0), 0, count - 1)
    local hit = model.hits[selected + 1]
    if hit and hit.exec and hit.exec ~= "" then
        local ok, err = pcall(function()
            sys.call("apps.launch", hit.exec)
        end)
        if not ok then
            log("launcher: " .. tostring(err))
        end
    end
end)

on("key", function(combo, typed)
    if typed and type(typed) == "string" and #typed > 0 then
        local b = string.byte(typed, 1)
        if b and b >= 32 and b ~= 127 then
            for i = 0, 3 do
                if fact["isl." .. i .. ".phase"] == 1 then
                    fact["isl." .. i .. ".phase"] = 3
                    text.query = typed
                    pcall(function()
                        focus("query")
                    end)
                    return
                end
            end
        end
    end
end)

for i = 0, 3 do
    on("fact:isl." .. i .. ".phase", function(phase)
        if phase == 3 then
            pcall(function()
                focus("query")
            end)
        else
            text.query = ""
        end
        filter_apps()
    end)
end

pcall(function()
    sys.watch("media", function(media)
        if type(media) ~= "table" then
            return
        end
        local title = if type(media.title) == "string" then media.title else ""
        fact.media_active = title ~= "" and 1 or 0
        fact.playing = media.playing == true
        if title ~= "" then
            total_len = math.max(tonumber(media.length) or 0, 0)
            local pos = math.max(tonumber(media.position) or 0, 0)
            if total_len > 0 then
                fact.media_progress = math.clamp(pos / total_len, 0, 1)
                text.time_elapsed = format_time(pos)
                text.time_remaining = "-" .. format_time(math.max(0, total_len - pos))
            else
                fact.media_progress = 0
                text.time_elapsed = format_time(pos)
                text.time_remaining = "--:--"
            end
        end
    end)
end)

on("media_toggle", function()
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

on("media_seek", function(ratio)
    if total_len > 0 then
        local pos = math.clamp(tonumber(ratio) or 0, 0, 1) * total_len
        pcall(function()
            sys.call("media.seek", pos)
        end)
    end
end)
