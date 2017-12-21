' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Main entry point for the application.
' Starts the main scene
function main(args as dynamic) as void
    print("Twitched started")
    ' Load secret keys
	secret = parseJson(readAsciiFile("pkg:/secret.json"))
	' Initialize the main screen
	screen = createObject("roSGScreen")
	port = createObject("roMessagePort")
	screen.setMessagePort(port)
	scene = screen.createScene("Twitch")
	scene.backExitsScene = false
	' Set globals
	m.global = screen.getGlobalNode()
	m.global.addFields({
	   args: args, ' TODO handle deep links
	   secret: secret,
	   REG_TWITCH: "TWITCH",
	   REG_TOKEN: "TOKEN"
	})
	' Events
	screen.show()
	scene.observeField("do_exit", port)
	' Main loop
	while true
	   msg = wait(0, port)
	   if type(msg) = "roSGScreenEvent" 
	       if msg.isScreenClosed() 
	           return
	       end if
	   else if type(msg) = "roSGNodeEvent"
	       if msg.getField() = "do_exit"
	           if msg.getData()
	               screen.close()
	               return
	           end if
	       end if
	   end if
	end while
end function

' Entry point for the main scene
function init() as void
    print("Main scene started")
    ' Constants
    m.ARROW = "»"
    m.MAX_LIMIT = 100
    m.MAX_POSTERS = 100
    m.MAX_VIDEOS = 50
    m.DYNAMIC_GRID = 999
    m.INFO = 1000
    m.VIDEO_PLAYER = 1001
    m.LINK = 1002
    m.EXIT_DIALOG = 1003
    m.POPULAR = 0
    m.GAMES = 1
    m.CREATIVE = 2
    m.COMMUNITIES = 3
    m.FOLLOWED = 4
    m.SEARCH = 5
    m.SETTINGS = 6
    m.MENU_ITEMS = ["title_popular", "title_games", "title_creative", 
        "title_communities", "title_followed", "title_search", "title_settings"]
    ' Components
    m.header = m.top.findNode("header")
    m.main_menu = m.top.findNode("main_menu")
    m.content_grid = m.top.findNode("content_grid")
    m.poster_grid = m.top.findNode("poster_grid")
    m.info_screen = m.top.findNode("info_screen")
    m.dialog = m.top.findNode("dialog")
    m.registry = m.top.findNode("registry")
    m.twitch_api = m.top.findNode("twitch_api")
    m.video = m.top.findNode("video")
    m.message = m.top.findNode("status_message")
    m.link_screen = m.top.findNode("link_screen")
    m.settings_panel = m.top.findNode("settings")
    m.search_panel = m.top.findNode("search")
    ' Events
    m.registry.observeField("result", "on_callback")
    m.twitch_api.observeField("result", "on_callback")
    m.info_screen.observeField("play_selected", "play_video")
    m.info_screen.observeField("game_selected", "load_dynamic_grid_for_game")
    m.dialog.observeField("buttonSelected", "on_dialog_button_selected")
    m.link_screen.observeField("linked_token", "on_link_token")
    m.link_screen.observeField("error", "on_link_error")
    m.link_screen.observeField("timeout", "on_link_timeout")
    m.video.observeField("state", "on_video_state_change")
    m.dialog.observeField("wasClosed", "on_dialog_closed")
    m.settings_panel.observeField("sign_out_in", "on_settings_authentication_request")
    m.search_panel.observeField("search", "on_search")
    ' Init
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_TOKEN, 
        "set_twitch_user_token"]
    init_main_menu()
    ' Parse args
    args = m.global.args
    ' Deep link
    if args.contentId <> invalid and args.mediaType <> invalid
        ' Go to a live stream
        if args.contentId = "twitch_stream" and args.mediaType = "live" and (args.twitch_user_name <> invalid or args.twitch_user_id <> invalid)
            m.twitch_api.get_streams = [{
                limit: 1,
                user_login: args.twitch_user_name,
                user_id: args.twitch_user_id
            }, "on_stream_info"]
            return
        ' Invalid deep link
        else
            error("error_deep_link_invalid", 1009)
        end if
    end if
    ' Normal init
    m.main_menu.setFocus(true)
end function

' Callback function that sets a the twitch API user token read from the registry
function set_twitch_user_token(event as object) as void
    if event.getData().result = invalid
        m.twitch_api.user_token = ""
        return
    end if
    m.twitch_api.user_token = event.getData().result
