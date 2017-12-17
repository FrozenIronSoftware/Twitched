' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the TwitchApi component
function init() as void
    m.port = createObject("roMessagePort")
    ' Constants
    m.API_KRAKEN = "https://twitchunofficial.herokuapp.com/api/twitch/kraken" ' API proxy/cacher
    m.API_HELIX = "https://twitchunofficial.herokuapp.com/api/twitch/helix" ' API proxy/cacher
    m.API = "https://twitchunofficial.herokuapp.com/api/twitch" ' Direct/unofficial API
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
    ' HTTP Api
    m.http = createObject("roUrlTransfer")
    m.http.setMessagePort(m.port)
    m.http.setCertificatesFile("common:/certs/ca-bundle.crt")
    m.http.addHeader("X-Roku-Reserved-Dev-Id", "") ' Automatically populated
    m.http.initClientCertificates()
    ' Variables
    ' TODO allow user login
    m.user_token = invalid
    m.http_response = invalid
    m.http_start_time = 0
    ' Events
    m.top.observeField("get_streams", m.port)
    m.top.observeField("get_games", m.port)
    m.top.observeField("get_communities", m.port)
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
            handle_url_event(msg)
        else if type(msg) = "roSGNodeEvent"
            if msg.getField() = "get_streams"
                get_streams(msg)
            else if msg.getField() = "get_games"
                get_games(msg)
            else if msg.getField() = "get_communities"
                get_communities(msg)
            end if
        end if
    end while
end function

' Handle a URL event
function handle_url_event(event as object) as void
    ' Transfer not complete
    if event.getInt() <> 1 then return
    ' Set the URL response variable
    m.http_response = {
        data: event.getString(),
        headers: event.getResponseHeadersArray(),
        status_code: event.getResponseCode(),
        error: event.getFailureReason()
    }
end function

' Make an API request for a list of streams
' @param params array of parameters [associative request_params, string callback]
' @return JSON data or invalid on error
function get_streams(params as object) as object
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
function get_games(params as object) as object
    request_url = m.API_KRAKEN + "/games"
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

' Make a request and set the results to the value.
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
    if req = "GET"
        response = get(request_url)
    else if req = "POST"
        'response = post(request_url, data)
        ' TODO handle post
    end if
    json = parseJson(response)
    ' Send result event
    m.top.setField("result", {
        callback: callback
        result: json
    })
end function

' Make an API request for a list of communities
' @param params array of parameters [associative request_params, string callback]
' @return JSON data or invalid on error
function get_communities(params as object) as object
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

' Helper function to request a URL and get its contents as a string
function get(request_url as string) as string
    m.http.setRequest("GET")
    m.http.setUrl(request_url)
    return m.http.getToString()
end function

' Get stream HLS URL for a streamer
function get_stream_url(params as object) as string
    return m.API + "/hls/" + params.encodeUri() + ".m3u8"
end function