fact.phase = 0
fact.playing = false
fact.media_progress = 0
fact.sel = 0

fact.util_phase = 0
fact.util_center_tool = 1
fact.selected_sink = 0
fact.audio_volume = 0
fact.audio_muted = false
fact.mic_volume = 0
fact.mic_muted = false

text.track_title = "Desktop Audio"
text.track_artist = "Nacre Shell"
text.time_elapsed = "0:00"
text.time_remaining = "--:--"
text.island_date = ""
text.query = ""

text.tool_name = "AUDIO STUDIO"
text.tool_sub = ""
text.active_sink_name = ""
text.audio_status_desc = ""
text.volume_percent_text = ""
text.mic_percent_text = ""
text.audio_engine_status = ""

model.hits = {}
model.sinks = {}
model.tools = {}

require("logic/island/search")()
require("logic/island/clock")()
require("logic/island/media")()
require("logic/audio/watcher")()
require("logic/audio/control")()
require("logic/utility/drawer")()

on("key", function(combo, typed)
    if fact.phase == 1 then
        if typed and type(typed) == "string" and #typed > 0 then
            local b = string.byte(typed, 1)
            if b and b >= 32 and b <= 126 then
                fact.phase = 3
                text.query = typed
                pcall(function()
                    focus("query")
                end)
                return
            end
        end
    end
end)