end function

' Initialize the main menu with translated items and set it as focused
function init_main_menu() as void
    ' Add items
    for each title in m.MENU_ITEMS
        item = m.main_menu.content.createChild("ContentNode")
        item.title = "   " + tr(title)
    end for
    ' Add events
    m.main_menu.observeField("itemFocused", "on_menu_item_focused")
    ' Focus main menu
    m.main_menu.jumpToItem = m.POPULAR
end function

' Handles an item focus event for the main menu
' Determines what content is loaded for the content grid
function on_menu_item_focused(message as object) as void
    load_menu_item(message.getData())
end function

' Loads a menu item and sets the stage passed
' @param stage stage to load/set
function load_menu_item(stage as integer, force = false as boolean) as void
    ' Ignore if the item is already active
    if m.stage = stage and not force then return
    ' Reset
    reset()
    ' Handle selection
    ' Popular
    if stage = m.POPULAR
        m.content_grid.visible = true
        show_message("message_loading")
        m.twitch_api.get_streams = [{limit: m.MAX_VIDEOS}, "set_content_grid"]
    ' Games
    else if stage = m.GAMES
        m.poster_grid.visible = true
        show_message("message_loading")
        m.twitch_api.get_games = [{limit: m.MAX_POSTERS}, "set_poster_grid"]
    ' Creative
    else if stage = m.CREATIVE
        m.content_grid.visible = true
        show_message("message_loading")
        ' Creative id: 488191
        show_message("message_loading")
        m.twitch_api.get_streams = [{limit: m.MAX_VIDEOS, game: "488191"}, 
            "set_content_grid"]
    ' Communities
    else if stage = m.COMMUNITIES
        m.poster_grid.visible = true
        show_message("message_loading")
        m.twitch_api.get_communities = [{limit: m.MAX_POSTERS}, "on_community_data"]
    ' Followed
    else if stage = m.FOLLOWED
        ' User name is not set show a login message
        if not is_authenticated()
            show_message("message_web_link")
        ' Show followed streams
        else
            show_message("message_loading")
            m.content_grid.visible = true
            m.twitch_api.get_followed_streams = [{limit: m.MAX_LIMIT}, "set_content_grid"]
        end if
    ' Search
    else if stage = m.SEARCH
        m.search_panel.visible = true
    ' Settings
    else if stage = m.SETTINGS
        m.settings_panel.authenticated = is_authenticated()
        m.settings_panel.visible = true
    ' Unhandled
    else
        print("Unknown menu item focused/stage selected: " + stage.toStr())
        return
    end if
    m.stage = stage
end function

' Set the poster grid to community data
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_communities response}
function on_community_data(event as object) as void
    show_message("")
    community_data = event.getData().result
    if type(community_data) <> "roAssociativeArray" or type(community_data.communities) <> "roArray"
        print("on_community_data: invalid data")
        error("error_api_fail", 1000)
        return
    end if
    ' Parse data to conform to the game end point data
    data = []
    for each community in community_data.communities
        ' Validate json
        if type(community) <> "roAssociativeArray" or community.avatarImageUrl = invalid or community.name = invalid
            print("on_community_data: invalid json")
            error("error_api_fail", 1001)
            return
        end if
        ' Construct item
        item = {
            box_art_url: community.avatarImageUrl,
            name: community.name,
            id: community.id,
            is_community: true
        }
        data.push(item)
    end for
    set_poster_grid({parsed: data})
end function

' Resets the stage, hiding all content components and resetting variables
function reset(only_hide = false as boolean) as void
    if not only_hide
        m.page = 0
        m.content_grid.content = invalid
        m.poster_grid.content = invalid
    end if
    m.header.title = invalid
    m.content_grid.visible = false
    m.poster_grid.visible = false
    m.info_screen.visible = false
    m.settings_panel.visible = false
    m.search_panel.visible = false
    ' Cancel any async requests
    m.twitch_api.cancel = true
    ' Clear message
    show_message("")
end function

