' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the TwitchApi component
function init() as void
    m.port = createObject("roMessagePort")
    ' Constants
    m.API_KRAKEN = "https://www.twitched.org/api/twitch/kraken" ' Kraken endpoint
    m.API_HELIX = "https://www.twitched.org/api/twitch/helix" ' Helix endpoint
    m.API = "https://www.twitched.org/api" ' Twitched Root API
    m.API_RAW = "https://api.twitch.tv/api" ' Twitch Raw (undocumented) endpoint [It's bloody raw - Gordon Ramsay]
    m.API_USHER = "https://usher.ttvnw.net" ' Twitch Raw (undocumented) endpoint
    m.API_VIZIMA = "https://vizima.twitch.tv/api" ' Twitch keyserver API
    m.top.setField("AUTH_URL", "https://twitched.org/link") ' User web endpoint
    m.top.HLS_TYPE_STREAM = 0
    m.top.HLS_TYPE_VIDEO = 1
    if m.global.secret.api_kraken <> invalid
        m.API_KRAKEN = m.global.secret.api_kraken
    end if
    if m.global.secret.api_helix <> invalid
        m.API_HELIX = m.global.secret.api_helix
    end if
    if m.global.secret.api <> invalid
        m.API = m.global.secret.api
    end if
    if m.global.secret.api_kraken <> invalid or m.global.secret.api_helix <> invalid or m.global.secret.api <> invalid
        print "== USING DEV API! =="
    end if
    m.GAME_THUMBNAIL_URL = "https://static-cdn.jtvnw.net/ttv-boxart/{name}-{width}x{height}.jpg"
    ' HTTP Api
    initialize_http_agent()
    initialize_twitch_http_agent()
    ' Variables
    m.callback = invalid
    m.hls_url_params = invalid
    m.parse_json = true
    m.hls_playlist = invalid
    m.last_twitch_token = ""
    m.last_twitch_sig = ""
    ' Events
    m.top.observeField("get_streams", m.port)
    m.top.observeField("get_games", m.port)
    m.top.observeField("get_communities", m.port)
    m.top.observeField("get_link_code", m.port)
    m.top.observeField("get_link_status", m.port)
    m.top.observeField("cancel", m.port)
    m.top.observeField("get_followed_streams", m.port)
    m.top.observeField("search", m.port)
    m.top.observeField("get_user_info", m.port)
    m.top.observeField("get_badges", m.port)
    m.top.observeField("user_token", m.port)
    m.top.observeField("get_videos", m.port)
    m.top.observeField("get_follows", m.port)
    m.top.observeField("follow_channel", m.port)
    m.top.observeField("unfollow_channel", m.port)
    m.top.observeField("get_ad_server", m.port)
    m.top.observeField("refresh_twitch_token", m.port)
    m.top.observeField("validate_token", m.port)
    m.top.observeField("get_hls_url", m.port)
    m.top.observeField("get_twitched_config", m.port)
    m.top.observeField("get_followed_communities", m.port)
    m.top.observeField("get_followed_games", m.port)
    m.top.observeField("is_following_game", m.port)
    m.top.observeField("follow_community", m.port)
    m.top.observeField("follow_game", m.port)
    m.top.observeField("unfollow_community", m.port)
    m.top.observeField("unfollow_game", m.port)
    ' Task init
    init_logging()
    m.top.functionName = "run"
    m.top.control = "RUN"
end function

