' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    ' Constants
    m.top.VIDEO = 0
    m.top.CHANNEL = 1
    m.top.GAME = 2
    ' Components
    m.keyboard = m.top.findNode("keyboard")
    m.search = m.keyboard.textEditBox
    m.buttons = m.top.findNode("search_buttons")
    ' Init
    m.buttons.buttons = [
        tr("button_search"), 
        tr("button_search_channels"), 
        tr("button_search_games")
    ]
    ' Events
    m.top.observeField("visible", "on_set_visible")
    m.top.observeField("focus", "on_set_visible")
    m.search.observeField("text", "on_text_changed")
    m.buttons.observeField("buttonSelected", "on_button_selected")
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    ' Keyboard
    if m.keyboard.isInFocusChain()
        ' Move to buttons
        if press and key = "right"
            m.buttons.setFocus(true)
            return true
        end if
    ' Buttons
    else if m.buttons.isInFocusChain()
        ' Move to keyboard
        if press and key = "left"
            m.keyboard.setFocus(true)
            return true
        end if
    end if
    return false
end function

' Check for visibility and focus the keyboard
function on_set_visible(event as object) as void
    if event.getData()
        if event.getField() = "focus"
            m.keyboard.setFocus(true)
        end if
    end if
end function

' Handle search text change
function on_text_changed(event as object) as void
    ' TODO search suggestions
end function

' Handle a button selection
' Set a search field to an array [integer type_of_search, string terms]
function on_button_selected(event as object) as void
    if len(m.search.text) <= 0 then return
    button = event.getData()
    m.top.setField("search", [button, m.search.text])
end function