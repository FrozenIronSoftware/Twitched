' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the Search component
function init() as void
    ' Constants
    m.top.VIDEO = 0
    m.top.CHANNEL = 1
    m.top.GAME = 2
    ' Components
    m.keyboard = m.top.findNode("keyboard")
    m.search = m.keyboard.textEditBox
    m.buttons = m.top.findNode("search_buttons")
    m.history = m.top.findNode("history")
    m.registry = m.top.findNode("registry")
    m.history_title = m.top.findNode("history_title")
    ' Var
    m.buttons.buttons = [
        tr("button_search"), 
        tr("button_search_channels"), 
        tr("button_search_games")
    ]
    m.history_array = []
    m.history_title.text = tr("title_search_history")
    ' Events
    m.top.observeField("visible", "on_set_visible")
    m.top.observeField("focus", "on_set_visible")
    m.search.observeField("text", "on_text_changed")
    m.buttons.observeField("buttonSelected", "on_button_selected")
    m.registry.observeField("result", "on_callback")
    m.history.observeField("itemSelected", "on_history_item_selected")
    ' Init
    load_history()
end function

' Handle callback
function on_callback(event as object) as void
    callback = event.getData().callback
    if callback = "on_history_read"
        on_history_read(event)
    else if callback = "on_history_write"
        on_history_write(event)
    else
        if callback = invalid
            callback = ""
        end if
        printl(m.WARN, "Search: Unhandled callback: " + callback)
    end if
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    ' Keyboard
    if m.keyboard.isInFocusChain()
        ' Move to buttons
        if press and key = "down"
            m.buttons.setFocus(true)
            return true
        ' Move to history
        else if press and key = "right" and has_history()
            m.history.setFocus(true)
            return true
        end if
    ' Buttons
    else if m.buttons.isInFocusChain()
        ' Move to keyboard
        if press and key = "up"
            m.keyboard.setFocus(true)
            return true
        ' Move to history
        else if press and key = "right" and has_history()
            m.history.setFocus(true)
            return true
        end if
    ' History
    else if m.history.isInFocusChain()
        ' Move to keyboard
        if press and key = "left"
            m.keyboard.setFocus(true)
            return true
        end if
    end if
    return false
end function

' Check if the history list has items
function has_history() as boolean
    return m.history.content <> invalid and m.history.content.getChildCount() > 0
end function

' Check for visibility and focus the keyboard
function on_set_visible(event as object) as void
    if event.getData()
        if event.getField() = "focus"
            m.keyboard.setFocus(true)
            load_history()
        end if
    end if
end function

' Load history and populate label list
function load_history() as void
    m.registry.read = [m.global.REG_HISTORY, m.global.REG_SEARCH, "on_history_read"]
end function

' Handle history data
function on_history_read(event as object) as void
    m.history.content = createObject("roSGNode", "ContentNode")
    m.history_array = []
    history_string = event.getData().result
    if type(history_string, 3) = "roString"
        history = parseJson(history_string)
        if type(history) = "roArray"
            m.history_array = history
            for each history_item in history
                if type(history_item) = "roAssociativeArray"
                    item = m.history.content.createChild("ContentNode")
                    item.title = ""
                    if history_item.query <> invalid
                        item.title += history_item.query
                    end if
                    query_type_string = invalid
                    query_type = history_item.query_type
                    if query_type = m.top.VIDEO
                        query_type_string = "streams"
                    ' Channel
                    else if query_type = m.top.CHANNEL
                        query_type_string = "channels"
                    ' Game
                    else if query_type = m.top.GAME
                        query_type_string = "games"
                    ' Unhandled
                    else
                        print "Unhandled search type: " + query_type.toStr()
                    end if
                    if query_type_string <> invalid
                        item.hdlistitemiconurl = "pkg:/locale/default/images/history_label_list_icon_" + query_type_string + ".png"
                        item.hdlistitemiconselectedurl = item.hdlistitemiconurl
                    end if
                end if
            end for
            item = m.history.content.createChild("ContentNode")
            item.title = "   " + tr("title_search_history_clear")
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
    save_search_to_history(button, m.search.text)
end function

' Save a search to the history
function save_search_to_history(query_type as integer, query as string) as void
    if type(m.history_array) <> "roArray"
        return
    end if
    history = m.history_array
    for history_index = 0 to history.count() - 1
        history_item = history[history_index]
        if type(history_item) = "roAssociativeArray" and history_item.query = query and history_item.query_type = query_type
            history.delete(history_index)
            history_index = history.count()
        end if
    end for
    history.unshift({
        query: query,
        query_type: query_type
    })
    while history.count() > 10
        history.pop()
    end while
    m.history_array = history
    historyJsonString = formatJson(history)
    m.registry.write = [m.global.REG_HISTORY, m.global.REG_SEARCH, 
        historyJsonString, "on_history_write"]
end function

' Handle history written event
function on_history_write(event as object) as void
    load_history()
end function

' Handle history item being selected
function on_history_item_selected(event as object) as void
    selected_index = event.getData()
    if selected_index < 0 or m.history_array = invalid
        return
    end if
    if selected_index >= m.history_array.count()
        if selected_index = m.history_array.count()
            clear_history()
        else
            return
        end if
    end if
    history_item = m.history_array[selected_index]
    if type(history_item) = "roAssociativeArray"
        m.top.setField("search", [history_item.query_type, history_item.query])
        save_search_to_history(history_item.query_type, history_item.query)
    end if
end function

' Clear recent history
function clear_history() as void
    m.registry.write = [m.global.REG_HISTORY, m.global.REG_SEARCH, "[]", 
        "on_history_write"]
end function