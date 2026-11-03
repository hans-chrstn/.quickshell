local wall_files = {}

local function extract_basename(path: string): string
    local name = path:match("([^/]+)$")
    return name or path
end

local function apply_wallpaper(idx: number)
    if #wall_files == 0 then
        return
    end
    local clamped_idx = ((idx - 1) % #wall_files) + 1
    fact.current_idx = clamped_idx
    local target_path = wall_files[clamped_idx]
    if not target_path then
        return
    end

    if fact.active_slot == 0 then
        text.wall_b = target_path
        fact.active_slot = 1
    else
        text.wall_a = target_path
        fact.active_slot = 0
    end

    text.current_title = extract_basename(target_path)
end

pcall(function()
    run("ls", { "-1", "/home/jin/.wallpapers" }, function(out, code)
        if code ~= 0 or not out then
            return
        end
        local list = {}
        for line in out:gmatch("[^\r\n]+") do
            local ext = line:match("%.(%w+)$")
            if ext then
                ext = ext:lower()
                if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
                    list[#list + 1] = "/home/jin/.wallpapers/" .. line
                end
            end
        end
        table.sort(list)
        wall_files = list
        fact.wall_count = #list
        if #list > 0 then
            apply_wallpaper(1)
        end
    end)
end)

on("next_wallpaper", function()
    apply_wallpaper(fact.current_idx + 1)
end)

on("prev_wallpaper", function()
    apply_wallpaper(fact.current_idx - 1)
end)

on("toggle_mode", function()
    if fact.wall_mode == 0 then
        fact.wall_mode = 1
        text.mode_label = "ANIMATED HYGGE WGSL"
    else
        fact.wall_mode = 0
        text.mode_label = "STATIC CROSSFADE"
    end
end)

on("desk_click", function()
    apply_wallpaper(fact.current_idx + 1)
end)
