' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the InfoScreen component
function init() as void
    ' Constants
    m.BUTTON_PLAY = 0
    m.BUTTON_GAME = 1
    m.BUTTON_STREAMER = 2
    m.BUTTON_VODS = 3
    m.TYPE_ALL = 0
    m.TYPE_UPLOAD = 1
    m.TYPE_HIGHLIGHT = 2
    m.TYPE_ARCHIVE = 3
    m.BUTTON_FOLLOW_UNFOLLOW = 0
    m.BUTTON_ERROR_CONFIRM = 0
    ' Components
    m.preview = m.top.findNode("preview")
    m.title = m.top.findNode("title")
    m.buttons = m.top.findNode("buttons")
    m.twitch_api = m.top.findNode("twitch_api")
    m.vods = m.top.findNode("vods_list")
    m.message = m.top.findNode("message")
    m.dialog = m.top.findNode("dialog")
    ' Info Group
    m.info_group = m.top.findNode("stream_info")
    m.viewers = m.info_group.findNode("viewers")
    m.start_time = m.info_group.findNode("start_time")
    m.language = m.info_group.findNode("language")
    m.stream_type = m.info_group.findNode("stream_type")
    ' Init
    m.video_selected = invalid
    m.dialog_type = "video_type"
    m.user_info = invalid
    m.is_following = false
    init_logging()
    m.video_type = tr("title_videos")
    m.buttons.buttons = ["", "", "", ""]
    m.button_callbacks = []
    set_button(m.BUTTON_PLAY, tr("button_play"), "on_play_button_pressed")
    set_button(m.BUTTON_VODS, tr("button_vods"), "on_vods_button_pressed")
    ' Events
    m.top.observeField("preview_image", "on_set_field")
    m.top.observeField("title", "on_set_field")
    m.top.observeField("streamer", "on_set_field")
    m.top.observeField("game", "on_set_field")
    m.top.observeField("visible", "on_set_field")
    m.top.observeField("focus", "on_set_field")
    m.top.observeField("viewers", "on_set_field")
    m.top.observeField("start_time", "on_set_field")
    m.top.observeField("language", "on_set_field")
    m.top.observeField("stream_type", "on_set_field")
    m.top.observeField("token", "on_set_field")
    m.top.observeField("video_selected", "on_set_field")
    m.buttons.observeField("buttonSelected", "on_button_selected")
    m.twitch_api.observeField("result", "on_callback")
    m.vods.observeField("rowItemSelected", "on_video_selected")
    m.dialog.observeField("buttonSelected", "on_dialog_button_selected")
    m.dialog.observeField("wasClosed", "on_dialog_closed")
end function

' Handle callback
function on_callback(event as object) as void
    callback = event.getData().callback
    if callback = "on_user_info"
        on_user_info(event)
    else if callback = "on_follow_info"
        on_follow_info(event)
    else if callback = "on_video_data"
        on_video_data(event)
    else if callback = "on_follow_channel"
        on_follow_channel(event)
    else if callback = "on_unfollow_channel"
        on_unfollow_channel(event)
    else
        if callback = invalid
            callback = ""
        end if
        printl(m.WARN, "on_callback: Unhandled callback: " + callback)
    end if
end function

' Handle keys
function onKeyEvent(key as string, press as boolean) as boolean
    printl(m.DEBUG, "InfoScreen - Key: " + key + " Press: " + press.toStr())
    ' VODs
    if m.vods.hasFocus()
        ' Return to info screen original state
        if press and (key = "up" or key = "back")
            reset(m.BUTTON_VODS)
            return true
        ' Show video type selection dialog
        else if press and key = "options"
            m.dialog.optionsDialog = true
            m.dialog.title = tr("title_video_type")
            m.dialog.message = ""
            m.dialog.buttons = [
                tr("button_all"),
                tr("button_upload"),
                tr("button_highlight"),
                tr("button_archive")
            ]
            m.dialog_type = "video_type"
            m.dialog.focusButton = 0
            m.dialog.visible = true
            m.top.setField("dialog", m.dialog)
        end if
    end if
    return false
end function

' Check for visibility and focus the buttons
function on_set_visible(event as object) as void
    ' Not visible
    if event.getField() = "visible" and not event.getData()
        m.twitch_api.cancel = true
    ' Visible event
    else if event.getField() = "visible" and event.getData()
        reset()
    ' Focus event
    else if event.getField() = "focus"
        ' Reset
        if event.getData() = "reset"
            reset()
        ' Focus vods if visible
        else if event.getData() = "true"
            button = m.BUTTON_PLAY
            if m.vods.visible
                button = m.BUTTON_VODS
            end if
            reset(button, m.vods.visible)
        end if
    end if
