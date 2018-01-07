' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    m.port = createObject("roMessagePort")
    ' Components
    m.preview = m.top.findNode("preview")
    m.title = m.top.findNode("title")
    m.buttons = m.top.findNode("buttons")
    ' Info Group
    m.info_group = m.top.findNode("stream_info")
    m.viewers = m.info_group.findNode("viewers")
    m.start_time = m.info_group.findNode("start_time")
    m.language = m.info_group.findNode("language")
    m.stream_type = m.info_group.findNode("stream_type")
    ' Init
    m.buttons.buttons = ["", ""]
    m.button_callbacks = []
    set_button(0, tr("button_play"), "on_play_button_pressed")
    ' Events
    m.top.observeField("preview_image", "on_set_field")
    m.top.observeField("title", "on_set_field")
    m.top.observeField("streamer", "on_set_field")
    m.top.observeField("game", "on_set_field")
    m.top.observeField("visible", "on_set_field")
    m.top.observeField("focus", "on_set_field")
    m.top.observeField("viewers", "on_set_field")
    m.top.observeField("start_time", "on_set_field")
    m.top.observeField("language", "on_set_field")
    m.top.observeField("stream_type", "on_set_field")
    m.buttons.observeField("buttonSelected", "on_button_selected")
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function

' Check for visibility and focus the buttons
function on_set_visible(event as object) as void
    if event.getData() = true
        m.buttons.setFocus(true)
        m.buttons.focusButton = 0
    end if
end function

' Handle a button selection
function on_button_selected(event as object) as void
    callback = m.button_callbacks[event.getData()]
    if type(callback) = "String"
        eval(callback + "()")
    end if
end function

' Handle field updates
function on_set_field(event as object) as void
    field = event.getField()
    ' Image
    if field = "preview_image"
        m.preview.uri = event.getData()
    ' Title
    else if field = "title"
        m.title.text = event.getData()
    ' Streamer
    else if field = "streamer"
        'set_button(2, tr("prefix_streamer") + ": " + event.getData()[0], "on_streamer_button_pressed")
    ' Game
    else if field = "game"
        set_button(1, tr("prefix_game") + ": " + event.getData()[0], "on_game_button_pressed")
    ' Visible
    else if field = "visible" or field = "focus"
        on_set_visible(event)
    ' Viewers
    else if field = "viewers"
        if m.top.getField("stream_type") = "user"
            m.viewers.text = tr("title_views") + ": " + event.getData().toStr()
        else
            m.viewers.text = tr("title_viewers") + ": " + event.getData().toStr()
        end if
    ' Start time
    else if field = "start_time"
        set_time(event.getData())
    ' Language
    else if field = "language"
        m.language.text = tr("title_language") + ": " + event.getData()
    ' Stream type
    else if field = "stream_type"
        m.stream_type.text = tr("title_stream_type") + ": " + event.getData()
        m.top.setField("start_time", m.top.getField("start_time"))
        m.top.setField("viewers", m.top.getField("viewers"))
    end if
end function

' Set the time the stream started
' @param time_string time string in ISO8601 format
function set_time(time_string as string) as void
    ' Time from string
    time = createObject("roDateTime")
    time.fromISO8601String(time_string)
    ' Show time created if the type is a user
    if m.top.getField("stream_type") = "user"
        time.toLocalTime()
        m.start_time.text = tr("title_joined") + ": " + time.asDateString("short-month-no-weekday")
        return
    end if
    ' Show the up time of a stream
    now = createObject("roDateTime")
    ' Calculate up time
    total_seconds = now.asSeconds() - time.asSeconds()
    hours = int(total_seconds / (60 * 60))
    minutes = int((total_seconds / (60 * 60) - hours) * 60)
    ' Set up time
    m.start_time.text = tr("title_uptime") + ": "
    if hours > 0
        m.start_time.text += hours.toStr() + " " + trs("inline_hours", hours) + " "
    end if
    m.start_time.text += minutes.toStr() + " " + trs("inline_minutes", minutes)
end function

' Handle the streamer button being pressed
function on_streamer_button_pressed() as void
    streamer = m.top.getField("streamer")[1]
    ' TODO show streamer info screen
end function

' Handle the game button being pressed
function on_game_button_pressed() as void
    m.top.setField("game_selected", true)
end function

' Handle play button
function on_play_button_pressed() as void
    m.top.setField("play_selected", true)
end function

' Set a buttons contents and callback
function set_button(index as integer, name as string, callback as string) as void
    ' The buttons field is overwritten to trigger the observe field event
    ' Updating an entry will not update the menu
    buttons = m.buttons.buttons
    buttons[index] = name
    m.buttons.buttons = buttons
    ' Set callback
    m.button_callbacks[index] = callback
end function