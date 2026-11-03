return function()
    local all_apps = {}

    local function filter_apps()
        local q = (text.query or ""):lower()
        log("search: filter query='" .. q .. "' total_apps=" .. tostring(#all_apps))
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
        log("search: matched " .. tostring(#matched) .. " apps")
        for k, v in ipairs(matched) do
            log("search:   hit[" .. tostring(k) .. "] = " .. tostring(v.name) .. " (" .. tostring(v.exec) .. ")")
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
        if fact.phase ~= 3 then
            return
        end
        local idx = (tonumber(i) or 0) + 1
        local hit = model.hits[idx]
        log("launch: requested index=" .. tostring(i) .. " resolved_idx=" .. tostring(idx) .. " hit=" .. tostring(hit and hit.name or "none") .. " exec=" .. tostring(hit and hit.exec or "none"))
        if hit and hit.exec and hit.exec ~= "" then
            log("launch: executing sys.call('apps.launch', '" .. tostring(hit.exec) .. "')")
            local launched = false
            local function do_launch()
                if launched then
                    return
                end
                launched = true
                pcall(function()
                    sys.call("apps.launch", hit.exec)
                end)
            end

            local ok = pcall(function()
                run("hyprctl", { "dispatch", "focusmonitor", "DP-1" }, function()
                    do_launch()
                end)
            end)
            if not ok then
                do_launch()
            else
                after(120, do_launch)
            end
        end
        fact.phase = 0
    end)

    on("select_hit", function(i)
        fact.sel = tonumber(i) or 0
    end)

    on("fact:phase", function(phase)
        if phase ~= 3 then
            text.query = ""
            filter_apps()
        else
            filter_apps()
        end
    end)

    return {
        filter_apps = filter_apps
    }
end
