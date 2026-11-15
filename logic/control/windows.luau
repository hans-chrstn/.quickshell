-- Window actions are mediated by the compositor service; IDs are revalidated
-- against the current list before issuing a command.
return function()
    local live = {}
    local focused_output = ""

    local function update_focused_monitor()
        if focused_output == "" then
            fact.focused_monitor = -1
            return
        end
        for i = 0, 7 do
            if text["screen." .. i .. ".name"] == focused_output then
                fact.focused_monitor = i
                return
            end
        end
        fact.focused_monitor = -1
    end

    local function refresh(state)
        focused_output = type(state) == "table" and type(state.monitor) == "string" and state.monitor or ""
        update_focused_monitor()
        local rows = {}
        live = {}
        for _, item in ipairs(type(state) == "table" and type(state.list) == "table" and state.list or {}) do
            local id = tonumber(item.id)
            if id and #rows < 32 then
                local title = type(item.title) == "string" and item.title or ""
                local app = type(item.class) == "string" and item.class or ""
                local monitor = type(item.monitor) == "string" and item.monitor or ""
                live[id] = item
                rows[#rows + 1] = {
                    id = id, title = title ~= "" and title or (app ~= "" and app or "Untitled window"),
                    app = app ~= "" and app or "Application", monitor = monitor,
                    active = item.active == true, minimized = item.minimized == true,
                }
            end
        end
        model.task_rows = rows
        if not live[fact.task_selected] then
            fact.task_selected = -1
            fact.task_close_confirm = false
            text.task_selected_title = ""
        end
    end

    if not sys.watch("window", refresh) then model.task_rows = {} end

    for i = 0, 7 do
        on("text:screen." .. i .. ".name", update_focused_monitor)
    end

    on("cc_task_select", function(value)
        local id = tonumber(value)
        if not id or not live[id] then return end
        fact.task_selected = id
        fact.task_close_confirm = false
        text.task_selected_title = live[id].title or live[id].class or "Window"
    end)

    local function act(command, target)
        local id = target or fact.task_selected
        if id < 0 or not live[id] then return end
        log("window action · " .. command .. " " .. tostring(id))
        local ok, err = pcall(sys.call, command, id)
        if not ok then log("window action: " .. tostring(err)) end
        fact.task_close_confirm = false
    end

    on("cc_task_focus", function()
        local item = live[fact.task_selected]
        if item then act(item.minimized and "window.restore" or "window.activate") end
    end)
    on("cc_task_minimize", function() act("window.minimize") end)
    on("cc_task_close", function()
        if fact.task_selected < 0 or not live[fact.task_selected] then return end
        if fact.task_close_confirm then act("window.close")
        else fact.task_close_confirm = true end
    end)
end
