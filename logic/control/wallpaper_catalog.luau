return function(settings)
    local home_ok, home_value = pcall(sys.ask, "env", "HOME")
    local home_dir = if home_ok and type(home_value) == "string" and home_value ~= "" then home_value else "/"
    local saved_dir = settings.get("wallpaper", "directory")
    local saved_selected = settings.get("wallpaper", "selected")
    local saved_applied = settings.get("wallpaper", "applied")

    local catalog = {
        home_dir = home_dir,
        wall_dir = if type(saved_dir) == "string" and saved_dir:sub(1, 1) == "/" then saved_dir else if home_dir == "/" then "/" else home_dir .. "/.wallpapers",
        wall_files = {},
    }

    if type(saved_applied) == "string" and saved_applied:sub(1, 1) == "/" then
        text.wall_applied_path = saved_applied
        fact.wall_applied = true
    end

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
        local n = #catalog.wall_files
        if n == 0 then
            text.wall_title = ""
            text.wall_preview_path = ""
            return
        end
        local idx = math.clamp(math.floor(tonumber(fact.wall_idx) or 1), 1, n)
        fact.wall_idx = idx
        local path = catalog.wall_files[idx]
        text.wall_title = wall_basename(path)
        text.wall_preview_path = path
    end

    local function remember_selection()
        local path = catalog.wall_files[math.floor(tonumber(fact.wall_idx) or 0)]
        if type(path) == "string" and path ~= "" then
            saved_selected = path
            settings.put("wallpaper", "selected", path, true)
        end
    end

    local function reset_selection()
        saved_selected = nil
        fact.wall_idx = 1
        settings.put("wallpaper", "selected", "", false)
    end

    local function load_wall_list()
        pcall(function()
            run("ls", { "-1A", catalog.wall_dir }, function(out, code)
                if code ~= 0 or type(out) ~= "string" then
                    return
                end
                local files = {}
                for line in out:gmatch("[^\r\n]+") do
                    if line:sub(-1) ~= "/" and is_image(line) then
                        files[#files + 1] = catalog.wall_dir .. "/" .. line
                    end
                end
                if type(saved_selected) == "string" and saved_selected:sub(1, 1) == "/" and is_image(wall_basename(saved_selected)) then
                    local found = false
                    for _, path in ipairs(files) do
                        if path == saved_selected then
                            found = true
                            break
                        end
                    end
                    if not found then
                        files[#files + 1] = saved_selected
                    end
                end
                table.sort(files)
                catalog.wall_files = files
                fact.wall_count = #files
                if type(saved_selected) == "string" then
                    for i, path in ipairs(files) do
                        if path == saved_selected then
                            fact.wall_idx = i
                            break
                        end
                    end
                end
                sync_wall_title()
            end)
        end)
    end

    catalog.wall_basename = wall_basename
    catalog.is_image = is_image
    catalog.sync_wall_title = sync_wall_title
    catalog.remember_selection = remember_selection
    catalog.reset_selection = reset_selection
    catalog.load_wall_list = load_wall_list

    load_wall_list()

    return catalog
end
