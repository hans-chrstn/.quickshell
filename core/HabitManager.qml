pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Singleton {
    id: root

    readonly property string persistencePath: {
        return Quickshell.cachePath("tasks.json")
    }

    readonly property ListModel habitStore: ListModel {
    }

    readonly property ListModel dailyStore: ListModel {
    }

    readonly property ListModel todoStore: ListModel {
    }

    readonly property ListModel tagStore: ListModel {
    }

    function addHabit(data) {
        let tagData = data.tags || []
        
        root.habitStore.append({
            "title": String(data.title || "New Habit"),
            "notes": String(data.notes || ""),
            "isPositive": !!data.isPositive,
            "isNegative": !!data.isNegative,
            "difficulty": String(data.difficulty || "easy"),
            "resetCounter": String(data.resetCounter || "daily"),
            "counter": 0,
            "streak": 0,
            "lastUpdate": new Date().getTime(),
            "timestamp": new Date().getTime(),
            "tags": []
        })
        
        let habit = root.habitStore.get(root.habitStore.count - 1)
        for (let t of tagData) {
            habit.tags.append({ 
                "name": String(t.name || t) 
            })
        }
        
        root.saveData()
    }

    function removeHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            root.habitStore.remove(index)
            root.saveData()
        }
    }

    function incrementHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            let item = root.habitStore.get(index)
            if (item) {
                root.habitStore.setProperty(
                    index, 
                    "counter", 
                    (item.counter || 0) + 1
                )
                root.habitStore.setProperty(
                    index, 
                    "lastUpdate", 
                    new Date().getTime()
                )
                root.saveData()
            }
        }
    }

    function decrementHabit(index) {
        if (index >= 0 && index < root.habitStore.count) {
            let item = root.habitStore.get(index)
            if (item) {
                let newCounter = (item.counter || 0) - 1
                if (newCounter < 0) {
                    root.removeHabit(index)
                } else {
                    root.habitStore.setProperty(
                        index, 
                        "counter", 
                        newCounter
                    )
                    root.habitStore.setProperty(
                        index, 
                        "lastUpdate", 
                        new Date().getTime()
                    )
                    root.saveData()
                }
            }
        }
    }

    function addDaily(data) {
        let tagData = data.tags || []
        let checklistItems = data.checklist || []
        
        root.dailyStore.append({
            "title": String(data.title || "New Daily"),
            "notes": String(data.notes || ""),
            "startDate": String(data.startDate || ""),
            "repeats": String(data.repeats || "daily"),
            "repeatEvery": parseInt(data.repeatEvery) || 1,
            "difficulty": String(data.difficulty || "easy"),
            "completed": false,
            "streak": 0,
            "lastUpdate": new Date().getTime(),
            "timestamp": new Date().getTime(),
            "tags": [],
            "checklist": []
        })
        
        let daily = root.dailyStore.get(root.dailyStore.count - 1)
        for (let t of tagData) {
            daily.tags.append({ 
                "name": String(t.name || t) 
            })
        }
        
        for (let item of checklistItems) {
            daily.checklist.append({
                "title": String(item.title || ""),
                "completed": !!item.completed
            })
        }
        
        root.saveData()
    }

    function removeDaily(index) {
        if (index >= 0 && index < root.dailyStore.count) {
            root.dailyStore.remove(index)
            root.saveData()
        }
    }

    function toggleDaily(index) {
        if (index >= 0 && index < root.dailyStore.count) {
            let item = root.dailyStore.get(index)
            if (item) {
                let newState = !item.completed
                root.dailyStore.setProperty(
                    index, 
                    "completed", 
                    newState
                )
                
                if (item.checklist) {
                    for (let i = 0; i < item.checklist.count; i++) {
                        item.checklist.setProperty(
                            i, 
                            "completed", 
                            newState
                        )
                    }
                }
                
                root.dailyStore.setProperty(
                    index, 
                    "lastUpdate", 
                    new Date().getTime()
                )
                
                root.saveData()
            }
        }
    }

    function toggleDailyChecklistItem(dailyIndex, itemIndex) {
        if (dailyIndex >= 0 && dailyIndex < root.dailyStore.count) {
            let daily = root.dailyStore.get(dailyIndex)
            if (daily && daily.checklist && itemIndex >= 0 && itemIndex < daily.checklist.count) {
                let item = daily.checklist.get(itemIndex)
                daily.checklist.setProperty(
                    itemIndex, 
                    "completed", 
                    !item.completed
                )
                
                let allChecked = true
                for (let i = 0; i < daily.checklist.count; i++) {
                    if (!daily.checklist.get(i).completed) {
                        allChecked = false
                        break
                    }
                }
                
                root.dailyStore.setProperty(
                    dailyIndex, 
                    "completed", 
                    allChecked
                )
                
                root.dailyStore.setProperty(
                    dailyIndex, 
                    "lastUpdate", 
                    new Date().getTime()
                )
                
                root.saveData()
            }
        }
    }

    function addTodo(data) {
        let tagData = data.tags || []
        let checklistItems = data.checklist || []
        
        root.todoStore.append({
            "title": String(data.title || "New To-Do"),
            "notes": String(data.notes || ""),
            "difficulty": String(data.difficulty || "easy"),
            "dueDate": String(data.dueDate || ""),
            "completed": false,
            "timestamp": new Date().getTime(),
            "tags": [],
            "checklist": []
        })
        
        let todo = root.todoStore.get(root.todoStore.count - 1)
        for (let t of tagData) {
            todo.tags.append({ 
                "name": String(t.name || t) 
            })
        }
        
        for (let item of checklistItems) {
            todo.checklist.append({
                "title": String(item.title || ""),
                "completed": !!item.completed
            })
        }
        
        root.saveData()
    }

    function removeTodo(index) {
        if (index >= 0 && index < root.todoStore.count) {
            root.todoStore.remove(index)
            root.saveData()
        }
    }

    function toggleTodo(index) {
        if (index >= 0 && index < root.todoStore.count) {
            let item = root.todoStore.get(index)
            if (item) {
                let newState = !item.completed
                root.todoStore.setProperty(
                    index, 
                    "completed", 
                    newState
                )
                
                if (item.checklist) {
                    for (let i = 0; i < item.checklist.count; i++) {
                        item.checklist.setProperty(
                            i, 
                            "completed", 
                            newState
                        )
                    }
                }
                
                root.saveData()
            }
        }
    }

    function toggleTodoChecklistItem(todoIndex, itemIndex) {
        if (todoIndex >= 0 && todoIndex < root.todoStore.count) {
            let todo = root.todoStore.get(todoIndex)
            if (todo && todo.checklist && itemIndex >= 0 && itemIndex < todo.checklist.count) {
                let item = todo.checklist.get(itemIndex)
                todo.checklist.setProperty(
                    itemIndex, 
                    "completed", 
                    !item.completed
                )
                
                let allChecked = true
                for (let i = 0; i < todo.checklist.count; i++) {
                    if (!todo.checklist.get(i).completed) {
                        allChecked = false
                        break
                    }
                }
                
                root.todoStore.setProperty(
                    todoIndex, 
                    "completed", 
                    allChecked
                )
                
                root.saveData()
            }
        }
    }

    function addTag(name) {
        let cleanName = String(name || "").trim()
        if (cleanName === "") {
            return
        }
        
        let exists = false
        for (let i = 0; i < root.tagStore.count; i++) {
            if (root.tagStore.get(i).name === cleanName) {
                exists = true
                break
            }
        }
        
        if (!exists) {
            root.tagStore.append({ 
                "name": cleanName 
            })
            root.saveData()
        }
    }

    function removeTag(index) {
        if (index >= 0 && index < root.tagStore.count) {
            root.tagStore.remove(index)
            root.saveData()
        }
    }

    function processTemporalResets() {
        let now = new Date()
        let nowMs = now.getTime()
        let changed = false

        for (let i = 0; i < root.habitStore.count; i++) {
            let h = root.habitStore.get(i)
            if (root.shouldReset(h.lastUpdate, h.resetCounter, now)) {
                if (h.counter > 0) {
                    root.habitStore.setProperty(i, "streak", (h.streak || 0) + 1)
                } else {
                    root.habitStore.setProperty(i, "streak", 0)
                }
                root.habitStore.setProperty(i, "counter", 0)
                root.habitStore.setProperty(i, "lastUpdate", nowMs)
                changed = true
            }
        }

        for (let i = 0; i < root.dailyStore.count; i++) {
            let d = root.dailyStore.get(i)
            if (root.shouldReset(d.lastUpdate, d.repeats, now)) {
                if (d.completed) {
                    root.dailyStore.setProperty(i, "streak", (d.streak || 0) + 1)
                } else {
                    root.dailyStore.setProperty(i, "streak", 0)
                }
                root.dailyStore.setProperty(i, "completed", false)
                if (d.checklist) {
                    for (let j = 0; j < d.checklist.count; j++) {
                        d.checklist.setProperty(j, "completed", false)
                    }
                }
                root.dailyStore.setProperty(i, "lastUpdate", nowMs)
                changed = true
            }
        }

        if (changed) {
            root.saveData()
        }
    }

    function shouldReset(lastUpdateMs, interval, now) {
        let last = new Date(lastUpdateMs)
        
        if (interval === "daily") {
            return now.getDate() !== last.getDate() || 
                   now.getMonth() !== last.getMonth() || 
                   now.getFullYear() !== last.getFullYear()
        }
        
        if (interval === "weekly") {
            let diff = now.getTime() - last.getTime()
            let dayDiff = diff / (1000 * 60 * 60 * 24)
            if (dayDiff >= 7) return true
            let lastDay = last.getDay() || 7
            let nowDay = now.getDay() || 7
            return nowDay < lastDay
        }
        
        if (interval === "monthly") {
            return now.getMonth() !== last.getMonth() || 
                   now.getFullYear() !== last.getFullYear()
        }
        
        if (interval === "yearly") {
            return now.getFullYear() !== last.getFullYear()
        }
        
        return false
    }

    Timer {
        id: resetCheckTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.processTemporalResets()
        }
    }

    function modelToData(model) {
        let arr = []
        if (!model) return arr
        
        for (let i = 0; i < model.count; i++) {
            let item = model.get(i)
            let obj = {}
            
            for (let prop in item) {
                if (prop === "objectName" || prop === "parent" || typeof item[prop] === "function") {
                    continue
                }
                
                let val = item[prop]
                if (val && typeof val === "object" && val.count !== undefined) {
                    obj[prop] = root.modelToData(val)
                } else {
                    obj[prop] = val
                }
            }
            arr.push(obj)
        }
        return arr
    }

    function saveData() {
        let data = {
            "habits": root.modelToData(root.habitStore),
            "dailies": root.modelToData(root.dailyStore),
            "todos": root.modelToData(root.todoStore),
            "tags": root.modelToData(root.tagStore)
        }
        persistenceFile.setText(
            JSON.stringify(data, null, 4)
        )
    }

    FileView {
        id: persistenceFile
        path: root.persistencePath
        printErrors: false
        
        onLoaded: {
            if (persistenceFile.status !== FileView.Ready) {
                return
            }
            
            try {
                let raw = text()
                if (!raw || raw.trim() === "") {
                    return
                }
                
                let p = JSON.parse(raw)
                
                if (p.habits) {
                    root.habitStore.clear()
                    for (let hData of p.habits) {
                        let tags = hData.tags || []
                        hData.tags = [] 
                        root.habitStore.append(hData)
                        let h = root.habitStore.get(root.habitStore.count - 1)
                        for (let t of tags) {
                            h.tags.append({ "name": String(t.name || t) })
                        }
                    }
                }

                if (p.dailies) {
                    root.dailyStore.clear()
                    for (let dData of p.dailies) {
                        let tags = dData.tags || []
                        let checklist = dData.checklist || []
                        dData.tags = []
                        dData.checklist = []
                        root.dailyStore.append(dData)
                        let d = root.dailyStore.get(root.dailyStore.count - 1)
                        for (let t of tags) {
                            d.tags.append({ "name": String(t.name || t) })
                        }
                        for (let c of checklist) {
                            d.checklist.append({
                                "title": String(c.title || ""),
                                "completed": !!c.completed
                            })
                        }
                    }
                }

                if (p.todos) {
                    root.todoStore.clear()
                    for (let tData of p.todos) {
                        let tags = tData.tags || []
                        let checklist = tData.checklist || []
                        tData.tags = []
                        tData.checklist = []
                        root.todoStore.append(tData)
                        let t = root.todoStore.get(root.todoStore.count - 1)
                        for (let tg of tags) {
                            t.tags.append({ "name": String(tg.name || tg) })
                        }
                        for (let c of checklist) {
                            t.checklist.append({
                                "title": String(c.title || ""),
                                "completed": !!c.completed
                            })
                        }
                    }
                }
                
                if (p.tags) {
                    root.tagStore.clear()
                    for (let tg of p.tags) {
                        root.tagStore.append(tg)
                    }
                }
                
                root.processTemporalResets()
            } catch (e) {
                console.error("HabitManager: Load Failed", e)
            }
        }
    }
}