end function

' Reset the info screen state
function reset(button = 0 as integer, focus_vods = false as boolean) as void
    m.dialog.visible = false
    m.dialog.close = true
    m.buttons.focusButton = button
    m.buttons.setFocus(not focus_vods)
    m.vods.setFocus(focus_vods)
    m.vods.visible = focus_vods
    m.info_group.visible = not focus_vods
    m.message.text = ""
    m.top.video_selected = invalid
    if (not focus_vods) and (not is_video())
        m.video_selected = invalid
    end if
    m.top.setField("options", false)
    m.video_type = tr("title_videos")
    m.dialog_type = ""
end function

' Check if the info screen is displaying info about a video
function is_video() as boolean
    stream_type = m.top.getField("stream_type")
    return stream_type = "upload" or stream_type = "archive" or stream_type = "highlight"
end function

' Check if the info screen is displaying a user
function is_user() as boolean
    stream_type = m.top.getField("stream_type")
    return stream_type = "user" or stream_type = "user_follow"
end function

' Handle a button selection
function on_button_selected(event as object) as void
    callback = m.button_callbacks[event.getData()]
    if callback = "on_play_button_pressed"
        on_play_button_pressed()
    else if callback = "on_vods_button_pressed"
        on_vods_button_pressed()
    else if callback = "on_streamer_button_pressed"
        on_streamer_button_pressed()
    else if callback = "on_game_button_pressed"
        on_game_button_pressed()
    end if
end function

' Handle field updates
function on_set_field(event as object) as void
    field = event.getField()
    ' Image
    if field = "preview_image"
        m.preview.uri = event.getData()
    ' Title
    else if field = "title"
        m.title.text = event.getData()
    ' Streamer
    else if field = "streamer"
        set_button(m.BUTTON_STREAMER, tr("prefix_streamer") + ": " + event.getData()[0], "on_streamer_button_pressed")
    ' Game
    else if field = "game"
        set_button(m.BUTTON_GAME, tr("prefix_game") + ": " + event.getData()[0], "on_game_button_pressed")
    ' Visible
    else if field = "visible" or field = "focus"
        on_set_visible(event)
    ' Viewers
    else if field = "viewers"
        if is_user() or is_video()
            m.viewers.text = tr("title_views") + ": " + pretty_number(event.getData())
        else
            m.viewers.text = tr("title_viewers") + ": " + pretty_number(event.getData())
        end if
    ' Start time
    else if field = "start_time"
        set_time(event.getData())
    ' Language
    else if field = "language"
        m.language.text = tr("title_language") + ": " + event.getData()
    ' Stream type
    else if field = "stream_type"
        m.stream_type.text = tr("title_stream_type") + ": " + event.getData()
        m.top.setField("start_time", m.top.getField("start_time"))
        m.top.setField("viewers", m.top.getField("viewers"))
    ' Token
    else if field = "token"
        m.twitch_api.user_token = event.getData()
    ' Video selected
    else if field = "video_selected"
        if event.getData() <> invalid and m.video_selected = invalid
            m.video_selected = event.getData()
        end if
    end if
end function

' Set the time the stream started
' @param time_string time string in ISO8601 format
function set_time(time_string as string) as void
    ' Time from string
    time = createObject("roDateTime")
    time.fromISO8601String(time_string)
    ' Check if the time parsed correctly
    if time.getYear() <= 1970
        m.start_time.text = tr("title_status") + ": " + tr("inline_offline")
        return
    ' This is a user follow
    else if is_user_follow()
        time.toLocalTime()
        m.start_time.text = tr("title_followed") + ": " + time.asDateString("short-month-no-weekday")
        return
    ' Show time created if the type is a user
    else if is_user()
        time.toLocalTime()
        m.start_time.text = tr("title_joined") + ": " + time.asDateString("short-month-no-weekday")
        return
    ' Show published at if the type is a VOD
    else if is_video()
        time.toLocalTime()
        m.start_time.text = tr("title_published_at") + ": " + time.asDateString("short-month-no-weekday")
        return
    end if
    ' Show the up time of a stream
    now = createObject("roDateTime")
    ' Calculate up time
    total_seconds = now.asSeconds() - time.asSeconds()
    hours = int(total_seconds / (60 * 60))
    minutes = int((total_seconds / (60 * 60) - hours) * 60)
    ' Set up time
    m.start_time.text = tr("title_uptime") + ": "
    if hours > 0
        m.start_time.text += hours.toStr() + " " + trs("inline_hours", hours) + " "
    end if
    m.start_time.text += minutes.toStr() + " " + trs("inline_minutes", minutes)
