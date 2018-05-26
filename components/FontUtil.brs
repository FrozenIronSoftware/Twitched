' Copyright (C) 2018 Rolando Islas. All Rights Reserved.

' FontUtil entry point
function init() as void
    ' Constants
    m.PORT = createObject("roMessagePort")
    ' Components
    m.font_registry = createObject("roFontRegistry")
    ' Events
    m.top.observeField("get_size", m.PORT)
    ' Variables
    m.cache = {}
    ' Init
    init_logging()
    ' Task init
    m.top.functionName = "run"
    m.top.control = "RUN"
end function

' Main task loop
function run() as void
    printl(m.DEBUG, "FontUtil: Task started")
    while true
        msg = wait(0, m.PORT) 
        ' Field event
        if type(msg) = "roSGNodeEvent"
            if msg.getField() = "get_size"
                get_size(msg.getData())
            end if
        end if
    end while
end function

' Get the width and height of a string with the specified font size
' @param params roArray [text as string, font_size as integer, callback as string]
function get_size(params as object) as void
    text = params[0]
    font_size = params[1]
    font = m.cache[font_size.toStr()]
    if font = invalid
        font = m.font_registry.getDefaultFont(font_size, false, false)
        m.cache[font_size.toStr()] = font
    end if
    m.top.result = {
        callback: params[2],
        result: {
            ' FIXME font width returned is roughly 6.5% smaller than label text
            width: font.getOneLineWidth(text, 1920) * 1.065,
            height: font.getOneLineHeight()
        }
    }
end function