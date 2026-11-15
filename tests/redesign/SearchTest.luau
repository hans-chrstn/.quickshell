local all_apps = {}

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

on("text:query", filter_apps)

on("launch", function(i)
    if fact.phase ~= 3 then
        return
    end
    local count = #model.hits
    if count == 0 then
        return
    end
    local selected = math.clamp(math.floor(tonumber(i) or 0), 0, count - 1)
    local idx = selected + 1
    local hit = model.hits[idx]
    if hit and hit.exec and hit.exec ~= "" then
        local ok, err = pcall(function()
            sys.call("apps.launch", hit.exec)
        end)
        if not ok then
            log("launcher: " .. tostring(err))
        end
    end
    fact.phase = 0
end)

on("select_hit", function(i)
    local count = #model.hits
    fact.sel = if count > 0 then math.clamp(math.floor(tonumber(i) or 0), 0, count - 1) else 0
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
