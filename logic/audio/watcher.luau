return function()
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
            local def_name = ""
            for idx, out in ipairs(st.outputs) do
                if idx > 12 then break end
                local is_def = out.default == true
                if is_def then
                    fact.selected_sink = out.id or idx
                    def_name = out.name or "Default Output"
                    text.active_sink_name = def_name
                    text.tool_sub = def_name
                end
                table.insert(list, {
                    id = tonumber(out.id) or idx,
                    name = out.name or `Sink {idx}`,
                    is_default = is_def,
                })
            end
            if #list > 0 then
                model.sinks = list
                text.audio_engine_status = "PipeWire · live mixer"
                if text.tool_sub == "" and list[1] then
                    text.tool_sub = list[1].name
                end
            else
                model.sinks = {}
                text.audio_engine_status = "No output devices"
            end
        end

        if st.inputs and type(st.inputs) == "table" then
            local list = {}
            for idx, input in ipairs(st.inputs) do
                if idx > 12 then break end
                local is_def = input.default == true
                if is_def then
                    fact.selected_source = tonumber(input.id) or idx
                end
                list[#list + 1] = {
                    id = tonumber(input.id) or idx,
                    name = input.name or `Input {idx}`,
                    is_default = is_def,
                }
            end
            model.sources = list
        end

        if st.apps and type(st.apps) == "table" then
            local list = {}
            for idx, app in ipairs(st.apps) do
                if idx > 16 then break end
                list[#list + 1] = {
                    id = tonumber(app.id) or idx,
                    name = app.name or app.binary or `Application {idx}`,
                    title = app.title or "Application audio",
                    volume = math.clamp(math.round((tonumber(app.volume) or 0) * 100), 0, 100),
                    muted = app.muted == true,
                    playing = app.playing == true,
                }
            end
            model.audio_apps = list
        else
            model.audio_apps = {}
        end
    end

    local ok, err = pcall(function()
        sys.watch("audio", function(st)
            sync_audio_state(st)
        end)
    end)
    if not ok then
        text.audio_engine_status = "Audio service unavailable"
        log("audio: " .. tostring(err))
    end
end
