#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
#NoTrayIcon
Persistent(true)

; ==============================================================================
; SECTION 1: ELEVATION RESILIENCE & PERFORMANCE ENGINE
; ==============================================================================

; Elevate if started with /elevate argument; otherwise run seamlessly in current token context
if (A_Args.Length > 0 && A_Args[1] = "/elevate" && !A_IsAdmin) {
    try {
        if A_IsCompiled
            Run('*RunAs "' A_ScriptFullPath '"')
        else
            Run('*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"')
        ExitApp()
    }
}

SendMode("Input")
ListLines(False)
KeyHistory(0)
SetWinDelay(-1)
SetControlDelay(-1)
ProcessSetPriority("H")
SetMouseDelay(-1)
SetDefaultMouseSpeed(0)
A_MaxHotkeysPerInterval := 5000
A_MenuMaskKey := "vk07"

MinimizeMemoryUsage()

; ==============================================================================
; SECTION 2: HIGH-PERFORMANCE SYSTEM LOGIC
; ==============================================================================

MinimizeMemoryUsage() {
    try {
        hProcess := DllCall("GetCurrentProcess", "Ptr")
        DllCall("psapi\EmptyWorkingSet", "Ptr", hProcess)
    }
}

ShowBrightnessOSD(val) {
    static osdGui := ""
    static osdProgress := ""
    static osdText := ""

    if (osdGui == "") {
        osdGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale", "Brightness OSD")
        osdGui.BackColor := "1E1E1E"

        ; Windows 11 Rounded Corners via DWM (DWMWCP_ROUND = 2)
        try {
            cornerVal := 2
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", osdGui.Hwnd, "UInt", 33, "Int*", &cornerVal, "UInt", 4)
        }

        ; Segoe Fluent Icons Sun glyph (0xE706)
        osdGui.SetFont("s13 cFFFFFF", "Segoe Fluent Icons")
        osdGui.Add("Text", "x16 y12 w24 h24", Chr(0xE706))

        ; Cyan Accent Slider Bar (matching Windows 11 Volume flyout)
        osdProgress := osdGui.Add("Progress", "x48 y18 w160 h4 Background333333 c60CDFF Range0-100", val)

        ; Value Display
        osdGui.SetFont("s11 norm cFFFFFF", "Segoe UI Variable Text")
        osdText := osdGui.Add("Text", "x218 y12 w36 h24 Right", val)
    } else {
        osdProgress.Value := val
        osdText.Value := val
    }

    ; Center at bottom of primary display (matching native Volume flyout)
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    w := 270, h := 44
    x := left + ((right - left - w) // 2)
    y := bottom - h - 60

    osdGui.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")
    ; Re-assert HWND_TOPMOST (0x0013 = SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE)
    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
    SetTimer(() => osdGui.Hide(), -1500)
}

AdjustBrightness(offset) {
    if !A_IsAdmin {
        ToolTip("Hardware Brightness control requires Administrative rights.")
        SetTimer(() => ToolTip(), -2500)
        return
    }
    static wmi := ""
    try {
        if (wmi = "")
            wmi := ComObjGet("winmgmts:\\.\root\WMI")

        found := false
        currentBrightness := 0
        for obj in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=True") {
            currentBrightness := obj.CurrentBrightness
            found := true
        }
        if !found
            throw Error("No WMI-compatible display found (common on external/desktop monitors).")

        newBrightness := Max(0, Min(100, currentBrightness + offset))
        for obj in wmi.ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods WHERE Active=True")
            obj.WmiSetBrightness(0, newBrightness)

        ShowBrightnessOSD(newBrightness)
    } catch Error as e {
        ToolTip("Hardware Error: " . e.Message)
        SetTimer(() => ToolTip(), -2500)
    }
}