' Set the poster grid with game content
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_games response}
function set_poster_grid(event as object) as void
    show_message("")
    ' Check for data
    is_event = type(event) = "roSGNodeEvent"
    is_assocarray = type(event) = "roAssociativeArray"
    if (not is_event or type(event.getData().result) <> "roArray") and (not is_assocarray or type(event.parsed) <> "roArray")
        print("set_poster_grid: invalid data")
        error("error_api_fail", 1002)
        return
    end if
    ' Check for a forced event with parsed data
    if is_event and type(event.getData().result) = "roArray"
        m.poster_data = event.getData().result
    else if is_assocarray and type(event.parsed) = "roArray"
        m.poster_data = event.parsed
    else
        print("set_poster_grid: invalid data")
        error("error_api_fail", 1003)
        return
    end if
    ' Check if there is no data
    if m.poster_data.count() = 0
        show_message("message_no_data")
    end if
    ' Set content
    m.poster_grid.content = createObject("roSGNode","ContentNode")
    for each data in m.poster_data
        ' Validate json
        if type(data) <> "roAssociativeArray" or data.box_art_url = invalid
            print("set_poster_grid: invalid json")
            error("error_api_fail", 1004)
            return
        end if
        ' Add node
        node = m.poster_grid.content.createChild("ContentNode")
        node.hdgridposterurl = data.box_art_url.replace("{width}", "195").replace("{height}", "120")
        node.sdgridposterurl = data.box_art_url.replace("{width}", "80").replace("{height}", "45")
        node.shortdescriptionline1 = data.name
        if data.viewers <> invalid
            viewer_string = "{0} {1}"
            node.shortdescriptionline2 = substitute(viewer_string, data.viewers.toStr(), trs("inline_viewers", data.viewers), "", "")
        end if
    end for
end function

' Set the content grid to the data given to it
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_streams response}
function set_content_grid(event as object) as void
    show_message("")
    if type(event.getData().result) <> "roArray"
        print(event.getData().result)
        error("error_api_fail", 1005)
        return
    end if
    m.video_data = event.getData().result
    m.content_grid.content = createObject("roSGNode","ContentNode")
    ' Check if there is data
    if m.video_data.count() = 0
        show_message("message_no_data")
    end if
    ' Add items
    for each data in m.video_data
        ' Validate json data
        if type(data) <> "roAssociativeArray" or type(data.user_name) <> "roAssociativeArray" or data.thumbnail_url = invalid or data.title = invalid or data.viewer_count = invalid
            error("error_api_fail", 1006)
            return
        end if
        ' Add node
        node = m.content_grid.content.createChild("ContentNode")
        if data.thumbnail_url <> "null" and data.thumbnail_url <> ""
            node.hdgridposterurl = data.thumbnail_url.replace("{width}", "195").replace("{height}", "120")
            node.sdgridposterurl = data.thumbnail_url.replace("{width}", "80").replace("{height}", "45")
        else
            node.hdgridposterurl = "pkg:/locale/default/images/poster_error.png"
        end if
        node.shortdescriptionline1 = data.title
        ' User
        if data.type = "user"
            node.shortdescriptionline2 = data.user_name.display_name
        ' Stream
        else
            viewer_string = "{0} {1} on {2}"
            node.shortdescriptionline2 = substitute(viewer_string, data.viewer_count.toStr(), trs("inline_viewers", data.viewer_count), data.user_name.display_name, "")
        end if
    end for
end function

' Show an error message and possibly exit
function error(msg as string, error_code = invalid as object, title = "" as string) as void
    msg = tr(msg)
    print(msg)
    if title = ""
        title = tr("title_error")
    else
        title = tr(title)
    end if
    ' Show error
    m.dialog.title = title
    m.dialog.message = msg
    if error_code <> invalid
        m.dialog.message += chr(10) + tr("title_error_code") + ": " + error_code.toStr()
        print("Error Code: " + error_code.toStr())
    end if
    m.dialog.buttons = []
    m.dialog.visible = true
    m.top.dialog = m.dialog
end function

' Show a message dialog
function show_message_dialog(msg as string, title = "" as string)
    if title = ""
        title = tr("title_info")
    end if
    error(msg, invalid, title)
end function

