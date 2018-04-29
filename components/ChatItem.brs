' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the ChatItem component
function init() as void
    ' Constants
    ' Components
    m.message = m.top.findNode("message")
    m.name = m.top.findNode("name")
    m.badges = m.top.findNode("badges")
    m.emotes = m.top.findNode("emotes")
    m.font_util = m.top.findNode("font_util")
    ' Variables
    m.emote_indices = invalid
    m.emote_index = 0
    m.message_characters_removed = 0
    m.emote_size = 0
    ' Init
    init_logging()
    ' Events
    m.top.observeField("itemContent", "on_item_content_change")
    m.font_util.observeField("result", "on_callback")
end function

' Handle callback
function on_callback(event as object) as void
    callback = event.getData().callback
    if callback = "on_text_size"
        on_text_size(event)
    else if callback = "on_space_size"
        on_space_size(event)
    else
        if callback = invalid
            callback = ""
        end if
        printl(m.WARN, "ChatItem: Unhandled callback: " + callback)
    end if
end function

' Handle a content change
function on_item_content_change(event as object) as void
    message = event.getData().message
    if type(message) <> "roAssociativeArray"
        return
    end if
    ' Set name
    if message.name = invalid or message.message = invalid
        message.name = ""
        message.message = ""
    end if
    m.name.text = clean(message.name)
    if len(m.name.text) < 3
        m.name.text = "justinfan"
    end if
    ' Set message
    ' The message is at max 500 characters
    m.message.text = clean(message.message)
    if len(m.message.text) > 80
        m.message.font = "font:SmallestSystemFont"
    else if len(m.message.text) > 50
        m.message.font = "font:SmallSystemFont"
    else
        m.message.font = "font:MediumSystemFont"
    end if
    ' Set Color
    if message.color <> invalid and message.color <> ""
        m.name.color = message.color
    else
        m.name.color = "0x00ff00"
    end if
    ' Emotes
    add_emotes(message.emotes)
    ' Add badges
    m.name.width = 400
    m.name.translation = [0, 0]
    badge_size = 18
    name_height = 22
    badge_margin = 5
    m.badges.removeChildrenIndex(m.badges.getChildCount(), 0)
    if type(message.badges) = "roArray"
        if message.badges.count() > 0
            badges_width = message.badges.count() * badge_size + ((message.badges.count() - 1) * badge_margin)
            m.name.width -= badges_width
            m.name.translation = [badges_width + badge_margin, 0]
            for badge_index = 0 to message.badges.count() - 1
                badge = m.badges.createChild("Poster")
                badge.uri = message.badges[badge_index]
                badge.width = badge_size
                badge.height = badge_size
                badge.translation = [badge_index * badge_size, 
                    (name_height - badge_size) / 2]
                if badge_index > 0
                    badge.translation = [badge.translation[0] + badge_margin, 
                        badge.translation[1]]
                end if
            end for
        end if
    end if
end function

' Handle adding emotes for a message
function add_emotes(emotes) as void
    ' TODO Ignore on old devices
    ' Reset emotes
    m.emotes.removeChildrenIndex(m.emotes.getChildCount(), 0)
    m.emote_indices = emotes
    m.emote_index = 0
    m.message_characters_removed = 0
    ' Request the size of the space characters
    m.font_util.get_size = ["  ", m.message.font.size, "on_space_size"]
end function

' Handle the size of the emote space being calculated
function on_space_size(event as object) as void
    size = m.message.font.size
    if event.getData().result.width < size
        size = event.getData().result.width
    end if
    m.emote_size = size
    add_emote()
end function

' Parse one emote and handle removing the text and adding the poster
function add_emote() as void
    emotes = m.emote_indices
    if type(emotes) = "roArray"
        if emotes.count() > m.emote_index
            emote = emotes[m.emote_index]
            if type(emote) = "roAssociativeArray"
                if type(emote.start) = "roInt" and type(emote.end) = "roInt"
                    ' Remove emote text
                    'print "ORIGINAL: " + m.message.text
                    message = left(m.message.text, emote.start - m.message_characters_removed)
                    left_message = message
                    'print "LEFT: " + left_message 
                    message += "  "
                    message += mid(m.message.text, emote.end - m.message_characters_removed + 2)
                    m.message.text = message
                    m.message_characters_removed += emote.end - emote.start + 1 - 2
                    'print "EMOTE: " + m.message.text
                    ' Request text size
                    m.font_util.get_size = [left_message, m.message.font.size, "on_text_size"]
                end if
            end if
        end if
    end if
end function

' Handle text size event for the text to the left of the emote
function on_text_size(event as object) as void
    size = event.getData().result
    if size.width >= m.message.width
        ' FIXME Handle more than the first line
        m.emote_index++
        add_emote()
        return
    end if
    emotes = m.emote_indices
    if type(emotes) = "roArray"
        if emotes.count() > m.emote_index
            emote = emotes[m.emote_index]
            if type(emote) = "roAssociativeArray"
                if type(emote.url, 3) = "roString"
                    emote = emotes[m.emote_index]
                    emoteComponent = m.emotes.createChild("Poster")
                    emoteComponent.uri = emote.url
                    emoteComponent.width = m.emote_size
                    emoteComponent.height = m.emote_size
                    x = size.width
                    y = m.message.translation[1] + (fix(x / m.message.width) * size.height)
                    if fix(x / m.message.width) > 0
                        x -= m.message.width * fix(x / m.message.width)
                    end if
                    emoteComponent.translation = [x + 5, y + 5]
                end if
            end if
        end if
    end if
    m.emote_index++
    add_emote()
end function