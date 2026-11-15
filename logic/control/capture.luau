-- Capture actions belong here; the scene owns the controls and their motion.
return function(settings)
    local home = sys.ask("env", "HOME") or "."
    local recorder = nil
    local serial = 0
    fact.capture_cursor = settings.get("capture", "cursor") == true
    fact.capture_jpeg = settings.get("capture", "jpeg") == true
    fact.capture_fps60 = settings.get("capture", "fps60") ~= false
    fact.capture_audio = settings.get("capture", "audio") == true

    on("cc_capture_cursor", function()
        log("capture · cursor toggle")
        fact.capture_cursor = not fact.capture_cursor
        settings.put("capture", "cursor", fact.capture_cursor)
    end)
    on("cc_capture_format", function(value)
        fact.capture_jpeg = tonumber(value) == 1
        settings.put("capture", "jpeg", fact.capture_jpeg)
    end)
    on("cc_capture_fps", function(value)
        fact.capture_fps60 = tonumber(value) == 60
        settings.put("capture", "fps60", fact.capture_fps60)
    end)
    on("cc_capture_audio", function()
        log("capture · audio toggle")
        fact.capture_audio = not fact.capture_audio
        settings.put("capture", "audio", fact.capture_audio)
    end)

    local function output_for(index)
        local number = tonumber(index)
        if number == nil or number < 0 or number >= 8 then return nil end
        local name = text["screen." .. math.floor(number) .. ".name"]
        if type(name) ~= "string" or name == "" then return nil end
        return name
    end

    local function destination(kind, done)
        local folder = kind == "PICTURES" and "Pictures" or "Videos"
        run("xdg-user-dir", { kind }, function(output, code)
            local base = code == 0 and (output or ""):match("^%s*(.-)%s*$") or ""
            if base == "" then base = home .. "/" .. folder end
            local path = base .. "/Nacre"
            run("mkdir", { "-p", path }, function(_, mkdir_code)
                if mkdir_code == 0 then done(path)
                else
                    text.capture_status = "Could not create " .. folder .. " folder"
                    fact.capture_busy = false
                end
            end)
        end)
    end

    local function next_file(folder, extension)
        serial = serial + 1
        return folder .. "/capture-" .. os.date("%Y%m%d-%H%M%S") .. "-" .. serial .. extension
    end

    on("cc_screenshot", function(index)
        if fact.capture_busy then return end
        local output = output_for(index)
        if not output then text.capture_status = "Display unavailable"; return end
        log("capture · screenshot output", output)
        fact.capture_busy = true
        text.capture_status = "Preparing screenshot…"
        -- The scene folds before the compositor is photographed.
        after(1100, function()
            destination("PICTURES", function(folder)
                local jpeg = fact.capture_jpeg
                local args = { "-o", output, "-t", jpeg and "jpeg" or "png" }
                if fact.capture_cursor then args[#args + 1] = "-c" end
                local file = next_file(folder, jpeg and ".jpg" or ".png")
                args[#args + 1] = file
                run("grim", args, function(_, code)
                    fact.capture_busy = false
                    if code ~= 0 then
                        text.capture_status = "Screenshot failed"
                        log("capture · grim failed", code)
                        return
                    end
                    text.capture_status = "Screenshot saved"
                    spawn("satty", { "--filename", file, "--output-filename", file }, function() end,
                        function(_, satty_code)
                            if satty_code ~= 0 then log("capture · satty exited", satty_code) end
                        end)
                end)
            end)
        end)
    end)

    on("cc_capture_record", function(index)
        if recorder then
            fact.capture_busy = true
            text.capture_status = "Finishing recording…"
            kill(recorder, "int") -- MP4 needs its index written before the file is ready.
            return
        end
        if fact.capture_busy then return end
        local output = output_for(index)
        if not output then text.capture_status = "Display unavailable"; return end
        log("capture · recording output", output)
        text.capture_target = output
        fact.capture_busy = true
        text.capture_status = "Preparing recording…"
        after(1100, function()
            destination("VIDEOS", function(folder)
                local file = next_file(folder, ".mp4")
                local this_recorder
                local function start_with_audio(sink)
                    local args = { "-o", output, "-f", file, "-r", fact.capture_fps60 and "60" or "30", "-D" }
                    if sink then args[#args + 1] = "--audio=" .. sink .. ".monitor" end
                    log("capture · recorder args", table.concat(args, " "))
                    this_recorder = spawn("wf-recorder", args, function() end,
                        function(_, code)
                            if recorder == this_recorder then recorder = nil end
                            fact.capture_recording = false
                            fact.capture_busy = false
                            text.capture_target = ""
                            text.capture_status = code == 0 and "Recording saved" or "Recording failed"
                            log("capture · recorder exited", code, file)
                        end)
                    if this_recorder == nil then
                        fact.capture_busy = false
                        text.capture_target = ""
                        text.capture_status = "Recorder could not start"
                        return
                    end
                    recorder = this_recorder
                    after(450, function()
                        if recorder == this_recorder then
                            fact.capture_recording = true
                            fact.capture_busy = false
                            text.capture_status = "Recording screen"
                        end
                    end)
                end
                if fact.capture_audio then
                    run("pactl", { "info" }, function(name, code)
                        local sink = type(name) == "string" and name:match("Default Sink:%s*([^\r\n]+)") or ""
                        if code ~= 0 or sink == "" then
                            fact.capture_busy = false
                            text.capture_target = ""
                            text.capture_status = "Desktop audio unavailable"
                            return
                        end
                        start_with_audio(sink)
                    end)
                else
                    start_with_audio(nil)
                end
            end)
        end)
    end)
end
