return function(wallpaper_catalog, settings)
    on("cc_wall_apply", function()
        local path = wallpaper_catalog.wall_files[math.floor(tonumber(fact.wall_idx) or 0)]
        if type(path) == "string" and path ~= "" then
            text.wall_applied_path = path
            fact.wall_applied = true
            settings.put("wallpaper", "applied", path, true)
            wallpaper_catalog.remember_selection()
        end
    end)

    on("cc_wall_prev", function()
        local n = #wallpaper_catalog.wall_files
        if n == 0 then
            return
        end
        fact.wall_idx = if fact.wall_idx > 1 then fact.wall_idx - 1 else n
        wallpaper_catalog.sync_wall_title()
        wallpaper_catalog.remember_selection()
    end)

    on("cc_wall_next", function()
        local n = #wallpaper_catalog.wall_files
        if n == 0 then
            return
        end
        fact.wall_idx = if fact.wall_idx < n then fact.wall_idx + 1 else 1
        wallpaper_catalog.sync_wall_title()
        wallpaper_catalog.remember_selection()
    end)
end
