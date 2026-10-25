.pragma library

var schemaVersion = 1
var maximumScreens = 32

function screenName(value) {
    return String(value || "").trim().slice(0, 128)
}

function normalize(value) {
    const source = value || ({})
    const screens = ({})
    let count = 0
    for (const rawName in source.screens || ({})) {
        if (count >= maximumScreens)
            break
        const name = screenName(rawName)
        if (name.length === 0 || source.screens[rawName] !== true
                || screens[name] === true)
            continue
        screens[name] = true
        count += 1
    }
    return {
        schemaVersion: schemaVersion,
        global: source.global === true,
        screens: screens
    }
}

function suppressGlobal(value) {
    return { schemaVersion: schemaVersion, global: true, screens: ({}) }
}

function suppressScreen(value, nameValue) {
    const current = normalize(value)
    const name = screenName(nameValue)
    if (name.length === 0 || current.global)
        return current
    if (current.screens[name] !== true
            && Object.keys(current.screens).length >= maximumScreens)
        return current
    const screens = Object.assign({}, current.screens)
    screens[name] = true
    return { schemaVersion: schemaVersion, global: false, screens: screens }
}

function resumeAll(value) {
    return { schemaVersion: schemaVersion, global: false, screens: ({}) }
}

function resumeScreen(value, nameValue) {
    const current = normalize(value)
    const name = screenName(nameValue)
    if (name.length === 0 || current.global)
        return current
    const screens = ({})
    for (const key in current.screens) {
        if (key !== name)
            screens[key] = true
    }
    return { schemaVersion: schemaVersion, global: false, screens: screens }
}

function suppressed(value, nameValue) {
    const current = normalize(value)
    return current.global || current.screens[screenName(nameValue)] === true
}
