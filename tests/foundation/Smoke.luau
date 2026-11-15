fact.count = 0
text.label = "Smoke test ready"

on("tick", function()
    fact.count += 1
    text.label = `Clicks: {fact.count}`
end)
