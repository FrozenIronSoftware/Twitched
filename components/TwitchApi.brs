' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the TwitchApi component
function init() as void
    m.port = createObject("roMessagePort")
    ' Constants
    m.API_KRAKEN = "https://twitched.org/api/twitch/kraken" ' API proxy/cacher
    m.API_HELIX = "https://twitched.org/api/twitch/helix" ' API proxy/cacher
    m.API = "https://twitched.org/api" ' Direct/unofficial API
    m.top.setField("AUTH_URL", "https://twitched.org/link") ' User web endpoint
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
    m.http = createObject("roUrlTransfer")
    m.http.setMessagePort(m.port)
    m.http.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.http.addHeader("X-Roku-Reserved-Dev-Id", "") ' Automatically populated
    m.http.addHeader("Client-ID", m.global.secret.client_id)
    m.http.initClientCertificates()
    ' Variables
    m.callback = invalid
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
    ' Task init
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
                m.http.asyncCancel()
                m.callback = invalid
            else if msg.getField() = "get_followed_streams"
                get_followed_streams(msg)
            else if msg.getField() = "search"
                search(msg)
            else if msg.getField() = "get_user_info"
                get_user_info(msg)
            else if msg.getField() = "get_badges"
                get_badges(msg)
            else if msg.getField() = "user_token"
                m.http.addHeader("Twitch-Token", msg.getData())
            else if msg.getField() = "get_videos"
                get_videos(msg)
            else if msg.getField() = "get_follows"
                get_follows(msg)
            else if msg.getField() = "follow_channel"
                follow_channel(msg)
            else if msg.getField() = "unfollow_channel"
                unfollow_channel(msg)
            end if
        end if
    end while
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
function request(req as string, request_url as string, params as object, callback as string, data = "" as string) as void
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
    if req = "GET"
        get(request_url)
    else if req = "POST"
        'response = post(request_url, data)
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
        print "HTTP request failed:"
        print tab(2)"URL: " + m.http.getUrl()
        print tab(2)"Status Code: " + event.getResponseCode().toStr()
        print tab(2)"Reason: " + event.getFailureReason()
    end if
    ' Response
    response = event.getString()
    ' Parse
    json = parseJson(response)
    ' Send result event
    m.top.setField("result", {
        callback: m.callback
        result: json
    })
    m.callback = invalid
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
function get(request_url as string) as void
    print "Get request to " + request_url
    m.http.setRequest("GET")
    m.http.setUrl(request_url)
    m.http.asyncGetToString()
end function

' Get stream HLS URL for a streamer
function get_stream_url(params as object) as string
    return m.API + "/twitch/hls/" + params.encodeUri() + ".m3u8"
end function

' Get video HLS URL for a video id
function get_video_url(params as object) as string
    return m.API + "/twitch/vod/" + params.encodeUri() + ".m3u8"
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
    print "start"
    print params
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