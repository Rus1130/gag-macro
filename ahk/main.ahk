#Requires AutoHotkey v2.0
#Include ./lib/JSON.ahk

jsonFile := "config.json"
logFile := "log.txt"

; Read and parse JSON
if !FileExist(jsonFile) {
    MsgBox("config.json file not found.")
    ExitApp
}

if !FileExist(logFile) {
    FileAppend("", logFile)
}

macro_running := false
last_fired_egg := 0
last_fired_shop := 0
loop_counter := 0
trigger_egg_macro := false

jsonText := FileRead(jsonFile)
CONFIG := Jxon_Load(&jsonText)

window := Gui("+Resize", "Grow a Garden Macro")
window.SetFont("s10")

; Positions and sizes for 3 columns
x1 := 10, y1 := 0, w := 250
x2 := x1 + w + 20
x3 := x2 + w + 20

seedList := ["Carrot", "Strawberry", "Blueberry", "Tomato", "Cauliflower", "Watermelon", "Green Apple", "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Sugar Apple"]

gearList := ["Watering Can", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Tanning Mirror", "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot"]

eggList := ["Common Egg", "Common Summer Egg", "Rare Summer Egg", "Mythical Egg", "Paradise Egg", "Bug Egg"]

seedIndexes := []
gearIndexes := []
chosenEggs := []

JoinArr(arr, delim) {
    result := ""
    for i, item in arr {
        if (i > 1) {
            result .= delim
        }
        result .= item
    }
    return result
}

; Create GroupBoxes
; Now populate each column — example for eggs:
AddItemsToColumn(window, "Seeds", seedList, x1 + 10, y1 + 20)
AddItemsToColumn(window, "Gears", gearList, x2 + 10, y1 + 20)
AddItemsToColumn(window, "Eggs", eggList, x3 + 10, y1 + 20)

AddItemsToColumn(gui, label, items, x, startY) {
    y := startY
    i := 0
    
    labelVar := window.addText(" x" x " y" y " h40 w200", label)
    labelVar.SetFont("s16 Bold")
    y += 30
    for key, value in items {
        chk := window.Add("Checkbox", "x" x " y" y " w200", value)

        chk.Value := CONFIG[StrLower(label)][value]

        if(StrCompare(StrLower(label), "seeds") == 0) {
            if(chk.Value == 1) {
                seedIndexes.Push(i)
            }
        }

        if(StrCompare(StrLower(label), "gears") == 0) {
            if(chk.Value == 1) {
                gearIndexes.Push(i)
            }
        }

        if(StrCompare(StrLower(label), "eggs") == 0) {
            if(chk.Value == 1) {
                chosenEggs.Push(value)
            }
        }

        i++
        y += 25
    }
}

Log(text) {
    global logFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend("`n[" timestamp "] "  text, logFile)
}

HoldKey(key, sec) {
    Send("{" key " down}")
    Sleep(sec * 1000)
    Send("{" key " up}")
}

StartMacro(*) {
    global macro_running, seedIndexes, gearIndexes, chosenEggs, CONFIG
    if !macro_running {
        macro_running := true
        Sleep(CONFIG["grace"] * 1000)
        WinMinimize("Grow a Garden Macro")
        WinActivate("Roblox")
        HoldKey("I", 5)
        HoldKey("O", 0.5)
        Log("Macro started ================================================================================")
        ; MsgBox("Seeds: " JoinArr(seedIndexes, ", ") "`nGears: " JoinArr(gearIndexes, ", ") "`nEggs: " JoinArr(chosenEggs, ", "))
        SetTimer(Master, 10)
    }
}

startButton := window.AddButton("x" x1 " y" 450 " w100", "Start")

startButton.OnEvent("Click", StartMacro)

window.Show("AutoSize Center")

Kill(*) {
    global macro_running
    if macro_running {
        macro_running := false
        SetTimer(Master, 0)
        MsgBox("Macro stopped.")
    }
}

Hotkey(CONFIG['kill_key'], Kill)

Master() {
    global loop_counter, last_fired_egg, last_fired_shop, CONFIG, trigger_egg_macro
    if !macro_running {
        SetTimer(Master, 0)
        return
    }

    ; macro logic here
    current_time := A_TickCount

    if Mod(current_time, CONFIG["egg_timer"] * 1000) = 0 && current_time != last_fired_egg {
        last_fired_egg := current_time
        trigger_egg_macro := true
    }

    if Mod(current_time, CONFIG["shop_timer"] * 1000) = 0 && current_time != last_fired_shop {
        last_fired_shop := current_time
        Macro()
    }
}

Macro() {
    global CONFIG, trigger_egg_macro

    Log("Macro loop")

    if trigger_egg_macro {
        trigger_egg_macro := false
    }
}