' Handles key events not handled by other components
function onKeyEvent(key as string, press as boolean) as boolean
    print("Key: " + key + " Press: " + press.toStr())
    ' Main Menu
    if m.main_menu.hasFocus() 
        ' Menu item selected
        if press and (key = "right" or key = "OK")
            ' Show login/link prompt
            if stage_requires_authentication() and not is_authenticated()
                show_link_screen()
            ' Focus video grid
            else if stage_contains_video_grid()
                m.content_grid.setFocus(true)
            ' Focus poster grid
            else if stage_contains_poster_grid()
                m.poster_grid.setFocus(true)
            ' Focus settings panel
            else if m.stage = m.SETTINGS
                m.settings_panel.setFocus(true)
                m.settings_panel.focus = true
            ' Focus search panel
            else if m.stage = m.SEARCH
                m.search_panel.setFocus(true)
                m.search_panel.focus = true
            ' Unhandled
            else
                print("Unhandled menu item selection")
                return false
            end if
            return true
        ' App exit
        else if press and key = "back"
            ' Show exit confirm dialog
            save_stage_info(m.EXIT_DIALOG)
            m.stage = m.EXIT_DIALOG
            m.dialog.title = tr("title_exit_confirm")
            m.dialog.message = tr("message_exit_confirm")
            m.dialog.buttons = [tr("button_cancel"), tr("button_confirm")]
            m.dialog.focusButton = 1
            m.dialog_callback = "do_exit"
            m.dialog.visible = true
            m.top.dialog = m.dialog
            return true
        end if
    ' Video/Poster Grid
    else if m.content_grid.hasFocus() or m.poster_grid.hasFocus()
        ' Return to menu
        if press and (key = "left" or key = "back")
            ' Go to previous poster grid
            if m.stage = m.DYNAMIC_GRID
                set_saved_stage_info(m.DYNAMIC_GRID)
                m.poster_grid.setFocus(true)
                m.content_grid.visible = false
                m.poster_grid.visible = true
                ' Check if the poster grid is empty
                if m.poster_grid.content = invalid
                    load_menu_item(m.stage, true)
                end if
            ' Return to search
            else if m.stage = m.SEARCH
                reset()
                m.search_panel.visible = true
                m.search_panel.setFocus(true)
                m.search_panel.focus = true
            ' Menu
            else
                m.main_menu.setFocus(true)
            end if
            return true
        ' Item selected
        else if press and key = "OK"
            ' Video grid stages
            if stage_contains_video_grid()
                show_video_info_screen()
            ' Poster grid stages
            else if stage_contains_poster_grid()
                load_dynamic_grid()
            ' Search
            else if m.stage = m.SEARCH
                ' Info screen
                if m.content_grid.hasFocus()
                    show_video_info_screen()
                ' Dynamic Grid
                else if m.poster_grid.hasFocus()
                    load_dynamic_grid()
                ' Unhandled
                else
                    print "Unhandled search item OK press"
                end if
            ' Unhandled
            else
                print("Unhandled poster/video grid selection. Stage: " +  m.stage.toStr())
                return false
            end if
            return true
        end if
    ' Info screen
    else if m.info_screen.isInFocusChain()
        ' Back button - hide/go back
        if press and key = "back"
            set_saved_stage_info(m.INFO)
            ' Poster
            if stage_contains_poster_grid()
                m.poster_grid.setFocus(true)
            ' Video
            else if stage_contains_video_grid()
                m.content_grid.setFocus(true)
            ' Search
            else if m.stage = m.SEARCH
                m.content_grid.setFocus(true)
            ' Other
            else
                m.main_menu.setFocus(true)
            end if
            m.info_screen.visible = false
            m.video.control = "stop" ' Stop any pre-buffering
        end if
    ' Video
    else if m.video.hasFocus()
        ' Stop playing and hide video node
        if press and key = "back"
            hide_video()
            ' Preload again on the info screen
            preload_video()
        end if
    ' Link screen
    else if m.link_screen.isInFocusChain()
        ' Back button pressed - cancel link
        if press and key = "back"
            hide_link_screen()
            error("error_link_canceled")
        end if
    ' Settings
    else if m.settings_panel.isInFocusChain()
        ' Back - return focus to main menu
        if press and (key = "back" or key = "left")
            m.main_menu.setFocus(true)
        end if
    ' Search
    else if m.search_panel.isInFocusChain()
        ' Back
        if press and (key = "back" or key = "left")
            m.main_menu.setFocus(true)
        end if
    end if
    return false
end function

' Checks if the current stage's content is a video grid
function stage_contains_video_grid() as boolean
    return m.stage = m.POPULAR or m.stage = m.FOLLOWED or m.stage = m.DYNAMIC_GRID or m.stage = m.CREATIVE
end function

' Checks if the current stage's content is a poster grid
function stage_contains_poster_grid() as boolean
    return m.stage = m.GAMES or m.stage = m.COMMUNITIES
