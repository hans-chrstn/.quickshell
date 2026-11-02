fact.phase = 0
fact.active_tool = 0
fact.selected_wall = 0

on("pick_wall", function(idx)
    local i = tonumber(idx) or 0
    fact.selected_wall = math.clamp(i, 0, 2)
end)

on("close_flyout", function()
    if fact.phase == 2 then
        fact.phase = 1
    end
end)
