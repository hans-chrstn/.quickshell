.pragma library

var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
var maximumEncodedLength = 131072

function decode(value) {
    const text = String(value || "").replace(/\s+/g, "")
    if (text.length === 0)
        return ""
    if (text.length > maximumEncodedLength || text.length % 4 !== 0
            || !/^[A-Za-z0-9+/]*={0,2}$/.test(text))
        return null
    const bytes = []
    for (let index = 0; index < text.length; index += 4) {
        const first = alphabet.indexOf(text[index])
        const second = alphabet.indexOf(text[index + 1])
        const third = text[index + 2] === "="
            ? 0 : alphabet.indexOf(text[index + 2])
        const fourth = text[index + 3] === "="
            ? 0 : alphabet.indexOf(text[index + 3])
        if (first < 0 || second < 0 || third < 0 || fourth < 0)
            return null
        const packed = (first << 18) | (second << 12)
            | (third << 6) | fourth
        bytes.push((packed >> 16) & 255)
        if (text[index + 2] !== "=")
            bytes.push((packed >> 8) & 255)
        if (text[index + 3] !== "=")
            bytes.push(packed & 255)
    }
    let encoded = ""
    for (const byte of bytes)
        encoded += "%" + byte.toString(16).padStart(2, "0")
    try {
        return decodeURIComponent(encoded)
    } catch (exception) {
        return null
    }
}