ShowVolumeOSD(val) {
    static osdGui := ""
    static osdIcon := ""
    static osdProgress := ""
    static osdText := ""

    val := Round(val)
    iconCode := (val == 0) ? 0xE74F : (val < 34 ? 0xE992 : (val < 67 ? 0xE993 : 0xE994))

    if (osdGui == "") {
        osdGui := Gui("-Caption +AlwaysOnTop +ToolWindow -DPIScale", "Volume OSD")
        osdGui.BackColor := "1E1E1E"

        ; Windows 11 Rounded Corners via DWM (DWMWCP_ROUND = 2)
        try {
            cornerVal := 2
            DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", osdGui.Hwnd, "UInt", 33, "Int*", &cornerVal, "UInt", 4)
        }

        ; Segoe Fluent Icons Volume glyph
        osdGui.SetFont("s13 cFFFFFF", "Segoe Fluent Icons")
        osdIcon := osdGui.Add("Text", "x16 y12 w24 h24", Chr(iconCode))

        ; Cyan Accent Slider Bar
        osdProgress := osdGui.Add("Progress", "x48 y18 w160 h4 Background333333 c60CDFF Range0-100", val)

        ; Value Display
        osdGui.SetFont("s11 norm cFFFFFF", "Segoe UI Variable Text")
        osdText := osdGui.Add("Text", "x218 y12 w36 h24 Right", val)
    } else {
        osdIcon.Value := Chr(iconCode)
        osdProgress.Value := val
        osdText.Value := val
    }

    ; Center at bottom of primary display (matching native flyout)
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    w := 270, h := 44
    x := left + ((right - left - w) // 2)
    y := bottom - h - 60

    osdGui.Show("x" . x . " y" . y . " w" . w . " h" . h . " NoActivate")
    ; Re-assert HWND_TOPMOST (0x0013 = SWP_NOSIZE | SWP_NOMOVE | SWP_NOACTIVATE)
    DllCall("SetWindowPos", "Ptr", osdGui.Hwnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0013)
    SetTimer(() => osdGui.Hide(), -1500)
}

AdjustVolume(offset) {
    try {
        currentVol := SoundGetVolume()
        newVol := Max(0, Min(100, Round(currentVol + offset)))
        SoundSetVolume(newVol)
        ShowVolumeOSD(newVol)
    } catch {
        SoundSetVolume((offset > 0 ? "+2" : "-2"))
        try {
            ShowVolumeOSD(SoundGetVolume())
        }
    }
}

; ==============================================================================
; SECTION 3: SYSTEM HOTKEYS & ENGINE TOGGLES
; ==============================================================================

#SuspendExempt
; Left Alt + Right Alt (Pause/Play Script Engine)
LAlt & RAlt:: {
    Suspend(-1)
    if A_IsSuspended {
        ToolTip("SCRIPT PAUSED")
        SetTimer(() => ToolTip(), -1000)
    } else {
        ToolTip("SCRIPT ACTIVE")
        SetTimer(() => ToolTip(), -1000)
    }
}
#SuspendExempt False

; Left Alt (Pass-through alignment)
; Non-blocking menu mask on release without freezing Alt combos
~LAlt up:: {
    Send("{Blind}{vkE8}")
}

; Right Alt (Non-blocking menu mask on release)
~RAlt up:: {
    Send("{Blind}{vkE8}")
}

; ==============================================================================
; SECTION 4: HARDENED MOUSE DEBOUNCE ENGINE (All 5 Buttons)
; Filters microswitch chatter on Left, Right, Middle, and Side thumb buttons
; using isBlocked state machine to ensure clean down/up event pairs.
; ==============================================================================

DebounceMs := 40

lastDown  := Map("LButton", 0, "RButton", 0, "MButton", 0, "XButton1", 0, "XButton2", 0)
lastUp    := Map("LButton", 0, "RButton", 0, "MButton", 0, "XButton1", 0, "XButton2", 0)
isBlocked := Map("LButton", false, "RButton", false, "MButton", false, "XButton1", false, "XButton2", false)

HandleDown(btn) {
    global lastDown, lastUp, isBlocked, DebounceMs
    now := A_TickCount
    ; Block if press comes too soon after either last press or last release (bounce chatter)
    if (now - lastDown[btn] < DebounceMs || now - lastUp[btn] < DebounceMs) {
        isBlocked[btn] := true
        return
    }
    isBlocked[btn] := false
    lastDown[btn] := now
    Send("{Blind}{" btn " down}")
}

HandleUp(btn) {
    global lastUp, isBlocked
    if (isBlocked[btn]) {
        ; Swallow the release event corresponding to the suppressed bounce press
        isBlocked[btn] := false
        return
    }
    lastUp[btn] := A_TickCount
    Send("{Blind}{" btn " up}")
}

; Button 1 = Left click
*LButton::HandleDown("LButton")
*LButton up::HandleUp("LButton")

; Button 2 = Right click
*RButton::HandleDown("RButton")
*RButton up::HandleUp("RButton")

; Button 3 = Middle click (scroll wheel press)
*MButton::HandleDown("MButton")
*MButton up::HandleUp("MButton")

; Button 4 = Side button (Back)
*XButton1::HandleDown("XButton1")
*XButton1 up::HandleUp("XButton1")

; Button 5 = Side button (Forward)
*XButton2::HandleDown("XButton2")
*XButton2 up::HandleUp("XButton2")

; ==============================================================================
; SECTION 5: HARDWARE TRIGGERS & LOCAL DEV LAUNCHERS
; ==============================================================================

; Ctrl + \ (WMI Brightness Up)
$^\::AdjustBrightness(10)

; Ctrl + ' (WMI Brightness Down)
$^'::AdjustBrightness(-10)

; Alt + = (Universal OS Volume Up)
$!=::AdjustVolume(2)

; Alt + - (Universal OS Volume Down)
$!-::AdjustVolume(-2)

; Alt + W (Universal Fullscreen Toggle / Fn + F11)
!w::Send("{F11}")

; Alt + E (Universal Fullscreen Toggle / Fn + F11)
!e::Send("{F11}")

; Alt + F (True Toggle: Workspace Zoom 1844x1064 Left of Taskbar <-> Previous State)
RunSilentProcess(cmdLine, captureStdout := false) {
    hRead := 0, hWrite := 0
    if captureStdout {
        sa := Buffer(24, 0)
        NumPut("UInt", 24, sa, 0)
        NumPut("Int", 1, sa, 16)
        if !DllCall("CreatePipe", "Ptr*", &hRead, "Ptr*", &hWrite, "Ptr", sa, "UInt", 0)
            return ""
        DllCall("SetHandleInformation", "Ptr", hRead, "UInt", 1, "UInt", 0)
    }

    si := Buffer(104, 0)
    NumPut("UInt", 104, si, 0)
    NumPut("UInt", captureStdout ? 0x00000101 : 0x00000001, si, 60)
    NumPut("UShort", 0, si, 64)
    if captureStdout {
        NumPut("Ptr", hWrite, si, 88)
        NumPut("Ptr", hWrite, si, 96)
    }

    pi := Buffer(24, 0)
    ok := DllCall("CreateProcessW", "Ptr", 0, "Str", cmdLine, "Ptr", 0, "Ptr", 0, "Int", captureStdout ? 1 : 0, "UInt", 0x08000000, "Ptr", 0, "Ptr", 0, "Ptr", si, "Ptr", pi)
    if captureStdout
        DllCall("CloseHandle", "Ptr", hWrite)

    if !ok {
        if captureStdout
            DllCall("CloseHandle", "Ptr", hRead)
        return ""
    }

    hProc := NumGet(pi, 0, "Ptr")
    DllCall("CloseHandle", "Ptr", NumGet(pi, A_PtrSize, "Ptr"))

    out := ""
    if captureStdout {
        buf := Buffer(4096, 0)
        bytesRead := 0
        while DllCall("ReadFile", "Ptr", hRead, "Ptr", buf, "UInt", 4096, "UInt*", &bytesRead, "Ptr", 0) && bytesRead > 0
            out .= StrGet(buf, bytesRead, "UTF-8")
        DllCall("CloseHandle", "Ptr", hRead)
    }

    DllCall("WaitForSingleObject", "Ptr", hProc, "UInt", 3000)
    DllCall("CloseHandle", "Ptr", hProc)
    return out
}

ToggleGlazeZoom() {
    static busy := false
    static prevFloatingBounds := Map()
    static glazeCli := "C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe"

    if (busy || !FileExist(glazeCli))
        return
    busy := true
    try {
        json := RunSilentProcess('"' . glazeCli . '" query focused', true)
        if !RegExMatch(json, '"focused":\{"type":"window","id":"([^"]+)"', &mId)
            return
        winId := mId[1]

        stateType := RegExMatch(json, '"state":\{"type":"([^"]+)"', &mSt) ? mSt[1] : ""
        width := RegExMatch(json, '"width":(\d+),"height":(\d+),"x":(-?\d+),"y":(-?\d+)', &mRect) ? Integer(mRect[1]) : 0
        height := mRect ? Integer(mRect[2]) : 0
        posX := mRect ? Integer(mRect[3]) : 0
        posY := mRect ? Integer(mRect[4]) : 0

        if (stateType == "floating" && width == 1844 && height == 1064 && posX == 8 && posY == 8) {
            if prevFloatingBounds.Has(winId) {
                prev := prevFloatingBounds[winId]
                prevFloatingBounds.Delete(winId)
                RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' size --width ' . prev.w . 'px --height ' . prev.h . 'px')
                RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' position --x-pos ' . prev.x . ' --y-pos ' . prev.y)
            } else {
                RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' set-tiling')
            }
        } else {
            if (stateType == "floating" && width > 0 && height > 0)
                prevFloatingBounds[winId] := {w: width, h: height, x: posX, y: posY}
            else if prevFloatingBounds.Has(winId)
                prevFloatingBounds.Delete(winId)

            RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' set-floating --shown-on-top=false')
            RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' size --width 1844px --height 1064px')
            RunSilentProcess('"' . glazeCli . '" command --id ' . winId . ' position --x-pos 8 --y-pos 8')
        }
    } finally {
        busy := false
    }
}

