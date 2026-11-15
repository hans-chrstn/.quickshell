return function(store)
    local picker_current_dir = store.wall_dir
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
            return store.home_dir
        end
        if path:sub(1, 2) == "~/" then
            return store.home_dir .. path:sub(2)
        end
        return path
    end

    local function picker_display_path(path)
        if store.home_dir ~= "" and path == store.home_dir then
            return "~"
        end
        if store.home_dir ~= "" and path:sub(1, #store.home_dir + 1) == store.home_dir .. "/" then
            return "~" .. path:sub(#store.home_dir + 1)
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
        if not store.is_image(store.wall_basename(item.path)) then
            return
        end
        local found = 0
        for i = 1, #store.wall_files do
            if store.wall_files[i] == item.path then
                found = i
            end
        end
        if found == 0 then
            store.wall_files[#store.wall_files + 1] = item.path
            table.sort(store.wall_files)
            for i = 1, #store.wall_files do
                if store.wall_files[i] == item.path then
                    found = i
                end
            end
            fact.wall_count = #store.wall_files
        end
        fact.wall_idx = found
        store.sync_wall_title()
    end)

    on("picker_nav_up", function()
        picker_load_dir(picker_parent_dir(picker_current_dir))
    end)

    on("picker_choose", function()
        store.wall_dir = picker_current_dir
        fact.picker_open = false
        store.load_wall_list()
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