end function

' Check if the type is a user_follow. User is_user() for a general
' user/user_follow check
function is_user_follow()
    stream_type = m.top.getField("stream_type")
    return stream_type = "user_follow"
end function

' Handle the streamer button being pressed
function on_streamer_button_pressed() as void
    ' Show loading dialog
    m.dialog.optionsDialog = false
    m.dialog.title = tr("title_loading")
    m.dialog.message = tr("title_loading")
    m.dialog.buttons = []
    m.dialog.visible = true
    m.dialog_type = "loading"
    m.top.setField("dialog", m.dialog)
    ' Load streamer info
    streamer = m.top.getField("streamer")[1]
    m.twitch_api.cancel = true
    m.twitch_api.get_user_info = [{
        login: streamer
    }, "on_user_info"]
end function

' Handle user info
function on_user_info(event as object) as void
    ' Validate
    users = event.getData().result
    if type(users) <> "roArray" or users.count() < 1 or type(users[0]) <> "roAssociativeArray"
        error(3000)
        return
    end if
    ' Save user info
    m.user_info = users[0]
    ' Request follow info
    m.twitch_api.cancel = true
    m.twitch_api.get_follows = [{
        limit: 1,
        from_login: m.top.user_name,
        to_login: m.top.streamer[1],
        no_cache: "true"
    }, "on_follow_info"]
end function

function on_follow_info(event as object) as void
    ' Validate
    follows = event.getData().result
    if type(follows) <> "roArray"
        print follows
        error(3001)
        return
    end if
    ' Save follow info
    m.is_following = follows.count() > 0
    ' Show user info dialog
    m.dialog.optionsDialog = false
    m.dialog.title = m.top.streamer[0]
    m.dialog.message = clean(m.user_info.description)
    if m.top.user_name = "" or m.top.token = ""
        m.dialog.buttons = []
    else if m.is_following
        m.dialog.buttons = [tr("button_unfollow")]
    else
        m.dialog.buttons = [tr("button_follow")]
    end if
    m.dialog.focusButton = 0
    m.dialog_type = "user_info"
    m.dialog.visible = true
    m.top.setField("dialog", m.dialog)
end function

' Show the dialog error
function error(code as integer) as void
    m.optionsDialog = false
    m.dialog.title = tr("title_error")
    m.dialog.message = tr("error_api_fail") + chr(10) + tr("title_error_code") + ": " + code.toStr()
    m.dialog.buttons = [tr("button_confirm")]
    m.dialog.focusButton = 0
    m.dialog_type = "error"
    m.dialog.visible = true
    m.top.setField("dialog", m.dialog)
end function

' Handle the game button being pressed
function on_game_button_pressed() as void
    m.top.setField("game_selected", true)
end function

' Handle play button
function on_play_button_pressed() as void
    printl(m.DEBUG, "InfoScreen: Play button pressed")
    ' Stream play
    if not is_video()
        m.top.setField("play_selected", true)
    ' Video play
    else
        if m.video_selected <> invalid
            m.top.setField("video_selected", m.video_selected)
        else
            m.top.setField("play_selected", true)
        end if
    end if
end function

' Handle vods button press
function on_vods_button_pressed(video_type = 0 as integer) as void
    ' Clear VODs
    m.vods.content.removeChildrenIndex(m.vods.content.getChildCount(), 0)
    ' Show loading message
    m.info_group.visible = false
    m.message.text = tr("message_loading")
    ' Determine type
    video_type_string = ""
    if video_type = m.TYPE_ALL
        video_type_string = "all"
    else if video_type = m.TYPE_UPLOAD
        video_type_string = "upload"
    else if video_type = m.TYPE_ARCHIVE
        video_type_string = "archive"
    else if video_type = m.TYPE_HIGHLIGHT
        video_type_string = "highlight"
    end if
    m.video_type = tr("title_video_type_" + video_type_string)
    ' Request videos
    m.twitch_api.cancel = true
    m.twitch_api.get_videos = [{
        limit: 50,
        user_id: m.top.getField("streamer")[2],
        type: video_type_string
    }, "on_video_data"]
    m.top.setField("options", true)
end function