$!f::ToggleGlazeZoom()

; Ctrl + Alt + 3 (Launch localhost:3000)
^!3:: Run("http://localhost:3000")

; Ctrl + Alt + 5 (Launch localhost:5173)
^!5:: Run("http://localhost:5173")

; Ctrl + Alt + 8 (Launch localhost:8080)
^!8:: Run("http://localhost:8080")

; Ctrl + Shift + L (Instant Universal Find/Select All Matches)
^+l:: {
    clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")

    if ClipWait(0.1, 0) {
        Send("^f^v!a")
    } else {
        Send("^f!a")
    }

    SetTimer(() => (A_Clipboard := clipSaved), -300)
}

; ==============================================================================
; SECTION 6: UNIFIED DEVELOPER LAUNCHERS (Consolidated from devbox-win)
; ==============================================================================

; Win + Enter (Windows Terminal)
#Enter:: {
    Run("wt.exe")
}

; Win + B (Default Browser / Web)
#b:: {
    Run("https://github.com")
}

; Win + Shift + E (Explorer at User Profile)
#+e:: {
    Run('explorer.exe "' . EnvGet("USERPROFILE") . '"')
}

; Win + Shift + D (Media Inspector & Downloader)
#+d:: {
    runner := "V:\projects\media-inspector\run-media-dl.vbs"
    if FileExist(runner) {
        Run('wscript.exe "' . runner . '"',, "Hide")
    }
}

