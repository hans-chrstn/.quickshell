return function()
    local current_pos = 0
    local total_len = 0
    local playback_rate = 1
    local is_playing = false
    local is_scrubbing = false
    local scrub_generation = 0

    local function format_time(sec)
        if not sec or sec <= 0 then
            return "0:00"
        end
        local minutes = math.floor(sec / 60)
        local seconds = math.floor(sec % 60)
        return string.format("%d:%02d", minutes, seconds)
    end

    local function publish_position()
        if total_len > 0 then
            current_pos = math.clamp(current_pos, 0, total_len)
            fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
            text.time_elapsed = format_time(current_pos)
            text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
        else
            fact.media_progress = 0
            text.time_elapsed = format_time(current_pos)
            text.time_remaining = "--:--"
        end
    end

    local watch_ok, watch_err = pcall(function()
        sys.watch("media", function(media)
            if type(media) ~= "table" then
                return
            end

            is_playing = media.playing == true
            fact.playing = is_playing
            fact.media_can_seek = media.can_seek == true
            playback_rate = math.max(tonumber(media.rate) or 1, 0)

            text.track_title = if type(media.title) == "string" and media.title ~= "" then media.title else "Desktop Audio"
            if type(media.artist) == "string" and media.artist ~= "" then
                text.track_artist = media.artist
            elseif type(media.player) == "string" and media.player ~= "" then
                text.track_artist = media.player
            else
                text.track_artist = "Nacre Shell"
            end

            total_len = math.max(tonumber(media.length) or 0, 0)
            if not is_scrubbing then
                current_pos = math.max(tonumber(media.position) or 0, 0)
                publish_position()
            end
        end)
    end)
    if not watch_ok then
        log("media: " .. tostring(watch_err))
    end

    every(1000, function()
        if is_playing and total_len > 0 and not is_scrubbing then
            current_pos = math.min(current_pos + playback_rate, total_len)
            publish_position()
        end
    end)

    local function call_media(operation: string, value: number?)
        local ok, err = pcall(function()
            if value == nil then
                sys.call(operation)
            else
                sys.call(operation, value)
            end
        end)
        if not ok then
            log("media: " .. tostring(err))
        end
    end

    on("media_toggle", function()
        call_media("media.toggle")
    end)

    on("media_prev", function()
        call_media("media.previous")
    end)

    on("media_next", function()
        call_media("media.next")
    end)

    on("media_seek", function(ratio)
        if not fact.media_can_seek or total_len <= 0 then
            return
        end

        local normalized = math.clamp(tonumber(ratio) or 0, 0, 1)
        scrub_generation += 1
        local generation = scrub_generation
        is_scrubbing = true
        current_pos = normalized * total_len
        publish_position()
        call_media("media.seek", current_pos)

        after(400, function()
            if generation == scrub_generation then
                is_scrubbing = false
            end
        end)
    end)
end
