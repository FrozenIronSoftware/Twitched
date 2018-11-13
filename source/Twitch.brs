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
	   REG_HISTORY: "HISTORY",
	   REG_SEARCH: "SEARCH",
	   REG_HLS_LOCAL: "HLS",
       REG_START_MENU: "START_MENU",
       REG_VOD_BOOKMARK: "VOD_BOOKMARK",
	   VERSION: app_info.getVersion(),
	   P1080: "1080p",
	   P720: "720p",
	   P480: "480p",
	   P360: "360p",
	   P240: "240p",
	   use_local_hls_parsing: true,
       start_menu_index: 0,
	   twitched_config: {}
	})
	' Events
	screen.show()
	if m.global.secret.safe_area_overlay
	   display_safe_area(scene)
	end if
	scene.observeField("do_exit", port)
    input = createObject("roInput")
    input.setMessagePort(port)
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
       else if type(msg) = "roInputEvent"
           info = msg.getInfo()
           if info <> invalid
               scene.deep_link = {
                   contentId: info.contentId,
                   mediaType: info.mediaType
               }
           end if
	   end if
	end while
end function

' Test function that displays a string and its calculated size
' Rename actual main method to use
function main2()
    reg = CreateObject("roFontRegistry")
    scr = CreateObject("roSGScreen")
    port = CreateObject( "roMessagePort" )
    scr.SetMessagePort( port )
    usage = "Left/Right chg Face, Up/Dn chg Size, FF/REW chg Fudge Factor"
    size = 35
    s = "how now brown cow"
    loop = true
    mode = 0
    fudge = 1.0

    while loop
        scr.Clear(&hFF808080)

        bold = Int(mode/2)
        italic = mode mod 2

        f = reg.GetDefaultFont( size, bold, italic )
        w = Int( f.GetOneLineWidth( s, 10000 ) * fudge )
        h = f.GetOneLineHeight()

        txt = "w = "+w.ToStr()+" h = "+h.ToStr()

        scr.DrawRect(100, 200, w, h, &hFFFFFFFF)
        scr.DrawText(s, 100, 200, &h00FFFFFF, f)
        scr.DrawText(txt, 100, 40, &h000000FF, f)
        scr.DrawText(usage, 100, 300, &h000000FF, f)
        scr.Finish()

        while true
            msg = wait(0, port)
            if msg <> invalid and type(msg) = "roUniversalControlEvent" then
                i = msg.GetInt()
                if i =  2 ' up
                    size = size + 1
                    exit while
                else if i =  3 ' down
                    size = size - 1
                    exit while
                else if i =  4 ' left
                    mode = (mode+1) mod 4
                    exit while
                else if i =  5 ' right
                    mode = (mode-1) mod 4
                    exit while
                else if i =  6 ' select
                    exit while
                else if i =  8 ' reverse
                    fudge = fudge * 0.99
                    exit while
                else if i =  9 ' forward
                    fudge = fudge * 1.01
                    exit while
                end if
            end if
        end while
    end while
end function

' Test function that displays a label and its text's calculated size
' Rename actual main method to use
function main3()
    font_registry = CreateObject("roFontRegistry")
    font_registry.register("pkg:/resources/code_new_roman.otf")
    screen = createObject("roSGScreen")
    port = createObject("roMessagePort")
    screen.setMessagePort(port)
    scene = screen.createScene("FontTest")
    screen.show()
    label = scene.findNode("text")
    label.text = "How now brown cow How now brown cow How now brown cow How now brown cow"
    rect = scene.findNode("rect")
    font = font_registry.getFont("Code New Roman", 35, false, false)
    label.font = font
    rect.width = font.getOneLineWidth(label.text, 1920) * 1.065

    while true
        while true
            msg = wait(0, port)
        end while
    end while
end function

