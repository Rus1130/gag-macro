#Requires AutoHotkey v2.0
#Include ./lib/OCR.ahk

settingsFile := "settings.ini"
logFile := "log.txt"

; Read and parse JSON
if !FileExist(settingsFile) {
    MsgBox("settings.ini file not found.")
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

window := Gui("+Resize", "Grow a Garden Macro")
window.SetFont("s10")

ReadEntireIni(filePath) {
    result := Map()
    sections := StrSplit(IniRead(filePath), "`n")

    for i, section in sections {
        iniSection := StrSplit(IniRead(filePath, section), "`n")

        result[section] := Map()

        for j, line in iniSection {
            if (line != "") {
                key := StrSplit(line, "=")[1]
                value := StrSplit(line, "=")[2]

                if(section = "Settings"){
                    if(RegExMatch(value, "^-?\d+$")){
                        value := value + 0
                    }
                }

                result[section][key] := value
            }
        }
    }

    return result
}

SetSetting(section, key, value) {
    global settingsFile
    IniWrite(value, settingsFile, section, key)
}
CONFIG := ReadEntireIni(settingsFile)

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

JoinMap(m, delim := "`n") {
    str := ""
    for key, val in m {
        if IsObject(val) ; Check if val is a Map (or Object with keys)
            serializedVal := "{" . JoinMap(val, ", ") . "}"
        else
            serializedVal := val
        str .= key "=" serializedVal delim
    }
    return RTrim(str, delim)  ; remove trailing delimiter
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
seedCheckboxes := AddItemsToColumn(window, "Seeds", seedList, x1 + 10, y1 + 20)
gearCheckboxes := AddItemsToColumn(window, "Gears", gearList, x2 + 10, y1 + 20)
eggCheckboxes := AddItemsToColumn(window, "Eggs", eggList, x3 + 10, y1 + 20)

AddItemsToColumn(gui, label, items, x, startY) {
    global CONFIG
    y := startY
    i := 0
    
    labelVar := window.addText(" x" x " y" y " h40 w200", label)
    labelVar.SetFont("s16 Bold")
    y += 30

    checkboxes := []

    for key, value in items {
        chk := window.Add("Checkbox", "x" x " y" y " w200", value)

        value := CONFIG[label][value]
        chk.Value := value = "true"

        i++
        y += 25

        checkboxes.Push(chk)
    }

    return checkboxes
}

Log(text, newline := 0) {
    global logFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    if(newline) {
        FileAppend("`n", logFile)
    }
    FileAppend("`n[" timestamp "] "  text, logFile)
}

DebugLog(text, newLine := 0){
    global logFile
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    if(newLine) {
        FileAppend("`n", "debug_log.txt")
    }

    if Type(text) == "Integer" {
        text := "(Integer) " text
    } else if Type(text) == "Float" {
        text := "(Float) " text
    } else if Type(text) == "String" {
        text := "(String) " text
    } else if Type(text) == "Object" {
        text := "(Map) " JoinMap(text)
    } else if Type(text) == "Array" {
        text := "[" JoinArr(text) "]"
    }
    FileAppend("`n[" timestamp "] "  text, "debug_log.txt")
}

HoldKey(key, sec) {
    Send("{" key " down}")
    Sleep(sec * 1000)
    Send("{" key " up}")
}

Press(key, num := 1, delay := 50) {
    loop num {
        if(macro_running == false) {
            break
        }
        Sleep(delay)
        Send("{" key "}")
        if(macro_running == false) {
            break
        }
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
        if(macro_running = false) {
            break
        }
        x += dx
        y += dy
        MouseMove(x, y, 0)  ; instant per step, but appears smooth
        Sleep(delay)
    }
}

PreCheck() {
    ; reset zoom
    HoldKey("I", 10)
    HoldKey("O", 0.5)

    ; reset ui nav
    Press("\", 2)
    LeftClick()
    Sleep(100)
    Press("\")

    ; navigate into the seed shop
    Press("D", 3)
    Sleep(100)
    Press("Enter")
    Sleep(100)
    Press("E")
    Sleep(2500)
    Press("S")

    ; first 2 presses: go to top of box
    ; second 2 presses: return to settings gear
    Press("\", 4)

    ; go back into the shop
    Press("D", 3)
    Sleep(100)
    Press("S")
    Sleep(500)
    carrotCheck := FindImage("img/carrot_check.png")
    if(carrotCheck == 1){
        Press("Enter")
    }

    ; exit shop
    Press("W")
    Press("Enter")

    ; go to gear shop
    Press("2")
    LeftClick()
    Sleep(500)
    Press("E")

    ; actually enter the gear shop
    x := (A_ScreenWidth / 2) + (A_ScreenWidth / 4)
    y := A_ScreenHeight / 2
    SmoothMove(x, y - 60, 10, 2)
    Sleep(2000)
    LeftClick()
    Sleep(2000)

    ; reset ui nav
    Press("\", 2)
    LeftClick()
    Press("\")

    ; go back into the shop
    Sleep(100)
    Press("D", 3)
    Sleep(100)
    Press("S")
    Sleep(100)

    ; reset dropdown
    Press("Enter", 2)
    Sleep(500)
    wateringCanCheck := FindImage("img/watering_can_check.png")
    if(wateringCanCheck == 1){
        Press("Enter")
    }

    ; reset gear shop state
    ; makes sure that everything is collapsed, the last item was the top, etc
    Press("W")
    Press("Enter")

    ; return to plot
    Press("\", 2)
    Press("D", 4)
    Press("Enter")
    Press("A", 4)
}

StartMacro(*) {
    global macro_running, seedIndexes, gearIndexes, chosenEggs, CONFIG, do_check
    if !macro_running {
        macro_running := true
        Sleep(CONFIG['Settings']["grace"] * 1000)
        WinMinimize("Grow a Garden Macro")
        WinActivate("Roblox")

        for i, chk in seedCheckboxes {
            if(chk.Value == 1) {
                SetSetting("Seeds", chk.Text, chk.Value == 1 ? "true" : "false")
                seedIndexes.Push(i)
            }
        }

        for i, chk in gearCheckboxes {
            if(chk.Value == 1) {
                SetSetting("Gears", chk.Text, chk.Value == 1 ? "true" : "false")
                gearIndexes.Push(i)
            }
        }

        for i, chk in eggCheckboxes {
            if(chk.Value == 1) {
                SetSetting("Eggs", chk.Text, chk.Value == 1 ? "true" : "false")
                chosenEggs.Push(eggList[i])
            }
        }

        ; PreCheck()

        Log("Macro started ================================================================================", 1)
        DebugLog("================================================================================", 1)
        ; MsgBox("Seeds: " JoinArr(seedIndexes, ", ") "`nGears: " JoinArr(gearIndexes, ", ") "`nEggs: " JoinArr(chosenEggs, ", "))
        
        Macro()
        
        ; master macro timer
        ; SetTimer(Master, 10)
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

Hotkey(CONFIG['Settings']['kill_key'], Kill)

Master() {
    global loop_counter, last_fired_egg, last_fired_shop, CONFIG, trigger_egg_macro
    if !macro_running {
        SetTimer(Master, 0)
        return
    }

    ; macro logic here
    current_time := A_TickCount

    if Mod(current_time, CONFIG['Settings']["egg_timer"] * 1000) = 0 && current_time != last_fired_egg { ; default 1800
        last_fired_egg := current_time
        trigger_egg_macro := true
    }

    if Mod(current_time, CONFIG['Settings']["shop_timer"] * 1000) = 0 && current_time != last_fired_shop { ; default 300
        last_fired_shop := current_time
        Macro()
    }
}

FindImage(path, x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight) {
    xResult := 0
    yResult := 0

    imgFound := ImageSearch(&xResult, &yResult, x1, y1, x2, y2, "*TransBlack *30 " path)
    return imgFound
}

FindText(text){

}

; trigger_egg_macro := true
Macro() {
    global CONFIG, trigger_egg_macro, seedIndexes, gearIndexes, chosenEggs, do_check
    Log("Macro loop")

    ; ; go to seed shop
    ; Press("D", 3)
    ; Press("Enter")
    ; Press("E")
    ; Sleep(2000)
    ; Press("S")

    ; ; loop through seedIndexes to buy the right seeds
    ; for i, seedIndex in seedIndexes {
    ;     if(macro_running = false) {
    ;         break
    ;     }
    ;     Press("S", seedIndex - 1)
    ;     Press("Enter")
    ;     Press("S")
    ;     Sleep(1000)

    ;     fileName := "img/no_stock/" . StrReplace(StrLower(seedList[seedIndex]), " ", "_") . ".png"

    ;     notInStock := FindImage(fileName)
    ;     if(notInStock == 1) {
    ;         Log("Seed " seedList[seedIndex] " not in stock.")
    ;     } else {
    ;         Log("Seed " seedList[seedIndex] " in stock. Buying...")
    ;         Press("Enter", 30)
    ;     }
        
    ;     Press("W")
    ;     Press("Enter")
    ;     Press("W", seedIndex - 1)
    ; }

    ; Press("Enter", 2)
    ; Sleep(300)
    ; Press("W")
    ; Sleep(300)
    ; Press("Enter")
    
    ; return to top of seed shop and exit

    ; go to gear shop
    Sleep(500)
    Press("2")
    LeftClick()
    Sleep(500)
    Press("E")

    ; enter gear shop
    x := (A_ScreenWidth / 2) + (A_ScreenWidth / 4)
    y := A_ScreenHeight / 2
    SmoothMove(x, y - 50, 10, 2)
    Sleep(3000)
    LeftClick()
    Sleep(2000)
    Press("\", 2)
    LeftClick()
    Press("\")
    Press("D", 3)
    Press("S")

    ; buy gears
    for i, gearIndex in gearIndexes {
        if(macro_running = false) {
            break
        }
        Press("S", gearIndex - 1)
        Press("Enter")
        Press("S")
        Sleep(1000)

        notInStock := FindImage("img/no_stock.png")
        if(notInStock == 0) {
            Log("Gear " gearList[gearIndex] " not in stock.")
        } else {
            Log("Gear " gearList[gearIndex] " in stock. Buying...")
            Press("Enter", 30)
        }
        
        Press("W")
        Press("Enter")
        Press("W", gearIndex - 1)
    }

    ; return to top of gear shop and exit
    Press("W")
    Press("Enter")


    if trigger_egg_macro {
        ; egg 1
        HoldKey("S", 0.9)
        Press("E")
        Sleep(500)
        egg1Text := OCR.FromDesktop().Text
        buyEgg1 := false
        for i, egg in chosenEggs {
            if (InStr(egg1Text, "Purchase " egg)) {
                buyEgg1 := true
                break
            }
        }
        Press("\")
        Press("D", 3)
        Press("S")

        if(buyEgg1) {
            Press("Enter")
        } else {
            Press("D", 2)
            Press("Enter")
        }
        Press("\")


        ; egg 2
        HoldKey("S", 0.2)
        Press("E")
        Sleep(500)
        egg2Text := OCR.FromDesktop().Text
        buyEgg2 := false
        for i, egg in chosenEggs {
            if (InStr(egg2Text, "Purchase " egg)) {
                buyEgg2 := true
                break
            }
        }
        Press("\")
        Press("D", 3)
        Press("S")

        if(buyEgg2) {
            Press("Enter")
        } else {
            Press("D", 2)
            Press("Enter")
        }
        Press("\")

        ; egg 3
        HoldKey("S", 0.2)
        Press("E")
        Sleep(500)
        egg3Text := OCR.FromDesktop().Text
        buyEgg3 := false
        for i, egg in chosenEggs {
            if (InStr(egg3Text, "Purchase " egg)) {
                buyEgg3 := true
                break
            }
        }
        Press("\")
        Press("D", 3)
        Press("S")
        if(buyEgg3) {
            Press("Enter")
        } else {
            Press("D", 2)
            Press("Enter")
        }


        ; result := OCR.FromDesktop()
        ; MsgBox "All text from desktop: `n" result.Text
        trigger_egg_macro := false
    }

    ; Press("\", 2)
    ; LeftClick()
    ; Press("\")
    ; Press("D", 4)
    ; Press("Enter")
    ; Press("A", 4)
}