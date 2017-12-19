' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    m.port = createObject("roMessagePort")
    ' Components
    m.title = m.top.findNode("title")
    m.message = m.top.findNode("message")
    m.code = m.top.findNode("code")
    m.message_footer = m.top.findNode("message_footer")
    m.url = m.top.findNode("url")
    m.twitch_api = createObject("roSGNode", "TwitchApi")
    m.timer = m.top.findNode("timer")
    ' Init
    m.title.text = tr("title_link")
    m.message.text = tr("message_link").replace("{1}", m.twitch_api.AUTH_URL)
    m.message_footer.text = tr("message_link_close")
    m.url.text = m.twitch_api.AUTH_URL
    ' Events
    m.top.observeField("do_link", "do_link")
    m.twitch_api.observeField("result", "on_callback")
    m.timer.observeField("fire", "on_timer")
end function

' Begin the link process
' Ignores event
function do_link(event as object) as void
    m.twitch_api.get_link_code = "on_link_code"
end function

' Given an event with link code data, validate and begin the request loop
' waiting for authentication
function on_link_code(event as object) as void
    link_code = event.getData().result
    if type(link_code) <> "roAssociativeArray"
        m.top.setField("error", 2000)
        return
    else if link_code.id = invalid
        m.top.setField("error", 2001)
        return
    end if
    ' Set code on screen
    m.code.text = link_code.id
    ' Start timer
    m.timer.control = "start"
end function

' Handle a timer event
' Request the status of a link code
function on_timer(event as object) as void
    ' Stop the loop if the link screen is not up
    if not m.top.visible
        m.timer.control = "stop"
        return
    end if
    ' Request link status
    m.twitch_api.get_link_status = "on_link_status"
end function

' Handle link status
function on_link_status(event as object) as void
    status = event.getData().result
    if type(status) <> "roAssociativeArray"
        m.top.setField("error", 2002)
        m.timer.contol = "stop"
        return
    end if
    ' Check the status
    if status.error <> invalid
        print status.error
        m.top.setField("timeout", true)
    else if status.complete and status.token <> invalid
        m.top.setField("linked_token", status.token)
    end if
end function