' Display the safe area guidelines
function display_safe_area(scene as object)
        device_info = createObject("roDeviceInfo")
        display_size = device_info.getDisplaySize()
        poster = createObject("roSGNode", "Poster")
        poster.height = display_size.h
        poster.width = display_size.w
        if poster.height = 1080
            poster.uri = "pkg:/locale/default/images/safe_area_fhd.png"
        else
            poster.uri = "pkg:/locale/default/images/safe_area_hd.png"
        end if
        scene.appendChild(poster)
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
    m.CHECK_PLAY = 1005
    m.POPULAR = 0
    m.GAMES = 1
    m.COMMUNITIES = 2
    m.FOLLOWED = 3
    m.SEARCH = 4
    m.SETTINGS = 5
    m.MENU_ITEMS = ["title_popular", "title_games",
        "title_communities", "title_followed", "title_search", "title_settings"]
    ' Components
    m.ads = invalid
    #if enable_ads
        m.ads = createObject("roSGNode", "Ads")
        ad_loading_message = m.top.findNode("ad_loading_message")
        ad_loading_message.text = tr("message_loading")
    #end if
    m.ad_container = m.top.findNode("ad_container")
    m.header = m.top.findNode("header")
    m.main_menu = m.top.findNode("main_menu")
    m.content_grid = m.top.findNode("content_grid")
    m.poster_grid = m.top.findNode("poster_grid")
    m.info_screen = m.top.findNode("info_screen")
    m.dialog = m.top.findNode("dialog")
    m.registry = m.top.findNode("registry")
    m.twitch_api = m.top.findNode("twitch_api")
    m.twitch_api_auth = m.top.findNode("twitch_api_auth")
    m.video = m.top.findNode("video")
    m.message = m.top.findNode("status_message")
    m.link_screen = m.top.findNode("link_screen")
    m.settings_panel = m.top.findNode("settings")
    m.search_panel = m.top.findNode("search")
    m.video_title = m.top.findNode("video_title")
    m.chat = m.top.findNode("chat")
    m.stream_info_timer = m.top.findNode("stream_info_timer")
    m.video_background = m.top.findNode("video_background")
    m.play_check_timer = m.top.findNode("play_check_timer")
    ' Events
    if m.ads <> invalid
        m.ads.observeField("status", "on_ads_end")
    end if
    m.registry.observeField("result", "on_callback")
    m.twitch_api.observeField("result", "on_callback")
    m.twitch_api_auth.observeField("result", "on_callback")
    m.info_screen.observeField("play_selected", "on_info_screen_play_selected")
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
    m.settings_panel.observeField("hls_local", "on_hls_local_change")
    m.settings_panel.observeField("start_menu_index", "on_start_menu_index_change")
    m.search_panel.observeField("search", "on_search")
    m.chat.observeField("blur", "on_chat_blur")
    m.stream_info_timer.observeField("fire", "update_stream_info")
    m.play_check_timer.observeField("fire", "check_play_video")
    m.poster_grid.observeField("rowItemSelected", "on_poster_item_selected")
    m.top.observeField("deep_link", "on_input_deep_link")
    ' Vars
    m.video_quality = m.global.P720
    m.last_underrun = 0
    m.did_scale_up = false
    m.last_upscale = 0
    m.video_quality_force = "auto"
    m.deep_link_start_time = invalid
    m.last_ad_position = 0
    m.theater_mode_enabled = false
    m.is_video_preloaded = false
    m.load_vod_at_time = false
    m.video_position = -1
    m.temp_poster_data = invalid
    m.dynamic_poster_id = invalid
    m.has_attempted_refresh = false
    m.bookmarks = invalid
    ' Init
    init_logging()
    init_analytics()
    init_main_menu()
    show_message("message_loading")
    m.stream_info_timer.control = "start"
    ' Load twitched config
    m.twitch_api.get_twitched_config = "on_twitched_config"
end function

' Handle twitched config json
function on_twitched_config(event as object) as void
    twitched_config = event.getData().result
    ' Parse config
    if type(twitched_config) <> "roAssociativeArray"
        printl(m.DEBUG, "Failed to load Twitched config")
        twitched_config = {}
    else
        printl(m.DEBUG, "Loaded Twitched config")
    end if
    if type(twitched_config.force_remote_hls) <> "Boolean" and type(twitched_config.force_remote_hls) <> "roBoolean"
        printl(m.DEBUG, "Twitched config missing force_remote_hls field. Defaulting to false")
        twitched_config.force_remote_hls = false
    end if
    if type(twitched_config.stream_qualities) <> "roArray"
        printl(m.DEBUG, "Twitched config missing stream_qualities field. Defaulting to empty array")
        twitched_config.stream_qualities = []
    end if
    if type(twitched_config.ad_limit_stream) <> "roInt" and type(twitched_config.ad_limit_stream) <> "Integer"
        printl(m.DEBUG, "Twitched config missing ad_limit_stream field. Defaulting to 2")
        twitched_config.ad_limit_stream = 2
    end if
    if type(twitched_config.ad_limit_vod) <> "roInt" and type(twitched_config.ad_limit_vod) <> "Integer"
        printl(m.DEBUG, "Twitched config missing ad_limit_vod field. Defaulting to 2")
        twitched_config.ad_limit_vod = 2
    end if
    if type(twitched_config.ad_interval) <> "roInt" and type(twitched_config.ad_interval) <> "Integer"
        printl(m.DEBUG, "Twitched config missing ad_interval field. Defaulting to 20 minutes (in seconds)")
        twitched_config.ad_interval = 20 * 60
    end if
    m.global.twitched_config = twitched_config
    ' Load registry data that does not need to be acted upon immediatly
    m.registry.read_multi = [m.global.REG_TWITCH, [
        m.global.REG_HLS_LOCAL,
        m.global.REG_START_MENU
    ], "on_registry_multi_read"]
end function

' Handle the initial multi read of the registry
function on_registry_multi_read(event as object) as void
    result = event.getData().result
    if type(result) = "roAssociativeArray"
        ' Set use local hls parsing defaults to true
        m.global.use_local_hls_parsing = (result[m.global.REG_HLS_LOCAL] = "true" or result[m.global.REG_HLS_LOCAL] = invalid)
        start_menu_index = result[m.global.REG_START_MENU]
        if start_menu_index <> invalid
            m.global.start_menu_index = val(start_menu_index, 0)
            if m.global.start_menu_index > m.SEARCH or m.global.start_menu_index < 0
                m.global.start_menu_index = 0
            end if
        end if
    end if
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_LANGUAGUE,
        "on_twitch_language"]
