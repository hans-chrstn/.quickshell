.pragma library

function text(value) {
    return value === undefined || value === null ? "" : String(value);
}

function indexOf(model, key) {
    for (let index = 0; index < model.count; index++) {
        if (text(model.get(index).key) === key)
            return index;
    }
    return -1;
}

function reconcile(model, records, keyProperty, fallbackPrefix) {
    const source = Array.isArray(records) ? records : [];
    const property = text(keyProperty);
    const prefix = text(fallbackPrefix) || "row:";
    for (let targetIndex = 0; targetIndex < source.length; targetIndex++) {
        const record = source[targetIndex];
        const candidate = property.length > 0 ? record?.[property] : "";
        const key = text(candidate) || prefix + targetIndex;
        let currentIndex = indexOf(model, key);
        if (currentIndex < 0) {
            model.insert(targetIndex, {
                key: key,
                record: record
            });
            currentIndex = targetIndex;
        } else if (currentIndex !== targetIndex) {
            model.move(currentIndex, targetIndex, 1);
            currentIndex = targetIndex;
        }
        model.setProperty(currentIndex, "record", record);
    }
    while (model.count > source.length)
        model.remove(model.count - 1);
}
