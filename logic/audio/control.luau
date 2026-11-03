return function()
    on("set_vol", function(v)
        local val = math.clamp(tonumber(v) or 0, 0, 100)
        fact.audio_volume = math.round(val)
        text.volume_percent_text = if fact.audio_muted then "MUTED" else `{fact.audio_volume}%`
        pcall(function()
            sys.call("audio.volume", val / 100.0)
        end)
    end)

    on("toggle_mute", function()
        fact.audio_muted = not fact.audio_muted
        if fact.audio_muted then
            text.volume_percent_text = "MUTED"
        else
            text.volume_percent_text = `{fact.audio_volume}%`
        end
        pcall(function()
            sys.call("audio.mute", fact.audio_muted)
        end)
    end)

    on("set_mic", function(v)
        local val = math.clamp(tonumber(v) or 0, 0, 100)
        fact.mic_volume = math.round(val)
        text.mic_percent_text = if fact.mic_muted then "MUTED" else `{fact.mic_volume}%`
        pcall(function()
            sys.call("audio.input", val / 100.0)
        end)
    end)

    on("toggle_mic_mute", function()
        fact.mic_muted = not fact.mic_muted
        if fact.mic_muted then
            text.mic_percent_text = "MUTED"
        else
            text.mic_percent_text = `{fact.mic_volume}%`
        end
        pcall(function()
            sys.call("audio.input_mute", fact.mic_muted)
        end)
    end)

    on("pick_sink", function(id)
        local sid = tonumber(id) or 0
        fact.selected_sink = sid
        local list = model.sinks
        for idx, s in ipairs(list) do
            local matched = s.id == sid or idx == sid
            s.is_default = matched
            if matched then
                text.active_sink_name = s.name or ""
                text.tool_sub = s.name or ""
            end
        end
        model.sinks = list
        pcall(function()
            sys.call("audio.sink", sid)
        end)
    end)
end