end function

' Initialize Google Analytics
function init_analytics() as void
    m.global.addField("analytics", "node", false)
    m.global.analytics = createObject("roSGNode", "Roku_Analytics:AnalyticsNode")
    m.global.analytics.debug = false
    m.global.analytics.init = {
        google: {
            trackingID: m.global.secret.google_analytics_id,
            defaultParams: {
                t: "event",
                ec: "Navigation"
            }
        }
    }
    m.global.analytics.trackEvent = {
        google: {
            ea: "App Launch"
        }
    }
end function

' Handle callback
function on_callback(event as object) as void
    callback = event.getData().callback
    if callback = "on_twitch_language"
        on_twitch_language(event)
    else if callback = "on_token_write"
        on_token_write(event)
    else if callback = "refresh_token"
        refresh_token(event)
    else if callback = "refresh_token_and_start"
        refresh_token_and_start(event)
    else if callback = "on_twitch_quality"
        on_twitch_quality(event)
    else if callback = "on_language_write"
        on_language_write(event)
    else if callback = "on_quality_write"
        on_quality_write(event)
    else if callback = "set_twitch_user_token"
        set_twitch_user_token(event)
    else if callback = "on_stream_info"
        on_stream_info(event)
    else if callback = "set_content_grid"
        set_content_grid(event)
    else if callback = "set_poster_grid"
        set_poster_grid(event)
    else if callback = "on_community_data"
        on_community_data(event)
    else if callback = "on_refreshed_token"
        on_refreshed_token(event)
    else if callback = "on_refreshed_token_start"
        on_refreshed_token_start(event)
    else if callback = "on_twitch_user_info_start"
        on_twitch_user_info_start(event)
    else if callback = "on_twitch_user_info_reload"
        on_twitch_user_info_reload(event)
    else if callback = "on_hls_data"
        on_hls_data(event)
    else if callback = "on_registry_multi_read"
        on_registry_multi_read(event)
    else if callback = "on_twitched_config"
        on_twitched_config(event)
    else if callback = "on_followed_community_data"
        on_followed_community_data(event)
    else if callback = "on_followed_game_data"
        on_followed_game_data(event)
    else if callback = "on_game_data"
        on_game_data(event)
    else if callback = "set_dynamic_content_grid"
        set_dynamic_content_grid(event)
    else if callback = "on_dynamic_follow_game_data"
        on_dynamic_follow_game_data(event)
    else if callback = "on_dynamic_follow_community_data"
        on_dynamic_follow_community_data(event)
    else if callback = "on_dynamic_follow_status_change"
        on_dynamic_follow_status_change(event)
    else if callback = "on_hls_local_write"
        on_hls_local_write(event)
    else if callback = "on_start_menu_index_write"
        on_start_menu_index_write(event)
    else if callback = "on_video_bookmark"
        on_video_bookmark(event)
    else if callback = "on_bookmark_write"
        on_bookmark_write(event)
    else
        if callback = invalid
            callback = ""
        end if
        printl(m.WARN, "on_callback: Unhandled callback: " + callback)
    end if
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
                track_deep_link("stream", args.twitch_user_name, args.twitch_user_id, invalid, args.deep_link_client)
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
                    track_deep_link("stream", user_name, user_name, invalid, args.deep_link_client)
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
                track_deep_link("VOD", invalid, invalid, video_id, args.deep_link_client)
                return
            end if
        end if
    end if
    ' Normal init
    m.main_menu.jumpToItem = m.global.start_menu_index
    m.main_menu.setFocus(true)
end function

' Send analytics data for a deep link
' All parameters are expected to be a string or invalid
function track_deep_link(link_type as object, streamer_name as object, streamer_id as object, video_id = invalid as object, deep_link_client = invalid as object) as void
    deep_link_params = ""
    if streamer_name <> invalid
        deep_link_params += "Streamer name: " + streamer_name + " "
    end if
    if streamer_id <> invalid
        deep_link_params += "Streamer ID: " + streamer_id + " "
    end if
    if video_id <> invalid
        deep_link_params += "Video ID: " + video_id + " "
    end if
    deep_link_params += "Type: " + link_type + " "
    if deep_link_client <> invalid
        deep_link_params += "Client: " + deep_link_client
    end if
    m.global.analytics.trackEvent = {
        google: {
            ea: "Deep Link",
            el: deep_link_params
        }
    }
end function

' Callback function that sets a the twitch API user token read from the registry
function set_twitch_user_token(event as object) as void
    if event.getData().result = invalid or event.getData().result = ""
        m.twitch_api.user_token = ""
        m.twitch_api_auth.user_token = ""
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
        m.twitch_api.get_games = [{limit: m.MAX_POSTERS}, "on_game_data"]
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

' Handle game data being loaded and request follows
function on_game_data(event as object) as void
    m.temp_poster_data = event.getData().result
    m.twitch_api.get_followed_games = [{limit: m.MAX_POSTERS}, "on_followed_game_data"]
