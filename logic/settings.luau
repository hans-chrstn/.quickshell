return function()
    local FILE = "settings.json"
    local data = { version = 1, wallpaper = {}, audio_apps = {} }
    local pending = 0

    local ok, saved = pcall(sys.ask, "files.read", FILE, "json")
    if ok and type(saved) == "table" then
        for name, section in pairs(saved) do
            if name ~= "version" and type(section) == "table" then
                data[name] = section
            end
        end
    elseif not ok then
        log("settings: unable to read " .. FILE .. ": " .. tostring(saved))
    end

    local function write()
        pending = 0
        local payload = { version = data.version }
        for name, section in pairs(data) do
            if name ~= "version" and (type(section) ~= "table" or next(section) ~= nil) then
                payload[name] = section
            end
        end
        local worked, err = pcall(sys.call, "files.write", FILE, payload)
        if not worked then
            log("settings: unable to save " .. FILE .. ": " .. tostring(err))
        end
    end

    local settings = {}

    function settings.section(name)
        local section = data[name]
        if type(section) ~= "table" then
            section = {}
            data[name] = section
        end
        return section
    end

    function settings.get(name, key)
        return settings.section(name)[key]
    end

    function settings.persist(immediate)
        if pending ~= 0 then
            pcall(cancel, pending)
            pending = 0
        end
        if immediate then
            write()
        else
            pending = after(600, write)
        end
    end

    function settings.put(name, key, value, immediate)
        settings.section(name)[key] = value
        settings.persist(immediate)
    end

    return settings
end
