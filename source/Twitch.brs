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
	app_info = createObject("roAppInfo")
	m.global = screen.getGlobalNode()
	m.global.addFields({
	   args: args,
	   secret: secret,
	   language: [],
	   REG_TWITCH: "TWITCH",
	   REG_TOKEN: "TOKEN",
	   REG_TOKEN_SCOPE: "TOKEN_SCOPE",
	   REG_REFRESH_TOKEN: "REFRESH_TOKEN"
	   REG_LANGUAGUE: "LANG",
	   REG_QUALITY: "QUALITY",
	   VERSION: app_info.getVersion()
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
    m.ADS_STAGE = 1004
    m.POPULAR = 0
    m.GAMES = 1
    m.CREATIVE = 2
    m.COMMUNITIES = 3
    m.FOLLOWED = 4
    m.SEARCH = 5
    m.SETTINGS = 6
    m.MENU_ITEMS = ["title_popular", "title_games", "title_creative", 
        "title_communities", "title_followed", "title_search", "title_settings"]
    m.AD_INTERVAL = 20 * 60
    ' Quality
    m.P1080 = "1080p"
    m.P720 = "720p"
    m.P480 = "480p"
    m.P360 = "360p"
    m.P240 = "240p"
    ' Components
    m.ads = invalid
    if m.global.secret.enable_ads
        m.ads = createObject("roSGNode", "Ads")
        ad_loading_message = m.top.findNode("ad_loading_message")
        ad_loading_message.text = tr("message_loading")
    end if
    m.ad_container = m.top.findNode("ad_container")
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
    m.video_title = m.top.findNode("video_title")
    m.chat = m.top.findNode("chat")
    m.stream_info_timer = m.top.findNode("stream_info_timer")
    m.video_background = m.top.findNode("video_background")
    ' Events
    if m.ads <> invalid
        m.ads.observeField("status", "on_ads_end")
    end if
    m.registry.observeField("result", "on_callback")
    m.twitch_api.observeField("result", "on_callback")
    m.info_screen.observeField("play_selected", "play_video")
    m.info_screen.observeField("game_selected", "load_dynamic_grid_for_game")
    m.info_screen.observeField("video_selected", "on_vod_video_selected")
    m.info_screen.observeField("dialog", "on_info_screen_dialog")
    m.info_screen.observeField("options", "on_info_screen_options")
    m.dialog.observeField("buttonSelected", "on_dialog_button_selected")
    m.link_screen.observeField("linked_token", "on_link_token")
    m.link_screen.observeField("error", "on_link_error")
    m.link_screen.observeField("timeout", "on_link_timeout")
    m.video.observeField("state", "on_video_state_change")
    m.video.observeField("bufferingStatus", "on_buffer_status")
    m.dialog.observeField("wasClosed", "on_dialog_closed")
    m.settings_panel.observeField("sign_out_in", "on_settings_authentication_request")
    m.settings_panel.observeField("language", "on_language_change")
    m.settings_panel.observeField("quality", "on_quality_change")
    m.search_panel.observeField("search", "on_search")
    m.chat.observeField("blur", "on_chat_blur")
    m.stream_info_timer.observeField("fire", "update_stream_info")
    ' Vars
    m.video_quality = m.P720
    m.last_underrun = 0
    m.did_scale_up = false
    m.last_upscale = 0
    m.video_quality_force = "auto"
    m.deep_link_start_time = invalid
    m.last_ad_position = 0
    m.theater_mode_enabled = false
    ' Init
    init_logging()
    init_main_menu()
    show_message("message_loading")
    m.stream_info_timer.control = "start"
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_LANGUAGUE, 
        "on_twitch_language"]
end function

' Parse deep links (if any) and start at the specified state or do a normal
' start
function deep_link_or_start() as void
    ' Parse args
    args = m.global.args
    ' Deep link
    twitch_stream_regex = createObject("roRegex", "twitch_stream(?:_*)(.*)", "")
    twitch_video_regex = createObject("roRegex", "twitch_video(?:_*)(.*)", "")
    if args.contentId <> invalid and args.mediaType <> invalid
        ' Go to a live stream
        if twitch_stream_regex.isMatch(args.contentId) and args.mediaType = "live"
            ' Additional parameters launch (twitch_user_name or twitch_user_id supplied)
            if args.twitch_user_name <> invalid or args.twitch_user_id <> invalid
                m.twitch_api.get_streams = [{
                    limit: 1,
                    user_login: args.twitch_user_name,
                    user_id: args.twitch_user_id
                }, "on_stream_info"]
                return
            ' Extract user name from contentId
            else
                user_name = twitch_stream_regex.match(args.contentId)[1]
                if user_name <> invalid and user_name <> ""
                    m.twitch_api.get_streams = [{
                        limit: 1,
                        user_login: user_name,
                        user_id: user_name
                    }, "on_stream_info"]
                    return
                end if
            end if
        ' Go to a video
        else if twitch_video_regex.isMatch(args.contentId) and args.mediaType = "special"
            video_id = args.twitch_video_id
            if video_id = invalid
                video_id = twitch_video_regex.match(args.contentId)[1]
            end if
            if video_id <> invalid and video_id <> ""
                if args.time <> invalid and args.time <> ""
                    m.deep_link_start_time = val(args.time)
                end if
                m.twitch_api.get_videos = [{
                    limit: 1,
                    id: video_id
                }, "on_stream_info"]
                return
            end if
        end if
    end if
    ' Normal init
    m.main_menu.setFocus(true)
end function

' Callback function that sets a the twitch API user token read from the registry
function set_twitch_user_token(event as object) as void
    if event.getData().result = invalid or event.getData().result = ""
        m.twitch_api.user_token = ""
        m.chat.token = ""
        m.chat.user_name = "justinfan" + rnd(&h7fffffff).toStr()
        print("Using generic Twitch chat user name")
        deep_link_or_start()
        return
    end if
    log_in(event.getData().result)
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
    ' Set header state
    m.header.showOptions = true
    m.header.optionsAvailable = true
    m.header.optionsText = tr("title_search")
    ' Ignore if the item is already active
    if m.stage = stage and not force then return
    ' Reset
    reset(false, false)
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
            m.twitch_api.get_followed_streams = [{
                limit: m.MAX_LIMIT * 5,
            }, "set_content_grid"]
        end if
    ' Search
    else if stage = m.SEARCH
        m.search_panel.visible = true
    ' Settings
    else if stage = m.SETTINGS
        m.settings_panel.authenticated = is_authenticated()
        m.settings_panel.quality = m.video_quality_force
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
function reset(only_hide = false as boolean, reset_header_options = true as boolean) as void
    if not only_hide
        m.page = 0
        m.content_grid.content = invalid
        m.poster_grid.content = invalid
    end if
    m.header.title = invalid
    if reset_header_options
        m.header.showOptions = false
        m.header.optionsAvailable = false
        m.header.optionsText = ""
    end if
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
        node.shortdescriptionline1 = clean(data.name)
        if data.viewers <> invalid
            viewer_string = "{0} {1}"
            node.shortdescriptionline2 = substitute(viewer_string, pretty_number(data.viewers), trs("inline_viewers", data.viewers), "", "")
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
        node = m.content_grid.content.createChild("VideoGridItemData")
        if data.thumbnail_url <> "null" and data.thumbnail_url <> ""
            node.image_url = data.thumbnail_url.replace("{width}", "195").replace("{height}", "120")
        else
            node.image_url = "pkg:/locale/default/images/poster_error.png"
        end if
        node.title = clean(data.title)
        name = clean(data.user_name.display_name)
        if data.user_name.display_name = invalid or len(name) <> len(data.user_name.display_name)
            name = clean(data.user_name.login)
        end if
        ' User
        if data.type = "user" or data.type = "user_follow"
            node.description = name
        ' Stream
        else
            viewer_string = "{0} {1} {2} {3}"
            node.description = substitute(viewer_string, pretty_number(data.viewer_count), trs("inline_viewers", data.viewer_count), tr("inline_on"), name)
            if data.game_name <> invalid
                node.game_image = m.twitch_api.callFunc("get_game_thumbnail", [data.game_name, 80, 112])
            end if
        end if
    end for
end function

' Show an error message and possibly exit
function error(msg as string, error_code = invalid as object, title = "" as string, buttons = [tr("button_confirm")] as object) as void
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
    m.dialog.buttons = buttons
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
    ' Ad stage
    if m.stage = m.ADS_STAGE
        ' Ignore. Control logic is handled by the RAF once it has focus.
    ' Main Menu
    else if m.main_menu.hasFocus() 
        ' Menu item selected
        if press and (key = "right" or key = "OK")
            m.header.showOptions = false
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
        ' Search
        else if press and key = "options"
            m.header.showOptions = false
            m.main_menu.jumpToItem = m.SEARCH
            load_menu_item(m.SEARCH)
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
            hide_video_info_screen()
        end if
    ' Video
    else if m.video.hasFocus()
        ' Stop playing and hide video node
        if press and key = "back"
            hide_video(false)
            ' Preload again on the info screen
            preload_video()
        ' Play/Pause
        else if press and key = "play"
            if m.video.state = "paused"
                m.video.control = "resume"
                m.video_title.visible = false
            else if m.video.state = "playing"
                m.video.control = "pause"
                m.video_title.visible = true
            end if
        ' Show title
        else if press and key = "OK" and (m.video.state = "paused" or m.video.state = "playing")
            m.video_title.visible = not m.video_title.visible
        ' Show chat
        else if (not m.chat.visible) and press and key = "right"
            m.chat.visible = true
            m.chat.connect = m.info_screen.streamer[1]
        ' Theater mode
        else if (not m.theater_mode_enabled) and m.chat.visible and press and key = "right" and (m.video.state = "paused" or m.video.state = "playing")
            m.theater_mode_enabled = true
            resize_video_theater_mode()
        ' Disable theater mode
        else if m.theater_mode_enabled and press and key = "left"
            m.theater_mode_enabled = false
            reset_video_size()
        ' Hide chat
        else if m.chat.visible and press and key = "left"
            m.chat.visible = false
            m.chat.disconnect = true
        ' Show chat keyboard
        else if m.chat.visible and press and key = "up"
            if (is_authenticated())
                m.chat.setFocus(true)
                m.chat.do_input = true
            else
                hide_video()
                hide_video_info_screen()
                show_link_screen()
            end if
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
    ' Chat
    else if m.chat.isInFocusChain()
        ' Back
        if (press and (key = "back" or key = "left" or key = "down")) or (not press and key = "back")
            m.video.setFocus(true)
            m.chat.do_input = false
        end if
    end if
    return false
end function

' Hide the video info screen and focus whatever content is under it
function hide_video_info_screen() as void
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
    if video_item = invalid
        print("show_video_info_screen: invalid video_item")
        return
    end if
    ' Calculate valid name
    name = clean(video_item.user_name.display_name)
    if video_item.user_name.display_name = invalid or len(name) <> len(video_item.user_name.display_name)
        name = clean(video_item.user_name.login)
    end if
    ' Set info screen data
    m.info_screen.preview_image = video_item.thumbnail_url.replace("%{width}", "292").replace("%{height}", "180").replace("{width}", "292").replace("{height}", "180")
    m.info_screen.title = clean(video_item.title)
    m.info_screen.streamer = [name, video_item.user_name.login, video_item.user_id]
    m.info_screen.game = [clean(video_item.game_name), video_item.game_id]
    m.info_screen.viewers = video_item.viewer_count
    if video_item.view_count > 0
        m.info_screen.viewers = video_item.view_count
    end if
    if video_item.published_at <> invalid and video_item.published_at <> ""
        m.info_screen.start_time = video_item.published_at
    else
        m.info_screen.start_time = video_item.started_at
    end if
    m.info_screen.language = video_item.language
    m.info_screen.stream_type = video_item.type
    ' Show info screen
    save_stage_info(m.INFO)
    m.header.title = tr("title_stream") + " " + m.ARROW + " " + name
    m.info_screen.setFocus(true)
    m.info_screen.visible = true
    m.stage = m.INFO
    ' Start video preload
    m.did_scale_down = false
    if m.video_quality_force = "auto"
        m.video_quality = m.P720
    else
        m.video_quality = m.video_quality_force
    end if
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
' @param load_vod_at_time boolean should a vod reuse the last seek position
function preload_video(load_vod_at_time = true as boolean) as void
    vod = m.info_screen.video_selected
    master_playlist = ""
    if vod = invalid
        streamer = m.info_screen.streamer[1]
        ' Fallback to ID in the event the client does not have the streamer 
        ' login name
        if streamer = invalid or streamer = ""
            streamer = ":" + m.info_screen.streamer[2]
        end if
        master_playlist = m.twitch_api.callFunc("get_stream_url", [streamer, m.video_quality])
    else
        master_playlist = m.twitch_api.callFunc("get_video_url", [vod.id, m.video_quality])
    end if
    ' Setup video data
    video = createObject("roSGNode", "ContentNode")
    video.streams = [{
        url: master_playlist,
        bitrate: 0,
        quality: false
    }]
    video.adaptiveMaxStartBitrate = 800
    video.switchingStrategy = "full-adaptation"
    video.titleSeason = m.info_screen.streamer[0]
    if vod <> invalid
        video.title = vod.title
        video.description = vod.description
        m.video.duration = vod.duration
    else
        video.title = m.info_screen.title
        if m.info_screen.game[0] <> invalid and m.info_screen.game[0] <> ""
            video.titleSeason += " " + tr("inline_playing") + " " + m.info_screen.game[0]
        end if
        video.description = m.info_screen.streamer[0]
        video.shortDescriptionLine1 = m.info_screen.title
        video.shortDescriptionLine2 = m.info_screen.game[0]
        m.video.duration = 0
    end if
    video.actors = m.info_screen.streamer[0]
    video.streamFormat = "hls"
    video.live = (vod = invalid)
    ' Set HTTP Agent
    http_agent = createObject("roHttpAgent")
    video.setHttpAgent(http_agent)
    video.httpCertificatesFile = "common:/certs/ca-bundle.crt"
    video.httpHeaders = [
        "X-Roku-Reserved-Dev-Id: ",
        "Client-ID: " + m.global.secret.client_id,
        "X-Twitched-Version: " + m.global.VERSION,
        "Twitch-Token: " + m.twitch_api.user_token
    ]
    video.httpSendClientCertificate = true
    ' Set title component
    m.video_title.findNode("title").text = video.title
    m.video_title.findNode("streamer").text = video.titleSeason
    ' Preload
    position = 0
    if (load_vod_at_time or m.deep_link_start_time <> invalid) and vod <> invalid
        if m.deep_link_start_time <> invalid
            position = m.deep_link_start_time
            m.deep_link_start_time = invalid
        else
            position = m.video.position
        end if
    end if
    m.video.enableTrickPlay = (vod <> invalid)
    m.video.content = video
    m.video.seek = position
    if not load_vod_at_time
        m.last_ad_position = position
    end if
    if m.ads = invalid
        m.video.control = "prebuffer"
    end if
end function

' Show and play video
' Only called by info_screen variable event
' @param event object field update notifier
' @param ignore_error boolean avoid showing an error screen
' @param show_ads boolean attempt to show ads before playing
function play_video(event = invalid as object, ignore_error = false as boolean, show_ads = true as boolean) as void
    ' Check state before playing. The info screen preloads and fails silently.
    ' If this happens, the video should be in a "finished" state
    if (m.video.state = "finished" or m.video.state = "error") and not ignore_error and m.stage = m.VIDEO_PLAYER
        show_video_error()
        return
    end if
    ' Show ads
    if m.ads <> invalid and show_ads
        printl(m.DEBUG, "Twitch: Starting ads")
        save_stage_info(m.ADS_STAGE)
        m.stage = m.ADS_STAGE
        m.ads.view = m.ad_container
        m.ads.show_ads = [m.info_screen.streamer[1], "GV", m.video.duration]
        m.ad_container.visible = true
    ' Show video
    else
        printl(m.DEBUG, "Twitch: Starting video")
        save_stage_info(m.VIDEO_PLAYER)
        m.stage = m.VIDEO_PLAYER
        m.video.setFocus(true)
        m.video.visible = true
        m.video_background.visible = true
        m.video.control = "play"
    end if
end function

' Handle ad event finished
' @param event object roSGNode
function on_ads_end(event as object) as void
    if m.stage <> m.ADS_STAGE
        return
    end if
    printl(m.DEBUG, "Twitch: Ads finished: " + event.getData().toStr())
    set_saved_stage_info(m.ADS_STAGE)
    m.ad_container.visible = false
    ' Play video
    if event.getData()
        play_video(invalid, false, false)
    ' Go back to info screen
    else
        m.info_screen.setFocus(true)
        m.info_screen.focus = "true"
    end if
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
    if m.stage = m.EXIT_DIALOG
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
    else
        m.dialog.close = true
    end if
end function

' Handle stream info and launch a video directly for a stream
' Expects TwitchAPI data for a single stream
' This will give an API error if the API returns invalid data or it cannot be
' reached.
' If no stream data is given to this an error will be displayed stating
' that the streamer could not be found or is not live
' This also closes any top level dialog if there are no errors
'
' Roku requirements do not allow error messages shown for invalid deep links
' Errors are logged and the home screen is started on error
function on_stream_info(event as object) as void
    ' Show API error
    if type(event.getData().result) <> "roArray"
        'error("error_api_fail", 1007)
        print tr("error_api_fail")
        print tab(2)"Error: 1007"
        m.main_menu.setFocus(true)
        return
    ' Not found
    else if event.getData().result.count() = 0
        'error("error_stream_not_found", 1008)
        print tr("error_stream_not_found")
        print tab(2)"Error: 1008"
        m.main_menu.setFocus(true)
        return
    end if
    ' Show info screen
    set_content_grid(event)
    m.content_grid.jumpToItem = 0
    m.content_grid.itemSelected = 0
    show_video_info_screen()
    ' Play
    video_data = event.getData().result[0]
    if type(video_data) = "roAssociativeArray"
        ' Add VOD info
        if video_data.duration <> invalid and video_data.duration <> ""
            video = createObject("roSGNode", "VodItemData")
            video.image_url = video_data.thumbnail_url.replace("%{width}", "195").replace("%{height}", "120")
            video.title = clean(video_data.title)
            video.id = video_data.id
            video.duration = video_data.duration_seconds
            m.info_screen.video_selected = video
        ' Play
        else
            play_video()
        end if
    end if
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
    show_message_dialog("message_link_success")
    key_val = {}
    key_val[m.global.REG_TOKEN] = event.getData().token
    key_val[m.global.REG_REFRESH_TOKEN] = event.getData().refresh_token
    key_val[m.global.REG_TOKEN_SCOPE] = event.getData().scope
    m.registry.write_multi = [
        m.global.REG_TWITCH
        key_val,
        "on_token_write"
    ]
    log_in(event.getData().token, false)
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
    print "Video State: " + event.getData()
    ' Handle error
    if event.getData() = "error"
        print(m.video.errorMsg)
        if m.stage = m.VIDEO_PLAYER
            hide_video()
            show_video_error()
        end if
    ' Video ended
    else if event.getData() = "finished" and m.stage = m.VIDEO_PLAYER
        hide_video()
    ' Video is buffering
    else if event.getData() = "buffering" and m.stage = m.VIDEO_PLAYER
        reset_video_size()
    ' Video is playing
    else if event.getData() = "playing" and m.stage = m.VIDEO_PLAYER
        if m.theater_mode_enabled
            resize_video_theater_mode()
        end if
    end if
end function

' Resize the video to the normal fullscreen dimensions
function reset_video_size() as void
    m.video.width = 0
    m.video.height = 0
    m.video.translation = [0, 0]
end function

' Resize the video so it is small enough to fix next to the open chat window
function resize_video_theater_mode() as void
    m.video.width = 780
    m.video.height = 438
    m.video.translation = [500, 141]
end function

' Shows a video error based on the current video source and error code
function show_video_error()
    for each stream in m.video.content.streams
        print stream
    end for
    if m.video.content <> invalid and type(m.video.content.streams) = "roArray" and m.video.content.streams.count() = 1 and len(m.video.content.streams[0].url) - len(m.video.content.streams[0].url.replace("/hls/", "")) <> 0
        error("error_stream_offline", m.video.errorCode)
    else
        error("error_video", m.video.errorCode)
    end if
end function

' Hide the video and show the info screen
function hide_video(reset_info_screen = true as boolean) as void
    set_saved_stage_info(m.VIDEO_PLAYER)
    m.info_screen.setFocus(true)
    m.info_screen.visible = true
    if reset_info_screen
        m.info_screen.focus = "reset"
    else
        m.info_screen.focus = "true"
    end if
    m.video.control = "stop"
    m.video.visible = false
    m.video_title.visible = false
    m.chat.visible = false
    m.chat.disconnect = true
    m.theater_mode_enabled = false
    m.video_background.visible = false
    reset_video_size()
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
        log_out()
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

' Handle Twitch user info
' @param event object field event with result key
' @param do_start boolean if specified, this function will call deep_link_or_start()
function on_twitch_user_info(event as object, do_start = false as boolean) as void
    info = event.getData().result
    ' API down
    if type(info) <> "roArray"
        print("on_twitch_user_info: invalid data")
        error("error_api_fail", 1011)
        if do_start
            deep_link_or_start()
        end if
        return
    end if
    ' Invalid token. Try to refresh it
    if info.count() < 1
        print "Invalid token. Attempting to refresh"
        refresh_callback = "refresh_token"
        if do_start
            refresh_callback = "refresh_token_and_start"
        end if
        m.registry.read_multi = [
            m.global.REG_TWITCH, 
            [m.global.REG_REFRESH_TOKEN, m.global.REG_TOKEN_SCOPE], 
            refresh_callback
        ]
        return
    end if
    ' Do not call start before refresh attempt
    if do_start
        deep_link_or_start()
    end if
    user = info[0]
    if type(user) <> "roAssociativeArray"
        print("on_twitch_user_info: invalid data")
        error("error_api_fail", 1012)
        return
    end if
    ' Set user info
    if user.login = invalid or user.login = ""
        print("on_twitch_user_info: empty username")
        error("error_api_fail", 1013)
        return
    end if
    m.chat.user_name = user.login
    m.info_screen.user_name = user.login
    print("Twitch user name set")
end function

' Attempt to refresh the user token and call deep_link_or_start()
function refresh_token_and_start(event as object) as void
    refresh_token(event, true)
end function

' Attempt to refresh the user token
' @param event object registry read event
' @param do_start boolean should the app be started
function refresh_token(event as object, do_start = false as boolean) as void
    printl(m.DEBUG, "Fetched refresh token and scope from registry")
    reg_data = event.getData().result
    refresh_callback = "on_refreshed_token"
    if do_start
        refresh_callback = "on_refreshed_token_start"
    end if
    m.twitch_api.refresh_twitch_token = [
        reg_data[m.global.REG_REFRESH_TOKEN],
        reg_data[m.global.REG_TOKEN_SCOPE],
        refresh_callback
    ]
end function

' Handle refreshed token data and call deep_link_or_start()
function on_refreshed_token_start(event as object) as void
    on_refreshed_token(event, true)
end function

' Handle refreshed token data
' @param event object twitch api event
' @param do_start boolean start app
function on_refreshed_token(event as object, do_start = false as boolean) as void
    printl(m.DEBUG, "on_refreshed_token: do_start: " + do_start.toStr())
    data = event.getData().result
    if data = invalid or type(data) <> "roAssociativeArray"
        printl(m.DEBUG, "on_refreshed_token: invalid data")
        error("error_api_fail", 1016)
    else if data.error <> invalid and data.error
        printl(m.DEBUG, "Token could not be refreshed. Logging out")
        log_out(false)
    else
        printl(m.DEBUG, "Received token from refresh")
        key_val = {}
        key_val[m.global.REG_TOKEN] = data.token
        key_val[m.global.REG_REFRESH_TOKEN] = data.refresh_token
        key_val[m.global.REG_TOKEN_SCOPE] = data.scope
        m.registry.write_multi = [
            m.global.REG_TWITCH
            key_val,
            "on_token_write"
        ]
        log_in(data.token, false)
    end if
    if do_start
        deep_link_or_start()
    end if
end function

' Handle twitch user info and reload the menu
function on_twitch_user_info_reload(event as object) as void
    load_menu_item(m.stage, true) ' Force a reload of the menu
    on_twitch_user_info(event)
end function

' Handle Twitch user info and initialize the app
function on_twitch_user_info_start(event as object) as void
    on_twitch_user_info(event, true)
end function

' Remove the token from the registry and all object that require it
function log_out(do_show_message = true as boolean) as void
    m.twitch_api.user_token = ""
    load_menu_item(m.stage, true) ' Force a reload of the menu
    if do_show_message
        show_message_dialog("message_log_out")
    end if
    key_val = {}
    key_val[m.global.REG_TOKEN] = ""
    key_val[m.global.REG_REFRESH_TOKEN] = ""
    key_val[m.global.REG_TOKEN_SCOPE] = ""
    m.registry.write_multi = [
        m.global.REG_TWITCH
        key_val,
        "on_token_write"
    ]
    m.chat.token = ""
    m.chat.user_name = "justinfan" + rnd(&h7fffffff).toStr()
    m.info_screen.token = ""
    m.info_screen.user_name = ""
end function

' Add the token to objects that expect it and request user info
function log_in(token as string, do_start = true as boolean) as void
    m.twitch_api.user_token = token
    m.chat.token = m.twitch_api.user_token
    m.info_screen.token = m.twitch_api.user_token
    if do_start
        m.twitch_api.get_user_info = [{}, "on_twitch_user_info_start"]
    else
        m.twitch_api.get_user_info = [{}, "on_twitch_user_info_reload"]
    end if
    print("Twitch user token set")
end function

' Handle chat blur event
' Set focus back to video
function on_chat_blur(event as object) as void
    m.video.setFocus(true)
    m.chat.do_input = false
end function

' Handle vod video being selected
function on_vod_video_selected(event as object) as void
    id = event.getData()
    if id = invalid 
        return
    end if
    preload_video(false)
    play_video(invalid, true)
end function

' Set the dialog for the info screen
function on_info_screen_dialog(event as object) as void
    m.top.dialog = invalid
    m.top.dialog = event.getData()
end function

' Show or hide the options button
function on_info_screen_options(event as object) as void
    show = event.getData()
    m.header.showOptions = show
    m.header.optionsAvailable = show
    m.header.optionsText = ""
end function

' Update stream info
' Ignores event
function update_stream_info(event = invalid as object) as void
    if m.stage <> m.VIDEO_PLAYER or type(m.video.streamingSegment) <> "roAssociativeArray" or m.video.streamingSegment.segBitrateBps = invalid or type(m.video.streamInfo) <> "roAssociativeArray" or m.video.streamInfo.measuredBitrate = invalid or m.video.streamInfo.isUnderrun = invalid
        return
    end if
    printl(m.EXTRA, "========== Stream Info ==========")
    printl(m.EXTRA, "Bitrate: " + m.video.streamingSegment.segBitrateBps.toStr())
    printl(m.EXTRA, "Measured: " + m.video.streamInfo.measuredBitrate.toStr())
    printl(m.EXTRA, "Underrun: " + m.video.streamInfo.isUnderrun.toStr())
    printl(m.EXTRA, "Screen: " + createObject("roDeviceInfo").getVideoMode())
    printl(m.EXTRA, "Quality: " + m.video_quality)
    ' Do not up/down scale if the video is not playing
    if m.video.state <> "playing"
        return
    end if 
    check_play_ads()
    ' Check if a scale up should be tried
    if not m.did_scale_down and m.video.streamInfo.measuredBitrate - m.video.streamingSegment.segBitrateBps >= 1000000
        on_buffer_status(true)
    ' Check if there is not enough bandwidth and scale down
    else if m.video.streamingSegment.segBitrateBps > m.video.streamInfo.measuredBitrate
        on_buffer_status(false)
    end if
end function

' Try to play a mid roll ad
function check_play_ads() as void
    if m.ads = invalid or m.video = invalid or m.video.content = invalid or m.video.content.live = invalid or m.video.position = invalid or m.video.duration = invalid
        return
    end if
    printl(m.EXTRA, "Ad Time: " + (m.AD_INTERVAL - (m.video.position - m.last_ad_position)).toStr())
    ' Check if enough time has passed for an ad
    if m.video.position - m.last_ad_position >= m.AD_INTERVAL
        printl(m.DEBUG, "Twitch: Mid-roll ads")
        m.last_ad_position = m.video.position
        if m.video.content.live
            m.last_ad_position = 0
        end if
        set_saved_stage_info(m.VIDEO_PLAYER)
        preload_video(true)
        play_video(invalid, false, true)
    end if
end function

' Handle registry language data
' Defaults to the system language if there are no set languages
' @param event registry callback associative array
' @param do_load specifies if the registry should load the twitch token
function on_twitch_language(event as object) as void
    language = invalid
    if event.getData().result <> invalid and event.getData().result <> ""
        language = parseJson(event.getData().result)
    end if
    if language = invalid or language.count() = 0
        print "Using system default language"
        language = []
        device_info = createObject("roDeviceInfo")
        system_lang = device_info.getCurrentLocale()
        if system_lang = "en_US" or system_lang = "en_GB"
            language.push("en")
        else if system_lang = "fr_CA"
            language.push("fr")
        else if system_lang = "es_ES"
            language.push("es")
        else if system_lang = "de_DE"
            language.push("de")
        end if
    end if
    m.global.language = language
    ' Load the quality from the registry
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_QUALITY, 
        "on_twitch_quality"]
