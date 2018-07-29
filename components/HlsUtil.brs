' Copyright (C) 2018 Rolando Islas. All Rights Reserved.

' Get the max quality of video the current roku model will support
function get_max_quality_for_model(quality as string) as object
    quality = ucase(quality)
    if right(quality, 1) = "P"
        quality = left(quality, len(quality) - 1)
    end if
    requested_quality = val(quality, 0)
    model = createObject("roDeviceInfo").getModel()
    for each stream_quality in m.global.twitched_config.stream_qualities
        if stream_quality.model = model
            stream_quality = limit_stream_quality(stream_quality, requested_quality)
            return stream_quality
        end if
    end for
    ' Quality not found in database
    ' Send a sensible 720p 30fps 7mbps default quality
    return {
        id: 0,
        model: model,
        bitrate: 7000000,
        comment: "",
        "240p30": true,
        "240p60": false,
        "480p30": true,
        "480p60": false,
        "720p30": true,
        "720p60": false,
        "1080p30": true,
        "1080p60": false,
        "only_source_60": true
    }
end function

' Limit stream quality
' @param stream_quality stream associative array
' @param limit resolution limit
function limit_stream_quality(stream_quality as object, limit as integer) as object
    if limit < 1080
        stream_quality.["1080p30"] = false
        stream_quality.["1080p60"] = false
    end if
    if limit < 720
        stream_quality.["720p30"] = false
        stream_quality.["720p60"] = false
    end if
    if limit < 480
        stream_quality.["480p30"] = false
        stream_quality.["480p60"] = false
    end if
    if limit < 240
        stream_quality.["240p30"] = false
        stream_quality.["240p60"] = false
    end if
    return stream_quality
end function

' Get FPS of a playlist
function get_stream_fps(playlist as object) as integer
    return get_quality_and_fps(playlist).fps
end function

' Return an associative array containing quality and fps fields for a playlist
function get_quality_and_fps(playlist as object) as object
    quality_regex = createObject("roRegex", ".*NAME=" + chr(34) +"(\d+)p?(\d*).*" + chr(34) + ".*", "")
    quality = 0
    fps = 0
    if quality_regex.isMatch(playlist.line_one)
        groups = quality_regex.match(playlist.line_one)
        quality = val(groups[1], 0)
        fps = val(groups[2], 0)
        if fps = 0
            fps = 30
        end if
    end if
    return {
        quality: quality,
        fps: fps
    }
end function

' Get stream quality
function get_stream_quality(playlist as object) as integer
    return get_quality_and_fps(playlist).quality
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

' Check if the playlist is a source stream
function is_stream_source(playlist as object) as boolean
    return instr(0, playlist.line_one, "source") > 0
end function

' Convert the playlist associative array to an array
function stream_to_array(playlist as object) as object
    return [
        playlist.line_one,
        playlist.line_two,
        playlist.line_three
    ]
end function

' Check if a stream playlist if of lesser or equal quality to the one passed
function stream_meets_quality(max_quality as object, stream as object) as boolean
    ' Check if this stream is 60 FPS. If it is and the StreamQuality denies
    ' non-source 60 FPS, check if it is a source stream.
    if get_stream_fps(stream) = 60 and max_quality.only_source_60 and not is_stream_source(stream)
        return false
    end if
    ' Check if the bitrate is higher than the defined max bitrate
    if get_stream_bitrate(stream) > max_quality.bitrate
        return false
    end if
    ' Check 30 FPS streams
    if get_stream_fps(stream) = 30
        if get_stream_quality(stream) <= 240 and not max_quality["240p30"]
            return false
        end if
        if get_stream_quality(stream) > 240 and get_stream_quality(stream) <= 480 and not max_quality["480p30"]
            return false
        end if
        if get_stream_quality(stream) = 720 and not max_quality["720p30"]
            return false
        end if
        if get_stream_quality(stream) > 720 and not max_quality["1080p30"]
            return false
        end if
    end if
    ' Check 60 FPS streams
    if get_stream_fps(stream) = 60
        if get_stream_quality(stream) <= 240 and not max_quality["240p60"]
            return false
        end if
        if get_stream_quality(stream) > 240 and get_stream_quality(stream) <= 480 and not max_quality["480p60"]
            return false
        end if
        if get_stream_quality(stream) = 720 and not max_quality["720p60"]
            return false
        end if
        if get_stream_quality(stream) > 720 and not max_quality["1080p60"]
            return false
        end if
    end if
    return true
end function
