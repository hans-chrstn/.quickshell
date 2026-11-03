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
                if idx > 3 then break end
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
                text.audio_engine_status = "PIPEWIRE · WIREPLUMBER DIRECT"
                if text.tool_sub == "" and list[1] then
                    text.tool_sub = list[1].name
                end
            else
                text.audio_engine_status = "NO OUTPUT DEVICES"
            end
        end
    end

    pcall(function()
        sys.watch("audio", function(st)
            sync_audio_state(st)
        end)
    end)
end