end function

' Handle followed game data
function on_followed_game_data(event as object) as void
    set_poster_grid([m.temp_poster_data, event.getData().result])
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
        name = community.name
        if type(community.display_name, 3) = "roString" and community.display_name <> ""
            name = community.display_name
        end if
        item = {
            box_art_url: community.avatarImageUrl,
            name: name,
            id: community.id,
            is_community: true
        }
        data.push(item)
    end for
    m.temp_poster_data = data
    m.twitch_api.get_followed_communities = [{limit: m.MAX_POSTERS}, "on_followed_community_data"]
end function

' Handle community follows
function on_followed_community_data(event as object) as void
    follows_data = event.getData().result
    follows = []
    if type(follows_data) = "roArray"
        for each follow in follows_data
            if type(follow) = "roAssociativeArray" and follow.id <> invalid and follow.name <> invalid and follow.avatar_image_url <> invalid
                follow = {
                    box_art_url: follow.avatar_image_url,
                    name: follow.name,
                    id: follow.id,
                    is_community: true
                }
                follows.push(follow)
            end if
        end for
    end if
    set_poster_grid([m.temp_poster_data, follows])
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
    m.twitch_api_auth.cancel = true
    ' Clear message
    show_message("")
end function

' Set the poster grid with game content
' @param event roSGNodeMessage with data containing an associative array
'        {result: object twitch_get_games response}
function set_poster_grid(event as object) as void
    show_message("")
    ' Check for data
    posters = []
    follows = []
    if type(event) = "roSGNodeEvent" and type(event.getData().result) = "roArray"
        posters = event.getData().result
    else if type(event) = "roArray" and event.count() = 2 and type(event[0]) = "roArray"
        posters = event[0]
        if type(event[1]) = "roArray"
            follows = event[1]
        end if
    else
        print("set_poster_grid: invalid data")
        error("error_api_fail", 1002)
        return
    end if
    ' Check if there is no data
    if posters.count() = 0 and follows.count() = 0
        show_message("message_no_data")
    end if
    ' Set content
    m.poster_data = [posters, follows]
    content = createObject("roSGNode","ContentNode")
    main_section = content.createChild("ContentNode")
    main_section.title = ""
    if not add_posters_to_section(main_section, posters, 1003, false)
        return
    end if
    if follows.count() > 0
        follow_section = content.createChild("ContentNode")
        follow_section.title = ""
        if not add_posters_to_section(follow_section, follows, 1004, true)
            return
        end if
    end if
    m.poster_grid.content = content
end function

' Populate a section with the posters
function add_posters_to_section(section, posters, error_code, is_follows) as boolean
    for each data in posters
        ' Section title
        if section.title = ""
            if data.is_community = true ' Checked for true because it may not exist
                if is_follows
                    section.title = tr("title_followed_communities")
                else
                    section.title = tr("title_communities")
                end if
            else
                if is_follows
                    section.title = tr("title_followed_games")
                else
                    section.title = tr("title_games")
                end if
            end if
        end if
        ' Validate json
        if type(data) <> "roAssociativeArray" or data.box_art_url = invalid
            print("set_poster_grid: invalid json")
            error("error_api_fail", error_code)
            return false
        end if
        ' Add node
        node = section.createChild("PosterRowListItemData")
        node.image_url = data.box_art_url.replace("{width}", "195").replace("{height}", "280")
        node.title = clean(data.name)
    end for
    return true
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
            node.image_url = data.thumbnail_url.replace("{width}", "390").replace("{height}", "240")
        else
            node.image_url = "pkg:/locale/default/images/poster_error.png"
        end if
        node.title = clean(data.title)
        if node.title = ""
            node.title = tr("message_no_description")
        end if
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
            if data.game_name <> invalid and (m.dynamic_poster_id = invalid or m.dynamic_poster_id.is_community)
                node.game_image = m.twitch_api.callFunc("get_game_thumbnail", [data.game_name, 120, 168])
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
    ' Search
    else if m.search_panel.isInFocusChain()
        ' Back
        if press and (key = "back" or key = "left")
            m.main_menu.setFocus(true)
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
                ' Reset options
                m.header.showOptions = false
                m.header.optionsAvailable = false
                m.header.optionsText = ""
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
            ' Search
            else if m.stage = m.SEARCH
                ' Info screen
                if m.content_grid.hasFocus()
                    show_video_info_screen()
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
        ' Handle options
        else if press and key = "options"
            if m.stage = m.DYNAMIC_GRID
                follow_dynamic_game_or_community()
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
        is_vod = (m.info_screen.video_selected <> invalid)
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
        else if (not m.chat.visible) and press and key = "right" and not is_vod
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