end function

' Load a video grid with the currently selected game/community/creative videos
function load_dynamic_grid(game_name = "" as string, game_id = "" as string, community_id = "" as string) as void
    ' Check data
    if type(m.poster_data) <> "roArray" and game_name = "" and game_id = "" and community_id = ""
        print("load_dynamic_grid: Invalid poster data")
        return
    end if
    ' Get selected game
    if game_name = "" and game_id = "" and community_id = ""
        selected_index = m.poster_grid.itemSelected
        if selected_index <> invalid and selected_index < m.poster_data.count()
            ' Set data
            poster_item = m.poster_data[selected_index]
            game_name = poster_item.name
            ' Community
            if poster_item.is_community = true
                community_id = poster_item.id.toStr()
            ' Game
            else
                game_id = poster_item.id.toStr()
            end if
        else
            print("Invalid poster selection")
            if selected_index <> invalid
                print tab(2)"Index: " + selected_index.toStr()
            else
                print tab(2)"Index: invalid"
            end if
            print tab(2)"Poster Data: " + (m.poster_data <> invalid).toStr()
        end if
    end if
    ' Save info
    save_stage_info(m.DYNAMIC_GRID)
    ' Reset
    reset(true)
    ' Load streams
    show_message("message_loading")
    m.content_grid.content = invalid
    m.twitch_api.get_streams = [{
        limit: m.MAX_VIDEOS,
        game: game_id,
        community: community_id
    }, "set_content_grid"]
    ' Title
    if m.stage = m.COMMUNITIES and community_id <> ""
        m.header.title = tr("title_community") + " " + m.ARROW + " " + game_name
    else
        m.header.title = game_name
    end if
    ' Show grid
    m.content_grid.visible = true
    m.content_grid.setFocus(true)
    m.stage = m.DYNAMIC_GRID
end function

' Show the video information screen for the current item
function show_video_info_screen() as void
    ' Get current video data
    selected_index = m.content_grid.itemSelected
    if selected_index = invalid or selected_index >= m.video_data.count() or selected_index < 0
        print("Could not show info screen: Index invalid")
        print(selected_index)
        return
    end if
    video_item = m.video_data[selected_index]
    ' Set info screen data
    m.info_screen.preview_image = video_item.thumbnail_url.replace("{width}", "292").replace("{height}", "180")
    m.info_screen.title = video_item.title
    m.info_screen.streamer = [video_item.user_name.display_name, video_item.user_name.login]
    m.info_screen.game = [video_item.game_name, video_item.game_id]
    m.info_screen.viewers = video_item.viewer_count
    m.info_screen.start_time = video_item.started_at
    m.info_screen.language = video_item.language
    m.info_screen.stream_type = video_item.type
    ' Show info screen
    save_stage_info(m.INFO)
    m.header.title = tr("title_stream") + " " + m.ARROW + " " + video_item.user_name.display_name
    m.info_screen.setFocus(true)
    m.info_screen.visible = true
    m.stage = m.INFO
    ' Start video preload
    preload_video()
end function

' Save the stage info
' @param stage id of stage calling this function
function save_stage_info(stage_id as integer) as void
    if type(m.previous_stage) <> "roArray"
        m.previous_stage = []
    end if
    ' Save position for return
    m.previous_stage[stage_id] = {
        title: m.header.title,
        stage: m.stage
    }
end function

' Set stage info
' @param stage id of stage calling this function
function set_saved_stage_info(stage_id as integer) as void
    if type(m.previous_stage) <> "roArray" or type(m.previous_stage[stage_id]) <> "roAssociativeArray"
        print "Called set_saved_stage_info without first saving stage info for stage id: " + stage_id.toStr()
        return
    end if
    m.header.title = m.previous_stage[stage_id].title
    m.stage = m.previous_stage[stage_id].stage
end function

