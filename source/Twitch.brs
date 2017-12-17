' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Main entry point for the application.
' Starts the main scene
function main(args as dynamic) as void
    print("Twitched started")
    ' Load secret keys
	secret = parseJson(readAsciiFile("pkg:/secret.json"))
	' Initialize the TwitchApi "class"
	' Show the main screen
	screen = createObject("roSGScreen")
	m.port = createObject("roMessagePort")
	screen.setMessagePort(m.port)
	scene = screen.createScene("Twitch")
	scene.backExitsScene = false
	m.global = screen.getGlobalNode()
	m.global.addFields({
	   args: args, ' TODO handle deep links
	   secret: secret,
	   REG_TWITCH: "TWITCH",
	   REG_USER_NAME: "USER_NAME"
	})
	screen.show()
	' Main loop
	while true
	   msg = wait(0, m.port)
	   if type(msg) = "roSGScreenEvent" 
	       if msg.isScreenClosed() 
	           return
	       end if
	   end if
	end while
end function

' Entry point for the main scene
function init() as void
    print("Main scene started")
    ' Constants
    m.ARROW = "»"
    m.DYNAMIC_GRID = 999
    m.INFO = 1000
    m.VIDEO_PLAYER = 1001
    m.POPULAR = 0
    m.GAMES = 1
    m.CREATIVE = 2
    m.COMMUNITIES = 3
    m.FOLLOWED = 4
    m.MENU_ITEMS = ["title_popular", "title_games", "title_creative", 
        "title_communities", "title_followed"]
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
    ' Events
    m.registry.observeField("result", "on_callback")
    m.twitch_api.observeField("result", "on_callback")
    m.info_screen.observeField("play_selected", "play_video")
    m.info_screen.observeField("game_selected", "load_dynamic_grid_for_game")
    ' Init
    m.registry.read = [m.global.REG_TWITCH, m.global.REG_USER_NAME, 
        "set_twitch_user_name"]
    init_main_menu()
end function

' Handle an async callback result
' The event data is expected to be an associative array with a callback field
' The callback should expect the event passed to it with the result in the 
' result field of the data assocarray
function on_callback(event as object) as void
    callback = event.getData().callback
    error_code = eval(callback + "(event)")
    ' Compile error
    if type(error_code) = "roList"
        for each field in error_code
            print(field)
        end for
        return
    ' Runtime error
    else if type(error_code) = "Integer"
        if error_code <> &hfc and error_code <> &he2 and error_code <> &hff
            print "Callback error:" + error_code.toStr()
        end if
        return
    ' Unknown
    else
        print "An unknown error occurred whilst attempting a callback."
        print error_code
    end if
end function

' Callback function that sets a the twitch API user name read from the registry
function set_twitch_user_name(event as object) as void
    m.twitch_api.user_name = event.getData().result
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
    m.main_menu.setFocus(true)
    m.main_menu.jumpToItem = m.POPULAR
end function

' Handles an item focus event for the main menu
' Determines what content is loaded for the content grid
function on_menu_item_focused(message as object) as void
    ' Ignore if the item is already active
    if m.stage = message.getData() then return
    ' Reset
    reset()
    ' Handle selection
    ' Popular
    if message.getData() = m.POPULAR
        m.content_grid.visible = true
        m.twitch_api.get_streams = [{limit: 16}, "set_content_grid"]
    ' Games
    else if message.getData() = m.GAMES
        m.poster_grid.visible = true
        m.twitch_api.get_games = [{limit: 18}, "set_poster_grid"]
    ' Creative
    else if message.getData() = m.CREATIVE
        m.content_grid.visible = true
        ' Creative id: 488191
        m.twitch_api.get_streams = [{limit: 16, game: "488191"}, 
            "set_content_grid"]
    ' Communities
    else if message.getData() = m.COMMUNITIES
        m.poster_grid.visible = true
        m.twitch_api.get_communities = [{limit: 18}, "on_community_data"]
    ' Followed
    else if message.getData() = m.FOLLOWED
        m.content_grid.visible = true
    ' Unhandled
    else
        print("Unknown menu item focused: " + message.getData().toStr())
        return
    end if
    m.stage = message.getData()
end function

' Set the poster grid to community data
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_communities response}
function on_community_data(event as object) as void
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
            game: {
                box: {
                    medium: community.avatarImageUrl
                },
                name: community.name
            },
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
end function

' Set the poster grid with game content
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_games response}
function set_poster_grid(event as object) as void
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
    ' Set content
    m.poster_grid.content = createObject("roSGNode","ContentNode")
    for each data in m.poster_data
        ' Validate json
        if type(data) <> "roAssociativeArray" or type(data.game) <> "roAssociativeArray" or type(data.game.box) <> "roAssociativeArray"
            print("set_poster_grid: invalid json")
            error("error_api_fail", 1004)
            return
        end if
        ' Add node
        node = m.poster_grid.content.createChild("ContentNode")
        node.hdgridposterurl = data.game.box.medium
        node.sdgridposterurl = data.game.box.small
        node.shortdescriptionline1 = data.game.name
        if data.viewers <> invalid
            plural = "s"
            if data.viewers = 1 then plural = ""
            viewer_string = "{0} {1}"
            node.shortdescriptionline2 = substitute(viewer_string, data.viewers.toStr(), trs("inline_viewers", data.viewers), "", "")
        end if
    end for
