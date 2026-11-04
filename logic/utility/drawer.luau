return function()
    local registry = {
        { id = 0, name = "CANVAS & WALLPAPER", sub = "HYGGE ENGINE" },
        { id = 1, name = "AUDIO STUDIO", sub = "OUTPUTS & INPUTS" },
    }

    local by_id = {}
    for _, t in ipairs(registry) do
        by_id[t.id] = t
    end
    model.tools = registry
    fact.util_tool_count = #registry

    local function update_tool_display(id: number)
        local item = by_id[id]
        if item then
            text.tool_name = item.name
            if id == 1 and text.active_sink_name and text.active_sink_name ~= "" then
                text.tool_sub = text.active_sink_name
            elseif id == 0 and text.wall_current_title and text.wall_current_title ~= "" then
                text.tool_sub = text.wall_current_title
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
        local i = math.clamp(math.floor(tonumber(idx) or 0), 0, math.max(#registry - 1, 0))
        fact.util_center_tool = i
        update_tool_display(i)
    end)

    update_tool_display(fact.util_center_tool)
end
