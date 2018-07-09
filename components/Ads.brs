' Copyright (C) 2017-2018 Rolando Islas. All Rights Reserved.

#if enable_ads

Library "Roku_Ads.brs"

' Ads entry point
function init() as void
    ' Constants
    m.PORT = createObject("roMessagePort")
    ' Ads
    m.ads = Roku_Ads()
    m.ads.enableNielsenDar(true)
    m.ads.setNielsenAppId(m.global.secret.ad_nielsen_id)
    ' Components
    m.twitch_api = m.top.findNode("twitch_api")
    ' Events
    m.top.observeField("show_ads", m.PORT)
    m.twitch_api.observeField("result", m.PORT)
    ' Init
    init_logging()
    m.twitch_api.get_ad_server = "on_ad_server"
    ' Variables
    m.did_fetch_server = false
    ' Task init
    m.top.functionName = "run"
    m.top.control = "RUN"
end function

' Set the ad url of the Roku_Ads instance
function set_ad_url(ad_url as string) as void
    m.ads.setAdUrl(ad_url.replace("ROKU_ADS_TRACKING_ID_OBEY_LIMIT", get_ad_id()))
end function

' Handle ad server request data from Twitched's API
function on_ad_server(event as object) as void
    ad_server = event.getData().result
    if type(ad_server) <> "roAssociativeArray" or (type(ad_server.ad_server) <> "roString" and type(ad_server.ad_server) <> "String")
        printl(m.DEBUG, "Ads: Failed to fetch ad server from Twitched API")
        return
    end if
    printl(m.DEBUG, "Ads: Fetched ad server from Twitched API")
    m.did_fetch_server = true
    set_ad_url(ad_server.ad_server)
end function

' Get the ad id for the device, obeying limited ad tracking
function get_ad_id() as string
    ad_id = ""
    device_info = createObject("roDeviceInfo")
    if not device_info.isAdIdTrackingDisabled()
        ad_id = device_info.getAdvertisingId()
    end if
    return ad_id
end function

' Main task function
function run() as void
    printl(m.DEBUG, "Ads: Ads task started")
    while true
        msg = wait(0, m.PORT)
        ' Field event
        if type(msg) = "roSGNodeEvent"
            if msg.getField() = "show_ads"
                show_ads(msg.getData())
            else if msg.getField() = "result"
                on_callback(msg)
            end if
        end if
    end while
end function

' Handle callback
function on_callback(event as object) as void
    callback = event.getData().callback
    if callback = "on_ad_server"
        on_ad_server(event)
    else
        if callback = invalid
            callback = ""
        end if
        printl(m.WARN, "on_callback: Unhandled callback: " + callback)
    end if
end function

' Async show ads call
' Sets the status to the result of the ad call
' @param params roArray [nielsen_id  as string, genre as string, content_length as integer]
function show_ads(params as object) as void
    if not m.did_fetch_server
        m.twitch_api.get_ad_server = "on_ad_server"
    end if
    nielsen_id = params[0]
    genre = params[1]
    content_length = params[2]
    m.ads.setNielsenProgramId(nielsen_id) ' Streamer
    m.ads.setNielsenGenre(genre) ' General variety
    m.ads.setContentLength(content_length) ' Seconds
    ads = m.ads.getAds()
    ads_count = 0
    if ads <> invalid
        ads_count = ads.count()
    end if
    track_ads(ads_count)
    if ads_count = 0
        printl(m.DEBUG, "Ads: No ads loaded")
        m.top.setField("status", true)
        return
    end if
    printl(m.DEBUG, "Ads: Showing ads")
    m.top.setField("status", m.ads.showAds(ads, invalid, m.top.view))
end function

' Send analytics data about how many ads were received for playback
function track_ads(ads_count as integer) as void
    m.global.analytics.trackEvent = {
        google: {
            ec: "Ad",
            ea: "Ads Started",
            el: "Count: " + ads_count.toStr()
        }
    }
end function

#else

    function init() as void
    end function

#end if
