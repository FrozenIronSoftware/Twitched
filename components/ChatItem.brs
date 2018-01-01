' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the ChatItem component
function init() as void
    ' Constants
    ' Components
    m.message = m.top.findNode("message")
    m.name = m.top.findNode("name")
    ' Init
    ' Events
    m.top.observeField("itemContent", "on_item_content_change")
end function

' Handle a content change
function on_item_content_change(event as object) as void
    message = event.getData().message
    if type(message) <> "roAssociativeArray"
        return
    end if
    if message.name = invalid or message.name = "" or message.message = invalid
        return
    end if
    m.name.text = clean(message.name)
    if len(m.name.text) < 3
        m.name.text = "justinfan"
    end if
    ' The message is at max 500 characters
    m.message.text = clean(message.message)
    if len(m.message.text) > 50
        m.message.font = "font:SmallestSystemFont"
    else
        m.message.font = "font:MediumSystemFont"
    end if
    if message.color <> invalid and message.color <> ""
        m.name.color = message.color
    end if
end function