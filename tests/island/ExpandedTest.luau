fact.playing = false
fact.media_progress = 0

text.track_title = ""
text.track_artist = ""
text.time_elapsed = ""
text.time_remaining = ""

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
        if m and m.title and m.title ~= "" then
            text.track_title = m.title
            local artist = m.artist or ""
            if artist == "" and m.player and m.player ~= "" then
                artist = m.player
            end
            text.track_artist = (artist ~= "") and artist or "Unknown Artist"
            is_playing = m.playing or false
            fact.playing = is_playing

            total_len = tonumber(m.length) or 0
            if not is_scrubbing then
                current_pos = tonumber(m.position) or 0
                if total_len > 0 then
                    text.time_elapsed = format_time(current_pos)
                    text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
                    fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
                else
                    text.time_elapsed = "0:00"
                    text.time_remaining = "--:--"
                    fact.media_progress = 0
                end
            end
        else
            is_playing = false
            fact.playing = false
            current_pos = 0
            total_len = 0
            text.track_title = "Desktop Audio"
            text.track_artist = "Nacre Shell"
            text.time_elapsed = "0:00"
            text.time_remaining = "--:--"
            fact.media_progress = 0
        end
    end)
end)

every(1000, function()
    if is_playing and total_len > 0 and not is_scrubbing then
        current_pos = math.min(current_pos + 1, total_len)
        text.time_elapsed = format_time(current_pos)
        text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
        fact.media_progress = math.clamp(current_pos / total_len, 0, 1)
    end
end)

on("media_seek", function(ratio)
    local r = tonumber(ratio) or 0
    r = math.clamp(r, 0, 1)
    if total_len > 0 then
        is_scrubbing = true
        current_pos = r * total_len
        text.time_elapsed = format_time(current_pos)
        text.time_remaining = "-" .. format_time(math.max(0, total_len - current_pos))
        fact.media_progress = r

        pcall(function()
            sys.call("media.seek", current_pos)
        end)

        after(400, function()
            is_scrubbing = false
        end)
    end
end)

on("media_toggle", function()
    is_playing = not is_playing
    fact.playing = is_playing
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