' Use the set community or game id to follow or unfollow
function follow_dynamic_game_or_community()
    if type(m.dynamic_poster_id) = "roAssociativeArray" and m.dynamic_poster_id.is_following <> invalid and m.dynamic_poster_id.id <> invalid and m.dynamic_poster_id.is_community <> invalid
        if not m.dynamic_poster_id.is_following
            if m.dynamic_poster_id.is_community
                m.twitch_api.follow_community = [m.dynamic_poster_id.id, "on_dynamic_follow_status_change"]
            else
                m.twitch_api.follow_game = [m.dynamic_poster_id.id, "on_dynamic_follow_status_change"]
            end if
        else
            if m.dynamic_poster_id.is_community
                m.twitch_api.unfollow_community = [m.dynamic_poster_id.id, "on_dynamic_follow_status_change"]
            else
                m.twitch_api.unfollow_game = [m.dynamic_poster_id.id, "on_dynamic_follow_status_change"]
            end if
        end if
    end if
end function

' Handle a follow status update
function on_dynamic_follow_status_change(event as object) as void
    update_dynamic_follow_status(true)
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
    return m.stage = m.POPULAR or m.stage = m.FOLLOWED or m.stage = m.DYNAMIC_GRID
end function

' Checks if the current stage's content is a poster grid
function stage_contains_poster_grid() as boolean
    return m.stage = m.GAMES or m.stage = m.COMMUNITIES
end function

' Handle poster item selection
function on_poster_item_selected(event as object) as void
    load_dynamic_grid()
end function

' Load a video grid with the currently selected game/community videos
function load_dynamic_grid(game_name = "" as string, game_id = "" as string, community_id = "" as string) as void
    ' Check data
    if (type(m.poster_data) <> "roArray" or m.poster_data.count() < 2 or type(m.poster_data[0]) <> "roArray" or type(m.poster_data[1]) <> "roArray") and game_name = "" and game_id = "" and community_id = ""
        print("load_dynamic_grid: Invalid poster data")
        return
    end if
    ' Get selected game
    if game_name = "" and game_id = "" and community_id = ""
        selected_index = m.poster_grid.rowItemSelected
        if selected_index <> invalid and selected_index.count() = 2 and selected_index[0] < m.poster_data.count()
            ' Set data
            poster_item = m.poster_data[selected_index[0]][selected_index[1]]
            if type(poster_item) <> "roAssociativeArray"
                print("load_dynamic_grid: invalid poster item")
                return
            end if
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
    m.dynamic_poster_id = invalid
    if game_id <> ""
        m.dynamic_poster_id = {}
        m.dynamic_poster_id.id = game_id
        m.dynamic_poster_id.is_community = false
    else if community_id <> ""
        m.dynamic_poster_id = {}
        m.dynamic_poster_id.id = community_id
        m.dynamic_poster_id.is_community = true
    end if
    m.twitch_api.get_streams = [{
        limit: m.MAX_VIDEOS,
        game: game_id,
        community: community_id
    }, "set_dynamic_content_grid"]
    ' Title
    if m.stage = m.COMMUNITIES and community_id <> ""
        m.header.title = tr("title_community") + " " + m.ARROW + " " + game_name
    else
        m.header.title = game_name
    end if
    ' Show grid
    m.content_grid.visible = true
    m.content_grid.setFocus(true)
    ' Set stage
    m.stage = m.DYNAMIC_GRID
end function

' Set the content grid and load follow info for the active game or community
function set_dynamic_content_grid(event as object) as void
    set_content_grid(event)
    update_dynamic_follow_status()
end function

' Request the staus of the current dynamic item follow
function update_dynamic_follow_status(no_cache = false as boolean) as void
    if m.dynamic_poster_id <> invalid and m.dynamic_poster_id.id <> "" and m.dynamic_poster_id.is_community <> invalid
        if not m.dynamic_poster_id.is_community
            m.twitch_api.is_following_game = [
                {
                    id: m.dynamic_poster_id.id,
                    no_cache: no_cache
                },
                "on_dynamic_follow_game_data"]
        else
            m.twitch_api.get_followed_communities = [
                {to_id: m.dynamic_poster_id.id},
                "on_dynamic_follow_community_data"
            ]
        end if
    end if
end function

' Handle follow data for a community on the dynamic grid
function on_dynamic_follow_community_data(event as object) as void
    follows = event.getData().result
    title = ""
    is_following = false
    if type(follows) = "roArray" and follows.count() = 1
        title = tr("title_unfollow")
        is_following = true
    else
        title = tr("title_follow")
        is_following = false
    end if
    if type(m.dynamic_poster_id) = "roAssociativeArray"
        m.dynamic_poster_id.is_following = is_following
    end if
    m.header.showOptions = true
    m.header.optionsAvailable = true
    m.header.optionsText = title
end function

