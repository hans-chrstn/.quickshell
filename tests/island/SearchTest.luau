fact.sel = 0
text.query = ""
model.hits = {}

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

on("text:query", function()
    filter_apps()
end)

on("launch", function(i)
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

    text.query = ""
    filter_apps()
    pcall(function()
        focus("query")
    end)
end)

pcall(function()
    focus("query")
end)
