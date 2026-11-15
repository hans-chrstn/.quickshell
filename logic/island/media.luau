return function()
    local total_len = 0
    
    local seek_suppress = false
    
    local suppress_id = 0
    
    local function arm_seek_suppress()
        seek_suppress = true
        if suppress_id ~= 0 then
            cancel(suppress_id)
        end
        suppress_id = after(1500, function()
            seek_suppress = false
        end)
    end
    
    local function format_time(sec)
        if not sec or sec <= 0 then
            return "0:00"
        end
        local m = math.floor(sec / 60)
        local s = math.floor(sec % 60)
        return string.format("%d:%02d", m, s)
    end

    pcall(function()
        sys.watch("media", function(media)
            if type(media) ~= "table" then
                return
            end
            local title = if type(media.title) == "string" then media.title else ""
            local artist = if type(media.artist) == "string" then media.artist else ""
            local art = if type(media.art) == "string" then media.art else ""
            fact.media_active = title ~= "" and 1 or 0
            fact.playing = media.playing == true
            text.media_title = title
            text.media_artist = artist
            text.media_art = art
            fact.art_present = art ~= "" and 1 or 0
            if title == "" then
                return
            end
            total_len = math.max(tonumber(media.length) or 0, 0)
            if seek_suppress then
                return
            end
            local pos = math.max(tonumber(media.position) or 0, 0)
            if total_len > 0 then
                fact.media_progress = math.clamp(pos / total_len, 0, 1)
                text.time_elapsed = format_time(pos)
                text.time_remaining = "-" .. format_time(math.max(0, total_len - pos))
            else
                fact.media_progress = 0
                text.time_elapsed = format_time(pos)
                text.time_remaining = "--:--"
            end
        end)
    end)
    
    on("media_toggle", function()
        pcall(function()
            sys.call("media.toggle")
        end)
    end)
    
    on("media_prev", function()
        arm_seek_suppress()
        pcall(function()
            sys.call("media.previous")
        end)
    end)
    
    on("media_next", function()
        arm_seek_suppress()
        pcall(function()
            sys.call("media.next")
        end)
    end)
    
    on("media_seek", function(ratio)
        if total_len > 0 then
            local pos = math.clamp(tonumber(ratio) or 0, 0, 1) * total_len
            arm_seek_suppress()
            pcall(function()
                sys.call("media.seek", pos)
            end)
        end
    end)
end
