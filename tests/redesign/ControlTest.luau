local home_ok, home_value = pcall(sys.ask, "env", "HOME")
local home_dir = if home_ok and type(home_value) == "string" and home_value ~= "" then home_value else "/"
local wall_dir = if home_dir == "/" then "/" else home_dir .. "/.wallpapers"

local wall_files = {}

local function wall_basename(path)
    return path:match("([^/]+)$") or path
end

local function is_image(name)
    local ext = name:match("%.(%w+)$")
    if not ext then
        return false
    end
    ext = ext:lower()
    return ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp"
end

local function sync_wall_title()
    local n = #wall_files
    if n == 0 then
        text.wall_title = ""
        text.wall_preview_path = ""
        return
    end
    local idx = math.clamp(math.floor(tonumber(fact.wall_idx) or 1), 1, n)
    fact.wall_idx = idx
    local path = wall_files[idx]
    text.wall_title = wall_basename(path)
    text.wall_preview_path = path
end

local function load_wall_list()
    pcall(function()
        run("ls", { "-1A", wall_dir }, function(out, code)
            if code ~= 0 or type(out) ~= "string" then
                return
            end
            local files = {}
            for line in out:gmatch("[^\r\n]+") do
                if line:sub(-1) ~= "/" and is_image(line) then
                    files[#files + 1] = wall_dir .. "/" .. line
                end
            end
            table.sort(files)
            wall_files = files
            fact.wall_count = #files
            sync_wall_title()
        end)
    end)
end

load_wall_list()

on("cc_wall_prev", function()
    local n = #wall_files
    if n == 0 then
        return
    end
    fact.wall_idx = if fact.wall_idx > 1 then fact.wall_idx - 1 else n
    sync_wall_title()
end)

on("cc_wall_next", function()
    local n = #wall_files
    if n == 0 then
        return
    end
    fact.wall_idx = if fact.wall_idx < n then fact.wall_idx + 1 else 1
    sync_wall_title()
end)

local picker_current_dir = wall_dir
local picker_raw_items = {}
local picker_generation = 0
local picker_max_items = 16

local function picker_publish()
    local items = {}
    for idx = 1, math.min(#picker_raw_items, picker_max_items) do
        items[#items + 1] = picker_raw_items[idx]
    end
    model.picker_items = items
end

local function picker_normalize_path(path)
    if path == "~" then
        return home_dir
    end
    if path:sub(1, 2) == "~/" then
        return home_dir .. path:sub(2)
    end
    return path
end

local function picker_display_path(path)
    if home_dir ~= "" and path == home_dir then
        return "~"
    end
    if home_dir ~= "" and path:sub(1, #home_dir + 1) == home_dir .. "/" then
        return "~" .. path:sub(#home_dir + 1)
    end
    return path
end

local function picker_parent_dir(path)
    local cleaned = path:gsub("/+$", "")
    local parent = cleaned:match("^(.*)/[^/]+$")
    if not parent or parent == "" then
        return "/"
    end
    return parent
end

local function picker_load_dir(dir_path)
    local target = picker_normalize_path(dir_path)
    picker_generation += 1
    local generation = picker_generation
    text.picker_status = "Loading"

    local ok, err = pcall(function()
        run("ls", { "-1pA", target }, function(out, code)
            if generation ~= picker_generation then
                return
            end
            if code ~= 0 or type(out) ~= "string" then
                text.picker_status = "Unable to open this folder"
                log("file picker: unable to open " .. target)
                return
            end

            local dirs = {}
            local files = {}
            for line in out:gmatch("[^\r\n]+") do
                local is_dir = line:sub(-1) == "/"
                local clean_name = if is_dir then line:sub(1, -2) else line
                local item = {
                    name = clean_name,
                    is_dir = is_dir,
                    path = (target == "/" and "" or target) .. "/" .. clean_name,
                }
                if is_dir then
                    dirs[#dirs + 1] = item
                else
                    files[#files + 1] = item
                end
            end

            table.sort(dirs, function(a, b) return a.name:lower() < b.name:lower() end)
            table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)

            local combined = {}
            for _, item in ipairs(dirs) do
                if #combined >= 256 then break end
                combined[#combined + 1] = {
                    id = #combined,
                    name = item.name,
                    is_dir = true,
                    path = item.path,
                }
            end
            for _, item in ipairs(files) do
                if #combined >= 256 then break end
                combined[#combined + 1] = {
                    id = #combined,
                    name = item.name,
                    is_dir = false,
                    path = item.path,
                }
            end

            picker_current_dir = target
            picker_raw_items = combined
            text.picker_dir_text = picker_display_path(target)
            text.picker_status = if #combined == 0 then "This folder is empty" else ""
            picker_publish()
        end)
    end)
    if not ok then
        text.picker_status = "Folder browsing is unavailable"
        log("file picker: " .. tostring(err))
    end
end

on("picker_select_item", function(id_val)
    local idx = (tonumber(id_val) or -1) + 1
    local item = picker_raw_items[idx]
    if not item then
        text.picker_status = "That item is no longer available"
        return
    end
    if item.is_dir then
        picker_load_dir(item.path)
        return
    end
    fact.picker_open = false
    if not is_image(wall_basename(item.path)) then
        return
    end
    local found = 0
    for i = 1, #wall_files do
        if wall_files[i] == item.path then
            found = i
        end
    end
    if found == 0 then
        wall_files[#wall_files + 1] = item.path
        table.sort(wall_files)
        for i = 1, #wall_files do
            if wall_files[i] == item.path then
                found = i
            end
        end
        fact.wall_count = #wall_files
    end
    fact.wall_idx = found
    sync_wall_title()
end)

on("picker_nav_up", function()
    picker_load_dir(picker_parent_dir(picker_current_dir))
end)

on("picker_choose", function()
    wall_dir = picker_current_dir
    fact.picker_open = false
    load_wall_list()
end)

on("picker_cancel", function()
    picker_generation += 1
    fact.picker_open = false
end)

on("cc_browse", function()
    fact.picker_open = true
    picker_load_dir(picker_current_dir)
end)

local function level_text(v, muted)
    return if muted then "MUTED" else `{math.round(v)}%`
end

local function sync_audio(st)
    if not st or type(st) ~= "table" then
        return
    end
    if st.volume ~= nil then
        local v = math.clamp(math.round((tonumber(st.volume) or 0) * 100), 0, 100)
        fact.audio_volume = v
        text.volume_percent_text = level_text(v, st.muted == true)
    end
    if st.muted ~= nil then
        fact.audio_muted = st.muted == true
        text.volume_percent_text = level_text(fact.audio_volume, fact.audio_muted)
    end
    if st.input ~= nil then
        local v = math.clamp(math.round((tonumber(st.input) or 0) * 100), 0, 100)
        fact.mic_volume = v
        text.mic_percent_text = level_text(v, st.input_muted == true)
    end
    if st.input_muted ~= nil then
        fact.mic_muted = st.input_muted == true
        text.mic_percent_text = level_text(fact.mic_volume, fact.mic_muted)
    end
    if st.outputs and type(st.outputs) == "table" and #st.outputs > 0 then
        local list = {}
        fact.has_sink = false
        for idx, out in ipairs(st.outputs) do
            if #list >= 4 then
                break
            end
            list[#list + 1] = {
                id = tonumber(out.id) or idx,
                name = out.name or `Sink {idx}`,
                is_default = out.default == true,
            }
            if out.default == true and (out.name or "") ~= "" then
                text.active_sink_name = out.name
                fact.has_sink = true
            end
        end
        model.sinks = list
    end
    if st.inputs and type(st.inputs) == "table" and #st.inputs > 0 then
        local list = {}
        for idx, inp in ipairs(st.inputs) do
            if #list >= 4 then
                break
            end
            list[#list + 1] = {
                id = tonumber(inp.id) or idx,
                name = inp.name or `Source {idx}`,
                is_default = inp.default == true,
            }
        end
        model.sources = list
    end
end

local function mock_audio_devices()
    model.sinks = {
        { id = 0, name = "Headphones", is_default = true },
        { id = 1, name = "Speakers (built-in)", is_default = false },
        { id = 2, name = "HDMI - Display 1", is_default = false },
    }
    model.sources = {
        { id = 0, name = "Microphone (built-in)", is_default = true },
        { id = 1, name = "Line In", is_default = false },
    }
    text.active_sink_name = "Headphones"
    fact.has_sink = true
end

mock_audio_devices()

pcall(function()
    sys.watch("audio", sync_audio)
end)

on("cc_vol", function(v)
    local val = math.clamp(math.floor(tonumber(v) or 0), 0, 100)
    fact.audio_volume = val
    text.volume_percent_text = level_text(val, fact.audio_muted)
    pcall(function()
        sys.call("audio.volume", val / 100)
    end)
end)

on("cc_mute", function()
    fact.audio_muted = not fact.audio_muted
    text.volume_percent_text = level_text(fact.audio_volume, fact.audio_muted)
    pcall(function()
        sys.call("audio.mute", fact.audio_muted)
    end)
end)

on("cc_mic", function(v)
    local val = math.clamp(math.floor(tonumber(v) or 0), 0, 100)
    fact.mic_volume = val
    text.mic_percent_text = level_text(val, fact.mic_muted)
    pcall(function()
        sys.call("audio.input", val / 100)
    end)
end)

on("cc_mic_mute", function()
    fact.mic_muted = not fact.mic_muted
    text.mic_percent_text = level_text(fact.mic_volume, fact.mic_muted)
    pcall(function()
        sys.call("audio.input_mute", fact.mic_muted)
    end)
end)

on("cc_pick_sink", function(id)
    fact.selected_sink = math.floor(tonumber(id) or 0)
    pcall(function()
        sys.call("audio.default", fact.selected_sink)
    end)
end)

on("cc_pick_source", function(id)
    fact.selected_source = math.floor(tonumber(id) or 0)
    pcall(function()
        sys.call("audio.default", fact.selected_source)
    end)
end)
