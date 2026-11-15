local all_apps = {}

local total_len = 0

local seek_suppress = false

local suppress_id = 0

local function arm_seek_suppress()
    seek_suppress = true
    if suppress_id ~= 0 then
        cancel(suppress_id)
    end
    suppress_id = after(1500, function()
        seek_suppress = false
    end)
end

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

on("frame", function()
end)

local nc_active = {}

local nc_history = {}

local nc_expanded = {}

local nc_open_id = nil

local nc_flat = {}

local nc_seen = {}

local flash_id = 0

local auto_id = 0

local icon_ver = 0

local function now_epoch()
    local ok, t = pcall(function()
        return os.time()
    end)
    if ok and type(t) == "number" then
        return t
    end
    return nil
end

local function rel_time(t0)
    local now = now_epoch()
    if not now or not t0 then
        return ""
    end
    local d = now - t0
    if d < 60 then
        return "now"
    end
    if d < 3600 then
        return math.floor(d / 60) .. "m"
    end
    if d < 86400 then
        return math.floor(d / 3600) .. "h"
    end
    return math.floor(d / 86400) .. "d"
end

local function nstr(v)
    if type(v) == "string" then
        return v
    end
    return ""
end

local function nc_reset()
    nc_open_id = nil
    for k in pairs(nc_expanded) do
        nc_expanded[k] = nil
    end
end

