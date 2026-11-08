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
                if q ~= "" and #matched >= 32 then
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
                    text.query = typed
                    fact["isl." .. i .. ".phase"] = 3
                    pcall(function()
                        focus("query")
                    end)
                    filter_apps()
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

local function env_override(name, fallback)
    local ok, val = pcall(function()
        return sys.ask("env", name)
    end)
    if ok and type(val) == "string" and val ~= "" then
        return val
    end
    return fallback
end

local geo_url = env_override("NACTEST_WEATHER_GEO", "https://ipwho.is/")
local met_base = env_override("NACTEST_WEATHER_MET", "https://api.open-meteo.com/v1/forecast")

local function json_num(body, path)
    local ok, val = pcall(json.decode, body)
    if not ok then
        return nil
    end
    for _, key in ipairs(path) do
        if type(val) ~= "table" then
            return nil
        end
        val = val[key]
    end
    if type(val) ~= "number" then
        return nil
    end
    return val
end

local function code_to_kind(code)
    if code == nil or code < 0 then
        return 0
    end
    if code <= 1 then
        return 1
    end
    if code == 2 then
        return 2
    end
    if code == 3 then
        return 3
    end
    if code == 45 or code == 48 then
        return 4
    end
    if code >= 51 and code <= 57 then
        return 5
    end
    if (code >= 61 and code <= 67) or code == 80 or code == 81 or code == 82 then
        return 6
    end
    if (code >= 71 and code <= 77) or code == 85 or code == 86 then
        return 7
    end
    if code >= 95 and code <= 99 then
        return 8
    end
    return 0
end

local weather_retries = 0
local geo_lat = nil
local geo_lon = nil

local function refresh_weather()
    local fail = function()
        if weather_retries < 3 then
            weather_retries = weather_retries + 1
            after(15000 * weather_retries, refresh_weather)
        end
    end
    local function fetch_meteo()
        local met = met_base
            .. "?latitude=" .. string.format("%.4f", geo_lat)
            .. "&longitude=" .. string.format("%.4f", geo_lon)
            .. "&current=weather_code"
        run("curl", { "-s", "-f", "--max-time", "8", met }, function(out2, code2)
            if code2 ~= 0 or type(out2) ~= "string" then
                fail()
                return
            end
            local wc = json_num(out2, { "current", "weather_code" })
            if wc == nil then
                fail()
                return
            end
            weather_retries = 0
            fact.weather = code_to_kind(math.floor(wc))
        end)
    end
    local ok = pcall(function()
        if geo_lat ~= nil then
            fetch_meteo()
            return
        end
        run("curl", { "-s", "-f", "--max-time", "8", geo_url }, function(out, code)
            if code ~= 0 or type(out) ~= "string" then
                fail()
                return
            end
            geo_lat = json_num(out, { "latitude" })
            geo_lon = json_num(out, { "longitude" })
            if geo_lat == nil or geo_lon == nil then
                fail()
                return
            end
            fetch_meteo()
        end)
    end)
    if not ok then
        fail()
    end
end

after(2500, refresh_weather)
every(3600e3, refresh_weather)
