' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the Chat component
function init() as void
    ' Constants
    m.CHAT_ITEMS = 4
    ' Components
    m.irc = m.top.findNode("irc")
    m.chat_list = m.top.findNode("chat_list")
    ' Init
    init_logging()
    init_chat_list()
    ' Events
    m.top.observeField("connect", "connect")
    m.top.observeField("disconnect", "disconnect")
    m.top.observeField("token", "set_token")
    m.top.observeField("user_name", "set_user_name")
    m.irc.observeField("chat_message", "on_chat_message")
end function

function init_chat_list() as void
    for item_index = 0 to m.CHAT_ITEMS
        m.chat_list.content.createChild("ChatItemData")
    end for
end function

' Handle connecting
' Event is a field event with the value being a string with the streamer name
function connect(event as object) as void
    clear_chat()
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

' Clear the chat messages
function clear_chat() as void
    m.chat_list.content.removeChildrenIndex(m.chat_list.getChildCount(), 0)
end function

' Handle disconnect
' Event is a field event with the value being ignored
function disconnect(event as object) as void
    clear_chat()
    m.irc.disconnect = true
end function

' Handle a chat message
function on_chat_message(event as object) as void
    message = event.getData()
    add_chat_message(message)
end function

' Add a chat message to the chat list
function add_chat_message(message as object) as void
    ' Set the message to an empty chat item
    for item_index = 0 to m.CHAT_ITEMS
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