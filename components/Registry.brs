' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Init registry component
function init() as void
    m.port = createObject("roMessagePort")
    ' Events
    m.top.observeField("read", m.port)
    m.top.observeField("write", m.port)
    ' Task init
    m.top.functionName = "run"
    m.top.control = "RUN"
end function

' Main task loop
function run() as void
    print("Registry task started")
    while true
        msg = wait(0, m.port)
        if type(msg) = "roSGNodeEvent"
            if msg.getField() = "read"
                read(msg)
            else if msg.getField() = "write"
                write(msg)
            end if
        end if
    end while
end function

' Read a registry key
' @param params array [string section, string key, string callback]
function read(params as object) as void
    reg = createObject("roRegistrySection", params.getData()[0])
    m.top.setField("result", {
        type: "read",
        section: params.getData()[0],
        key: params.getData()[1],
        callback: params.getData()[2],
        result: reg.read(params.getData()[1])
    })
end function

' Write a registry key
' @param params array [string section, string key, string value, string callback]
function write(params as object) as void
    reg = createObject("roRegistrySection", params.getData()[0])
    write_status = reg.write(params.getData()[1], params.getData()[2]) and reg.flush()
    m.top.setField("result", {
        type: "write",
        section: params.getData()[0],
        key: params.getData()[1],
        callback: params.getData()[3],
        result: write_status
    })
end function