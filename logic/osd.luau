return function()
    local hide_timer = nil
    local audio_seen = false
    local brightness_seen = false
    local last_volume = nil
    local last_muted = nil
    local last_brightness = nil

    local function target_monitor()
        for i = 0, 7 do
            if fact["mon." .. i .. ".here"] == 1 then
                return i
            end
        end
        local focused = tonumber(fact.focused_monitor)
        if focused and focused >= 0 and focused < 8 then return focused end
        return 0
    end

    local function show(kind, level, muted)
        local amount = math.clamp(tonumber(level) or 0, 0, 1)
        fact.osd_target = target_monitor()
        fact.osd_kind = kind
        fact.osd_level = amount
        fact.osd_muted = muted == true
        text.osd_percent = if muted then "MUTED" else tostring(math.floor(amount * 100 + 0.5)) .. "%"
        fact.osd_visible = 1
        if hide_timer then cancel(hide_timer) end
        hide_timer = after(1800, function()
            fact.osd_visible = 0
            hide_timer = nil
        end)
    end

    local function audio_changed(data)
        if type(data) ~= "table" then return end
        local volume = tonumber(data.volume)
        local muted = data.muted == true
        if not volume then return end
        if audio_seen and (math.abs(volume - last_volume) > 0.004 or muted ~= last_muted) then
            show(1, volume, muted)
        end
        last_volume, last_muted, audio_seen = volume, muted, true
    end

    sys.watch("brightness", function(data)
        if type(data) ~= "table" or data.present ~= true then return end
        local level = tonumber(data.level)
        if not level then return end
        if brightness_seen and math.abs(level - last_brightness) > 0.004 then
            show(2, level, false)
        end
        last_brightness, brightness_seen = level, true
    end)
    return { audio = audio_changed }
end
