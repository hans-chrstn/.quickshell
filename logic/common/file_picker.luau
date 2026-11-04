return function(cfg)
    local on_choose = cfg and cfg.on_choose
    local on_cancel = cfg and cfg.on_cancel
    local on_select_file = cfg and cfg.on_select_file
    local home_dir = cfg and cfg.home_dir or ""
    local current_dir = cfg and cfg.initial_dir or home_dir
    local raw_items = {}
    local request_generation = 0
    local page = 0
    local page_size = 6

    local function publish_page(requested_page: number)
        local page_count = math.max(math.ceil(#raw_items / page_size), 1)
        page = math.clamp(math.floor(requested_page), 0, page_count - 1)
        local first = page * page_size + 1
        local visible = {}
        for idx = first, math.min(first + page_size - 1, #raw_items) do
            visible[#visible + 1] = raw_items[idx]
        end
        model.picker_items = visible
        text.picker_page_text = string.format("%d / %d", page + 1, page_count)
    end

    local function normalize_path(path: string): string
        if path == "~" then
            return home_dir
        end
        if path:sub(1, 2) == "~/" then
            return home_dir .. path:sub(2)
        end
        return path
    end

    local function display_path(path: string): string
        if home_dir ~= "" and path == home_dir then
            return "~"
        end
        if home_dir ~= "" and path:sub(1, #home_dir + 1) == home_dir .. "/" then
            return "~" .. path:sub(#home_dir + 1)
        end
        return path
    end

    local function parent_dir(path: string): string
        local cleaned = path:gsub("/+$", "")
        local parent = cleaned:match("^(.*)/[^/]+$")
        if not parent or parent == "" then
            return "/"
        end
        return parent
    end

    local function load_dir(dir_path: string)
        local target = normalize_path(dir_path)
        request_generation += 1
        local generation = request_generation
        text.picker_status = "Loading"

        local ok, err = pcall(function()
            run("ls", { "-1pA", target }, function(out, code)
                if generation ~= request_generation then
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

                current_dir = target
                raw_items = combined
                text.picker_dir_text = display_path(target)
                text.picker_status = if #combined == 0 then "This folder is empty" else ""
                publish_page(0)
            end)
        end)
        if not ok then
            text.picker_status = "Folder browsing is unavailable"
            log("file picker: " .. tostring(err))
        end
    end

    on("picker_select_item", function(id_val)
        local idx = (tonumber(id_val) or -1) + 1
        local item = raw_items[idx]
        if not item then
            text.picker_status = "That item is no longer available"
            return
        end
        if item.is_dir then
            load_dir(item.path)
        elseif on_select_file then
            on_select_file(item.path)
        end
    end)

    on("picker_nav_up", function()
        load_dir(parent_dir(current_dir))
    end)

    on("picker_prev_page", function()
        publish_page(page - 1)
    end)

    on("picker_next_page", function()
        publish_page(page + 1)
    end)

    on("picker_choose", function()
        if on_choose then
            on_choose(current_dir)
        end
        fact.picker_open = false
    end)

    on("picker_cancel", function()
        request_generation += 1
        if on_cancel then
            on_cancel()
        end
        fact.picker_open = false
    end)

    load_dir(current_dir)

    return {
        load_dir = load_dir,
        get_dir = function() return current_dir end,
    }
end
