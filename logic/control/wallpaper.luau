return function(store)
    on("cc_wall_apply", function()
        local path = store.wall_files[math.floor(tonumber(fact.wall_idx) or 0)]
        if type(path) == "string" and path ~= "" then
            text.wall_applied_path = path
            fact.wall_applied = true
        end
    end)

    on("cc_wall_prev", function()
        local n = #store.wall_files
        if n == 0 then
            return
        end
        fact.wall_idx = if fact.wall_idx > 1 then fact.wall_idx - 1 else n
        store.sync_wall_title()
    end)

    on("cc_wall_next", function()
        local n = #store.wall_files
        if n == 0 then
            return
        end
        fact.wall_idx = if fact.wall_idx < n then fact.wall_idx + 1 else 1
        store.sync_wall_title()
    end)
end
