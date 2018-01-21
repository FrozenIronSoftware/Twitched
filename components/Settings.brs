' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    ' Constants
    m.URL_INFO = "https://twitched.org/info"
    m.URL_OSS = "https://twitched.org/info/oss"
    m.URL_PRIVACY = "https://twitched.org/info/privacy"
    m.INFO = 0
    m.OSS = 1
    m.PRIVACY = 2
    m.LANGUAGE = 3
    m.LOG_IN_OUT = 4
    m.MENU_ITEMS = ["title_info", "title_oss", "title_privacy_policy", "title_language", "title_log_in_out"]
    m.LANG_JSON = parseJson(readAsciiFile("pkg:/resources/twitch_lang.json"))
    ' Components
    m.menu = m.top.findNode("menu")
    m.title = m.top.findNode("title")
    m.message = m.top.findNode("message")
    m.checklist = m.top.findNode("checklist")
    ' Init
    init_menu()
    ' Events
    m.top.observeField("visible", "on_set_visible")
    m.top.observeField("focus", "on_set_visible")
    m.menu.observeField("itemSelected", "on_menu_item_selected")
    m.menu.observeField("itemFocused", "on_menu_item_focused")
    m.checklist.observeField("checkedState", "on_checked_state_update")
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    ' Checklist
    if m.checklist.hasFocus()
        ' Set main settings menu focus
        if press and (key = "left" or key = "back")
            m.menu.setFocus(true)
            return true
        end if
    ' Menu
    else if m.menu.hasFocus()
        ' Activate 
        if press and key = "right" and m.menu.itemFocused = m.LANGUAGE
            m.checklist.setFocus(true)
            return true
        end if
    end if
    return false
end function

' Check for visibility and focus the menu
function on_set_visible(event as object) as void
    if event.getData()
        reset()
        if event.getField() = "focus"
            m.menu.setFocus(true)
        end if
        m.menu.jumpToItem = 0
        ' Add log in/out item
        log_in_out = m.menu.content.getChild(m.LOG_IN_OUT)
        if m.top.getField("authenticated")
            log_in_out.title = "   " + tr("title_log_out")
        else
            log_in_out.title = "   " + tr("title_log_in")
        end if
    end if
end function

' Handle menu item selected
function on_menu_item_selected(event as object) as void
    select_menu_item(event.getData())
end function

' Handle menu item focus
function on_menu_item_focused(event as object) as void
    focus_menu_item(event.getData())
end function

' Select a menu item
function select_menu_item(item as integer) as void
    ' Info
    if item = m.INFO
    ' OSS
    else if item = m.OSS
    ' Privacy Policy
    else if item = m.PRIVACY
    ' Language
    else if item = m.LANGUAGE
        m.checklist.setFocus(true)
    ' Log in/out
    else if item = m.LOG_IN_OUT
        ' Sign out
        if m.top.getField("authenticated")
            m.top.setField("sign_out_in", "out")
        ' Sign in
        else
            m.top.setField("sign_out_in", "in")
        end if
    ' Unhandled
    else
        print "Unhandled setting menu item selected: " + item.toStr()
    end if
end function

' Focus a menu item
function focus_menu_item(item as integer) as void
    reset()
    ' Info
    if item = m.INFO
        m.title.text = tr("title_info")
        m.message.text = tr("message_settings_info").replace("{1}", m.URL_INFO)
    ' OSS
    else if item = m.OSS
        m.title.text = tr("title_oss")
        m.message.text = tr("message_settings_oss").replace("{1}", m.URL_OSS)
    ' Privacy Policy
    else if item = m.PRIVACY
        m.title.text = tr("title_privacy_policy")
        m.message.text = tr("message_settings_privacy_policy").replace("{1}", m.URL_PRIVACY)
    ' Language
    else if item = m.LANGUAGE
        checked_state = []
        ' Set title
        m.title.text = tr("title_language")
        ' Clear content
        m.checklist.content.removeChildrenIndex(m.checklist.content.getChildCount(), 0)
        ' Add lang items
        for each lang_item in m.LANG_JSON
            lang_enabled = false
            for each lang in m.global.language
                if lang_item.code = lang
                    lang_enabled = true
                end if
            end for
            checked_state.push(lang_enabled)
            ' Add lang to checklist
            check_item = m.checklist.content.createChild("ContentNode")
            name = clean(lang_item.name)
            if len(name) <> len(lang_item.name)
                name = lang_item.name_en
            end if
            check_item.title = name
            check_item.hideicon = false
        end for
        ' Set checklist state
        m.checklist.checkedState = checked_state
        m.checklist.visible = true
    ' Log in/out
    else if item = m.LOG_IN_OUT
    ' Unhandled
    else
        print "Unhandled setting menu item focused: " + item.toStr()
    end if
end function

' Reset the title and message
function reset() as void
    m.title.text = ""
    m.message.text = ""
    m.checklist.visible = false
end function

' Initialize the settings panel list
function init_menu() as void
    ' Add items
    for each title in m.MENU_ITEMS
        item = m.menu.content.createChild("ContentNode")
        item.title = "   " + tr(title)
    end for
end function

' Handle checklist checked state change
function on_checked_state_update(event as object) as void
    if m.LANG_JSON.count() <> m.checklist.checkedState.count()
        return
    end if
    language = []
    for index = 0 to m.LANG_JSON.count() - 1
        if m.checklist.checkedState[index]
            language.push(m.LANG_JSON[index].code)
        end if
    end for
    m.top.setField("language", language)
end function