' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the Chat component
function init() as void
    ' Constants
    m.CHAT_ITEMS = 5
    ' Components
    m.irc = m.top.findNode("irc")
    m.chat_list = m.top.findNode("chat_list")
    m.keyboard = m.top.findNode("keyboard")
    m.chat_timer = m.top.findNode("chat_timer")
    ' Vars
    m.queued_messages = []
    ' Init
    init_logging()
    init_chat_list()
    m.chat_timer.control = "start"
    m.top.delay_seconds = 25
    ' Events
    m.top.observeField("connect", "connect")
    m.top.observeField("disconnect", "disconnect")
    m.top.observeField("token", "set_token")
    m.top.observeField("user_name", "set_user_name")
    m.top.observeField("do_input", "activate_input")
    m.top.observeField("visible", "on_visibility_change")
    m.irc.observeField("chat_message", "on_chat_message")
    m.keyboard.observeField("buttonSelected", "on_keyboard_button_selected")
    m.chat_timer.observeField("fire", "update_message")
end function

' Handle key events
function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function

' Add chat items
function init_chat_list() as void
    for item_index = 0 to m.CHAT_ITEMS - 1
        chat_item = m.chat_list.content.createChild("ChatItemData")
    end for
end function

' Handle connecting
' Event is a field event with the value being a string with the streamer name
function connect(event as object) as void
    m.queued_messages = []
    set_connecting_message()
    m.irc.connect = event.getData()
end function

' Add a message to indicate the chat is connecting
function set_connecting_message() as void
    add_chat_message({
        name: tr("twitched")
        color: "#ffffff"
        message: tr("message_irc_connecting")
    })
end function

' Handle disconnect
' Event is a field event with the value being ignored
function disconnect(event as object) as void
    m.irc.disconnect = true
    m.queued_messages = []
end function

' Handle a chat message
function on_chat_message(event as object) as void
    message = event.getData()
    queue_chat_message(message)
end function

' Queue a chat message to be added later by the delayed loop
function queue_chat_message(message as object) as void
    message_time = uptime(0)
    message_packet = {
        time: message_time,
        message: message
    }
    if message.do_not_queue = true
        message_packet.time = 0
    end if
    m.queued_messages.push(message_packet)
end function

' Add a chat message to the chat list
function add_chat_message(message as object) as void
    ' Set the message to an empty chat item
    for item_index = 0 to m.CHAT_ITEMS - 1
        chat_item = m.chat_list.content.getChild(item_index)
        if type(chat_item.message) <> "roAssociativeArray"
            chat_item.message = message
            return
        end if
    end for
    ' No chat items were empty. Delete the first and create a new one.
    m.chat_list.content.removeChildIndex(0)
    chat_item = m.chat_list.content.createChild("ChatItemData")
    chat_item.message = message
end function

' Set user token
function set_token(event as object) as void
    m.irc.token = event.getData()
end function

' Set user name
function set_user_name(event as object) as void
    m.irc.user_name = event.getData()
end function

' Handle an input request
' Expects a sgnode event with the field data being a boolean
function activate_input(event as object) as void
    if event.getData() and m.top.user_name <> "" and m.top.token <> ""
        m.keyboard.title = tr("title_chat")
        m.keyboard.buttons = [tr("button_confirm"), tr("button_cancel")]
        m.keyboard.keyboard.text = ""
        m.keyboard.visible = true
        m.keyboard.setFocus(true)
    else
        m.keyboard.visible = false
    end if
end function

' Handle a button press on the keyboard dialog
' 0 confirm, 1 cancel
function on_keyboard_button_selected(event as object) as void
    input = m.keyboard.keyboard.text
    confirm = event.getData() = 0
    if confirm
        if input <> invalid and input <> ""
            m.irc.send_chat_message = input
        end if
    end if
    m.keyboard.visible = false
    m.top.setField("blur", true)
end function

' Hide keyboard on visibility change
function on_visibility_change(event as object) as void
    m.keyboard.visible = false
end function

' Handle update message loop
function update_message(event as object) as void
    time = uptime(0)
    to_remove = 0
    for each message in m.queued_messages
        if time - message.time >= m.top.delay_seconds
            add_chat_message(message.message)
            to_remove += 1
        else
            goto remove_messages
        end if
    end for
    remove_messages:
    for remove_index = 0 to to_remove - 1
        m.queued_messages.delete(0)
    end for
end function
