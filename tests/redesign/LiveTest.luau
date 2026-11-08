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
    local count = #model.hits
    if count == 0 then
        return
    end
    local selected = math.clamp(math.floor(tonumber(i) or 0), 0, count - 1)
    local hit = model.hits[selected + 1]
    log("launch idx=" .. selected .. " " .. (hit and hit.name or "nil"))
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
    if typed and type(typed) == "string" and #typed > 0 and fact.phase == 1 then
        local b = string.byte(typed, 1)
        if b and b >= 32 and b ~= 127 then
            text.query = typed
            fact.phase = 3
            pcall(function()
                focus("query")
            end)
            filter_apps()
            return
        end
    end
end)

on("fact:phase", function(phase)
    if phase == 3 then
        pcall(function()
            focus("query")
        end)
    else
        text.query = ""
    end
    filter_apps()
end)
