local file_picker = require("logic/common/file_picker")

return function()
    local wall_files = {}
    local load_generation = 0
    local home_dir = ""

    local home_ok, home_value = pcall(sys.ask, "env", "HOME")
    if home_ok and type(home_value) == "string" and home_value ~= "" then
        home_dir = home_value
    else
        home_dir = "/"
        log("wallpaper: HOME is unavailable; starting at the filesystem root")
    end

    local current_dir = if home_dir == "/" then "/" else home_dir .. "/.wallpapers"

    local function display_path(path: string): string
        if home_dir ~= "/" and path == home_dir then
            return "~"
        end
        if home_dir ~= "/" and path:sub(1, #home_dir + 1) == home_dir .. "/" then
            return "~" .. path:sub(#home_dir + 1)
        end
        return path
    end

    local function extract_basename(path: string): string
        return path:match("([^/]+)$") or path
    end

    local function apply_wallpaper(idx: number)
        if #wall_files == 0 then
            return
        end
        local wrapped_idx = ((idx - 1) % #wall_files) + 1
        local target_path = wall_files[wrapped_idx]
        if type(target_path) ~= "string" or target_path == "" then
            return
        end

        fact.wall_current_idx = wrapped_idx
        if fact.wall_active_slot == 0 then
            text.wall_b = target_path
            fact.wall_active_slot = 1
        else
            text.wall_a = target_path
            fact.wall_active_slot = 0
        end

        text.wall_current_title = extract_basename(target_path)
        if fact.util_center_tool == 0 then
            text.tool_sub = text.wall_current_title
        end
    end

    local function apply_wallpaper_file(file_path: string)
        local selected_idx = nil
        for idx, path in ipairs(wall_files) do
            if path == file_path then
                selected_idx = idx
                break
            end
        end
        if not selected_idx then
            wall_files = { file_path }
            fact.wall_count = 1
            selected_idx = 1
        end
        apply_wallpaper(selected_idx)
    end

    local function load_wallpapers_from(dir_path: string)
        load_generation += 1
        local generation = load_generation
        text.wall_current_title = "Loading wallpapers"

        local ok, err = pcall(function()
            run("ls", { "-1A", dir_path }, function(out, code)
                if generation ~= load_generation then
                    return
                end
                if code ~= 0 or type(out) ~= "string" then
                    text.wall_current_title = "Unable to open wallpaper folder"
                    log("wallpaper: unable to open " .. dir_path)
                    return
                end

                local list = {}
                for line in out:gmatch("[^\r\n]+") do
                    local ext = line:match("%.(%w+)$")
                    if ext then
                        ext = ext:lower()
                        if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
                            list[#list + 1] = (dir_path == "/" and "" or dir_path) .. "/" .. line
                        end
                    end
                end
                table.sort(list)

                current_dir = dir_path
                wall_files = list
                fact.wall_count = #list
                text.wall_dir_path = display_path(dir_path)
                if #list > 0 then
                    apply_wallpaper(1)
                else
                    fact.wall_current_idx = 0
                    text.wall_current_title = "No supported images in this folder"
                    if fact.util_center_tool == 0 then
                        text.tool_sub = text.wall_current_title
                    end
                end
            end)
        end)
        if not ok then
            text.wall_current_title = "Wallpaper browsing is unavailable"
            log("wallpaper: " .. tostring(err))
        end
    end

    local read_ok, saved = pcall(sys.ask, "files.read", "wallpaper-dir.json", "json")
    if read_ok and type(saved) == "table" and type(saved.dir) == "string" and saved.dir ~= "" then
        current_dir = saved.dir
    elseif not read_ok then
        log("wallpaper: saved folder could not be read")
    end

    local picker = file_picker({
        home_dir = home_dir,
        initial_dir = current_dir,
        on_choose = function(chosen_dir)
            local ok, err = pcall(function()
                sys.call("files.write", "wallpaper-dir.json", { dir = chosen_dir })
            end)
            if not ok then
                text.picker_status = "The folder could not be saved"
                log("wallpaper: " .. tostring(err))
            end
            load_wallpapers_from(chosen_dir)
        end,
        on_select_file = function(chosen_file)
            local ext = chosen_file:match("%.(%w+)$")
            if not ext then
                text.picker_status = "Choose a JPG, PNG, or WebP image"
                return
            end
            ext = ext:lower()
            if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
                apply_wallpaper_file(chosen_file)
                fact.picker_open = false
            else
                text.picker_status = "Choose a JPG, PNG, or WebP image"
            end
        end,
    })

    on("open_picker", function()
        fact.picker_open = true
        picker.load_dir(current_dir)
    end)

    on("next_wallpaper", function()
        apply_wallpaper(fact.wall_current_idx + 1)
    end)

    on("prev_wallpaper", function()
        apply_wallpaper(fact.wall_current_idx - 1)
    end)

    on("toggle_wall_mode", function()
        if fact.wall_mode == 0 then
            fact.wall_mode = 1
            text.wall_mode_label = "Hygge shader"
        else
            fact.wall_mode = 0
            text.wall_mode_label = "Static crossfade"
        end
    end)

    load_wallpapers_from(current_dir)
end
