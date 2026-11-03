return function()
    local current_pos = 0
    local total_len = 0
    local is_playing = false
    local is_scrubbing = false

    local function format_time(sec)
        if not sec or sec <= 0 then
            return "0:00"
        end
        local m = math.floor(sec / 60)
        local s = math.floor(sec % 60)
        return string.format("%d:%02d", m, s)
    end

    pcall(function()
        sys.watch("media", function(m)
            if not m or type(m) ~= "table" then return end

            is_playing = m.playing == true
            fact.playing = is_playing

            local title = m.title
            local artist = m.artist

            if not title or title == "" then
                text.track_title = "Desktop Audio"
            else
                text.track_title = title
            end

            if not artist or artist == "" then
                text.track_artist = "Nacre Shell"
            else
                text.track_artist = artist
            end

            total_len = tonumber(m.length) or 0
            if not is_scrubbing then
                current_pos = tonumber(m.position) or 0
                if total_len > 0 then
                    fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
                    local rem = math.max(0, total_len - current_pos)
                    text.time_elapsed = format_time(current_pos)
                    text.time_remaining = "-" .. format_time(rem)
                else
                    fact.media_progress = 0
                    text.time_elapsed = format_time(current_pos)
                    text.time_remaining = "--:--"
                end
            end
        end)
    end)

    on("media_toggle", function()
        pcall(function()
            sys.call("media.toggle")
        end)
    end)

    on("media_prev", function()
        pcall(function()
            sys.call("media.previous")
        end)
    end)

    on("media_next", function()
        pcall(function()
            sys.call("media.next")
        end)
    end)

    on("media_seek", function(ratio)
        local r = tonumber(ratio) or 0
        r = math.clamp(r, 0, 1)
        fact.media_progress = r
        if total_len > 0 then
            local target_sec = r * total_len
            current_pos = target_sec
            text.time_elapsed = format_time(target_sec)
            local rem = math.max(0, total_len - target_sec)
            text.time_remaining = "-" .. format_time(rem)
            pcall(function()
                sys.call("media.seek", target_sec)
            end)
        end
    end)
end