local function nc_rebuild()
    local merged = {}
    for _, n in ipairs(nc_active) do
        merged[#merged + 1] = n
    end
    for _, n in ipairs(nc_history) do
        merged[#merged + 1] = n
    end
    local order = {}
    local by_app = {}
    for _, n in ipairs(merged) do
        local app = nstr(n.app)
        if app == "" then
            app = "Unknown"
        end
        if not by_app[app] then
            by_app[app] = {}
            order[#order + 1] = app
        end
        by_app[app][#by_app[app] + 1] = n
    end
    local rows = {}
    local flat = {}
    for _, app in ipairs(order) do
        local items = by_app[app]
        if #items > 5 then
            local cut = {}
            for i = 1, 5 do
                cut[i] = items[i]
            end
            items = cut
        end
        local newest = items[1]
        local title = nstr(newest.title)
        if title == "" then
            title = nstr(newest.body):sub(1, 40)
        end
        if title == "" then
            title = "Notification"
        end
        local count = #items
        if nc_expanded[app] and count > 1 then
            rows[#rows + 1] = { app = app, badge = "", title = title, body = "", time = rel_time(newest.time), open = 0 }
            flat[#flat + 1] = { type = "group", app = app }
            for _, n in ipairs(items) do
                local body = nstr(n.body)
                local ti = nstr(n.title)
                if ti == "" then
                    ti = body:sub(1, 40)
                end
                if ti == "" then
                    ti = "Notification"
                end
                local id = n.id
                rows[#rows + 1] = {
                    app = app,
                    badge = "",
                    title = ti,
                    body = body,
                    time = rel_time(n.time),
                    open = if id ~= nil and id == nc_open_id then 1 else 0
                }
                flat[#flat + 1] = { type = "item", app = app, id = id }
            end
        else
            rows[#rows + 1] = {
                app = app,
                badge = if count > 1 then "×" .. count else "",
                title = title,
                body = nstr(newest.body),
                time = rel_time(newest.time),
                open = if count == 1 and newest.id ~= nil and newest.id == nc_open_id then 1 else 0
            }
            flat[#flat + 1] = { type = if count > 1 then "group" else "single", app = app, id = newest.id }
        end
        if #rows >= 20 then
            break
        end
    end
    nc_flat = flat
    model.nc = rows
    text.nc_count = if #rows > 0 then #rows .. " kept" else ""
end

local function any_awake()
    for i = 0, 3 do
        if fact["isl." .. i .. ".phase"] ~= 0 then
            return true
        end
    end
    return false
end

local function pill_flash()
    fact.nc_flash = 1
    if flash_id ~= 0 then
        cancel(flash_id)
    end
    flash_id = after(2200, function()
        fact.nc_flash = 0
        flash_id = 0
    end)
end

local auto_woke = {}

local function auto_fold_check()
    for i = 0, 3 do
        if auto_woke[i] and fact["isl." .. i .. ".phase"] == 1 then
            auto_woke[i] = nil
            if fact["isl." .. i .. ".grace_in"] ~= 1 then
                fact["isl." .. i .. ".phase"] = 0
                fact.awake_count = (tonumber(fact.awake_count) or 0) - 1
            end
        end
    end
end

local function auto_pop()
    for i = 0, 3 do
        if not auto_woke[i] and fact["isl." .. i .. ".phase"] == 0 then
            fact["isl." .. i .. ".phase"] = 1
            auto_woke[i] = true
            fact.awake_count = (tonumber(fact.awake_count) or 0) + 1
        end
    end
    if auto_id ~= 0 then
        cancel(auto_id)
    end
    auto_id = after(2400, function()
        auto_id = 0
        auto_fold_check()
    end)
end

local function nc_set_pop(n)
    local title = nstr(n.title)
    local body = nstr(n.body)
    local app = nstr(n.app)
    if title == "" then
        title = body:sub(1, 60)
    end
    if title == "" then
        title = if app ~= "" then app else "Notification"
    end
    text.nc_pop_title = title
    text.nc_pop_body = body
    text.nc_pop_app = app
    local icon = nstr(n.image)
    if icon == "" then
        icon = nstr(n.icon)
    end
    if icon:sub(1, 1) == "/" then
        icon_ver = icon_ver + 1
        icon = icon .. "?" .. icon_ver
    end
    text.nc_pop_icon = icon
end

local function nc_check_new()
    for _, n in ipairs(nc_active) do
        local id = n.id
        if id ~= nil and not nc_seen[id] then
            if #nc_seen > 500 then
                nc_seen = {}
            end
            nc_seen[id] = true
            nc_set_pop(n)
            pill_flash()
            if not any_awake() then
                auto_pop()
            end
            return
        end
    end
end

pcall(function()
    sys.watch("notifications", function(list)
        if type(list) == "table" then
            nc_active = list
            nc_check_new()
            nc_rebuild()
        end
    end)
end)

pcall(function()
    sys.watch("notification_history", function(list)
        if type(list) == "table" then
            nc_history = list
            nc_rebuild()
        end
    end)
end)

on("nc_row_evt", function(i)
    local idx = (tonumber(i) or -1) + 1
    local node = nc_flat[idx]
    if not node then
        return
    end
    if node.type == "group" then
        if nc_expanded[node.app] then
            nc_expanded[node.app] = nil
            nc_open_id = nil
        else
            for k in pairs(nc_expanded) do
                nc_expanded[k] = nil
            end
            nc_expanded[node.app] = true
            nc_open_id = nil
        end
    else
        local id = node.id
        if id ~= nil and id == nc_open_id then
            nc_open_id = nil
        else
            nc_open_id = id
        end
    end
    nc_rebuild()
end)

on("nc_clear_evt", function()
    pcall(function()
        sys.call("notifications.clear")
        sys.call("notifications.clear_history")
    end)
    nc_reset()
    nc_seen = {}
    nc_rebuild()
end)

every(30000, function()
    nc_rebuild()
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
    local prev_phase = 0
    on("fact:isl." .. i .. ".phase", function(phase)
        if phase ~= 1 then
            auto_woke[i] = nil
        end
        if phase == 3 then
            pcall(function()
                focus("query")
            end)
        else
            text.query = ""
        end
        if phase ~= prev_phase and (phase == 4 or prev_phase == 4) then
            nc_reset()
            nc_rebuild()
        end
        prev_phase = phase
        filter_apps()
    end)
end

pcall(function()
    sys.watch("media", function(media)
        if type(media) ~= "table" then
            return
        end
        local title = if type(media.title) == "string" then media.title else ""
        local artist = if type(media.artist) == "string" then media.artist else ""
        local art = if type(media.art) == "string" then media.art else ""
        fact.media_active = title ~= "" and 1 or 0
        fact.playing = media.playing == true
        text.media_title = title
        text.media_artist = artist
        text.media_art = art
        fact.art_present = art ~= "" and 1 or 0
        if title == "" then
            return
        end
        total_len = math.max(tonumber(media.length) or 0, 0)
        if seek_suppress then
            return
        end
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
    end)
end)

on("media_toggle", function()
    pcall(function()
        sys.call("media.toggle")
    end)
end)

on("media_prev", function()
    arm_seek_suppress()
    pcall(function()
        sys.call("media.previous")
    end)
end)

on("media_next", function()
    arm_seek_suppress()
    pcall(function()
        sys.call("media.next")
    end)
end)

on("media_seek", function(ratio)
    if total_len > 0 then
        local pos = math.clamp(tonumber(ratio) or 0, 0, 1) * total_len
        arm_seek_suppress()
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
