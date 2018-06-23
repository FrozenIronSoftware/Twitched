' Copyright (C) 2018 Frozen Iron Software. All Rights Reserved.

' Create a new instance of the VideoGridItem component
function init() as void
    ' Constants
    ' Components
    m.image = m.top.findNode("image")
    m.title = m.top.findNode("title")
    ' Variables
    ' Init
    init_logging()
    ' Events
    m.top.observeField("itemContent", "on_item_content_change")
    m.top.observeField("itemHasFocus", "on_focus_change")
end function

' Handle focus change
function on_focus_change(event as object) as void
    if event.getData()
        m.title.repeatCount = -1
    else
        m.title.repeatCount = 0
    end if
end function

' Handle a content change
function on_item_content_change(event as object) as void
    m.image.uri = event.getData().image_url
    m.title.text = event.getData().title
end function