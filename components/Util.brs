' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Determine if the key should be singular or plural based on the amount and
' find the correct translation
function trs(key as string, amount as integer) as string
    if amount = 1 or amount = -1
        return tr(key + "_singular")
    end if
    return tr(key + "_plural")
end function

' Clean a string that may have invalid characters.
function clean(dirty as object) as string
    if m._clean_regex = invalid
        m._clean_regex = createObject("roRegex", "[^A-Za-z0-9\s!@#$%^&*()_\-+=<,>\./\?';\:\[\]\{\}\\\|" + chr(34) + "]", "")
    end if
    if type(dirty) <> "roString" and type(dirty) <> "String" and type(dirty) <> "string"
        return ""
    end if
    return m._clean_regex.replaceAll(dirty, "")
end function

' Log a message
' @param level log level string or integer
' @param msg message to print
function printl(level as object, msg as object) as void
    if _parse_level(level) > m.log_level
        return
    end if
    print(msg)
end function

' Parse level to an integer
' @param level string or integer level
function _parse_level(level as object) as integer
    level_string = level.toStr()
    log_level = 0
    if level_string = "INFO" or level_string = "0"
        log_level = m.INFO
    else if level_string = "DEBUG" or level_string = "1"
        log_level = m.DEBUG
    else if level_string = "EXTRA" or level_string = "2"
        log_level = m.EXTRA
    else if level_string = "VERBOSE" or level_string = "3"
        log_level = m.VERBOSE
    end if
    return log_level
end function

' Initialize logging
function init_logging() as void
    m.INFO = 0
    m.DEBUG = 1
    m.EXTRA = 2
    m.VERBOSE = 3
    level_string = m.global.secret.log_level
    log_level = 0
    if level_string = "INFO" or level_string = "0"
        log_level = m.INFO
    else if level_string = "DEBUG" or level_string = "1"
        log_level = m.DEBUG
    else if level_string = "EXTRA" or level_string = "2"
        log_level = m.EXTRA
    else if level_string = "VERBOSE" or level_string = "3"
        log_level = m.VERBOSE
    end if
    m.log_level = log_level
end function

' Returns a string representation of a number, with delimiters added for
' readability
function pretty_number(ugly_number as dynamic) as string
    ' Check if the number is large enough for a delimiter
    if ugly_number < 1000
        return ugly_number.toStr()
    end if
    ' Determine delimiter
    delimiter = get_regional_number_delimiter()
    ' Construct the string with the delimiter
    ugly = ugly_number.toStr().split("")
    ugly_reversed = []
    for digit = ugly.count() - 1 to 0 step -1
        ugly_reversed.Push(ugly[digit])
    end for
    ugly = ugly_reversed
    pretty = ""
    digit_count = 0
    for each digit in ugly
        if digit_count = 3
            pretty = delimiter + pretty
            digit_count = 0
        end if
        pretty = digit + pretty
        digit_count++
    end for
    return pretty
end function

' Return the character used to delimit thousands in a number
function get_regional_number_delimiter() as string
    device_info = createObject("roDeviceInfo")
    country_code = device_info.getCountryCode()
    if country_code = "US" or country_code = "GB" or country_code = "IE"
        return ","
    else if country_code = "CA" or country_code = "FR"
        return " "
    else if country_code = "MX"
        return "."
    else if country_code = "OT"
        return " "
    end if
    return " "
end function