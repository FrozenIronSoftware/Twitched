' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the ChatItem component
function init() as void
    ' Constants
    ' Components
    m.message = m.top.findNode("message")
    m.name = m.top.findNode("name")
    m.badges = m.top.findNode("badges")
    ' Variables
    ' Init
    init_logging()
    ' Events
    m.top.observeField("itemContent", "on_item_content_change")
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
    ' TODO handle emotes
    if type(message.emotes) = "roArray"
        for each emote in message.emotes
            printl(m.VERBOSE, emote)
        end for
    end if
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