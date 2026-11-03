return function()
    local registry = {
        { id = 0, name = "CANVAS & WALLPAPER", sub = "HYGGE ENGINE" },
        { id = 1, name = "AUDIO STUDIO", sub = "OUTPUTS & INPUTS" },
        { id = 2, name = "BLUETOOTH", sub = "CONTROLLER" },
        { id = 3, name = "NETWORKS", sub = "CONNECTIONS" },
        { id = 4, name = "MONITORS", sub = "DISPLAYS" },
    }

    local by_id = {}
    for _, t in ipairs(registry) do
        by_id[t.id] = t
    end
    model.tools = registry

    local function update_tool_display(id: number)
        local item = by_id[id]
        if item then
            text.tool_name = item.name
            if id == 1 and text.active_sink_name and text.active_sink_name ~= "" then
                text.tool_sub = text.active_sink_name
            else
                text.tool_sub = item.sub
            end
        end
    end

    on("toggle_util_drawer", function()
        if fact.util_phase == 1 then
            fact.util_phase = 2
        elseif fact.util_phase == 2 then
            fact.util_phase = 1
        end
    end)

    on("select_tool", function(idx)
        local i = tonumber(idx) or 0
        fact.util_center_tool = i
        update_tool_display(i)
    end)

    update_tool_display(fact.util_center_tool)
end
