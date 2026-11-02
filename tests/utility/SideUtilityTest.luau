fact.phase = 0
fact.center_tool = 0
fact.selected_wall = 0
fact.night_light = false
fact.volume_pct = 80

local TOOL_NAMES = {
    [0] = "WALLPAPER STUDIO",
    [1] = "AUDIO OUTPUT",
    [2] = "DISPLAY & NIGHT",
    [3] = "POWER & BATTERY",
    [4] = "GLASS SETTINGS"
}

local TOOL_SUBS = {
    [0] = "GPU DIRECT RENDER",
    [1] = "ANALOG DAC · 96kHz",
    [2] = "WAYLAND GAMMA LUT",
    [3] = "PERFORMANCE MODE",
    [4] = "SMOKED REFRACTION"
}

text.tool_name = TOOL_NAMES[0]
text.tool_sub = TOOL_SUBS[0]

local function update_tool(idx)
    local c = tonumber(idx) or 0
    c = math.clamp(c, 0, 4)
    fact.center_tool = c
    text.tool_name = TOOL_NAMES[c] or "TOOL"
    text.tool_sub = TOOL_SUBS[c] or "READY"
end

on("select_tool", function(idx)
    update_tool(idx)
end)

on("toggle_drawer", function()
    if fact.phase == 1 then
        fact.phase = 2
    elseif fact.phase == 2 then
        fact.phase = 1
    end
end)

on("toggle_night", function()
    fact.night_light = not fact.night_light
end)

on("pick_wall", function(idx)
    local i = tonumber(idx) or 0
    fact.selected_wall = math.clamp(i, 0, 2)
end)