' Main task loop
function run() as void
    print("Twitch API task started")
    while true
        msg = wait(0, m.port)
        if type(msg) = "roUrlEvent"
            on_http_response(msg)
        else if type(msg) = "roSGNodeEvent"
            if msg.getField() = "get_streams"
                get_streams(msg)
            else if msg.getField() = "get_games"
                get_games(msg)
            else if msg.getField() = "get_communities"
                get_communities(msg)
            else if msg.getField() = "get_link_code"
                get_link_code(msg)
            else if msg.getField() = "get_link_status"
                get_link_status(msg)
            else if msg.getField() = "cancel"
                initialize_http_agent()
                initialize_twitch_http_agent()
            else if msg.getField() = "get_followed_streams"
                get_followed_streams(msg)
            else if msg.getField() = "search"
                search(msg)
            else if msg.getField() = "get_user_info"
                get_user_info(msg)
            else if msg.getField() = "get_badges"
                get_badges(msg)
            else if msg.getField() = "user_token"
                initialize_http_agent()
                initialize_twitch_http_agent()
            else if msg.getField() = "get_videos"
                get_videos(msg)
            else if msg.getField() = "get_follows"
                get_follows(msg)
            else if msg.getField() = "follow_channel"
                follow_channel(msg)
            else if msg.getField() = "unfollow_channel"
                unfollow_channel(msg)
            else if msg.getField() = "get_ad_server"
                get_ad_server(msg)
            else if msg.getField() = "refresh_twitch_token"
                refresh_twitch_token(msg)
            else if msg.getField() = "validate_token"
                validate_token(msg)
            else if msg.getField() = "get_hls_url"
                get_hls_url(msg)
            else if msg.getField() = "get_twitched_config"
                get_twitched_config(msg)
            else if msg.getField() = "get_followed_communities"
                get_followed_communities(msg)
            else if msg.getField() = "get_followed_games"
                get_followed_games(msg)
            else if msg.getField() = "is_following_game"
                is_following_game(msg)
            else if msg.getField() = "follow_community"
                follow_community(msg)
            else if msg.getField() = "follow_game"
                follow_game(msg)
            else if msg.getField() = "unfollow_community"
                unfollow_community(msg)
            else if msg.getField() = "unfollow_game"
                unfollow_game(msg)
            end if
        end if
    end while
end function

' Initialize the http agent
function initialize_http_agent() as void
    if m.http <> invalid
        m.http.asyncCancel()
        m.callback = invalid
    end if
    m.http = createObject("roUrlTransfer")
    m.http.setMessagePort(m.port)
    m.http.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.http.addHeader("X-Roku-Reserved-Dev-Id", "") ' Automatically populated
    m.http.addHeader("Client-ID", m.global.secret.client_id)
    m.http.addHeader("X-Twitched-Version", m.global.VERSION)
    m.http.addHeader("Twitch-Token", m.top.user_token)
    m.http.initClientCertificates()
end function

' Make an API request for a list of streams
' @param params array of parameters [associative request_params, string callback]
' @return JSON data or invalid on error
function get_streams(params as object) as void
    request_url = m.API_HELIX + "/streams"
    passed_params = params.getData()[0]
    ' Construct parameter array
    url_params = []
    if passed_params.after <> invalid
        url_params.push("after=" + m.http.escape(passed_params.after.toStr()))
    end if
    if passed_params.before <> invalid
        url_params.push("before=" + m.http.escape(passed_params.before.toStr()))
    end if
    if passed_params.community <> invalid and passed_params.community <> ""
        url_params.push("community_id=" + m.http.escape(passed_params.community.toStr()))
    end if
    if passed_params.first <> invalid
        url_params.push("first=" + m.http.escape(passed_params.first.toStr()))
    end if
    if passed_params.game <> invalid and passed_params.game <> ""
        url_params.push("game_id=" + m.http.escape(passed_params.game.toStr()))
    end if
    if passed_params.lang <> invalid
        url_params.push("language=" + m.http.escape(passed_params.lang.toStr()))
    end if
    if passed_params.type <> invalid
        url_params.push("type=" + m.http.escape(passed_params.type.toStr()))
    end if
    if passed_params.user_id <> invalid
        url_params.push("user_id=" + m.http.escape(passed_params.user_id.toStr()))
    end if
    if passed_params.user_login <> invalid
        url_params.push("user_login=" + m.http.escape(passed_params.user_login.toStr()))
    end if
    ' Non spec
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    ' Add globally defined language
    language_all = false
    for each lang in m.global.language
        if lang = "all"
            language_all = true
        end if
    end for
    if not language_all
        for each lang in m.global.language
            url_params.push("language=" + m.http.escape(lang.toStr()))
        end for
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Make an API request for a list of games
' @param params array of parameters [associative request_params, string callback]
' @return JSON data or invalid on error
function get_games(params as object) as void
    request_url = m.API_HELIX + "/games/top"
    passed_params = params.getData()[0]
    ' Construct parameter array
    url_params = []
    if passed_params.after <> invalid
        url_params.push("after=" + m.http.escape(passed_params.after.toStr()))
    end if
    if passed_params.before <> invalid
        url_params.push("before=" + m.http.escape(passed_params.before.toStr()))
    end if
    if passed_params.first <> invalid
        url_params.push("first=" + m.http.escape(passed_params.first.toStr()))
    end if
    ' Non-spec
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Make an async request, automatically handling the callback result and setting it to
' the result field
' A JSON parse is attempted, so the expected data should be JSON
' @param req type of request GET or POST
' @param request_url base URL to call with no parameters
' @param paramas array of string parameters to append in the format "key=value"
' @param callback callback string to embed in result
' @param data optional post body to send
function request(req as string, request_url as string, params as object, callback as string, data = "" as string, http_agent = m.http as object, parse_json = true as boolean) as void
    ' Construct URL from parameter array
    separator = "?"
    if not params.isEmpty()
        for each param in params
            request_url += separator + param
            separator = "&"
        end for
    end if
    ' Make the HTTP request
    m.callback = callback
    m.parse_json = parse_json
    if req = "GET"
        get(request_url, http_agent)
    else if req = "POST"
        'response = post(request_url, data, http_agent)
        ' TODO handle post
    end if