; Ctrl + Alt + R (Reload Engine)
^!r:: {
    ToolTip("[INFO] Reloading central AHK engine...")
    SetTimer(() => ToolTip(), -1500)

    targetExe := "V:\tools\auto-hotkey\hola-dev.exe"
    targetAhk := "V:\tools\auto-hotkey\hola-dev.ahk"
    ahkRunner := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

    if FileExist(targetExe) {
        Run('"' . targetExe . '"')
        ExitApp()
    } else if FileExist(targetAhk) && FileExist(ahkRunner) {
        Run('"' . ahkRunner . '" "' . targetAhk . '"')
        ExitApp()
    } else {
        Reload()
    }
}

; ==============================================================================
; SECTION 7: MANUAL OBSIDIAN VAULT SYNCHRONIZATION (Ctrl + *)
; Dispatches sync-hola.ps1 silently with desktop feedback
; ==============================================================================

SyncHolaVault() {
    ToolTip("[SYNC] Syncing Hola Vault...")
    SetTimer(() => ToolTip(), -2500)
    
    syncScript := "D:\vault\hola\system\scripts\sync-hola.ps1"
    if FileExist(syncScript) {
        Run('pwsh.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' . syncScript . '"',, "Hide")
    } else {
        ToolTip("[ERROR] sync-hola.ps1 not found.")
        SetTimer(() => ToolTip(), -3000)
    }
}