' Initialize video node and set it to preload
' Should only be called after info_screen is populated with video data
function preload_video() as void
    master_playlist = m.twitch_api.callFunc("get_stream_url", m.info_screen.streamer[1])
    ' Setup video data
    video = createObject("roSGNode", "ContentNode")
    video.streams = [{
        url: master_playlist,
        bitrate: 0,
        quality: false
    }]
    video.adaptiveMaxStartBitrate = 800
    video.switchingStrategy = "full-adaptation"
    video.title = m.info_screen.title
    video.titleSeason = m.info_screen.game[0] + " - " + m.info_screen.streamer[0]
    video.description = m.info_screen.streamer[0]
    video.sdPosterUrl = m.info_screen.preview
    video.shortDescriptionLine1 = m.info_screen.title
    video.shortDescriptionLine2 = m.info_screen.game[0]
    video.actors = m.info_screen.streamer[0]
    video.streamFormat = "hls"
    video.live = true
    ' Set HTTP Agent
    http_agent = createObject("roHttpAgent")
    video.setHttpAgent(http_agent)
    video.httpCertificatesFile = "common:/certs/ca-bundle.crt"
    video.httpHeaders = [
        "X-Roku-Reserved-Dev-Id:",
        "Client-ID:" + m.global.secret.client_id
    ]
    video.httpSendClientCertificate = true
    ' Preload
    m.video.content = video
    m.video.control = "prebuffer"
end function

' Show and play video
' Only called by info_screen variable event
' @param event field update notifier
function play_video(event = invalid as object) as void
    ' Check if the info screen is showing an offline stream
    if m.info_screen.stream_type = "user"
        error("error_stream_offline")
        return
    ' Check state before playing. The info screen preloads and fails silently.
    ' If this happens, the video should be in a "finished" state
    else if m.video.state = "finished" or m.video.state = "error"
        error("error_video", m.video.errorCode)
        return
    end if
    ' Show video
    save_stage_info(m.VIDEO_PLAYER)
    m.stage = m.VIDEO_PLAYER
    m.video.setFocus(true)
    m.video.visible = true
    m.video.control = "play"
end function

' Load the dynamic grid for a specific game
' Only called by info_screen variable event
' @param event field update notifier
function load_dynamic_grid_for_game(event as object) as void
    m.video.control = "stop" ' Stop any pre-buffering
    ' Check game id is not empty
    game_id = m.info_screen.game[1]
    game_name = m.info_screen.game[0]
    if game_id = invalid or game_id = ""
        return
    end if
    ' Hide info screen
    'set_saved_stage_info(m.INFO)
    m.main_menu.jumpToItem = m.GAMES
    m.twitch_api.get_games = [{limit: m.MAX_POSTERS}, "set_poster_grid"]
    m.info_screen.visible = false
    m.content_grid.setFocus(true)
    m.stage = m.GAMES
    m.header.title = ""
    ' Load grid
    load_dynamic_grid(game_name, game_id)
end function

' Send an exit event (set the exit field to true for any observers)
function do_exit() as void
    m.top.setField("do_exit", true)
end function

' Handle a button selected event for a dialog
' Expects the event's getData() function to have the buttonSelected index
' The index should be 0 for cancel or 1 for confirm
function on_dialog_button_selected(event as object) as void
    ' Canceled
    if event.getData() = 0
        set_saved_stage_info(m.EXIT_DIALOG)
        m.dialog.close = true
        m.main_menu.setFocus(true)
    ' Confirmed - call callback
    else if event.getData() = 1
        if m.dialog_callback <> invalid
            eval(m.dialog_callback + "()")
        else
            print("Dialog missing callback")
        end if
    else
        print("Unknown button selected on dialog:" + event.getData().toStr())
    end if
end function

' Handle stream info and launch a video directly for a stream
' Expects TwitchAPI data for a single stream
' This will give an API error if the API returns invalid data or it cannot be
' reached.
' If no stream data is given to this an error will be displayed stating
' that the streamer could not be found or is not live
' This also closes any top level dialog if there are no errors
function on_stream_info(event as object) as void
    ' Show API error
    if type(event.getData().result) <> "roArray"
        error("error_api_fail", 1007)
        m.main_menu.setFocus(true)
        return
    ' Not found
    else if event.getData().result.count() = 0
        error("error_stream_not_found", 1008)
        m.main_menu.setFocus(true)
        return
    end if
    ' Play the video
    set_content_grid(event)
    m.content_grid.jumpToItem = 0
    m.content_grid.itemSelected = 0
    show_video_info_screen()
    play_video()
end function

' Show the message label
function show_message(message as string) as void
    ' Hide
    if message = ""
        m.message.text = ""
        m.message.visible = false
    ' Show
    else
        message = tr(message)
        m.message.text = message
        m.message.visible = true
    end if
end function

' Check if the current stage requires authentication
function stage_requires_authentication() as boolean
    return m.stage = m.FOLLOWED
