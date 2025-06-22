#Requires AutoHotkey v2.0
#Include ./lib/JSON.ahk
#Include ./lib/OCR.ahk

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
do_check := false

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

JoinArr(arr, delim := ",") {
    result := ""
    for i, item in arr {
        if (i > 1) {
            result .= delim
        }
        result .= item
    }
    return result
}

findDifferences(arr) {
    diffs := []
    for i, val in arr {
        if i = 1
            diffs.Push(val)  ; Keep the first value
        else
            diffs.Push(val - arr[i - 1])
    }
    return diffs
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

Log(text, newline := 0) {
    global logFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    if(newline) {
        FileAppend("`n", logFile)
    }
    FileAppend("`n[" timestamp "] "  text, logFile)
}

HoldKey(key, sec) {
    Send("{" key " down}")
    Sleep(sec * 1000)
    Send("{" key " up}")
}

Press(key, num := 1, delay := 50) {
    loop num {
        Sleep(delay)
        Send("{" key "}")
    }
}

LeftClick(){
    Click("left")
}

SmoothMove(toX, toY, steps := 50, delay := 5) {
    MouseGetPos(&x, &y)
    dx := (toX - x) / steps
    dy := (toY - y) / steps

    Loop steps {
        x += dx
        y += dy
        MouseMove(x, y, 0)  ; instant per step, but appears smooth
        Sleep(delay)
    }
}

StartMacro(*) {
    global macro_running, seedIndexes, gearIndexes, chosenEggs, CONFIG, do_check
    if !macro_running {
        macro_running := true
        Sleep(CONFIG["grace"] * 1000)
        WinMinimize("Grow a Garden Macro")
        WinActivate("Roblox")
        HoldKey("I", 10)
        HoldKey("O", 0.5)
        Press("\", 2)
        LeftClick()
        Sleep(100)
        Press("\")

        ; pre check to make sure that the shops are in the correct states
        ; resetShopState()
        ; Press("W")
        ; Press("Enter")

        ; Press("2")
        ; LeftClick()
        ; Sleep(500)
        Press("E")

        ; add 1/4th of the screen width to the x position
        x := (A_ScreenWidth / 2) + (A_ScreenWidth / 4)
        y := A_ScreenHeight / 2

        SmoothMove(x, y - 30)

        Sleep(1000)
        LeftClick()

        ; move it half of the screen to the right, delta

        Log("Macro started ================================================================================", 1)
        ; MsgBox("Seeds: " JoinArr(seedIndexes, ", ") "`nGears: " JoinArr(gearIndexes, ", ") "`nEggs: " JoinArr(chosenEggs, ", "))
        
        ; Macro()
        
        ; master macro timer
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
        WinActivate("Grow a Garden Macro")
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

    if Mod(current_time, CONFIG["egg_timer"] * 1000) = 0 && current_time != last_fired_egg { ; default 1800
        last_fired_egg := current_time
        trigger_egg_macro := true
    }

    if Mod(current_time, CONFIG["shop_timer"] * 1000) = 0 && current_time != last_fired_shop { ; default 300
        last_fired_shop := current_time
        Macro()
    }
}

FindImage(path, x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight) {
    xResult := 0
    yResult := 0

    imgFound := ImageSearch(&xResult, &yResult, x1, y1, x2, y2, "*10 " path)

    return imgFound
}

FindText(text){

}

; resets shop state
; makes sure that everything is collapsed, the last item was the top, etc
resetShopState() {
    Press("D", 3)
    Sleep(100)
    Press("Enter")
    Sleep(100)
    Press("E")
    Sleep(2500)
    Press("S", 7)
    Sleep(100)
    Press("\", 4)
    Press("D", 3)
    Sleep(100)
    Press("S")
    Press("Enter", 2)
    Press("S", 7)
    Press("Enter", 2)
    Press("\", 2, 300)
}

Macro() {
    global CONFIG, trigger_egg_macro, seedIndexes, gearIndexes, chosenEggs, do_check
    Log("Macro loop")

    ; MsgBox(JoinArr(findDifferences(seedIndexes)))

    ; macro logic here


    if trigger_egg_macro {
        ; egg macro logic here

        ; result := OCR.FromDesktop()
        ; MsgBox "All text from desktop: `n" result.Text
        trigger_egg_macro := false
    }
}