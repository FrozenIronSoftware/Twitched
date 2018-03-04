' Copyright (C) 2017-2018 Rolando Islas. All Rights Reserved.

Library "Roku_Ads.brs"

' Ads entry point
function init() as void
    ' Constants
    m.PORT = createObject("roMessagePort")
    ' Ads
    m.ads = Roku_Ads()
    ad_url = m.global.secret.ad_server
    m.ads.setAdUrl(m.global.secret.ad_server.replace("ROKU_ADS_TRACKING_ID_OBEY_LIMIT", get_ad_id()))
    m.ads.enableNielsenDar(true)
    m.ads.setNielsenAppId(m.global.secret.ad_nielsen_id)
    ' Events
    m.top.observeField("show_ads", m.PORT)
    ' Init
    init_logging()
    ' Task init
    m.top.functionName = "run"
    m.top.control = "RUN"
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
            end if
        end if
    end while
end function

' Async show ads call
' Sets the status to the result of the ad call
' @param params roArray [nielsen_id  as string, genre as string, content_length as integer]
function show_ads(params as object) as void
    nielsen_id = params[0]
    genre = params[1]
    content_length = params[2]
    m.ads.setNielsenProgramId(nielsen_id) ' Streamer
    m.ads.setNielsenGenre(genre) ' General variety
    m.ads.setContentLength(content_length) ' Seconds
    ads = m.ads.getAds()
    if ads = invalid or ads.count() = 0
        printl(m.DEBUG, "Ads: No ads loaded")
        m.top.setField("status", true)
        return
    end if
    printl(m.DEBUG, "Ads: Showing ads")
    m.top.setField("status", m.ads.showAds(ads, invalid, m.top.view))
end function