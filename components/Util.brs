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
function clean(dirty as string) as string
    if m.clean_regex = invalid
        m.clean_regex = createObject("roRegex", "[^A-Za-z0-9\s!@#$%^&*()_\-+=<,>\./\?';\:\[\]\{\}\\\|" + chr(34) + "]", "")
    end if
    return m.clean_regex.replaceAll(dirty, "")
end function