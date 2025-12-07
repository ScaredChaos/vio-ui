local browser
local uiVisible = false
local browserReady = false
local keybinds = {}  -- merkt sich: commandId -> aktuell gebundene Taste

local screenW, screenH = guiGetScreenSize()
local browserW, browserH = 900, 600   -- Größe des UI-Fensters
local browserX, browserY = (screenW - browserW) / 2, (screenH - browserH) / 2

-- Event aus der Vue-UI: Spieler will eine Taste für einen Befehl wählen
addEvent("keybind_select_request", true)
addEventHandler("keybind_select_request", root, function(commandId)
    outputChatBox("[Keybind UI] Taste wählen für: " .. tostring(commandId), 184, 60, 53)
end)

local awaitingKeyFor = nil  -- merkt sich, für welchen Command wir eine Taste abfragen

addEvent("keybind_select_request", true)
addEventHandler("keybind_select_request", root, function(commandId)
    if not uiVisible then return end

    awaitingKeyFor = commandId
    outputChatBox("[Keybind UI] Drücke jetzt eine Taste für: " .. tostring(commandId), 184, 60, 53)
end)

-- UI möchte einen Bind speichern
addEvent("keybind_save_request", true)
addEventHandler("keybind_save_request", root, function(commandId, key)
    if not key or key == "" then
        outputChatBox("[Keybind UI] Bitte zuerst eine Taste wählen.", 255, 100, 100)
        return
    end

    -- alten Bind für diesen Command entfernen (falls vorhanden)
    if keybinds[commandId] then
        unbindKey(keybinds[commandId], "down", commandId)
    end

    -- neuen Bind setzen: key -> /commandId
    local ok = bindKey(key, "down", commandId)

    if ok then
        keybinds[commandId] = key
        outputChatBox(string.format("[Keybind UI] Bind gesetzt: %s -> /%s", key, commandId), 184, 60, 53)
    else
        outputChatBox("[Keybind UI] Bind konnte nicht gesetzt werden.", 255, 100, 100)
    end
end)


-- Nächste gedrückte Taste abfangen, wenn wir auf eine Auswahl warten
addEventHandler("onClientKey", root, function(button, press)
    if not press then return end              -- nur beim Drücken, nicht beim Loslassen
    if not awaitingKeyFor then return end     -- nur wenn wir wirklich warten
    if not uiVisible then return end          -- nur wenn das UI offen ist

    local commandId = awaitingKeyFor
    awaitingKeyFor = nil

    outputChatBox("[Keybind UI] Gewählte Taste: " .. tostring(button) .. " für " .. tostring(commandId), 184, 60, 53)

    -- An den Browser (Vue) zurückschicken, damit die UI sich aktualisiert
    if browserReady and isElement(browser) and type(executeBrowserJavascript) == "function" then
        local js = string.format(
            "window.mtaSetKeyForCommand && window.mtaSetKeyForCommand(%q, %q);",
            commandId,
            button
        )
        executeBrowserJavascript(browser, js)
    end
end)



-----------------------------------------------------------------------
-- Hilfsfunktion: Cursor relativ zum Browser
-----------------------------------------------------------------------
local function getCursorRelativeToBrowser()
    if not isCursorShowing() then
        return false
    end

    local cx, cy = getCursorPosition()
    if not cx or not cy then
        return false
    end

    local absX, absY = cx * screenW, cy * screenH

    if absX < browserX or absX > browserX + browserW
    or absY < browserY or absY > browserY + browserH then
        return false
    end

    -- relative Koordinaten im Browser
    local relX = absX - browserX
    local relY = absY - browserY
    return true, relX, relY
end

---------------------------------
-- UI zeichnen
---------------------------------
local function renderUI()
    if not uiVisible then
        return
    end

    if browserReady and isElement(browser) then
        dxDrawImage(
            browserX, browserY,
            browserW, browserH,
            browser,
            0, 0, 0,
            tocolor(255, 255, 255, 255),
            true
        )
    end
end
addEventHandler("onClientRender", root, renderUI)

---------------------------------------------------
-- Browser erstellen und index.html laden
---------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
    outputChatBox("[vue_keybinds] Resource gestartet.")

    browser = createBrowser(browserW, browserH, true, true)
    if not browser then
        outputChatBox("[vue_keybinds] FEHLER: Browser konnte nicht erstellt werden.")
        return
    end

    addEventHandler("onClientBrowserCreated", browser, function()
        outputChatBox("[vue_keybinds] Browser erstellt, lade index.html...")
        browserReady = true
        loadBrowserURL(browser, "http://mta/local/index.html")
    end)

    addEventHandler("onClientBrowserLoadingFailed", browser, function(url, errorCode, errorDesc)
        outputChatBox("[vue_keybinds] Laden fehlgeschlagen: " .. tostring(url) .. " | " .. tostring(errorCode) .. " | " .. tostring(errorDesc))
    end)
end)

---------------------------------
-- Mausbewegung (falls Funktion da)
---------------------------------
addEventHandler("onClientCursorMove", root, function()
    if not uiVisible or not browserReady or not isElement(browser) then
        return
    end

    local inside, relX, relY = getCursorRelativeToBrowser()
    if not inside then
        return
    end

    -- Nur benutzen, wenn die Funktion existiert
    if type(injectBrowserMouseMove) == "function" then
        injectBrowserMouseMove(browser, relX, relY)
    end
end)

---------------------------------
-- Klicks (falls Funktionen da)
---------------------------------
addEventHandler("onClientClick", root, function(button, state)
    if not uiVisible or not browserReady or not isElement(browser) then
        return
    end

    local inside = getCursorRelativeToBrowser()
    if not inside then
        return
    end

    if button == "left" or button == "right" then
        if state == "down" then
            if type(injectBrowserMouseDown) == "function" then
                injectBrowserMouseDown(browser, button)
            end
        elseif state == "up" then
            if type(injectBrowserMouseUp) == "function" then
                injectBrowserMouseUp(browser, button)
            end
        end
    end
end)

---------------------------------
-- UI anzeigen / verstecken
---------------------------------
local function showUI()
    uiVisible = true
    showCursor(true)
    guiSetInputEnabled(true)

    if isElement(browser) then
        focusBrowser(browser)
    end

    outputChatBox("[vue_keybinds] UI sichtbar (/binding).")
end

local function hideUI()
    uiVisible = false
    showCursor(false)
    guiSetInputEnabled(false)

    outputChatBox("[vue_keybinds] UI versteckt (/binding).")
end

-- Öffnen / Schließen mit /binding
addCommandHandler("binding", function()
    if uiVisible then
        hideUI()
    else
        showUI()
    end
end)
