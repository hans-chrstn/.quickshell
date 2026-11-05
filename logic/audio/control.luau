return function()
    local function call_audio(operation: string, value)
        local ok, err = pcall(function()
            if value == nil then
                sys.call(operation)
            else
                sys.call(operation, value)
            end
        end)
        if not ok then
            text.audio_engine_status = "AUDIO CONTROL UNAVAILABLE"
            log("audio: " .. tostring(err))
        end
        return ok
    end

    local function call_app_audio(operation: string, id: number, value)
        local ok, err = pcall(function()
            if value == nil then
                sys.call(operation, id)
            else
                sys.call(operation, id, value)
            end
        end)
        if not ok then
            text.audio_engine_status = "Application audio control unavailable"
            log("audio: " .. tostring(err))
        end
        return ok
    end

    on("set_vol", function(v)
        local val = math.clamp(tonumber(v) or 0, 0, 100)
        fact.audio_volume = math.round(val)
        text.volume_percent_text = if fact.audio_muted then "MUTED" else `{fact.audio_volume}%`
        call_audio("audio.volume", val / 100.0)
    end)

    on("toggle_mute", function()
        fact.audio_muted = not fact.audio_muted
        if fact.audio_muted then
            text.volume_percent_text = "MUTED"
        else
            text.volume_percent_text = `{fact.audio_volume}%`
        end
        call_audio("audio.mute", fact.audio_muted)
    end)

    on("set_mic", function(v)
        local val = math.clamp(tonumber(v) or 0, 0, 100)
        fact.mic_volume = math.round(val)
        text.mic_percent_text = if fact.mic_muted then "MUTED" else `{fact.mic_volume}%`
        call_audio("audio.input", val / 100.0)
    end)

    on("toggle_mic_mute", function()
        fact.mic_muted = not fact.mic_muted
        if fact.mic_muted then
            text.mic_percent_text = "MUTED"
        else
            text.mic_percent_text = `{fact.mic_volume}%`
        end
        call_audio("audio.input_mute", fact.mic_muted)
    end)

    on("pick_sink", function(id)
        local sid = tonumber(id) or 0
        fact.selected_sink = sid
        local updated = {}
        for _, sink in ipairs(model.sinks) do
            local matched = sink.id == sid
            updated[#updated + 1] = {
                id = sink.id,
                name = sink.name,
                is_default = matched,
            }
            if matched then
                text.active_sink_name = sink.name or ""
                text.tool_sub = sink.name or ""
            end
        end
        model.sinks = updated
        call_audio("audio.default", sid)
    end)

    on("pick_source", function(id)
        local source_id = tonumber(id) or 0
        fact.selected_source = source_id
        local updated = {}
        for _, source in ipairs(model.sources) do
            updated[#updated + 1] = {
                id = source.id,
                name = source.name,
                is_default = source.id == source_id,
            }
        end
        model.sources = updated
        call_audio("audio.default", source_id)
    end)

    on("set_app_vol", function(payload)
        local encoded = math.max(tonumber(payload) or 0, 0)
        local app_id = math.floor(encoded / 1000)
        local app_volume = math.clamp(encoded - app_id * 1000, 0, 100)
        call_app_audio("audio.app_volume", app_id, app_volume / 100)
    end)

    on("toggle_app_mute", function(id)
        call_app_audio("audio.app_mute", tonumber(id) or 0, nil)
    end)
end