end function

' Event callback for an http response
' set the result data if the status is not an error
function on_http_response(event as object) as void
    ' Transfer not complete
    if event.getInt() <> 1 or m.callback = invalid then return
    ' Canceled
    if event.getResponseCode() = -10001 or event.getFailureReason() = "Cancelled"
        return
    ' Fail
    else if event.getResponseCode() <> 200
        url = "Unknown"
        if m.http <> invalid and event.getSourceIdentity() = m.http.getIdentity()
            url = m.http.getUrl()
        else if m.http_twitch <> invalid and event.getSourceIdentity() = m.http_twitch.getIdentity()
            url = m.http_twitch.getUrl()
        end if
        print "HTTP request failed:"
        print tab(2)"URL: " + url
        print tab(2)"Status Code: " + event.getResponseCode().toStr()
        print tab(2)"Reason: " + event.getFailureReason()
        print tab(2)"Body: " + event.getString()
        print tab(2)"Headers: "
        for each header in event.getResponseHeadersArray()
            print tab(4)header + ": " + event.getResponseHeadersArray()[header]
        end for
    end if
    ' Response
    response = event.getString()
    ' Parse
    json = response
    if m.parse_json
        json = parseJson(json)
    else if event.getResponseCode() <> 200
        json = invalid
    end if
    ' Handle internal callback
    callback = m.callback
    m.callback = invalid
    if callback <> invalid and callback.left(1) = "_"
        event = {
            callback: callback,
            result: json
        }
        if callback = "_on_hls_access_token"
            _on_hls_access_token(event)
        else if callback = "_on_hls_playlist"
            _on_hls_playlist(event)
        else if callback = "_on_keyserver_data"
            _on_keyserver_data(event)
        else
            if callback = invalid
                callback = ""
            end if
            print("TwitchApi: Unhandled callback: " + callback)
        end if
    ' Send callback event
    else
        m.top.setField("result", {
            callback: callback
            result: json
        })
    end if
end function

' Make an API request for a list of communities
' @param params array of parameters [associative request_params, string callback]
' @return JSON data or invalid on error
function get_communities(params as object) as void
    request_url = m.API_KRAKEN + "/communities/top"
    passed_params = params.getData()[0]
    ' Construct parameter array
    url_params = []
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Helper function to request a URL in an asynchronous fashion
function get(request_url as string, http_agent as object) as void
    print "Get request to " + request_url
    http_agent.setRequest("GET")
    http_agent.setUrl(request_url)
    http_agent.asyncGetToString()
end function

' Get stream HLS URL for a streamer
' @param params array [streamer, video_quality]
function get_stream_url(params as object) as string
    return (m.API + "/twitch/hls/60/" + params[1] + "/" + get_device_model() + "/" + params[0] + "+" + params[1] + ".m3u8").encodeUri().replace("+", "%2B")
end function

' Get video HLS URL for a video id
' @param params array [video_id, video_quality]
function get_video_url(params as object) as string
    return (m.API + "/twitch/vod/60/" + params[1] + "/" + get_device_model() + "/" + params[0] + "+" + params[1] + ".m3u8").encodeUri().replace("+", "%2B")