' Handle follow data for a game on the dynamic grid
function on_dynamic_follow_game_data(event as object) as void
    result = event.getData().result
    title = ""
    is_following = false
    if type(result) = "roAssociativeArray" and result.status = true
        title = tr("title_unfollow")
        is_following = true
    else
        title = tr("title_follow")
        is_following = false
    end if
    if type(m.dynamic_poster_id) = "roAssociativeArray"
        m.dynamic_poster_id.is_following = is_following
    end if
    m.header.showOptions = true
    m.header.optionsAvailable = true
    m.header.optionsText = title
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
    m.info_screen.preview_image = video_item.thumbnail_url.replace("{width}", "438").replace("{height}", "270")
    m.info_screen.title = clean(video_item.title)
    if m.info_screen.title = ""
        m.info_screen.title = tr("message_no_description")
    end if
    m.info_screen.streamer = [name, video_item.user_name.login, video_item.user_id]
    game_name = clean(video_item.game_name)
    if game_name = ""
        game_name = tr("title_unknown")
    end if
    m.info_screen.game = [game_name, video_item.game_id]
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
        m.video_quality = m.global.P720
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
    m.twitch_api.cancel = true
    m.is_video_preloaded = false
    m.load_vod_at_time = load_vod_at_time
    vod = m.info_screen.video_selected
    if vod = invalid
        streamer = m.info_screen.streamer[1]
        ' Fallback to ID in the event the client does not have the streamer
        ' login name
        if streamer = invalid or streamer = ""
            streamer = m.info_screen.streamer[2]
        end if
        m.twitch_api.get_hls_url = [m.twitch_api.HLS_TYPE_STREAM, streamer,
            m.video_quality, "on_hls_data"]
    else
        m.twitch_api.get_hls_url = [m.twitch_api.HLS_TYPE_VIDEO, vod.id,
            m.video_quality, "on_hls_data"]
    end if
end function

' Handle HLS data (a m3u8 link).
' @param event
function on_hls_data(event = invalid as object, load_vod_at_time = m.load_vod_at_time as boolean) as void
    vod = m.info_screen.video_selected
    master_playlist = ""
    headers = []
    drm_data = invalid
    ' User direct Twitch HLS m3u8 URL
    if event <> invalid and type(event.getData().result) = "roAssociativeArray"
        hls_data = event.getData().result
        master_playlist = hls_data.url
        headers.append(hls_data.headers)
        drm_data = hls_data.drm_data
    ' Use Twitched proxy HLS URL
    else
        printl(m.DEBUG, "Local HLS get failed. Using Twitched's HLS endpoint.")
        headers.append([
            "X-Roku-Reserved-Dev-Id: ",
            "Client-ID: " + m.global.secret.client_id,
            "X-Twitched-Version: " + m.global.VERSION,
            "Twitch-Token: " + m.twitch_api.user_token
        ])
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
    end if
    ' Setup video data
    video = createObject("roSGNode", "ContentNode")
    if drm_data <> invalid
        video.drmParams = {
            keySystem: "widevine",
            licenseServerUrl: "https://wv-keyos-twitch.licensekeyserver.com/",
            appData: drm_data
        }
    end if
    video.url = master_playlist
    video.adaptiveMaxStartBitrate = 800
    video.switchingStrategy = "full-adaptation"
    video.titleSeason = m.info_screen.streamer[0]
    if vod <> invalid
        video.title = vod.title
        video.description = vod.description
        m.video.duration = vod.duration
        video.sdBifUrl = m.twitch_api.callFunc("get_bif_url", ["sd", vod.id])
        video.hdBifUrl = m.twitch_api.callFunc("get_bif_url", ["hd", vod.id])
        video.fhdBifUrl = m.twitch_api.callFunc("get_bif_url", ["fhd", vod.id])
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
    video.httpHeaders = headers
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
            if m.video_position > -1
                position = m.video_position
                m.video_position = -1
            else
                position = m.video.position
            end if
        end if
    end if
    printl(m.DEBUG, "Video position: " + position.toStr())
    m.video.enableTrickPlay = (vod <> invalid)
    m.video.content = video
    m.video.seek = position
    if not load_vod_at_time
        m.last_ad_position = position
    end if
    if m.ads = invalid
        m.video.control = "prebuffer"
    end if
    m.is_video_preloaded = true
end function

' Set params for the play check timer
function play_video(event = invalid as object, ignore_error = false as boolean, show_ads = true as boolean) as void
    save_stage_info(m.CHECK_PLAY)
    m.stage = m.CHECK_PLAY
    m.play_params = [event, ignore_error, show_ads]
    m.play_check_timer.control = "start"
end function

' Check if the video is preloaded and play call do_play_video if true
function check_play_video(event as object) as void
    set_saved_stage_info(m.CHECK_PLAY)
    if m.play_params <> invalid and m.is_video_preloaded
        do_play_video(m.play_params[0], m.play_params[1], m.play_params[2])
        m.play_params = invalid
        m.is_video_preloaded = false
        m.play_check_timer.control = "stop"
    else
        m.play_check_timer.control = "start"
    end if
end function

' Show and play video
' Only called by info_screen variable event
' @param event object field update notifier
' @param ignore_error boolean avoid showing an error screen
' @param show_ads boolean attempt to show ads before playing
function do_play_video(event = invalid as object, ignore_error = false as boolean, show_ads = true as boolean) as void
    ' Check state before playing. The info screen preloads and fails silently.
    ' If this happens, the video should be in a "finished" state
    if (m.video.state = "finished" or m.video.state = "error") and not ignore_error and m.stage = m.VIDEO_PLAYER
        show_video_error()
        return
    end if
    ' Show ads
    if m.ads <> invalid and show_ads
        printl(m.DEBUG, "Twitch: Starting ads")
        if m.load_vod_at_time
            m.video_position = m.video.position
        else
            m.video_position = 0
        end if
        save_stage_info(m.ADS_STAGE)
        m.stage = m.ADS_STAGE
        m.ads.view = m.ad_container
        is_vod = (m.info_screen.video_selected <> invalid)
        m.ads.show_ads = [m.info_screen.streamer[1], "GV", m.video.duration, is_vod]
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
        preload_video()
        play_video(invalid, false, false)
    ' Go back to info screen
    else
        m.info_screen.setFocus(true)
        m.info_screen.focus = "true"
    end if
    track_ads_end(event.getData())
