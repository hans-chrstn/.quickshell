local store = require("logic/control/store")()

local search = require("logic/island/search")()

require("logic/island/notifications")(search)
require("logic/island/media")()
require("logic/island/weather")()
require("logic/island/clock")()
require("logic/control/wallpaper")(store)
require("logic/control/picker")(store)
require("logic/control/audio")()