end function

' Get bif url
' @param params array [quality, video_id]
function get_bif_url(params as object) as string
    return (m.API + "/bif/" + params[1] + "/" + params[0] + ".bif").encodeUri()
end function

' Get the device model info string
' The model number is sanitized. The first numbers are kept and any letters are
' discarded. An X will be append to the numbers.
' Example: 8000EU becomes 8000X
' If the format is not matched, the unmodified model will be returned.
function get_device_model() as string
    device_info = createObject("roDeviceInfo")
    model_regex = createObject("roRegex", "([0-9]*).*", "")
    match = model_regex.match(device_info.getModel())
    if match.count() <> 2 or (type(match[1], 3) <> "roString" and type(match[1], 3) <> "String")
        return device_info.getModel()
    end if
    return match[1] + "X"
end function

' Request a link code from the API
' @param params is expected to be an event with data being a string callback
function get_link_code(params as object) as void
    device_info = createObject("roDeviceInfo")
    request_url = m.API + "/link"
    ' Params
    url_params = [
        "type=roku",
        "id=" + m.http.escape(device_info.getClientTrackingId())
    ]
    request("GET", request_url, url_params, params.getData())
end function

' Request the link status from the API
' @param params is expected to be an event with data being a string callback
function get_link_status(params as object) as void
    device_info = createObject("roDeviceInfo")
    request_url = m.API + "/link/status"
    ' Params
    url_params = [
        "type=roku",
        "id=" + m.http.escape(device_info.getClientTrackingId())
    ]
    request("GET", request_url, url_params, params.getData())
end function

' Request followed streams from the API for a user
' @param params array of parameters [associative request_params, string callback]
function get_followed_streams(params as object) as void
    request_url = m.API_HELIX + "/users/follows/streams"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request a search from the API