end function

' Send analytics data about the success of an ad run
function track_ads_end(success as boolean) as void
    m.global.analytics.trackEvent = {
        google: {
            ec: "Ad",
            ea: "Ads Finished",
            el: "Watched: " + success.toStr()
        }
    }
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
            if m.dialog_callback = "do_exit"
                do_exit()
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
            video.image_url = video_data.thumbnail_url.replace("{width}", "292").replace("{height}", "180")
            video.title = clean(video_data.title)
            video.id = video_data.id
            video.duration = video_data.duration_seconds
            m.info_screen.video_selected = video
        ' Play
        else
            preload_video()
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
    print tab(2)"Stage: " m.stage.toStr()
    ' Handle error
    if event.getData() = "error"
        video_error_message = m.video.errorMsg
        if video_error_message = invalid
            video_error_message = ""
        end if
        print tab(2)"Video error message: " video_error_message
        ' Don't do anthing if the error message is ignored
        if video_error_message = "ignored"
            print("+++++++++++++++++++++++++++++++++++++++++++++")
            return
        end if
        if m.stage = m.VIDEO_PLAYER or m.stage = m.CHECK_PLAY
            hide_video()
            show_video_error()
        end if
    ' Video ended
    else if event.getData() = "finished" and m.stage = m.VIDEO_PLAYER
        hide_video()
    ' Video is buffering
    else if event.getData() = "buffering" and (m.stage = m.VIDEO_PLAYER or m.stage = m.CHECK_PLAY)
        printl(m.DEBUG, "Resetting video size")
        reset_video_size()
    ' Video is playing
    else if event.getData() = "playing" and m.stage = m.VIDEO_PLAYER
        if m.theater_mode_enabled
            printl(m.DEBUG, "Setting video size to theater mode")
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
    m.video.width = 1170
    m.video.height = 657
    m.video.translation = [750, 211]
end function

' Shows a video error based on the current video source and error code
function show_video_error()
    if m.video.content <> invalid
        print m.video.content.url
    end if
    if m.video.content <> invalid and type(m.video.content.url, 3) = "roString" and len(m.video.content.url) - len(m.video.content.url.replace("/hls/", "")) <> 0
        error("error_stream_offline", m.video.errorCode)
    else
        error("error_video", m.video.errorCode)
    end if
end function

' Hide the video and show the info screen
function hide_video(reset_info_screen = true as boolean) as void
    bookmark_video()
    set_saved_stage_info(m.VIDEO_PLAYER)
    m.info_screen.setFocus(true)
    m.info_screen.visible = true
    if reset_info_screen
        m.info_screen.focus = "reset"
    else
        m.info_screen.focus = "true"
    end if
    m.ad_container.visible = false
    m.video.control = "stop"
    m.video.visible = false
    m.video_title.visible = false
    m.chat.visible = false
    m.chat.disconnect = true
    m.theater_mode_enabled = false
    m.video_background.visible = false
    m.play_params = invalid
    m.play_check_timer.control = "stop"
    m.is_video_preloaded = false
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
    if info.count() < 1 and not m.has_attempted_refresh
        m.has_attempted_refresh = true
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
    m.twitch_api_auth.refresh_twitch_token = [
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
        log_out(false, false)
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
        log_in(data.token, do_start)
        return
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
' @param do_show_message roBoolean should a log out message be shown to the user
' @param refresh_menu roBoolean should the menu be refreshed
function log_out(do_show_message = true as boolean, refresh_menu = true as boolean) as void
    m.twitch_api.cancel = true
    m.twitch_api.user_token = ""
    m.twitch_api_auth.user_token = ""
    if refresh_menu
        load_menu_item(m.stage, true) ' Force a reload of the menu
    end if
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
    old_token = ""
    if m.twitch_api.user_token <> invalid
        old_token = m.twitch_api.user_token
    end if
    printl(m.VERBOSE, "Old token: " + old_token)
    printl(m.VERBOSE, "New token: " + token)
    m.twitch_api.cancel = true
    m.twitch_api.user_token = token
    m.twitch_api_auth.user_token = token
    m.chat.token = m.twitch_api.user_token
    m.info_screen.token = m.twitch_api.user_token
    if do_start
        m.twitch_api_auth.validate_token = [{}, "on_twitch_user_info_start"]
    else
        m.twitch_api_auth.validate_token = [{}, "on_twitch_user_info_reload"]
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
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_VOD_BOOKMARK,
        "on_video_bookmark"]
end function

