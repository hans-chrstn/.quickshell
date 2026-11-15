local file_picker = require("logic/common/file_picker")

local home_ok, home_value = pcall(sys.ask, "env", "HOME")
local home_dir = if home_ok and type(home_value) == "string" and home_value ~= "" then home_value else "/"
local initial_dir = if home_dir == "/" then "/" else home_dir .. "/.wallpapers"

local function display_path(path: string): string
    if home_dir ~= "/" and path == home_dir then
        return "~"
    end
    if home_dir ~= "/" and path:sub(1, #home_dir + 1) == home_dir .. "/" then
        return "~" .. path:sub(#home_dir + 1)
    end
    return path
end

local picker = file_picker({
    home_dir = home_dir,
    initial_dir = initial_dir,
    on_choose = function(path)
        text.wall_dir_path = display_path(path)
        local ok, err = pcall(function()
            sys.call("files.write", "wallpaper-dir.json", { dir = path })
        end)
        if not ok then
            text.picker_status = "The folder could not be saved"
            log("wallpaper picker test: " .. tostring(err))
        end
    end,
    on_select_file = function(path)
        text.wall_current_title = path:match("([^/]+)$") or path
        fact.picker_open = false
    end,
})

on("open_picker", function()
    fact.picker_open = true
    picker.load_dir(picker.get_dir())
end)

on("prev_wallpaper", function()
    fact.wall_current_idx = if fact.wall_current_idx > 1 then fact.wall_current_idx - 1 else fact.wall_count
end)

on("next_wallpaper", function()
    fact.wall_current_idx = if fact.wall_current_idx < fact.wall_count then fact.wall_current_idx + 1 else 1
end)

on("toggle_wall_mode", function()
    fact.wall_mode = if fact.wall_mode == 0 then 1 else 0
    text.wall_mode_label = if fact.wall_mode == 1 then "HYGGE WGSL" else "STATIC CROSSFADE"
end)