' @param array of parameters [associative request_params, string callback]
function search(params as object) as void
    request_url = m.API_KRAKEN + "/search"
    passed_params = params.getData()[0]
    url_params = []
    ' All
    if passed_params.query <> invalid
        url_params.push("query=" + m.http.escape(passed_params.query.toStr()))
    end if
    if passed_params.type <> invalid
        url_params.push("type=" + m.http.escape(passed_params.type.toStr()))
    end if
    ' Streams/Channels       / (Games?)
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    if passed_params.hls <> invalid
        url_params.push("hls=" + m.http.escape(passed_params.hls.toStr()))
    end if
    ' Games
    if passed_params.live <> invalid
        url_params.push("live=" + m.http.escape(passed_params.live.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request user data with the current token
' @param array of parameters [associative request_params, string callback]
function get_user_info(params as object) as void
    request_url = m.API_HELIX + "/users"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.login <> invalid
        url_params.push("login=" + m.http.escape(passed_params.login))
    end if
    if passed_params.id <> invalid
        url_params.push("id=" + m.http.escape(passed_params.id.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Get badges JSON directly from Twitch
' @param params is expected to be an event with data being a string callback
function get_badges(params as object) as void
    request_url = "https://badges.twitch.tv/v1/badges/global/display"
    request("GET", request_url, [], params.getData())
end function

' Request videos from the API
' @param array of parameters [associative request_params, string callback]
function get_videos(params as object) as void
    request_url = m.API_HELIX + "/videos"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.id <> invalid
        url_params.push("id=" + m.http.escape(passed_params.id.toStr()))
    end if
    if passed_params.user_id <> invalid
        url_params.push("user_id=" + m.http.escape(passed_params.user_id.toStr()))
    end if
    if passed_params.after <> invalid
        url_params.push("after=" + m.http.escape(passed_params.after.toStr()))
    end if
    if passed_params.before <> invalid
        url_params.push("before=" + m.http.escape(passed_params.before.toStr()))
    end if
    if passed_params.first <> invalid
        url_params.push("first=" + m.http.escape(passed_params.first.toStr()))
    end if
    if passed_params.language <> invalid
        url_params.push("language=" + m.http.escape(passed_params.language.toStr()))
    end if
    if passed_params.period <> invalid
        url_params.push("period=" + m.http.escape(passed_params.period.toStr()))
    end if
    if passed_params.sort <> invalid
        url_params.push("sort=" + m.http.escape(passed_params.sort.toStr()))
    end if
    if passed_params.type <> invalid and passed_params.type <> ""
        url_params.push("type=" + m.http.escape(passed_params.type.toStr()))
    end if
    if passed_params.game_id <> invalid
        url_params.push("game_id=" + m.http.escape(passed_params.game_id.toStr()))
    end if
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request followed channels from the API for a user
' @param params array of parameters [associative request_params, string callback]
function get_follows(params as object) as void
    request_url = m.API_HELIX + "/users/follows"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.after <> invalid
        url_params.push("after=" + m.http.escape(passed_params.after.toStr()))
    end if
    if passed_params.before <> invalid
        url_params.push("before=" + m.http.escape(passed_params.before.toStr()))
    end if
    if passed_params.first <> invalid
        url_params.push("first=" + m.http.escape(passed_params.first.toStr()))
    end if
    if passed_params.from_id <> invalid
        url_params.push("from_id=" + m.http.escape(passed_params.from_id.toStr()))
    end if
    if passed_params.to_id <> invalid
        url_params.push("to_id=" + m.http.escape(passed_params.to_id.toStr()))
    end if
    if passed_params.from_login <> invalid and passed_params.from_login <> ""
        url_params.push("from_login=" + m.http.escape(passed_params.from_login.toStr()))
    end if
    if passed_params.to_login <> invalid and passed_params.to_login <> ""
        url_params.push("to_login=" + m.http.escape(passed_params.to_login.toStr()))
    end if
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    if passed_params.no_cache <> invalid
        url_params.push("no_cache=" + m.http.escape(passed_params.no_cache.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request API to follow a channel
' @param params array of parameters [associative request_params, string callback]
function follow_channel(params as object) as void
    request_url = m.API_KRAKEN + "/users/follows/follow"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.id <> invalid
        url_params.push("id=" + m.http.escape(passed_params.id.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request API to unfollow a channel
' @param params array of parameters [associative request_params, string callback]
function unfollow_channel(params as object) as void
    request_url = m.API_KRAKEN + "/users/follows/unfollow"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.id <> invalid
        url_params.push("id=" + m.http.escape(passed_params.id.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Return a game thumbnail url
' @param params array [string game_name, int width, int height]
function get_game_thumbnail(params as object) as string
    game_name = params[0]
    if game_name = invalid or (type(game_name) <> "roString" and type(game_name) <> "String" and type(game_name) <> "string")
        return ""
    end if
    return m.GAME_THUMBNAIL_URL.replace("{name}", game_name.encodeUri()).replace("{width}", params[1].toStr()).replace("{height}", params[2].toStr())
end function

' Request ad server from Twitched's API
' @param params field event expected to be an event with data being a string callback
function get_ad_server(params) as void
    request_url = m.API + "/ad/server"
    ' Params
    url_params = [
        "type=roku"
    ]
    request("GET", request_url, url_params, params.getData())
end function

' Request a token refresh from the Twitch API
' @param params array [string refresh_token, string token_scope, string callback]
function refresh_twitch_token(params) as void
    refresh_token = params.getData()[0]
    token_scope = params.getData()[1]
    callback = params.getData()[2]
    request_url = m.API + "/link/refresh"
    url_params = []
    if refresh_token <> invalid
        url_params.push("refresh_token=" + m.http.escape(refresh_token))
    end if
    if token_scope <> invalid
        url_params.push("scope=" + m.http.escape(token_scope))
    end if
    request("GET", request_url, url_params, callback)
end function

' Get info for the current token
' @param array of parameters [associative request_params, string callback]
function validate_token(params as object) as void
    request_url = m.API + "/link/validate"
    request("GET", request_url, [], params.getData()[1])
end function

' Get access data and construct a URL for an HLS endpoint
' @param event with data containing and array of parameters [integer hls_type,
'        string stream_id, string quality, string callback,
'        boolean force_fetch]
'        if force_fetch is true the global config and local config will be
'        ignored even if they dictate a fetch should fail
function get_hls_url(params as object) as void
    passed_params = params.getData()
    ' Return invalid so the server is called for HLS playlists
    force_fetch = false
    if passed_params[4] <> invalid and passed_params[4]
        force_fetch = passed_params[4]
    end if
    if ((not m.global.use_local_hls_parsing) or m.global.twitched_config.force_remote_hls) and (not force_fetch)
        m.top.setField("result", {
            callback: passed_params[3]
            result: invalid
        })
        return
    end if
    hls_url_params = {
        type: passed_params[0],
        id: passed_params[1],
        quality: passed_params[2],
        callback: passed_params[3],
        force_fetch: force_fetch,
        drm_data: invalid
    }
    ' If the ID is the same as the stored value use the cached data
    if m.hls_url_params <> invalid and m.hls_url_params.id = hls_url_params.id
        print "Using cached playlist data. IDs: " + hls_url_params.id + " - " + hls_url_params.id
        if type(m.hls_playlist, 3) = "roString"
            m.hls_url_params = hls_url_params
            clean_master_playlist()
            return
        end if
    end if
    m.hls_playlist = invalid
    m.hls_url_params = hls_url_params
    ' Start the access token flow
    url = invalid
    ' Stream
    if m.hls_url_params.type = m.top.HLS_TYPE_STREAM
        url = m.API_RAW + "/channels/" + m.hls_url_params.id + "/access_token"
    ' Video
    else if m.hls_url_params.type = m.top.HLS_TYPE_VIDEO
        url = m.API_RAW + "/vods/" + m.hls_url_params.id + "/access_token"
    ' Error
    else
        m.top.setField("result", {
            callback: m.hls_url_params.callback
            result: invalid
        })
        return
    end if
    ' Request access token
    request("GET", url, [], "_on_hls_access_token", "", m.http_twitch)
end function

' Handle HLS access data
' @param event roAssociativeArray internal event (not a field event)
function _on_hls_access_token(event as object) as void
    data = event.result
    ' Valid data
    if type(data) = "roAssociativeArray"
        m.hls_url_params.access_token = data
        url = ""
        url_params = []
        ' Stream
        if m.hls_url_params.type = m.top.HLS_TYPE_STREAM
            url = m.API_USHER + "/api/channel/hls/" + m.hls_url_params.id + ".m3u8"
            url_params.push("player=Twitched")
            url_params.push("token=" + m.http_twitch.escape(data.token))
            url_params.push("sig=" + m.http_twitch.escape(data.sig))
            url_params.push("p=" + m.http_twitch.escape(rnd(&h7fffffff).toStr()))
            url_params.push("type=any")
            url_params.push("allow_audio_only=true")
            url_params.push("allow_source=true")
            url_params.push("playlist_include_framerate=true")
            url_params.push("cdm=wv")
            url_params.push("max_level=52")
        ' Video
        else if m.hls_url_params.type = m.top.HLS_TYPE_VIDEO
            url = m.API_USHER + "/vod/" + m.hls_url_params.id + ".m3u8"
            url_params.push("player=Twitched")
            url_params.push("nauth=" + m.http_twitch.escape(data.token))
            url_params.push("nauthsig=" + m.http_twitch.escape(data.sig))
            url_params.push("p=" + m.http_twitch.escape(rnd(&h7fffffff).toStr()))
            url_params.push("type=any")
            url_params.push("allow_audio_only=true")
            url_params.push("allow_source=true")
            url_params.push("playlist_include_framerate=true")
            url_params.push("cdm=wv")
            url_params.push("max_level=52")
        ' Error
        else
            m.top.setField("result", {
                callback: m.hls_url_params.callback
                result: invalid
            })
            return
        end if
        ' Get Playlist
        request("GET", url, url_params, "_on_hls_playlist", "", m.http_twitch, false)
    ' Error
    else
        m.top.setField("result", {
            callback: m.hls_url_params.callback
            result: invalid
        })
    end if
end function

' Handle HLS m3u8 playlist string
function _on_hls_playlist(event as object) as void
    data = event.result
    m.hls_playlist = data
    request_twitch_keyserver_data()
end function

' Request keyserver auth data from Twitch
function request_twitch_keyserver_data() as void
    url = m.API_VIZIMA + "/authxml/" + m.hls_url_params.id
    url_params = []
    url_params.push("token=" + m.http_twitch.escape(m.hls_url_params.access_token.token))
    url_params.push("sig=" + m.http_twitch.escape(m.hls_url_params.access_token.sig))
    request("GET", url, url_params, "_on_keyserver_data", "", m.http_twitch, false)
end function

' Handle keyserver data
function _on_keyserver_data(event as object) as void
    data = event.result
    m.hls_url_params.drm_data = data
    clean_master_playlist()
end function

' Cleans the master playlist saved
' This function saves the playlist to tmp: and sets the result to
function clean_master_playlist() as void
    ' Check if all paramerters are present
    if type(m.hls_playlist, 3) <> "roString" or type(m.hls_url_params.quality, 3) <> "roString" or type(m.hls_url_params.callback, 3) <> "roString" or type(m.hls_url_params.id, 3) <> "roString"
        m.top.setField("result", {
            callback: m.hls_url_params.callback
            result: invalid
        })
        return
    end if
    ' Clean the playlist
    max_quality = get_max_quality_for_model(m.hls_url_params.quality, get_device_model())
    new_line_regex = createObject("roRegex", chr(13) + "?" + chr(10), "")
    lines = new_line_regex.split(m.hls_playlist)
    master_playlist = []
    playlists = []
    for line_index = 0 to lines.count() - 1
        line = lines[line_index]
        ' Not media line
        if instr(0, line, "#EXT-X-MEDIA") = 0
            master_playlist.push(line)
        ' Media line
        else
            ' EOF - add line but do not force add others
            if line_index + 2 >= lines.count()
                master_playlist.push(line)
            ' Add line and two after it to playlists list
            else
                playlists.push({
                    line_one: line,
                    line_two: lines[line_index + 1],
                    line_three: lines[line_index + 2]
                })
                line_index += 2
            end if
        end if
    end for
    ' Add compatible playlists
    playlists_meeting_quality = []
    for each playlist in playlists
        if stream_meets_quality(max_quality, playlist) and is_stream_video(playlist)
            playlists_meeting_quality.push(playlist)
        end if
    end for
    ' If no playlists match the quality, add the smallest
    'if playlists_meeting_quality.count() = 0
    '    smallest = invalid
    '    for each playlist in playlists
    '        if is_stream_video(playlist)
    '            if smallest = invalid or get_stream_quality(smallest) > get_stream_quality(playlist) and stream_meets_quality(max_quality, playlist)
    '                smallest = playlist
    '            end if
    '        end if
    '    end for
    '    if smallest <> invalid
    '        playlists_meeting_quality.push(smallest)
    '    end if
    'end if
    ' Add streams to the master playlist
    did_add_playlist = false
    for each playlist in playlists_meeting_quality
        if is_stream_video(playlist)
            master_playlist.append(stream_to_array(playlist))
            did_add_playlist = true
        end if
    end for
    ' If no playlists were added, add them all
    if not did_add_playlist
        print "Could not sort playlist, adding them all."
        for each playlist in playlists
            master_playlist.append(stream_to_array(playlist))
        end for
    end if
    ' Construct the master playlist file
    master_playlist_string = ""
    for each line in master_playlist
        master_playlist_string += line + chr(13) + chr(10)
    end for
    ' Create directories
    out_dir = ["playlist"]
    if m.hls_url_params.type = m.top.HLS_TYPE_STREAM
        out_dir.push("hls")
    else if m.hls_url_params.type = m.top.HLS_TYPE_VIDEO
        out_dir.push("vod")
    else
        m.top.setField("result", {
            callback: m.hls_url_params.callback
            result: invalid
        })
        return
    end if
    out_path = "tmp:/"
    for each dir_name in out_dir
        out_path += dir_name + "/"
        ' Error if directory creation fails
        if not createDirectory(out_path)
            m.top.setField("result", {
                callback: m.hls_url_params.callback
                result: invalid
            })
            return
        end if
    end for
    ' Write value
    ' The video node seems to cache playlist based on their path. Generate a new
    ' path each time and delete the old playlist.
    dir_contents = listDir(out_path)
    for each file_name in dir_contents
        print "Deleted playlist file: " + out_path + file_name
        deleteFile(out_path + file_name)
    end for
    out_path += m.hls_url_params.id + m.hls_url_params.quality + ".m3u8"
    if not writeAsciiFile(out_path, master_playlist_string)
        m.top.setField("result", {
            callback: m.hls_url_params.callback
            result: invalid
        })
        return
    end if
    print "Generated playlist file: " + out_path
    ' Set value
    m.top.setField("result", {
        callback: m.hls_url_params.callback
        result: {
            url: out_path,
            headers: [],
            drm_data: m.hls_url_params.drm_data
        }
    })
end function

' Search a directory for a file
' @return true if the file is found in the directory
function directory_contains_file(search_dir as string, file_name as string) as boolean
    for each file_name_in_dir in listDir(search_dir)
        if file_name_in_dir = file_name
            return true
        end if
    end for
    return false
end function

' Initialize the http agent for direct Twitch requests
function initialize_twitch_http_agent() as void
    if m.http_twitch <> invalid
        m.http_twitch.asyncCancel()
        m.callback = invalid
    end if
    m.http_twitch = createObject("roUrlTransfer")
    m.http_twitch.setMessagePort(m.port)
    m.http_twitch.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.http_twitch.addHeader("Accept", "*/*")
    m.http_twitch.addHeader("Client-ID", m.global.secret.client_id_twitch)
    'm.http_twitch.addHeader("Authorization", "Bearer " + m.top.user_token) ' This endpoint may change to Helix and require a bearer token
    m.http_twitch.addHeader("Authorization", "OAuth " + m.top.user_token)
    app_info = createObject("roAppInfo")
    space_regex = createObject("roRegex", "\s", "")
    m.http_twitch.addHeader("User-Agent", substitute("{0}Roku/{1} (BrightScript)", space_regex.replace(app_info.getTitle(), ""), app_info.getVersion()))
    m.http_twitch.initClientCertificates()
end function

' Request Twitched's config json
' @param params node event containing a string callback
function get_twitched_config(params as object) as void
    request_url = m.API + "/config"
    request("GET", request_url, [], params.getData())
end function

' Request followed communities
' @param params array [assocarray params, string callback]
function get_followed_communities(params as object) as void
    request_url = m.API + "/communities/follows"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    if passed_params.to_id <> invalid
        url_params.push("to_id=" + m.http.escape(passed_params.to_id.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Request followed games
' @param params array [assocarray params, string callback]
function get_followed_games(params as object) as void
    request_url = m.API + "/twitch/games/follows"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.limit <> invalid
        url_params.push("limit=" + m.http.escape(passed_params.limit.toStr()))
    end if
    if passed_params.offset <> invalid
        url_params.push("offset=" + m.http.escape(passed_params.offset.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Check if user is following a game
' @param params array [assocarray params, string callback]
function is_following_game(params as object) as void
    request_url = m.API + "/twitch/games/following"
    passed_params = params.getData()[0]
    url_params = []
    if passed_params.name <> invalid
        url_params.push("name=" + m.http.escape(passed_params.name.toStr()))
    end if
    if passed_params.id <> invalid
        url_params.push("id=" + m.http.escape(passed_params.id.toStr()))
    end if
    if passed_params.no_cache <> invalid
        url_params.push("no_cache=" + m.http.escape(passed_params.no_cache.toStr()))
    end if
    request("GET", request_url, url_params, params.getData()[1])
end function

' Follow a community
' @param params array [string id, string callback]
function follow_community(params as object) as void
    request_url = m.API + "/communities/follow"
    id = params.getData()[0]
    url_params = []
    url_params.push("id=" + m.http.escape(id.toStr()))
    request("GET", request_url, url_params, params.getData()[1])
end function


' Follow a game
' @param params array [string id, string callback]
function follow_game(params as object) as void
    request_url = m.API + "/twitch/games/follow"
    id = params.getData()[0]
    url_params = []
    url_params.push("id=" + m.http.escape(id.toStr()))
    request("GET", request_url, url_params, params.getData()[1])
end function

' Unfollow a community
' @param params array [string id, string callback]
function unfollow_community(params as object) as void
    request_url = m.API + "/communities/unfollow"
    id = params.getData()[0]
    url_params = []
    url_params.push("id=" + m.http.escape(id.toStr()))
    request("GET", request_url, url_params, params.getData()[1])
end function


' Unfollow a game
' @param params array [string id, string callback]
function unfollow_game(params as object) as void
    request_url = m.API + "/twitch/games/unfollow"
    id = params.getData()[0]
    url_params = []
    url_params.push("id=" + m.http.escape(id.toStr()))
    request("GET", request_url, url_params, params.getData()[1])
end function