' Set a buttons contents and callback
function set_button(index as integer, name as string, callback as string) as void
    ' The buttons field is overwritten to trigger the observe field event
    ' Updating an entry will not update the menu
    buttons = m.buttons.buttons
    buttons[index] = name
    m.buttons.buttons = buttons
    ' Set callback
    m.button_callbacks[index] = callback
end function

' Handle video data
function on_video_data(event as object) as void
    m.vods.content.removeChildrenIndex(m.vods.content.getChildCount(), 0)
    ' Parse event data
    videos = event.getData().result
    if type(videos) <> "roArray"
        printl(m.DEBUG, "InfoScreen: video data invalid")
        m.message.text = tr("error_api_fail")
        return
    end if
    m.message.text = ""
    ' Add row of video items
    row = m.vods.content.createChild("ContentNode")
    row.title = m.video_type
    populated = false
    for each video_data in videos
        if type(video_data) = "roAssociativeArray"
            if video_data.duration_seconds > 0
                video = row.createChild("VodItemData")
                video.image_url = video_data.thumbnail_url.replace("%{width}", "195").replace("%{height}", "120")
                video.title = clean(video_data.title)
                video.id = video_data.id
                video.duration = video_data.duration_seconds
                populated = true
            else
                printl(m.DEBUG, "InfoScreen: Video duration is 0 seconds. It has likely been deleted.")
            end if
        else
            printl(m.DEBUG, "InfoScreen: video item data invalid")
        end if
    end for
    if not populated
        m.vods.content.removeChildrenIndex(m.vods.content.getChildCount(), 0)
        m.message.text = tr("message_no_data")
    end if
    ' Show vods
    m.vods.visible = true
    m.vods.setFocus(true)
end function

' Handle a video being selected
function on_video_selected(event as object) as void
    selection = event.getData()
    ' Not first now
    if selection[0] <> 0
        return
    end if
    row = m.vods.content.getChild(selection[0])
    if row = invalid
        return
    end if
    video = row.getChild(selection[1])
    if video = invalid
        return
    end if
    m.top.setField("video_selected", video)
end function

' Handle dialog button
function on_dialog_button_selected(event as object) as void
    m.dialog.close = true
    button = event.getData()
    printl(m.DEBUG, "InfoScreen dialog button: " + button.toStr())
    if m.dialog_type = "video_type"
        on_vods_button_pressed(button)
    else if m.dialog_type = "user_info"
        on_user_info_button_pressed(button)
    else if m.dialog_type = "error"
        on_error_dialog_button_pressed(button)
    else if m.dialog_type = "loading"
        ' Ignore
    end if
end function

function on_error_dialog_button_pressed(button as integer) as void
    if button = m.BUTTON_ERROR_CONFIRM
        m.dialog.close = true
    end if
end function

' Handle a button press on the streamer info dialog
function on_user_info_button_pressed(button as integer) as void
    if button = m.BUTTON_FOLLOW_UNFOLLOW
        if type(m.user_info) <> "roAssociativeArray"
            printl(m.DEBUG, "Failed to handle follow/unfollow request. No user info.")
            return
        end if
        if not m.is_following
            m.dialog.buttons = [tr("button_follow")]
            m.twitch_api.cancel = true
            m.twitch_api.follow_channel = [{
                id: m.user_info.id
            }, "on_follow_channel"]
        else
            m.dialog.buttons = [tr("button_unfollow")]
            m.twitch_api.cancel = true
            m.twitch_api.unfollow_channel = [{
                id: m.user_info.id
            }, "on_unfollow_channel"]
        end if
    end if
end function

' Handle a channel follow
function on_follow_channel(event as object) as void
    ' Ignore
    printl(m.DEBUG, "Followed channel")
end function

' Handle a channel unfollow
function on_unfollow_channel(event as object) as void
    ' Ignore
    printl(m.DEBUG, "Unfollowed channel")
end function

' Handle dialog closing
function on_dialog_closed(event as object) as void
    printl(m.DEBUG, "InfoScreen: dialog closed")
    if m.dialog_type = "video_type" and not m.vods.hasFocus()
        m.vods.setFocus(true)
    else if m.dialog_type = "user_info" and not m.buttons.hasFocus()
        m.buttons.setFocus(true)
    else if m.dialog_type = "error" and not m.buttons.hasFocus()
        m.buttons.setFocus(true)
    else if m.dialog_type = "loading" and not m.buttons.hasFocus()
        m.twitch_api.cancel = true
        m.buttons.setFocus(true)
    end if
    m.dialog_type = ""
end function