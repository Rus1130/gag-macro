#Requires AutoHotkey v2.0
#Include ./lib/OCR.ahk

settingsFile := "settings.ini"

; Read and parse JSON
if !FileExist(settingsFile) {
    MsgBox("settings.ini file not found.")
    ExitApp
}

macro_running := false
last_fired_egg := 0
last_fired_shop := 0
loop_counter := 0
trigger_egg_macro := false
show_timestamp_tooltip := true
mouse_x := 0
mouse_y := 0
first_run := true

window := Gui("+Resize", "Rus' Grow a Garden Macro")
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

GetOCR() {
    global OCR
    return OCR.FromDesktop().Text
}

GetOCRRect(x, y, w, h) {
    global OCR
    return OCR.FromRect(x, y, w, h).Text
}

JoinMap(m, delim := "`n") {
    str := ""
    for key, val in m {
        if IsObject(val) ; Check if val is a Map (or Object with keys)
            serializedVal := "{" . JoinMap(val, ",") . "}"
        else
            serializedVal := val
        str .= key "=" serializedVal delim
    }
    return RTrim(str, delim)  ; remove trailing delimiter
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

DebugLog(text, newLine := 0){
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

Press(key, num := 1, delay := 100) {
    activeWindow := WinGetTitle("A")
    if(CONFIG['Settings']["window_failsafe"] = "true" && activeWindow != "Roblox" && activeWindow != "Rus' Grow a Garden Macro") {
        SetToolTip("")
        MsgBox("Roblox window must be focused as a failsafe.`nMacro has been terminated.`n" ToT())
        ExitApp
        return
    }

    loop num {
        if(macro_running == false) {
            break
        }
        ; get the current focused window
        Sleep(delay)
        Send("{" key "}")
        if(macro_running == false) {
            break
        }
    }
}

SetToolTip(text) {
    global CONFIG
    if(!macro_running) {
        ToolTip("")  ; Clear tooltip if macro is not running
        return
    } else if(CONFIG['Settings']["show_tooltips"] = "true") {
        ToolTip(text)
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

StartMacro(*) {
    global macro_running, seedIndexes, gearIndexes, chosenEggs, CONFIG
    if !macro_running {
        if(CONFIG["Config"]["gear_enter_point_set"] = "false"){
            MsgBox("Gear entrance point not set! Hit the 'Set Config' button.")
            return
        }

        if(CONFIG["Config"]["egg_top_corner_set"] = "false"){
            MsgBox("Egg top corner not set! Hit the 'Set Config' button.")
            return
        }

        if(CONFIG["Config"]["egg_bottom_corner_set"] = "false"){
            MsgBox("Egg bottom corner not set! Hit the 'Set Config' button.")
            return
        }

        SetToolTip("Getting data from settings.ini")
        for i, chk in seedCheckboxes {
            SetSetting("Seeds", chk.Text, chk.Value == 1 ? "true" : "false")
            if(chk.Value == 1) {
                seedIndexes.Push(i)
            }
        }

        for i, chk in gearCheckboxes {
            SetSetting("Gears", chk.Text, chk.Value == 1 ? "true" : "false")
            if(chk.Value == 1) {
                gearIndexes.Push(i)
            }
        }

        for i, chk in eggCheckboxes {
            SetSetting("Eggs", chk.Text, chk.Value == 1 ? "true" : "false")
            if(chk.Value == 1) {
                chosenEggs.Push(eggList[i])
            }
        }

        macro_running := true
        SetToolTip("Starting macro...")
        Sleep(CONFIG['Settings']["grace"] * 1000)
        SetToolTip("")
        WinMinimize("Rus' Grow a Garden Macro")
        WinActivate("Roblox")

        Sleep(200)

        chatCheck := 0
        SetToolTip("Checking if chat is open...")
        Loop 50 {
            if(macro_running = false) {
                break
            }

            chatString := GetOCRRect(0, 0, 500, 500)

            if(InStr(chatString, "[Tip]") || RegExMatch(chatString, "translates( supported lang)?")) {
                chatCheck++
            }
        }
        SetToolTip("")

        if(chatCheck > 25) {
            MsgBox("The chat is open! Please close it before starting the macro.")
            Kill()
            WinActivate("Rus' Grow a Garden Macro")
            return
        }

        tabCheck := 0
        SetToolTip("Checking if player list is open...")
        Loop 50 {
            if(macro_running = false) {
                break
            }

            tabString := GetOCRRect(A_ScreenWidth-500, 0, 500, 500)

            if(InStr(tabString, "People") || InStr(tabString, "Scheckles")) {
                tabCheck++
            }
        }
        ; The server has shut down.
        SetToolTip("")

        if(tabCheck > 25) {
            Press("Tab")
        }

        ; SetToolTip("Looking for Recall Wrench...")
        ; recallCount := 0 
        ; loop 8 {
        ;     if(macro_running = false) {
        ;         break
        ;     }
        ;     str := RegExReplace(GetOCR(), "Looking for Recall Wrench\.{1,3}", "")            
        ;     if(InStr(str, "Recall") = 0) {
        ;         recallCount++
        ;     }
        ; }

        ; if(recallCount > 4){
        ;     SetToolTip("Recall Wrench not found! Equipping now...")
        ;     Press("\", 2)
        ;     LeftClick()
        ;     Press("\")
        ;     Press("``")
        ;     Press("D", 3)
        ;     Press("S", 2)
        ;     Press("Enter")
        ;     Send("^a")
        ;     Press("Backspace")
        ;     Send("Recall")
        ;     Press("Enter")
        ;     Press("S", 3)
        ;     Press("W", 2)
        ;     Press("Enter")
        ;     Press("S")
        ;     Press("D")
        ;     Press("Enter")
        ;     Press("``")
        ; }
        ; SetToolTip("")

        Setup()
    }
}

AlignCamera() {
    ; turn on shift lock + follow camera
    Press("Esc")
    Sleep(100)
    Press("Tab")
    Sleep(100)
    Press("D")
    Sleep(100)
    Press("S")
    Sleep(100)
    Press("D", 2)
    Sleep(100)
    Press("Esc")
    Sleep(1000)

    ; reset camera orbit
    SetToolTip("Reset camera orbit")
    Press("LShift")
    Sleep(500)
    loop 200 {
        if(macro_running = false) {
            break
        }
        DllCall("user32.dll\mouse_event", "UInt", 0x0001, "Int", 0, "Int", 10, "UPtr", 0)
    }
    SetToolTip("")

    ; turn off shift lock
    Sleep(200)
    Press("Esc")
    Sleep(100)
    Press("Tab")
    Sleep(100)
    Press("D")
    Sleep(100)
    Press("Esc")
    Sleep(200)

    ; reset ui nav
    Press("\", 2)
    Sleep(100)
    LeftClick()
    Press("\")

    Press("D", 3)

    ; align camera
    SetToolTip("Aligning camera")
    loop 8 {
        if(macro_running = false) {
            break
        }
        Press("Enter")
        Press("D", 2)
        Press("Enter")
        Press("A", 2)
    }
    SetToolTip("")

    Press("Enter")

    ; turn off follow camera
    Press("Esc")
    Sleep(100)
    Press("Tab")
    Sleep(100)
    Press("S")
    Sleep(100)
    Press("D", 2)
    Sleep(100)
    Press("Esc")

    ; return to plot
    Sleep(200)
    Press("D")
    Sleep(200)
    Press("Enter")
    Sleep(100)
    Press("A", 4)

    ; reset zoom
    Press("\", 2)
    Sleep(100)
    LeftClick()
    SetToolTip("Resetting zoom")
    HoldKey("I", 10)
    HoldKey("O", 0.5)
}

Setup() {
    SetToolTip("Starting setup...")
    Sleep(1000)
    SetToolTip("")

    AlignCamera()

    ; reset ui nav
    SetToolTip("Resetting UI navigation")
    Press("\", 2)
    Sleep(100)
    LeftClick()
    Press("\")

    ; navigate into the seed shop
    SetToolTip("Navigating to seed shop")
    Press("D", 3)
    Sleep(100)
    Press("Enter")
    Sleep(100)
    Press("E")
    Sleep(2500)
    Press("S")

    ; first 2 presses: go to top of box
    ; second 2 presses: return to settings gear
    SetToolTip("Resetting seed shop state")
    Press("\", 4)
    Press("A", 3)

    ; go back into the shop
    SetToolTip("Enter seed shop")
    Press("D", 3)
    Sleep(100)
    Press("S")
    Sleep(500)

    ; reset dropdown
    SetToolTip("Resetting carrot dropdown")
    carrotCheck := FindImage("imgs/carrot_check.png")
    if(carrotCheck == 1){
        Press("Enter")
    }

    ; exit shop
    SetToolTip("Exiting seed shop")
    Press("W")
    Press("Enter")

    ; go to gear shop
    SetToolTip("Navigating to gear shop")
    Press("2")
    LeftClick()
    Sleep(500)
    Press("E")

    ; actually enter the gear shop
    SetToolTip("Entering gear shop")
    x := (A_ScreenWidth / 2) + (A_ScreenWidth / 4)
    y := A_ScreenHeight / 2
    SmoothMove(x, y - 60, 10, 2)
    Sleep(2000)
    LeftClick()
    Sleep(2000)

    ; reset ui nav
    SetToolTip("Resetting gear shop state")
    Press("\", 2)
    LeftClick()
    Press("\")

    ; go back into the shop
    SetToolTip("Re-entering gear shop")
    Sleep(100)
    Press("D", 3)
    Sleep(100)
    Press("S")
    Sleep(100)

    ; reset dropdown
    SetToolTip("Resetting watering can dropdown")
    Press("Enter", 2)
    Sleep(500)
    wateringCanCheck := FindImage("imgs/watering_can_check.png")
    if(wateringCanCheck == 1){
        Press("Enter")
    }

    ; exit gear shop
    SetToolTip("Exit gear shop")
    Press("W")
    Press("Enter")

    ; return to plot
    SetToolTip("Returning to plot")
    Press("\", 2)
    Press("D", 4)
    Press("Enter")
    Press("A", 4)
    SetToolTip("Setup complete")
    Sleep(1000)
    SetToolTip("")

    SetTimer(Master, 10)
}

setConfig(*) {
    global CONFIG, macro_running, mouse_x, mouse_y
    if !macro_running {
        macro_running := true
        SetToolTip("Starting config set...")
        Sleep(CONFIG['Settings']["grace"] * 1000)
        SetToolTip("")
        WinMinimize("Rus' Grow a Garden Macro")
        WinActivate("Roblox")

        AlignCamera()

        Sleep(100)
        Press("2")
        Sleep(100)
        LeftClick()
        Sleep(500)
        Press("E")
        Sleep(2000)

        t1() {
            if(macro_running = false) {
                ToolTip("")
                Kill()
                return
            }
            ToolTip("Left click where the dialogue option to enter the gear shop is located.")
        }
        SetTimer(t1, 16)
        KeyWait("LButton", "D")
        MouseGetPos(&mouse_x, &mouse_y)
        ToolTip("")
        SetTimer(t1, 0)

        SetSetting("Config", "gear_enter_point_set", "true")
        SetSetting("Config", "gear_enter_point_x", mouse_x)
        SetSetting("Config", "gear_enter_point_y", mouse_y)
        CONFIG['Config']["gear_enter_point_set"] := "true"
        CONFIG['Config']["gear_enter_point_x"] := mouse_x
        CONFIG['Config']["gear_enter_point_y"] := mouse_y

        Sleep(2000)
        Press("\")
        Press("D", 5)
        Press("S")
        Press("D")
        Press("Enter")
        Press("\")
        Sleep(100)
        HoldKey("S", 0.9)
        Press("E")
        Sleep(500)

        t2() {
            if(macro_running = false) {
                ToolTip("")
                Kill()
                return
            }
            ToolTip("Left click the top left of the egg shop box.")
        }
        SetTimer(t2, 16)
        KeyWait("LButton", "D")
        MouseGetPos(&mouse_x, &mouse_y)
        ToolTip("")
        SetTimer(t2, 0)

        SetSetting("Config", "egg_top_corner_set", "true")
        SetSetting("Config", "egg_top_corner_x", mouse_x)
        SetSetting("Config", "egg_top_corner_y", mouse_y)
        CONFIG['Config']["egg_top_corner_set"] := "true"
        CONFIG['Config']["egg_top_corner_x"] := mouse_x
        CONFIG['Config']["egg_top_corner_y"] := mouse_y

        Sleep(1500)

        t3() {
            if(macro_running = false) {
                ToolTip("")
                Kill()
                return
            }
            ToolTip("Left click the bottom right of the egg shop box.")
        }
        SetTimer(t3, 16)
        KeyWait("LButton", "D")
        MouseGetPos(&mouse_x, &mouse_y)
        ToolTip("")
        SetTimer(t3, 0)

        SetSetting("Config", "egg_bottom_corner_set", "true")
        SetSetting("Config", "egg_bottom_corner_x", mouse_x)
        SetSetting("Config", "egg_bottom_corner_y", mouse_y)
        CONFIG['Config']["egg_bottom_corner_set"] := "true"
        CONFIG['Config']["egg_bottom_corner_x"] := mouse_x
        CONFIG['Config']["egg_bottom_corner_y"] := mouse_y

        Sleep(600)

        ToolTip("Done! You can now run the macro.")
        
        SetTimer((*) => (
            ToolTip("")
        ), 2000)
    }

}

startButton := window.AddButton("x" x1 " y" 450 " w100", "Start")
configButton := window.AddButton("x" (x1 + 110) " y" 450 " w130", "Set Config")

startButton.OnEvent("Click", StartMacro)
configButton.OnEvent("Click", setConfig)

window.Show("AutoSize Center")

Kill(*) {
    global macro_running
    if macro_running {
        macro_running := false
        SetTimer(Master, 0)
        SetToolTip("")
        
        MsgBox("Macro stopped.")
        WinActivate("Rus' Grow a Garden Macro")
    }
}

Hotkey(CONFIG['Settings']['kill_key'], Kill)

getUnixTimeStamp() {
    epoch := "19700101000000"
    local_diff := DateDiff(A_Now, epoch, "Seconds")
    utc_offset_seconds := DateDiff(A_Now, A_NowUTC, "Seconds")
    unix_timestamp := local_diff - utc_offset_seconds
    return unix_timestamp
}

Master() {
    global loop_counter, last_fired_egg, last_fired_shop, CONFIG, trigger_egg_macro, show_timestamp_tooltip, first_run

    shopInterval := CONFIG['Settings']["shop_timer"]
    eggInterval := CONFIG['Settings']["egg_timer"]

    ; macro logic here
    current_time := getUnixTimeStamp()
    nextShopCheckIn := shopInterval - Mod(getUnixTimeStamp(), shopInterval)
    nextEggCheckIn := eggInterval - Mod(getUnixTimeStamp(), eggInterval)

    if(show_timestamp_tooltip){
        SetToolTip("Next shop check in " nextShopCheckIn "s`nNext egg check in " nextEggCheckIn "s")
    } else {
        SetToolTip("")
    }


    if !macro_running {
        Kill()
        return
    }

    if(first_run || (Mod(getUnixTimeStamp(), eggInterval) = 0) && (current_time != last_fired_egg)){
        last_fired_egg := current_time
        trigger_egg_macro := true
    }

    if(first_run || (Mod(getUnixTimeStamp(), shopInterval) = 0) && (current_time != last_fired_shop)) {
        last_fired_shop := current_time
        Macro()
    }

    if(first_run) {
        first_run := false
    }
}

FindImage(path, x1 := 0, y1 := 0, x2 := A_ScreenWidth, y2 := A_ScreenHeight) {
    xResult := 0
    yResult := 0

    imgFound := ImageSearch(&xResult, &yResult, x1, y1, x2, y2, "*TransBlack *30 " path)
    return imgFound
}

/**
 * Time of Termination
 */
ToT(){
    timestamp := FormatTime(, "dd/MM/yyyy HH:mm:ss")
    return "Time of termination: " . timestamp
}

Macro() {
    global CONFIG, trigger_egg_macro, seedIndexes, gearIndexes, chosenEggs, show_timestamp_tooltip, seedList, gearList

    show_timestamp_tooltip := false
    SetToolTip("")

    ; internet failsafe
    if(CONFIG["Settings"]["internet_failsafe"] == "true"){
        count := 0
        SetToolTip("Checking internet connection...")
        Loop 10 {
            internetFailsafe := GetOCR()
            if(internetFailsafe == "Disconnected Lost connection to the game server, please reconnect (Error Code: 277) Leave Reconnect"){
                count++
            }
        }

        SetToolTip("")

        if(count > 5){
            MsgBox("Internet was disconnected`nMacro has been terminated.`n" ToT())
            ExitApp
            return
        }
    }

    ; shutdown failsafe
    if(CONFIG["Settings"]["shutdown_failsafe"] == "true"){
        count := 0
        SetToolTip("Checking for server shutdown...")
        Loop 10 {
            shutdownFailsafe := GetOCR()
            if(shutdownFailsafe == "Disconnected The game has shut down (Error Code: 288) Leave Reconnect"){
                count++
            }
        }

        SetToolTip("")

        if(count > 5){
            MsgBox("Server has shut down`nMacro has been terminated.`n" ToT())
            ExitApp
            return
        }
    }

    ; go to seed shop
    Press("D", 3)
    Press("Enter")
    Press("E")
    Sleep(2000)
    Press("S")

    ; loop through seedIndexes to buy the right seeds
    for i, seedIndex in seedIndexes {
        if(macro_running = false) {
            break
        }
        SetToolTip("Buying " seedList[seedIndex] " Seed if in stock")
        Press("S", seedIndex - 1)
        Press("Enter")
        Press("S")

        Press("Enter", 30, 50)
        
        Press("W")
        Press("Enter")
        Press("W", seedIndex - 1)
        SetToolTip("")
    }

    Press("Enter", 2)
    Sleep(300)
    Press("W")
    Sleep(300)
    Press("Enter")
    ; return to top of seed shop and exit

    ; go to gear shop
    Sleep(500)
    Press("2", 1)
    LeftClick()
    Sleep(500)
    Press("E", 1)

    ; enter gear shop
    SmoothMove(CONFIG['Config']["gear_enter_point_x"], CONFIG['Config']["gear_enter_point_y"], 10, 2)
    Sleep(3000)
    LeftClick()
    Sleep(2000)
    Press("\", 2)
    LeftClick()
    Press("\", 1)
    Press("D", 3)
    Press("S", 1)

    ; buy gears
    for i, gearIndex in gearIndexes {
        if(macro_running = false) {
            break
        }
        SetToolTip("Buying " gearList[gearIndex] " Gear if in stock")
        Press("S", gearIndex - 1)
        Press("Enter")
        Press("S")

        Press("Enter", 5)
        
        Press("W", 1)
        Press("Enter", 1)
        Press("W", gearIndex - 1)
        SetToolTip("")
    }

    ; return to top of gear shop and exit
    Press("W", 1)
    Press("Enter", 1)

    Press("\")

    trigger_egg_macro := true
    if(trigger_egg_macro) {
        ; go to egg 1
        HoldKey("S", 0.9)
        Press("E")
        Sleep(500)
        SetToolTip("Checking egg 1...")
        egg1Count := 0
        buyEgg1 := false

        Loop 50 {
            egg1Text := GetOCRRect(
                CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_top_corner_y"],
                CONFIG['Config']["egg_bottom_corner_x"] - CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_bottom_corner_y"] - CONFIG['Config']["egg_top_corner_y"]
            )

            for i, egg in chosenEggs {
                if (InStr(egg1Text, "Purchase " egg)) {
                    egg1Count++
                }
            }
        }

        SetToolTip("")

        if(egg1Count > 25){
           buyEgg1 := true
        }

        if(buyEgg1) {
            SetToolTip("Buying egg 1")
        } else {
            SetToolTip("Skipping egg 1")
        }

        ; navigate to egg ui
        Press("\")
        Press("D", 3)
        Press("S")

        if(buyEgg1) {
            ; buy
            Press("Enter")
        } else {
            ; hit x
            Press("D", 2)
            Press("Enter")
        }
        SetToolTip("")
        Press("\")

        ; go to egg 2
        HoldKey("S", 0.18)
        Press("E")
        Sleep(500)
        SetToolTip("Checking egg 2...")
        egg2Count := 0
        buyEgg2 := false

        Loop 50 {
            egg2Text := GetOCRRect(
                CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_top_corner_y"],
                CONFIG['Config']["egg_bottom_corner_x"] - CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_bottom_corner_y"] - CONFIG['Config']["egg_top_corner_y"]
            )

            for i, egg in chosenEggs {
                if (InStr(egg2Text, "Purchase " egg)) {
                    egg2Count++
                }
            }
        }

        SetToolTip("")

        if(egg2Count > 25){
            buyEgg2 := true
        }

        if(buyEgg2) {
            SetToolTip("Buying egg 2")
        } else {
            SetToolTip("Skipping egg 2")
        }

        ; navigate to egg ui
        Press("\")
        Press("D", 3)
        Press("S")

        if(buyEgg2) {
            ; buy
            Press("Enter")
        } else {
            ; hit x
            Press("D", 2)
            Press("Enter")
        }
        SetToolTip("")
        Press("\")

        ; go to egg 3
        HoldKey("S", 0.18)
        Press("E")
        Sleep(500)
        SetToolTip("Checking egg 3...")
        egg3Count := 0
        buyEgg3 := false

        Loop 50 {
            egg3Text := GetOCRRect(
                CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_top_corner_y"],
                CONFIG['Config']["egg_bottom_corner_x"] - CONFIG['Config']["egg_top_corner_x"],
                CONFIG['Config']["egg_bottom_corner_y"] - CONFIG['Config']["egg_top_corner_y"]
            )

            for i, egg in chosenEggs {
                if (InStr(egg3Text, "Purchase " egg)) {
                    egg3Count++
                }
            }
        }

        SetToolTip("")

        if(egg3Count > 25){
            buyEgg3 := true
        }

        if(buyEgg3) {
            SetToolTip("Buying egg 3")
        } else {
            SetToolTip("Skipping egg 3")
        }

        ; navigate to egg ui
        Press("\")
        Press("D", 3)
        Press("S")

        if(buyEgg3) {
            ; buy
            Press("Enter")
        } else {
            ; hit x
            Press("D", 2)
            Press("Enter")
        }
        SetToolTip("")
        Press("\")

        trigger_egg_macro := false
    }

    Press("\", 2)
    LeftClick()
    Press("\")
    Press("D", 4)
    Press("Enter")
    Press("A", 4)

    show_timestamp_tooltip := true
}