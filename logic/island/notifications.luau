return function(search)
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
        for i = 0, 7 do
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
        for i = 0, 7 do
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
        local target = 0
        for i = 0, 7 do
            if fact["mon." .. i .. ".here"] == 1 then
                target = i
                break
            end
        end
        if not auto_woke[target] and fact["isl." .. target .. ".phase"] == 0 then
            fact["isl." .. target .. ".phase"] = 1
            auto_woke[target] = true
            fact.awake_count = (tonumber(fact.awake_count) or 0) + 1
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

    for i = 0, 7 do
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
            search.filter_apps()
        end)
    end
end