end function

' Check if the app is authenticated with Twitch
function is_authenticated() as boolean
    return m.twitch_api.user_token <> invalid and m.twitch_api.user_token <> ""
end function

' Show the link screen and begin the link process
function show_link_screen() as void
    save_stage_info(m.LINK)
    m.stage = m.LINK
    m.link_screen.visible = true
    m.link_screen.do_link = true
    m.link_screen.setFocus(true)
end function

' Hide the link screen
function hide_link_screen() as void
    set_saved_stage_info(m.LINK)
    m.main_menu.setFocus(true)
    m.link_screen.visible = false
end function

' Handle a twitch token having been obtain
function on_link_token(event as object) as void
    hide_link_screen()
    token = event.getData()
    m.twitch_api.user_token = token
    load_menu_item(m.stage, true) ' Force a reload of the menu
    show_message_dialog("message_link_success")
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_TOKEN, token, "on_token_write"]
end function

' Handle a twitch link error
function on_link_error(event as object) as void
    hide_link_screen()
    error("error_link_failed", event.getData())
end function

' Handle user token being written to registry
function on_token_write(event as object) as void
    if not event.getData().result
        error("error_token_write_fail", 1010)
    end if
end function

' Handle a twitch link timeout
' This generally means that the link time has expired
' It could also mean that the API has an error, but that would usually be 
' caught on the initial call to the link API endpoint
function on_link_timeout(event as object) as void
    hide_link_screen()
    error("error_link_timeout")
end function

' Handle video state changes
function on_video_state_change(event as object) as void
    print "Video State:" + event.getData()
    ' Handle error
    if event.getData() = "error"
        print(m.video.errorMsg)
        if m.stage = m.VIDEO_PLAYER
            hide_video()
            error("error_video", m.video.errorCode)
        end if
    else if event.getData() = "finished" and m.stage = m.VIDEO_PLAYER
        hide_video()
    end if
end function

' Hide the video and show the info screen
function hide_video() as void
    set_saved_stage_info(m.VIDEO_PLAYER)
    m.info_screen.setFocus(true)
    m.info_screen.visible = true
    m.info_screen.focus = true
    m.video.control = "stop"
    m.video.visible = false
end function

' Handle the close event for the dialog
function on_dialog_closed(event as object) as void
    if m.stage = m.EXIT_DIALOG
        set_saved_stage_info(m.EXIT_DIALOG)
        m.main_menu.setFocus(true)
    end if
end function

' Handle a request from the settings menu to sign in or out
function on_settings_authentication_request(event as object) as void
    direction = event.getData()
    ' Sign in
    if direction = "in"
        load_menu_item(m.stage, true) ' Force a reload of the menu
        show_link_screen()
    ' Sign out
    else if direction = "out"
        m.twitch_api.user_token = ""
        load_menu_item(m.stage, true) ' Force a reload of the menu
        show_message_dialog("message_log_out")
        m.registry.write = [m.global.REG_TWITCH, m.global.REG_TOKEN, "", "on_token_write"]
    ' Unhandled
    else
        print("Unhandled on_settings_authentication_request:")
        print(direction)
    end if
end function

' Handle a search request
function on_search(event as object) as void
    search_type = event.getData()[0]
    term = event.getData()[1]
    reset()
    ' Video
    if search_type = m.search_panel.VIDEO
        m.content_grid.visible = true
        m.content_grid.setFocus(true)
        m.twitch_api.search = [{
            type: "streams",
            limit: m.MAX_LIMIT
            query: term
        }, "set_content_grid"]
    ' Channel
    else if search_type = m.search_panel.CHANNEL
        m.content_grid.visible = true
        m.content_grid.setFocus(true)
        m.twitch_api.search = [{
            type: "channels",
            limit: m.MAX_LIMIT
            query: term
        }, "set_content_grid"]
    ' Game
    else if search_type = m.search_panel.GAME
        m.poster_grid.visible = true
        m.poster_grid.setFocus(true)
        m.twitch_api.search = [{
            type: "games",
            limit: m.MAX_LIMIT
            query: term
        }, "set_poster_grid"]
    ' Unhandled
    else
        print "Unhandled search type: " + search_type.toStr()
    end if
    ' Set title and message
    m.header.title = tr("title_search") + " " + m.ARROW + " " + term
    show_message("message_loading")
end function