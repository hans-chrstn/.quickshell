return function()
    local function level_text(v, muted)
        return if muted then "MUTED" else `{math.round(v)}%`
    end
    
    local PREF_FILE = "audio-apps.json"
    
    local prefs = {}
    local save_timer = 0
    
    local sink_rows = {}
    local source_rows = {}
    local sink_by_index = {}
    local source_by_index = {}
    local default_sink_index = nil
    local default_source_index = nil
    local pactl_default_sink = ""
    local pactl_default_source = ""
    local service_default_sink = ""
    local service_default_source = ""
    local service_sink_index = nil
    local service_source_index = nil
    
    local streams = {}
    local play_order = {}
    local recs = {}
    local rec_order = {}
    
    local function queue_save()
        if save_timer ~= 0 then
            pcall(cancel, save_timer)
        end
        save_timer = after(600, function()
            save_timer = 0
            pcall(function()
                sys.call("files.write", PREF_FILE, prefs)
            end)
        end)
    end
    
    local function set_pref(key, fields)
        local pref = prefs[key]
        if not pref then
            pref = {}
            prefs[key] = pref
        end
        for k, v in pairs(fields) do
            pref[k] = v
        end
        queue_save()
    end
    
    local function play_key(s)
        return "play:" .. (s.name or "") .. "|" .. (s.binary or "")
    end
    
    local function find_id(rows, name)
        for _, row in ipairs(rows) do
            if row.name == name then
                return row.id
            end
        end
        return nil
    end
    
    local function tidy_device_name(n)
        n = (n or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if n == "" then
            return ""
        end
        n = n:gsub("^[%w_]+_(output|input)%.", "")
        n = n:gsub("^%w{1,7}[%_%-]", "")
        n = n:gsub("[%_%-]", " ")
        local toks = {}
        for tok in n:gmatch("%S+") do
            local serial = tok:match("^[%d][%d][%d][%d][%d][%d][%d]*$") ~= nil
            local usb_id = tok:match("^[%d][%d]*:[%d][%d]*%.?[%d][%d]*$") ~= nil
            if not serial and not usb_id then
                toks[#toks + 1] = tok
            end
        end
        n = table.concat(toks, " ")
        n = n:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        return n
    end
    
    local function display_names(rows)
        local count = {}
        for _, r in ipairs(rows) do
            local d = (r.desc or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if d == "" then
                d = tidy_device_name(r.name)
            end
            r.display = d
            count[d] = (count[d] or 0) + 1
        end
        for _, r in ipairs(rows) do
            local t = tidy_device_name(r.name)
            if count[r.display] > 1 and t ~= "" and t ~= r.display then
                r.display = t
            end
        end
    end
    
    local function parse_device_list(out, cap)
        local rows = {}
        local cur = nil
        for line in out:gmatch("[^\r\n]+") do
            local idx = line:match("^%w+ #(%d+)$")
            if idx then
                if #rows < cap then
                    cur = { id = tonumber(idx), name = "", desc = "" }
                    rows[#rows + 1] = cur
                else
                    cur = nil
                end
            elseif cur then
                local name = line:match("^%s+Name:%s*(.-)%s*$")
                if name then
                    cur.name = name
                end
                local desc = line:match("^%s+Description:%s*(.-)%s*$")
                if desc then
                    cur.desc = desc
                end
            end
        end
        display_names(rows)
        return rows
    end
    
    local function device_name(idx, kind)
        if idx == nil then
            return ""
        end
        local map = if kind == "out" then sink_by_index else source_by_index
        return map[idx] or "Device " .. tostring(idx)
    end
    
    local function routed_flag(idx, kind)
        if idx == nil then
            return false
        end
        local def = if kind == "out" then default_sink_index else default_source_index
        if def == nil then
            return false
        end
        return idx ~= def
    end
    
    local function publish_play_rows()
        local list = {}
        for _, id in ipairs(play_order) do
            local s = streams[id]
            if s then
                list[#list + 1] = {
                    id = s.id,
                    kind = 0,
                    name = s.name,
                    title = s.title,
                    volume = s.volume,
                    muted = s.muted,
                    device = device_name(s.dev_index, "out"),
                    routed = routed_flag(s.dev_index, "out"),
                }
            end
        end
        model.play_rows = list
    end
    
    local function publish_rec_rows()
        local list = {}
        for _, id in ipairs(rec_order) do
            local r = recs[id]
            if r then
                list[#list + 1] = {
                    id = r.id,
                    kind = 1,
                    name = r.name,
                    title = "",
                    volume = 0,
                    muted = false,
                    device = device_name(r.dev_index, "in"),
                    routed = routed_flag(r.dev_index, "in"),
                }
            end
        end
        model.rec_rows = list
    end
    
    local function republish_devices()
        local out = {}
        for _, row in ipairs(sink_rows) do
            out[#out + 1] = {
                id = row.id,
                name = row.display or row.name,
                is_default = row.id == default_sink_index,
            }
        end
        model.sinks = out
        local ins = {}
        for _, row in ipairs(source_rows) do
            ins[#ins + 1] = {
                id = row.id,
                name = row.display or row.name,
                is_default = row.id == default_source_index,
            }
        end
        model.sources = ins
        fact.has_sink = default_sink_index ~= nil
        fact.has_source = default_source_index ~= nil
        text.active_sink_name = device_name(default_sink_index, "out")
        text.active_source_name = device_name(default_source_index, "in")
        fact.selected_sink = default_sink_index or 0
        fact.selected_source = default_source_index or 0
    end
    
    local function row_exists(rows, idx)
        for _, r in ipairs(rows) do
            if r.id == idx then
                return true
            end
        end
        return false
    end
    
    local function named_default(rows, pactl_name)
        if pactl_name == "" or pactl_name:sub(1, 1) == "@" then
            return nil
        end
        return find_id(rows, pactl_name)
    end
    
    local levels_dirty = false
    local function request_levels()
        if levels_dirty then
            return
        end
        levels_dirty = true
        after(300, function()
            levels_dirty = false
            if default_sink_index ~= nil then
                pcall(function()
                    run("pactl", { "get-sink-volume", tostring(default_sink_index) }, function(out, code)
                        if code == 0 and type(out) == "string" then
                            local v = out:match("(%d+)%%")
                            if v then
                                fact.audio_volume = math.clamp(tonumber(v) or 0, 0, 100)
                                text.volume_percent_text = level_text(fact.audio_volume, fact.audio_muted)
                            end
                        end
                    end)
                    run("pactl", { "get-sink-mute", tostring(default_sink_index) }, function(out, code)
                        if code == 0 and type(out) == "string" then
                            local m = out:match("[Mm]ute:%s*(%l+)")
                            if m then
                                fact.audio_muted = m == "yes"
                                text.volume_percent_text = level_text(fact.audio_volume, fact.audio_muted)
                            end
                        end
                    end)
                end)
            end
            if default_source_index ~= nil then
                pcall(function()
                    run("pactl", { "get-source-volume", tostring(default_source_index) }, function(out, code)
                        if code == 0 and type(out) == "string" then
                            local v = out:match("(%d+)%%")
                            if v then
                                fact.mic_volume = math.clamp(tonumber(v) or 0, 0, 100)
                                text.mic_percent_text = level_text(fact.mic_volume, fact.mic_muted)
                            end
                        end
                    end)
                    run("pactl", { "get-source-mute", tostring(default_source_index) }, function(out, code)
                        if code == 0 and type(out) == "string" then
                            local m = out:match("[Mm]ute:%s*(%l+)")
                            if m then
                                fact.mic_muted = m == "yes"
                                text.mic_percent_text = level_text(fact.mic_volume, fact.mic_muted)
                            end
                        end
                    end)
                end)
            end
        end)
    end
    
    local function sync_defaults()
        local def_sink = named_default(sink_rows, pactl_default_sink)
        if def_sink == nil and service_sink_index ~= nil and row_exists(sink_rows, service_sink_index) then
            def_sink = service_sink_index
        end
        if def_sink == nil then
            def_sink = named_default(sink_rows, service_default_sink)
        end
        local def_source = named_default(source_rows, pactl_default_source)
        if def_source == nil and service_source_index ~= nil and row_exists(source_rows, service_source_index) then
            def_source = service_source_index
        end
        if def_source == nil then
            def_source = named_default(source_rows, service_default_source)
        end
        local changed = def_sink ~= default_sink_index or def_source ~= default_source_index
        default_sink_index = def_sink
        default_source_index = def_source
        if changed then
            publish_play_rows()
            publish_rec_rows()
        end
        request_levels()
        republish_devices()
    end
    
    local function apply_device_rows(kind, rows)
        local map = {}
        for _, row in ipairs(rows) do
            map[row.id] = row.display or row.name
        end
        if kind == "out" then
            sink_by_index = map
            sink_rows = rows
        else
            source_by_index = map
            source_rows = rows
        end
        sync_defaults()
    end
    
    local function short_rows(out)
        local rows = {}
        for line in out:gmatch("[^\r\n]+") do
            local id, name = line:match("^(%d+)\t([^\t]+)")
            if id and name and #rows < 8 then
                local n = tonumber(id)
                if n then
                    rows[#rows + 1] = { id = n, name = name, desc = "" }
                end
            end
        end
        display_names(rows)
        return rows
    end
    
    local function fetch_devices(kind)
        local what = if kind == "out" then "sinks" else "sources"
        pcall(function()
            run("pactl", { "list", what }, function(out, code)
                if code == 0 and type(out) == "string" then
                    local rows = parse_device_list(out, 8)
                    if #rows > 0 then
                        apply_device_rows(kind, rows)
                        return
                    end
                end
                run("pactl", { "list", "short", what }, function(out2, code2)
                    if code2 == 0 and type(out2) == "string" then
                        apply_device_rows(kind, short_rows(out2))
                    end
                end)
            end)
        end)
    end
    
    local devices_dirty = false
    local function request_devices()
        if devices_dirty then
            return
        end
        devices_dirty = true
        after(250, function()
            devices_dirty = false
            pcall(function()
                fetch_devices("out")
                fetch_devices("in")
                run("pactl", { "info" }, function(out, code)
                    if code ~= 0 or type(out) ~= "string" then
                        return
                    end
                    for line in out:gmatch("[^\r\n]+") do
                        local s = line:match("^Default Sink:%s+(.-)%s*$")
                        if s then
                            pactl_default_sink = s
                        end
                        local r = line:match("^Default Source:%s+(.-)%s*$")
                        if r then
                            pactl_default_source = r
                        end
                    end
                    sync_defaults()
                end)
            end)
        end)
    end
    
    local function apply_pref_to_stream(s)
        local pref = prefs[play_key(s)]
        if not pref then
            return
        end
        if pref.volume ~= nil then
            local v = math.clamp(math.round(tonumber(pref.volume) or 0), 0, 100)
            pcall(function()
                run("pactl", { "set-sink-input-volume", tostring(s.id), tostring(v) .. "%" }, function(_, _) end)
            end)
        end
        if pref.muted ~= nil then
            pcall(function()
                run("pactl", { "set-sink-input-mute", tostring(s.id), if pref.muted == true then "1" else "0" }, function(_, _) end)
            end)
        end
        if pref.sink ~= nil then
            local dev = tonumber(pref.sink)
            if dev then
                s.dev_index = dev
                pcall(function()
                    run("pactl", { "move-sink-input", tostring(s.id), tostring(dev) }, function(_, _) end)
                end)
            end
        end
    end
    
    local function refresh_stream_devices()
        pcall(function()
            run("pactl", { "list", "sink-inputs" }, function(out, code)
                if code ~= 0 or type(out) ~= "string" then
                    return
                end
                local blocks = {}
                local cur = nil
                for line in out:gmatch("[^\r\n]+") do
                    local n = line:match("^Sink Input #(%d+)")
                    if n then
                        cur = { id = tonumber(n), dev_index = nil, name = "", binary = "", title = "", volume = 100, muted = false }
                        blocks[#blocks + 1] = cur
                    elseif cur then
                        local m = line:match("\tSink:%s+(%d+)")
                        if m then
                            cur.dev_index = tonumber(m)
                        end
                        local mut = line:match("\tMute:%s*(%l+)")
                        if mut then
                            cur.muted = mut == "yes"
                        end
                        local vol = line:match("\tVolume:.-(%d+)%%")
                        if vol then
                            cur.volume = tonumber(vol)
                        end
                        local nm = line:match('\t\tapplication%.name = "([^"]*)"')
                        if nm and cur.name == "" then
                            cur.name = nm
                        end
                        local bin = line:match('\t\tapplication%.process%.binary = "([^"]*)"')
                        if bin then
                            cur.binary = bin
                        end
                        local med = line:match('\t\tmedia%.name = "([^"]*)"')
                        if med then
                            cur.title = med
                        end
                    end
                end
                local seen = {}
                for _, b in ipairs(blocks) do
                    seen[b.id] = true
                    local name = if b.name ~= "" then b.name else "App"
                    local existing = streams[b.id]
                    if existing == nil then
                        local s = { id = b.id, name = name, binary = b.binary, title = b.title, volume = b.volume, muted = b.muted, dev_index = b.dev_index }
                        streams[b.id] = s
                        play_order[#play_order + 1] = b.id
                        apply_pref_to_stream(s)
                    else
                        existing.name = name
                        existing.binary = b.binary
                        existing.title = b.title
                        existing.volume = b.volume
                        existing.muted = b.muted
                        if existing.dev_index ~= b.dev_index then
                            existing.dev_index = b.dev_index
                        end
                    end
                end
                for id in pairs(streams) do
                    if not seen[id] then
                        streams[id] = nil
                    end
                end
                local next_order = {}
                for _, id in ipairs(play_order) do
                    if streams[id] ~= nil then
                        next_order[#next_order + 1] = id
                    end
                end
                play_order = next_order
                publish_play_rows()
            end)
        end)
    end
    
    local function refresh_rec_devices()
        pcall(function()
            run("pactl", { "list", "source-outputs" }, function(out, code)
                if code ~= 0 or type(out) ~= "string" then
                    return
                end
                local blocks = {}
                local cur = nil
                for line in out:gmatch("[^\r\n]+") do
                    local n = line:match("^Source Output #(%d+)")
                    if n then
                        cur = { id = tonumber(n), src = nil, name = nil }
                        blocks[#blocks + 1] = cur
                    elseif cur then
                        local m = line:match("\tSource:%s+(%d+)")
                        if m then
                            cur.src = tonumber(m)
                        end
                        local nm = line:match('application%.name = "([^"]*)"')
                        if nm and cur.name == nil then
                            cur.name = nm
                        end
                    end
                end
                local seen = {}
                for _, b in ipairs(blocks) do
                    seen[b.id] = true
                    local r = recs[b.id]
                    if r == nil then
                        local name = (b.name or "") ~= "" and b.name or "Recorder"
                        recs[b.id] = { id = b.id, name = name, dev_index = b.src }
                        rec_order[#rec_order + 1] = b.id
                        local pref = prefs["rec:" .. name]
                        if pref and pref.sink ~= nil then
                            local dev = tonumber(pref.sink)
                            if dev then
                                recs[b.id].dev_index = dev
                                pcall(function()
                                    run("pactl", { "move-source-output", tostring(b.id), tostring(dev) }, function(_, _) end)
                                end)
                            end
                        end
                    else
                        if (b.name or "") ~= "" then
                            r.name = b.name
                        end
                        if r.dev_index ~= b.src then
                            r.dev_index = b.src
                        end
                    end
                end
                local gone = {}
                for id in pairs(recs) do
                    if not seen[id] then
                        gone[#gone + 1] = id
                    end
                end
                for _, id in ipairs(gone) do
                    recs[id] = nil
                end
                local next_order = {}
                for _, id in ipairs(rec_order) do
                    if recs[id] ~= nil then
                        next_order[#next_order + 1] = id
                    end
                end
                rec_order = next_order
                publish_rec_rows()
            end)
        end)
    end
    
    local streams_dirty = false
    local function request_stream_devices()
        if streams_dirty then
            return
        end
        streams_dirty = true
        after(250, function()
            streams_dirty = false
            refresh_stream_devices()
            refresh_rec_devices()
        end)
    end
    
    local function sync_audio(st)
        if type(st) ~= "table" then
            return
        end
        service_default_sink = ""
        service_default_source = ""
        service_sink_index = nil
        service_source_index = nil
        if type(st.outputs) == "table" then
            for _, out in ipairs(st.outputs) do
                if out.default == true and type(out.name) == "string" and out.name ~= "" then
                    service_default_sink = out.name
                    service_sink_index = tonumber(out.id)
                end
            end
        end
        if type(st.inputs) == "table" then
            for _, inp in ipairs(st.inputs) do
                if inp.default == true and type(inp.name) == "string" and inp.name ~= "" then
                    service_default_source = inp.name
                    service_source_index = tonumber(inp.id)
                end
            end
        end
        sync_defaults()
        request_devices()
    end
    
    local function load_prefs()
        local ok, val = pcall(sys.ask, "files.read", PREF_FILE, "json")
        if ok and type(val) == "table" then
            prefs = val
        end
    end
    
    load_prefs()
    request_devices()
    request_stream_devices()
    
    pcall(function()
        sys.watch("audio", sync_audio)
    end)
    
    pcall(function()
        sys.watch("audio.level", function(v)
            local lvl = if type(v) == "table" then tonumber(v.level) else tonumber(v)
            fact.out_level = math.clamp(lvl or 0, 0, 1)
        end)
    end)
    
    local poll_timer = 0
    
    local function poll_tick()
        request_levels()
        request_stream_devices()
        poll_timer = after(1000, poll_tick)
    end
    
    local function stop_poll()
        if poll_timer ~= 0 then
            pcall(cancel, poll_timer)
            poll_timer = 0
        end
    end
    
    on("cc_wake_evt", function(v)
        if (tonumber(v) or 0) > 0 then
            if poll_timer == 0 then
                poll_tick()
            end
        else
            stop_poll()
        end
    end)
    
    on("cc_vol", function(v)
        local val = math.clamp(math.floor(tonumber(v) or 0), 0, 100)
        fact.audio_volume = val
        text.volume_percent_text = level_text(val, fact.audio_muted)
        if default_sink_index ~= nil then
            pcall(function()
                run("pactl", { "set-sink-volume", tostring(default_sink_index), tostring(val) .. "%" }, function(_, _) end)
            end)
        end
    end)
    
    on("cc_mute", function()
        fact.audio_muted = not fact.audio_muted
        text.volume_percent_text = level_text(fact.audio_volume, fact.audio_muted)
        if default_sink_index ~= nil then
            pcall(function()
                run("pactl", { "set-sink-mute", tostring(default_sink_index), if fact.audio_muted then "1" else "0" }, function(_, _) end)
            end)
        end
    end)
    
    on("cc_mic", function(v)
        local val = math.clamp(math.floor(tonumber(v) or 0), 0, 100)
        fact.mic_volume = val
        text.mic_percent_text = level_text(val, fact.mic_muted)
        if default_source_index ~= nil then
            pcall(function()
                run("pactl", { "set-source-volume", tostring(default_source_index), tostring(val) .. "%" }, function(_, _) end)
            end)
        end
    end)
    
    on("cc_mic_mute", function()
        fact.mic_muted = not fact.mic_muted
        text.mic_percent_text = level_text(fact.mic_volume, fact.mic_muted)
        if default_source_index ~= nil then
            pcall(function()
                run("pactl", { "set-source-mute", tostring(default_source_index), if fact.mic_muted then "1" else "0" }, function(_, _) end)
            end)
        end
    end)
    
    on("cc_pick_sink", function(id)
        local selected = math.floor(tonumber(id) or 0)
        if row_exists(sink_rows, selected) then
            for _, row in ipairs(sink_rows) do
                if row.id == selected then
                    pactl_default_sink = row.name
                    break
                end
            end
            sync_defaults()
            pcall(function()
                run("pactl", { "set-default-sink", tostring(selected) }, function(_, _)
                    request_devices()
                end)
            end)
        end
    end)
    
    on("cc_pick_source", function(id)
        local selected = math.floor(tonumber(id) or 0)
        if row_exists(source_rows, selected) then
            for _, row in ipairs(source_rows) do
                if row.id == selected then
                    pactl_default_source = row.name
                    break
                end
            end
            sync_defaults()
            pcall(function()
                run("pactl", { "set-default-source", tostring(selected) }, function(_, _)
                    request_devices()
                end)
            end)
        end
    end)
    
    on("cc_app_vol", function(v)
        local num = tonumber(v) or 0
        local rid = math.floor(num / 1000)
        local val = math.clamp(math.floor(num % 1000), 0, 100)
        local s = streams[rid]
        if s == nil then
            return
        end
        s.volume = val
        publish_play_rows()
        pcall(function()
            run("pactl", { "set-sink-input-volume", tostring(rid), tostring(val) .. "%" }, function(_, _) end)
        end)
        set_pref(play_key(s), { volume = val })
    end)
    
    on("cc_app_mute", function(v)
        local rid = math.floor(tonumber(v) or 0)
        local s = streams[rid]
        if s == nil then
            return
        end
        s.muted = not s.muted
        publish_play_rows()
        pcall(function()
            run("pactl", { "set-sink-input-mute", tostring(rid), if s.muted then "1" else "0" }, function(_, _) end)
        end)
        set_pref(play_key(s), { muted = s.muted })
    end)
    
    on("cc_route_open", function(v)
        local num = math.floor(tonumber(v) or 0)
        local kind = if num < 0 then 2 else 1
        local rid = if num < 0 then -num - 1 else num
        if (kind == 1 and streams[rid] == nil) or (kind == 2 and recs[rid] == nil) then
            return
        end
        fact.pick_kind = kind
        fact.pick_row = rid
    end)
    
    on("cc_route_pick", function(v)
        local dev = math.floor(tonumber(v) or 0)
        local kind = math.floor(tonumber(fact.pick_kind) or 0)
        local rid = math.floor(tonumber(fact.pick_row) or 0)
        fact.pick_kind = 0
        fact.pick_row = 0
        if kind == 1 then
            local s = streams[rid]
            if s == nil then
                return
            end
            s.dev_index = dev
            publish_play_rows()
            pcall(function()
                run("pactl", { "move-sink-input", tostring(rid), tostring(dev) }, function(_, _) end)
            end)
            set_pref(play_key(s), { sink = dev })
            request_stream_devices()
        elseif kind == 2 then
            local r = recs[rid]
            if r == nil then
                return
            end
            r.dev_index = dev
            publish_rec_rows()
            pcall(function()
                run("pactl", { "move-source-output", tostring(rid), tostring(dev) }, function(_, _) end)
            end)
            set_pref("rec:" .. r.name, { sink = dev })
            request_stream_devices()
        end
    end)
end