end function

' Handle language field change from settings
function on_language_change(event as object) as void
    if type(event.getData()) <> "roArray"
        return
    end if
    m.global.language = event.getData()
    json = formatJson(event.getData())
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_LANGUAGUE, json, 
        "on_language_write"]
end function

' Handle language being written to the registry
function on_language_write(event as object) as void
    if not event.getData().result
        error("error_language_write_fail", 1014)
    end if
end function

' Handle buffer status change
' Event can be an sgnodeevent or a boolean that represents an underrun status
function on_buffer_status(event as object) as void
    if (type(event) = "roBoolean" or event.getData() <> invalid) and m.video_quality_force = "auto"
        ' An underrun occurred. Lower bitrate
        if (((type(event) = "roBoolean" and not event) or (type(event) = "roSGNodeEvent" and event.getData().isUnderrun))) and createObject("roDateTime").asSeconds() - m.last_underrun >= 30
            printl(m.INFO, "Stream underrun")
            m.last_underrun = createObject("roDateTime").asSeconds()
            m.did_scale_down = true
            if m.video_quality = m.P1080
                m.video_quality = m.P720
            else if m.video_quality = m.P720
                m.video_quality = m.P480
            else if m.video_quality = m.P480
                m.video_quality = m.P360
            else if m.video_quality = m.P360
                m.video_quality = m.P240
            else if m.video_quality = m.P240
                return
            end if
            set_saved_stage_info(m.VIDEO_PLAYER)
            preload_video(true)
            play_video(invalid, false, false)
        ' Increase bitrate
        else if type(event) = "roBoolean" and event and createObject("roDateTime").asSeconds() - m.last_upscale >= 30
            printl(m.INFO, "Increasing stream quality")
            m.last_upscale = createObject("roDateTime").asSeconds()
            if m.video_quality = m.P240
                m.video_quality = m.P360
            else if m.video_quality = m.P360
                m.video_quality = m.P480
            else if m.video_quality = m.P480
                m.video_quality = m.P720
            else if m.video_quality = m.P720
                m.video_quality = m.P1080
            else if m.video_quality = m.P1080
                return
            end if
            set_saved_stage_info(m.VIDEO_PLAYER)
            preload_video(true)
            play_video(invalid, false, false)
        end if
    end if
end function

' Handle settings panel quality change event
function on_quality_change(event as object) as void
    if event.getData() = invalid or event.getData() = ""
        return
    end if
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_QUALITY, 
        event.getData(), "on_quality_write"]
    m.video_quality_force = event.getData()
end function

' Handle quality being written to the registry
function on_quality_write(event as object) as void
    if not event.getData().result
        error("error_language_write_fail", 1015)
    end if
end function

' Handle twitch quality loaded from the registry
function on_twitch_quality(event as object) as void
    quality = event.getData().result
    ' Force a quality
    if quality <> invalid and quality <> ""
        m.video_quality_force = quality
    end if
    ' Load the user token from the registry / start the main application flow
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_TOKEN, 
        "set_twitch_user_token"]
end function