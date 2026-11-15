return function()
    local function env_override(name, fallback)
        local ok, val = pcall(function()
            return sys.ask("env", name)
        end)
        if ok and type(val) == "string" and val ~= "" then
            return val
        end
        return fallback
    end
    
    local geo_url = env_override("NACTEST_WEATHER_GEO", "https://ipwho.is/")
    local met_base = env_override("NACTEST_WEATHER_MET", "https://api.open-meteo.com/v1/forecast")
    
    local function json_num(body, path)
        local ok, val = pcall(json.decode, body)
        if not ok then
            return nil
        end
        for _, key in ipairs(path) do
            if type(val) ~= "table" then
                return nil
            end
            val = val[key]
        end
        if type(val) ~= "number" then
            return nil
        end
        return val
    end
    
    local function code_to_kind(code)
        if code == nil or code < 0 then
            return 0
        end
        if code <= 1 then
            return 1
        end
        if code == 2 then
            return 2
        end
        if code == 3 then
            return 3
        end
        if code == 45 or code == 48 then
            return 4
        end
        if code >= 51 and code <= 57 then
            return 5
        end
        if (code >= 61 and code <= 67) or code == 80 or code == 81 or code == 82 then
            return 6
        end
        if (code >= 71 and code <= 77) or code == 85 or code == 86 then
            return 7
        end
        if code >= 95 and code <= 99 then
            return 8
        end
        return 0
    end
    
    local weather_retries = 0
    local geo_lat = nil
    local geo_lon = nil
    
    local function refresh_weather()
        local fail = function()
            if weather_retries < 3 then
                weather_retries = weather_retries + 1
                after(15000 * weather_retries, refresh_weather)
            end
        end
        local function fetch_meteo()
            local met = met_base
                .. "?latitude=" .. string.format("%.4f", geo_lat)
                .. "&longitude=" .. string.format("%.4f", geo_lon)
                .. "&current=weather_code"
            run("curl", { "-s", "-f", "--max-time", "8", met }, function(out2, code2)
                if code2 ~= 0 or type(out2) ~= "string" then
                    fail()
                    return
                end
                local wc = json_num(out2, { "current", "weather_code" })
                if wc == nil then
                    fail()
                    return
                end
                weather_retries = 0
                fact.weather = code_to_kind(math.floor(wc))
            end)
        end
        local ok = pcall(function()
            if geo_lat ~= nil then
                fetch_meteo()
                return
            end
            run("curl", { "-s", "-f", "--max-time", "8", geo_url }, function(out, code)
                if code ~= 0 or type(out) ~= "string" then
                    fail()
                    return
                end
                geo_lat = json_num(out, { "latitude" })
                geo_lon = json_num(out, { "longitude" })
                if geo_lat == nil or geo_lon == nil then
                    fail()
                    return
                end
                fetch_meteo()
            end)
        end)
        if not ok then
            fail()
        end
    end
    
    after(2500, refresh_weather)
    every(3600e3, refresh_weather)
end
