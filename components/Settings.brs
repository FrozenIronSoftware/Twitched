' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    ' Constants
    m.URL_INFO = "https://twitched.org/info"
    m.URL_OSS = "https://twitched.org/info/oss"
    m.URL_PRIVACY = "https://twitched.org/info/privacy"
    m.INFO = 5
    m.OSS = 6
    m.PRIVACY = 7
    m.LANGUAGE = 0
    m.QUALITY = 1
    m.LOG_IN_OUT = 4
    m.HLS_LOCAL = 3
    m.START_MENU = 2
    m.MENU_ITEMS = ["title_language", "title_quality", "title_start_menu",
        "title_hls_local", "title_log_in_out", "title_info", "title_oss",
        "title_privacy_policy"
    ]
    m.LANG_JSON = parseJson(readAsciiFile("pkg:/resources/twitch_lang.json"))
    ' Components
    m.menu = m.top.findNode("menu")
    m.title = m.top.findNode("title")
    m.message = m.top.findNode("message")
    m.checklist = m.top.findNode("checklist")
    m.radiolist = m.top.findNode("radiolist")
    ' Init
    m.initial_radio_list_position = m.radiolist.translation
    m.focused_menu_item = -1
    init_menu()
    ' Events
    m.top.observeField("visible", "on_set_visible")
    m.top.observeField("focus", "on_set_visible")
    m.menu.observeField("itemSelected", "on_menu_item_selected")
    m.menu.observeField("itemFocused", "on_menu_item_focused")
    m.checklist.observeField("checkedState", "on_checked_state_update")
    m.radiolist.observeField("checkedItem", "on_checked_Item_update")
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    ' Checklist / Radiolist
    if m.checklist.hasFocus() or m.radiolist.hasFocus()
        ' Set main settings menu focus
        if press and (key = "left" or key = "back")
            m.menu.setFocus(true)
            return true
        end if
    ' Menu
    else if m.menu.hasFocus()
        ' Activate
        if press and key = "right"
            if m.menu.itemFocused = m.LANGUAGE
                m.checklist.setFocus(true)
                return true
            else if m.menu.itemFocused = m.QUALITY
                m.radiolist.setFocus(true)
                return true
            else if m.menu.itemFocused = m.HLS_LOCAL
                m.radiolist.setFocus(true)
                return true
            else if m.menu.itemFocused = m.START_MENU
                m.radiolist.setFocus(true)
                return true
            end if
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
    ' Quality
    else if item = m.QUALITY
        m.radiolist.setFocus(true)
    ' Log in/out
    else if item = m.LOG_IN_OUT
        ' Sign out
        if m.top.getField("authenticated")
            m.top.setField("sign_out_in", "out")
        ' Sign in
        else
            m.top.setField("sign_out_in", "in")
        end if
    ' Local HLS
    else if item = m.HLS_LOCAL
        m.radiolist.setFocus(true)
    ' Start menu
    else if item = m.START_MENU
        m.radiolist.setFocus(true)
    ' Unhandled
    else
        print "Unhandled setting menu item selected: " + item.toStr()
    end if
end function

' Focus a menu item
function focus_menu_item(item as integer) as void
    reset()
    m.focused_menu_item = item
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
    ' Quality
    else if item = m.QUALITY
        ' Set title
        m.title.text = tr("title_video_quality")
        ' Clear content
        m.radiolist.content.removeChildrenIndex(m.radiolist.content.getChildCount(), 0)
        ' Add quality items
        items = ["title_automatic", "1080p", "720p", "480p", "360p", "240p"]
        for each quality in items
            radio_item = m.radiolist.content.createChild("ContentNode")
            radio_item.title = tr(quality)
        end for
        ' Set selected item
        if m.top.quality = "auto"
            m.radiolist.checkedItem = 0
        else
            for quality = 0 to items.count() - 1
                if m.top.quality = items[quality]
                    m.radiolist.checkedItem = quality
                end if
            end for
        end if
        ' Show radio list
        m.radiolist.visible = true
    ' Log in/out
    else if item = m.LOG_IN_OUT
    ' Local HLS
    else if item = m.HLS_LOCAL
        ' Title and message
        m.title.text = tr("title_hls_local")
        m.message.text = tr("message_hls_local")
        ' Clear content
        m.radiolist.content.removeChildrenIndex(m.radiolist.content.getChildCount(), 0)
        ' Add quality items
        items = ["title_enabled", "title_disabled"]
        for each state in items
            radio_item = m.radiolist.content.createChild("ContentNode")
            radio_item.title = tr(state)
        end for
        ' Set selected item
        if m.global.use_local_hls_parsing
            m.radiolist.checkedItem = 0
        else
            m.radiolist.checkedItem = 1
        end if
        ' Move radio list down
        trans = m.radiolist.translation
        m.radiolist.translation = [trans[0], trans[1] + 250]
        ' Show radio list
        m.radiolist.visible = true
    ' Start Menu
    else if item = m.START_MENU
        ' Title and text
        m.title.text = tr("title_start_menu")
        m.message.text = tr("message_start_menu")
        ' Clear
        m.radiolist.content.removeChildrenIndex(m.radiolist.content.getChildCount(), 0)
        ' Add menu items
        items = ["title_popular", "title_games",
            "title_communities", "title_followed", "title_search"]
        for each menu_title in items
            radio_item = m.radiolist.content.createChild("ContentNode")
            radio_item.title = tr(menu_title)
        end for
        ' Set the selected item
        m.radiolist.checkedItem = m.global.start_menu_index
        ' Move radio list down
        trans = m.radiolist.translation
        m.radiolist.translation = [trans[0], trans[1] + 125]
        ' Show
        m.radiolist.visible = true
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
    m.radiolist.visible = false
    m.radiolist.translation = m.initial_radio_list_position
    m.focused_menu_item = -1
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
    ' Check if all was selected prior to modification
    all_selected = false
    for each lang in m.global.language
        if lang = "all"
            all_selected = true
        end if
    end for
    ' Uncheck others if all is selected
    if m.checklist.checkedState[0] and not all_selected
        checkedState = [true]
        for index = 1 to m.LANG_JSON.count() - 1
            checkedState[index] = false
        end for
        m.checklist.checkedState = checkedState
    else if all_selected
        checkedState = m.checklist.checkedState
        checkedState[0] = false
        m.checklist.checkedState = checkedState
    end if
    ' Create list of enabled languages
    language = []
    for index = 0 to m.LANG_JSON.count() - 1
        if m.checklist.checkedState[index]
            language.push(m.LANG_JSON[index].code)
        end if
    end for
    m.top.setField("language", language)
end function

' Handle radiolist checked item change
function on_checked_item_update(event as object) as void
    if m.focused_menu_item = m.QUALITY
        if event.getData() = 0
            m.top.setField("quality", "auto")
        else if event.getData() > -1
            m.top.setField("quality", m.radiolist.content.getChild(event.getData()).title)
        end if
    else if m.focused_menu_item = m.HLS_LOCAL
        if event.getData() = 0
            m.top.setField("hls_local", true)
        else
            m.top.setField("hls_local", false)
        end if
    else if m.focused_menu_item = m.START_MENU
        if event.getData() > -1
            m.top.setField("start_menu_index", event.getData())
        end if
    end if
end function
