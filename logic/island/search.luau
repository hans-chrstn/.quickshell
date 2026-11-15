return function()
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
        for i = 0, 7 do
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
                for i = 0, 7 do
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
    return {
        filter_apps = filter_apps,
        search_open = search_open
    }
end
