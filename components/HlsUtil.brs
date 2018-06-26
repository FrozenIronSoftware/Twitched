' Copyright (C) 2018 Rolando Islas. All Rights Reserved.

' Get the max quality of video the current roku model will support
function get_max_quality_for_model(quality as string) as object
    quality = ucase(quality)
    if right(quality, 1) = "P"
        quality = left(quality, len(quality) - 1)
    end if
    default_quality = val(quality, 0)
    info = createObject("roDeviceInfo")
    model = info.getModel()
    max_30 = invalid
    max_60 = invalid
    max_bitrate = invalid
    ONE_MILLION = 1000000
    ' Big o' if else chain for models
    ' 720 30 FPS
    if model = "2700X" or model = "2500X" or model = "2450X" or model = "3000X" or model = "2400X"
        max_30 = 720
        max_60 = 0
        max_bitrate = 4 * ONE_MILLION
    ' 1080 60 FPS
    else if model = "8000X" or model = "3910X" or model = "3900X" or model = "3710X" or model = "3700X"
        max_30 = 1080
        max_60 = 1080
        max_bitrate = 7 * ONE_MILLION
    ' 1080 30 FPS
    else if model = "4230X" or model = "4210X" or model = "3500X" or model = "2720X" or model = "2710X" or model = "4200X" or model = "3400X" or model ="3420X" or model = "3100X" or model = "3050X" or model = "5000X" or model = "3800X" or model = "3600X"
        max_30 = 1080
        max_60 = 0
        max_bitrate = 7 * ONE_MILLION
    ' 4K 60 FPS
    else if model = "7000X" or model = "6000X" or model = "4660X" or model = "3810X" or model = "4640X" or model = "4630X" or model = "4620X" or model = "4400X"
        max_30 = 2160
        max_60 = 2160
        max_bitrate = 20 * ONE_MILLION
    ' Legacy SD 30 FPS
    else if model = "2100X" or model = "2100N" or model = "2050N" or model = "2050X" or model = "2000C" or model = "N1101" or model = "N1100" or model = "N1050" or model = "N1000"
        max_30 = 480
        max_60 = 0
        max_bitrate = 2 * ONE_MILLION
    ' Assume any new Roku device can play at least 1080p 60 FPS
    else
        max_30 = default_quality
        max_60 = default_quality
        max_bitrate = 7 * ONE_MILLION
    end if
    min_30 = max_30
    if default_quality < min_30
        min_30 = default_quality
    end if
    min_60 = max_60
    if default_quality < min_60
        min_60 = default_quality
    end if
    return {
        max_30: min_30,
        max_60: min_60,
        max_bitrate: max_bitrate
    }
end function

' Get FPS of a playlist
function get_stream_fps(playlist as object) as integer
    quality_regex = createObject("roRegex", ".*NAME=" + chr(34) +"(\d+)p?(\d*).*" + chr(34) + ".*", "")
    fps = 0
    if quality_regex.isMatch(playlist.line_one)
        groups = quality_regex.match(playlist.line_one)
        fps = val(groups[2], 0)
        if fps = 0
            fps = 30
        end if
    end if
    return fps
end function

' Check if the playlist if of the passed quality or lower
' @return true if the quality is the same or lower
function is_stream_quality_or_lower(playlist as object, quality as integer) as boolean
    quality_regex = createObject("roRegex", ".*NAME=" + chr(34) +"(\d+)p?(\d*).*" + chr(34) + ".*", "")
    stream_quality = 0
    if quality_regex.isMatch(playlist.line_one)
        groups = quality_regex.match(playlist.line_one)
        stream_quality = val(groups[1], 0)
    end if
    return quality > 0 and stream_quality <= quality
end function

' Get the bitrate of a playlist
function get_stream_bitrate(playlist as object) as integer
    bitrate_regex = createObject("roRegex", ".*BANDWIDTH=(\d+),.*", "")
    bitrate = 0
    if bitrate_regex.isMatch(playlist.line_two)
        groups = bitrate_regex.match(playlist.line_two)
        bitrate = val(groups[1], 0)
    end if
    return bitrate
end function

' Check if the playlist is a video
function is_stream_video(playlist as object) as boolean
    return instr(0, playlist.line_one, "audio") = 0 and instr(0, playlist.line_two, "audio") = 0
end function

' Convert the playlist associative array to an array
function stream_to_array(playlist as object) as object 
    return [
        playlist.line_one,
        playlist.line_two,
        playlist.line_three
    ]
end function