' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Determine if the key should be singular or plural based on the amount and
' find the correct translation
function trs(key as string, amount as integer) as string
    if amount = 1 or amount = -1
        return tr(key + "_singular")
    end if
    return tr(key + "_plural")
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