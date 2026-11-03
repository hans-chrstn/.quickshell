fact.phase = 0
fact.center_tool = 1
fact.selected_sink = 0
fact.audio_volume = 70
fact.audio_muted = false
fact.mic_volume = 50
fact.mic_muted = false

local TOOL_NAMES = {
    [0] = "WALLPAPER STUDIO",
    [1] = "AUDIO STUDIO",
    [2] = "DISPLAY & NIGHT",
    [3] = "POWER & BATTERY",
    [4] = "GLASS SETTINGS",
}

local TOOL_SUBS = {
    [0] = "GPU DIRECT RENDER",
    [1] = "PIPEWIRE · 48kHz",
    [2] = "WAYLAND GAMMA LUT",
    [3] = "PERFORMANCE MODE",
    [4] = "SMOKED REFRACTION",
}

text.tool_name = TOOL_NAMES[1]
text.tool_sub = TOOL_SUBS[1]
text.volume_percent_text = "70%"
text.mic_percent_text = "50%"
text.audio_engine_status = "PIPEWIRE · WIREPLUMBER DIRECT"

local function sync_audio_state(st)
    if not st or type(st) ~= "table" then return end

    if st.volume ~= nil then
        local v = math.clamp(math.round((tonumber(st.volume) or 0) * 100), 0, 100)
        fact.audio_volume = v
        text.volume_percent_text = if st.muted then "MUTED" else `{v}%`
    end

    if st.muted ~= nil then
        fact.audio_muted = st.muted == true
        if st.muted then
            text.volume_percent_text = "MUTED"
        else
            text.volume_percent_text = `{fact.audio_volume}%`
        end
    end

    if st.input ~= nil then
        fact.mic_volume = math.clamp(math.round((tonumber(st.input) or 0) * 100), 0, 100)
        text.mic_percent_text = `{fact.mic_volume}%`
    end

    if st.input_muted ~= nil then
        fact.mic_muted = st.input_muted == true
        if st.input_muted then
            text.mic_percent_text = "MUTED"
        else
            text.mic_percent_text = `{fact.mic_volume}%`
        end
    end

    if st.outputs and type(st.outputs) == "table" then
        local list = {}
        for idx, out in ipairs(st.outputs) do
            if idx > 3 then break end
            local is_def = out.default == true
            if is_def then
                fact.selected_sink = out.id or idx
                text.active_sink_name = out.name or "Default Output"
            end
            table.insert(list, {
                id = tonumber(out.id) or idx,
                name = out.name or `Sink {idx}`,
                is_default = is_def,
            })
        end
        if #list > 0 then
            model.sinks = list
        end
    end
end

pcall(function()
    sys.watch("audio", function(st)
        sync_audio_state(st)
    end)
end)

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

on("set_vol", function(v)
    local val = math.clamp(tonumber(v) or 0, 0, 100)
    fact.audio_volume = math.round(val)
    text.volume_percent_text = if fact.audio_muted then "MUTED" else `{fact.audio_volume}%`
    pcall(function()
        sys.call("audio.volume", val / 100)
    end)
end)

on("toggle_mute", function()
    pcall(function()
        sys.call("audio.mute")
    end)
end)

on("set_mic", function(v)
    local val = math.clamp(tonumber(v) or 0, 0, 100)
    fact.mic_volume = math.round(val)
    text.mic_percent_text = if fact.mic_muted then "MUTED" else `{fact.mic_volume}%`
    pcall(function()
        sys.call("audio.input", val / 100)
    end)
end)

on("toggle_mic_mute", function()
    pcall(function()
        sys.call("audio.input_mute")
    end)
end)

on("pick_sink", function(sink_id)
    local id = tonumber(sink_id)
    if not id then return end
    fact.selected_sink = id
    pcall(function()
        sys.call("audio.default", id)
    end)
end)