' Handle a video bookmark location
function on_video_bookmark(event as object) as void
    data = event.getData().result
    bookmarks = parseJson(data)
    m.bookmarks = bookmarks
    id = m.info_screen.video_selected
    m.video_position = 0
    if type(bookmarks) = "roArray"
        for each bookmark in bookmarks
            if bookmark.id = id
                m.video_position = bookmark.time
            end if
        end for
    end if
    preload_video(true)
    play_video(invalid, true)
end function

' Bookmark the current video time
function bookmark_video() as void
    if m.info_screen.video_selected = invalid or type(m.bookmarks) <> "roArray"
        return
    end if
    mark = {
        id: m.info_screen.video_selected,
        time: m.video.position
    }
    if m.bookmarks.count() >= 100
        m.bookmarks.delete(0)
    end if
    added = false
    for bookmark_index = 0 to m.bookmarks.count() - 1
        bookmark = m.bookmarks[bookmark_index]
        if bookmark.id = mark.id
            m.bookmarks[bookmark_index] = mark
            added = true
        end if
    end for
    if not added
        m.bookmarks.push(mark)
    end if
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_VOD_BOOKMARK,
        m.bookmarks, "on_bookmark_write"]
end function

' Handle bookmark being written
function on_bookmark_write(event as object) as void
    if not event.getData().result
        error("error_bookmark_write_fail", 1019)
    end if
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
    printl(m.EXTRA, "Position: " + m.video.position.toStr())
    ' Do not up/down scale if the video is not playing
    if m.video.state <> "playing"
        return
    end if
    check_play_ads()
    ' Wait 30 seconds before trying to scale
    if m.video.position < 30
        return
    end if
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
    printl(m.EXTRA, "Ad Time: " + (m.global.twitched_config.ad_interval - (m.video.position - m.last_ad_position)).toStr())
    ' Check if enough time has passed for an ad
    if m.video.position - m.last_ad_position >= m.global.twitched_config.ad_interval
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
    if (type(event) = "roBoolean" or event.getData() <> invalid) and m.video_quality_force = "auto" and m.stage = m.VIDEO_PLAYER
        ' An underrun occurred. Lower bitrate
        if (((type(event) = "roBoolean" and not event) or (type(event) = "roSGNodeEvent" and event.getData().isUnderrun))) and createObject("roDateTime").asSeconds() - m.last_underrun >= 30
            m.last_underrun = createObject("roDateTime").asSeconds()
            m.did_scale_down = true
            if m.video_quality = m.global.P1080
                m.video_quality = m.global.P720
            else if m.video_quality = m.global.P720
                m.video_quality = m.global.P480
            else if m.video_quality = m.global.P480
                m.video_quality = m.global.P360
            else if m.video_quality = m.global.P360
                m.video_quality = m.global.P240
            else if m.video_quality = m.global.P240
                return
            end if
            printl(m.INFO, "Stream underrun")
            m.chat.do_input = false
            set_saved_stage_info(m.VIDEO_PLAYER)
            preload_video(true)
            play_video(invalid, false, false)
        ' Increase bitrate
        else if type(event) = "roBoolean" and event and createObject("roDateTime").asSeconds() - m.last_upscale >= 30
            m.last_upscale = createObject("roDateTime").asSeconds()
            if m.video_quality = m.global.P240
                m.video_quality = m.global.P360
            else if m.video_quality = m.global.P360
                m.video_quality = m.global.P480
            else if m.video_quality = m.global.P480
                m.video_quality = m.global.P720
            else if m.video_quality = m.global.P720
                m.video_quality = m.global.P1080
            else if m.video_quality = m.global.P1080
                return
            end if
            printl(m.INFO, "Increasing stream quality")
            m.chat.do_input = false
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

' Handle the play button being selected on the info screen
function on_info_screen_play_selected(event as object) as void
    preload_video()
    play_video(event)
end function

' Handle HLS local settings option change
function on_hls_local_change(event as object) as void
    enabled = event.getData()
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_HLS_LOCAL,
        enabled.toStr(), "on_hls_local_write"]
    m.global.use_local_hls_parsing = enabled
end function

' Handle hls local setting being written to the registry
function on_hls_local_write(event as object) as void
    if not event.getData().result
        error("error_hls_local_write_fail", 1017)
    end if
end function

' Handle start menu index change from settings event
function on_start_menu_index_change(event as object) as void
    m.global.start_menu_index = event.getData()
    m.registry.write = [m.global.REG_TWITCH, m.global.REG_START_MENU,
        m.global.start_menu_index.toStr(), "on_start_menu_index_write"]
end function

' Handle start menu index setting being written to the registry
function on_start_menu_index_write(event as object) as void
    if not event.getData().result
        error("error_start_menu_index_write_fail", 1018)
    end if
end function

' Handle a deep link input event
' The event data should be an associative array
function on_input_deep_link(event as object) as void
    args = event.getData()
    if args <> invalid and (m.ads = invalid or not m.ads.showing_ads)
        hide_video()
        hide_video_info_screen()
        reset()
        m.stage = -1
        m.global.args = args
        deep_link_or_start()
    end if
end function