end function

' Set the content grid to the data given to it
' @param event roSGNodeMessage with data containing an associative array 
'        {result: object twitch_get_streams response}
function set_content_grid(event as object) as void
    if type(event.getData().result) <> "roArray"
        error("error_api_fail", 1005)
        return
    end if
    m.video_data = event.getData().result
    m.content_grid.content = createObject("roSGNode","ContentNode")
    for each data in m.video_data
        ' Validate json data
        if type(data) <> "roAssociativeArray" or type(data.user_name) <> "roAssociativeArray" or data.thumbnail_url = invalid or data.title = invalid or data.viewer_count = invalid
            error("error_api_fail", 1006)
            return
        end if
        ' Add node
        node = m.content_grid.content.createChild("ContentNode")
        node.hdgridposterurl = data.thumbnail_url.replace("{width}", "195").replace("{height}", "120")
        node.sdgridposterurl = data.thumbnail_url.replace("{width}", "80").replace("{height}", "45")
        node.shortdescriptionline1 = data.title
        plural = "s"
        if data.viewer_count = 1 then plural = ""
        viewer_string = "{0} {1} on {2}"
        node.shortdescriptionline2 = substitute(viewer_string, data.viewer_count.toStr(), trs("inline_viewers", data.viewer_count), data.user_name.display_name, "")
    end for
end function

' Show an error message and possibly exit
function error(msg as string, error_code = invalid as object) as void
    msg = tr(msg)
    print(msg)
    ' Show error
    m.dialog.title = tr("title_error")
    m.dialog.message = msg
    if error_code <> invalid
        m.dialog.message += chr(10) + tr("title_error_code") + ": " + error_code.toStr()
        print("Error Code: " + error_code.toStr())
    end if
    m.dialog.visible = true
    m.top.dialog = m.dialog
end function

' Handles key events not handled by other components
function onKeyEvent(key as string, press as boolean) as boolean
    print("Key: " + key + " Press: " + press.toStr())
    ' Main Menu
    if m.main_menu.hasFocus() 
        ' Menu item selected
        if press and (key = "right" or key = "OK")
            ' Focus video grid
            if stage_contains_video_grid()
                m.content_grid.setFocus(true)
            ' Focus poster grid
            else if stage_contains_poster_grid()
                m.poster_grid.setFocus(true)
            ' Unhandled
            else
                print("Unhandled menu item selection")
                return false
            end if
            return true
        end if
    ' Video/Poster Grid
    else if m.content_grid.hasFocus() or m.poster_grid.hasFocus()
        ' Return to menu
        if press and (key = "left" or key = "back" or key = "rewind")
            ' Go to previous poster grid
            if m.stage = m.DYNAMIC_GRID
                set_saved_stage_info(m.DYNAMIC_GRID)
                m.poster_grid.setFocus(true)
                m.content_grid.visible = false
                m.poster_grid.visible = true
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
            ' Other
            else
                m.main_menu.setFocus(true)
            end if
            m.info_screen.visible = false
        end if
    ' Video
    else if m.video.hasFocus()
        ' Stop playing and hide video node
        if press and key = "back"
            set_saved_stage_info(m.VIDEO_PLAYER)
            m.info_screen.setFocus(true)
            m.info_screen.visible = true
            m.info_screen.focus = true
            m.video.control = "stop"
            m.video.content = invalid
            m.video.visible = false
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
            game_name = poster_item.game.name
            ' Community
            if poster_item.is_community = true
                community_id = poster_item.id.toStr()
            ' Game
            else
                game_id = poster_item.game.id.toStr()
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
    m.content_grid.content = invalid
    m.twitch_api.get_streams = [{
        limit: 16,
        game: game_id,
        community: community_id
    }, "set_content_grid"]
    ' Title
    if m.stage = m.COMMUNITIES and community <> ""
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
    if selected_index = invalid or selected_index >= m.video_data.count()
        return
    end if
    video_item = m.video_data[selected_index]
    m.info_screen.video_data = video_item
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
    print(master_playlist)
    ' Setup video data
    video = createObject("roSGNode", "ContentNode")
    video.streams = [{
        url: master_playlist,
        bitrate: 0,
        quality: false
    }]
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
    ' Preload
    m.video.content = video
    m.video.control = "prebuffer"
end function

' Show and play video
' Only called by info_screen variable event
' @param event field update notifier
function play_video(event as object) as void
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
    ' Hide info screen
    'set_saved_stage_info(m.INFO)
    m.main_menu.jumpToItem = m.GAMES
    m.twitch_api.get_games = [{limit: 18}, "set_poster_grid"]
    m.info_screen.visible = false
    m.content_grid.setFocus(true)
    m.stage = m.GAMES
    m.header.title = ""
    ' Load grid
    game_id = m.info_screen.game[1]
    game_name = m.info_screen.game[0]
    load_dynamic_grid(game_name, game_id)
end function