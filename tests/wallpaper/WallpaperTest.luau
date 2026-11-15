local wall_files = {}

local function basename(path: string): string
    return path:match("([^/]+)$") or path
end

local function apply_wallpaper(idx: number)
    if #wall_files == 0 then
        return
    end
    local wrapped_idx = ((idx - 1) % #wall_files) + 1
    local target = wall_files[wrapped_idx]
    fact.wall_current_idx = wrapped_idx
    if fact.wall_active_slot == 0 then
        text.wall_b = target
        fact.wall_active_slot = 1
    else
        text.wall_a = target
        fact.wall_active_slot = 0
    end
    text.wall_current_title = basename(target)
end

local ok, home = pcall(sys.ask, "env", "HOME")
if ok and type(home) == "string" and home ~= "" then
    local wallpaper_dir = home .. "/.wallpapers"
    text.wall_dir_path = "~/.wallpapers"
    run("ls", { "-1A", wallpaper_dir }, function(out, code)
        if code ~= 0 or type(out) ~= "string" then
            text.wall_current_title = "No wallpaper directory"
            return
        end
        for line in out:gmatch("[^\r\n]+") do
            local ext = line:match("%.(%w+)$")
            if ext then
                ext = ext:lower()
                if ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" then
                    wall_files[#wall_files + 1] = wallpaper_dir .. "/" .. line
                end
            end
        end
        table.sort(wall_files)
        fact.wall_count = #wall_files
        apply_wallpaper(1)
    end)
end

on("next_wallpaper", function()
    apply_wallpaper(fact.wall_current_idx + 1)
end)

on("prev_wallpaper", function()
    apply_wallpaper(fact.wall_current_idx - 1)
end)

on("toggle_wall_mode", function()
    fact.wall_mode = if fact.wall_mode == 0 then 1 else 0
end)
