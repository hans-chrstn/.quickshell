return function(wallpaper_catalog, settings)
    local picker_current_dir = wallpaper_catalog.wall_dir
    local picker_raw_items = {}
    local picker_generation = 0
    local picker_max_items = 6
    local picker_page = 0

    local function picker_publish()
        local items = {}
        local first = picker_page * picker_max_items + 1
        for idx = first, math.min(#picker_raw_items, first + picker_max_items - 1) do
            items[#items + 1] = picker_raw_items[idx]
        end
        model.picker_items = items
        fact.picker_has_prev = picker_page > 0
        fact.picker_has_next = first + picker_max_items - 1 < #picker_raw_items
        text.picker_page_text = if #picker_raw_items == 0 then "0 items" else tostring(first) .. "–" .. tostring(first + #items - 1) .. " of " .. tostring(#picker_raw_items)
    end

    local function picker_normalize_path(path)
        if path == "~" then
            return wallpaper_catalog.home_dir
        end
        if path:sub(1, 2) == "~/" then
            return wallpaper_catalog.home_dir .. path:sub(2)
        end
        return path
    end

    local function picker_display_path(path)
        if wallpaper_catalog.home_dir ~= "" and path == wallpaper_catalog.home_dir then
            return "~"
        end
        if wallpaper_catalog.home_dir ~= "" and path:sub(1, #wallpaper_catalog.home_dir + 1) == wallpaper_catalog.home_dir .. "/" then
            return "~" .. path:sub(#wallpaper_catalog.home_dir + 1)
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
                    elseif wallpaper_catalog.is_image(clean_name) then
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
                picker_page = 0
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
        if not wallpaper_catalog.is_image(wallpaper_catalog.wall_basename(item.path)) then
            text.picker_status = "Choose an image file"
            return
        end
        fact.picker_open = false
        local found = 0
        for i = 1, #wallpaper_catalog.wall_files do
            if wallpaper_catalog.wall_files[i] == item.path then
                found = i
            end
        end
        if found == 0 then
            wallpaper_catalog.wall_files[#wallpaper_catalog.wall_files + 1] = item.path
            table.sort(wallpaper_catalog.wall_files)
            for i = 1, #wallpaper_catalog.wall_files do
                if wallpaper_catalog.wall_files[i] == item.path then
                    found = i
                end
            end
            fact.wall_count = #wallpaper_catalog.wall_files
        end
        fact.wall_idx = found
        wallpaper_catalog.sync_wall_title()
        wallpaper_catalog.remember_selection()
    end)

    on("picker_nav_up", function()
        picker_load_dir(picker_parent_dir(picker_current_dir))
    end)

    on("picker_prev_page", function()
        picker_page = math.max(0, picker_page - 1)
        picker_publish()
    end)
    on("picker_next_page", function()
        picker_page = math.min(math.max(0, math.ceil(#picker_raw_items / picker_max_items) - 1), picker_page + 1)
        picker_publish()
    end)

    on("picker_choose", function()
        wallpaper_catalog.wall_dir = picker_current_dir
        wallpaper_catalog.reset_selection()
        settings.put("wallpaper", "directory", picker_current_dir, true)
        fact.picker_open = false
        wallpaper_catalog.load_wall_list()
    end)

    on("picker_cancel", function()
        picker_generation += 1
        fact.picker_open = false
    end)

    on("cc_browse", function()
        fact.picker_open = true
        picker_load_dir(picker_current_dir)
    end)
end