; Ctrl + Numpad * (Numeric Keypad)
^NumpadMult::SyncHolaVault()
^sc037::SyncHolaVault()

; Ctrl + Shift + 8 (Standard Keyboard Ctrl + *)
^+8::SyncHolaVault()
^+sc009::SyncHolaVault()

; Ctrl + 8 (Convenience fallback for standard keyboard)
^8::SyncHolaVault()

; ==============================================================================
; SECTION 8: SLEEK SHORTCUT HUD (Win + `)
; Interactive, searchable desktop cheat-sheet overlay with Win32 dark mode
; ==============================================================================

global hudGui := ""
global searchBox := ""
global lvShortcuts := ""

hudShortcuts := [
    ; Global & System Launchers
    ["Global", "Ctrl + *", "Sync Hola Vault (Git Silent Sync)"],
    ["Global", "Win + ``", "Toggle Shortcut HUD (This Window)"],
    ["Global", "Win + Enter", "Launch Windows Terminal (wt.exe)"],
    ["Global", "Win + B", "Launch Default Browser (GitHub)"],
    ["Global", "Win + Shift + E", "Open File Explorer at User Profile"],
    ["Global", "Win + Shift + D", "Launch Media Inspector & Downloader"],
    ["Global", "Ctrl + \", "Display Brightness Up (+10%)"],
    ["Global", "Ctrl + '", "Display Brightness Down (-10%)"],
    ["Global", "Alt + =", "Master Volume Up (+2)"],
    ["Global", "Alt + -", "Master Volume Down (-2)"],
    ["Global", "Alt + W", "Universal Fullscreen Toggle (Fn + F11)"],
    ["Global", "Alt + E", "Universal Fullscreen Toggle (Fn + F11)"],
    ["Global", "Ctrl + Alt + 3", "Open Localhost:3000"],
    ["Global", "Ctrl + Alt + 5", "Open Localhost:5173"],
    ["Global", "Ctrl + Alt + 8", "Open Localhost:8080"],
    ["Global", "Ctrl + Shift + L", "Find & Select All Occurrences"],
    ["Global", "Ctrl + Alt + R", "Reload Central AHK Engine"],
    ["Global", "LAlt & RAlt", "Suspend / Resume Hotkey Engine"],
    ; Window Management (GlazeWM)
    ["GlazeWM", "Alt + H / J / K / L", "Focus Window Left / Down / Up / Right"],
    ["GlazeWM", "Alt + Shift + HJKL", "Move Focused Window Directionally"],
    ["GlazeWM", "Alt + 1..9", "Switch to Workspace 1 through 9"],
    ["GlazeWM", "Alt + Shift + 1..9", "Move Window to Workspace 1..9"],
    ["GlazeWM", "Alt + Shift + Space", "Toggle Floating Mode"],
    ["GlazeWM", "Alt + T", "Force Tiling Mode"],
    ["GlazeWM", "Alt + F", "Toggle Workspace Zoom (Left of Taskbar)"],
    ["GlazeWM", "Alt + ``", "Close Focused Window"],
    ["GlazeWM", "Alt + V", "Toggle Horizontal / Vertical Split"],
    ["GlazeWM", "Alt + Shift + R", "Reload GlazeWM Configuration"]
]

PopulateShortcutList(filterText := "") {
    global lvShortcuts, hudShortcuts
    lvShortcuts.Opt("-Redraw")
    lvShortcuts.Delete()
    q := StrLower(Trim(filterText))
    for row in hudShortcuts {
        cat := row[1]
        key := row[2]
        desc := row[3]
        if (q = "" || InStr(StrLower(cat), q) || InStr(StrLower(key), q) || InStr(StrLower(desc), q)) {
            lvShortcuts.Add("", cat, key, desc)
        }
    }
    lvShortcuts.Opt("+Redraw")
}

OnHUDActivate(wParam, lParam, msg, hwnd) {
    global hudGui
    if (hudGui != "" && hwnd == hudGui.Hwnd && (wParam & 0xFFFF) == 0) {
        hudGui.Hide()
    }
}

ToggleShortcutHUD() {
    global hudGui, searchBox, lvShortcuts
    if (hudGui != "") {
        if WinActive("ahk_id " . hudGui.Hwnd) {
            hudGui.Hide()
            return
        } else {
            searchBox.Value := ""
            PopulateShortcutList("")
            hudGui.Show("Center")
            searchBox.Focus()
            return
        }
    }

    hudGui := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox +Owner", "Shortcut HUD")
    hudGui.BackColor := "121316"
    hudGui.MarginX := 20
    hudGui.MarginY := 20

    ; DwmSetWindowAttribute: Immersive Dark Mode (20) & Rounded Corners (33)
    try {
        val := 1
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hudGui.Hwnd, "UInt", 20, "Int*", &val, "UInt", 4)
        cornerVal := 2
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hudGui.Hwnd, "UInt", 33, "Int*", &cornerVal, "UInt", 4)
    }

    ; Header
    hudGui.SetFont("s11 bold c38BDF8", "Segoe UI Variable Text")
    hudGui.Add("Text", "w840", "SHORTCUT HUD   •   Press Esc to dismiss")

    ; Search Box
    hudGui.SetFont("s10 norm cF0F2F5", "Segoe UI Variable Text")
    searchBox := hudGui.Add("Edit", "w840 h32 Background1A1B20")
    try {
        DllCall("uxtheme\SetWindowTheme", "Ptr", searchBox.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
    }

    ; ListView
    hudGui.SetFont("s10 norm cE2E8F0", "Cascadia Code")
    lvShortcuts := hudGui.Add("ListView", "w840 h440 Background161618 cF0F2F5 Grid -Multi", ["Domain", "Shortcut", "Command / Description"])
    try {
        DllCall("uxtheme\SetWindowTheme", "Ptr", lvShortcuts.Hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    }

    PopulateShortcutList("")

    ; Explicit default column widths (generous width so no shortcuts get truncated)
    lvShortcuts.ModifyCol(1, 100)
    lvShortcuts.ModifyCol(2, 260)
    lvShortcuts.ModifyCol(3, 460)

    searchBox.OnEvent("Change", (ctrl, *) => PopulateShortcutList(ctrl.Value))
    hudGui.OnEvent("Escape", (*) => hudGui.Hide())
    hudGui.OnEvent("Close", (*) => hudGui.Hide())

    ; Auto-dismiss on blur (loss of window focus)
    OnMessage(0x0006, OnHUDActivate)

    hudGui.Show("w880 h560 Center")
    searchBox.Focus()
}

; Win + ` (Toggle Shortcut HUD: sc029 / vkC0)
#sc029::ToggleShortcutHUD()


