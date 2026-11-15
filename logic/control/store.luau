return function()
    local home_ok, home_value = pcall(sys.ask, "env", "HOME")
    local home_dir = if home_ok and type(home_value) == "string" and home_value ~= "" then home_value else "/"

    local store = {
        home_dir = home_dir,
        wall_dir = if home_dir == "/" then "/" else home_dir .. "/.wallpapers",
        wall_files = {},
    }

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
        local n = #store.wall_files
        if n == 0 then
            text.wall_title = ""
            text.wall_preview_path = ""
            return
        end
        local idx = math.clamp(math.floor(tonumber(fact.wall_idx) or 1), 1, n)
        fact.wall_idx = idx
        local path = store.wall_files[idx]
        text.wall_title = wall_basename(path)
        text.wall_preview_path = path
    end

    local function load_wall_list()
        pcall(function()
            run("ls", { "-1A", store.wall_dir }, function(out, code)
                if code ~= 0 or type(out) ~= "string" then
                    return
                end
                local files = {}
                for line in out:gmatch("[^\r\n]+") do
                    if line:sub(-1) ~= "/" and is_image(line) then
                        files[#files + 1] = store.wall_dir .. "/" .. line
                    end
                end
                table.sort(files)
                store.wall_files = files
                fact.wall_count = #files
                sync_wall_title()
            end)
        end)
    end

    store.wall_basename = wall_basename
    store.is_image = is_image
    store.sync_wall_title = sync_wall_title
    store.load_wall_list = load_wall_list

    load_wall_list()

    return store
end
