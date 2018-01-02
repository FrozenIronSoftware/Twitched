' Copyright (C) 2017 Rolando Islas. All Rights Reserved.

' Create a new instance of the Irc component
function init() as void
    ' Constants
    m.PORT = createObject("roMessagePort")
    params_regex = "(\s(?:(?::(.*))|(?:([^\s]+))))"
    twitch_tag_regex = "([^\s;=]+=[^\s;]*)"
    twitch_tags_regex = "(?:@((?:$TWITCH_TAG;?)+)\s)?".replace("$TWITCH_TAG", twitch_tag_regex)
    m.PARAMS_REGEX = createObject("roRegex", params_regex, "")
    m.TWITCH_TAG_REGEX = createObject("roRegex", twitch_tag_regex, "")
    m.TWITCH_TAGS_REGEX = createObject("roRegex", twitch_tags_regex, "")
    m.MESSAGE_REGEX = createObject("roRegex", "^$TWITCH_TAGS(?::([^!@\s]+)(?:!([^@\s]+))?(?:@([^\s]+))?\s)?([A-Za-z0-9]+)($PARAMS+)?(?:\r?\n?)".replace("$PARAMS", params_regex).replace("$TWITCH_TAGS", twitch_tags_regex), "")
    m.NEW_LINE_REGEX = createObject("roRegex", chr(13) + "?" + chr(10), "")
    ' IRC Constants
    m.IRC_HOST_NAME = "irc.chat.twitch.tv"
    'm.IRC_HOST_NAME = "h61n"
    m.IRC_PORT = 6667
    m.PASS = "PASS"
    m.NICK = "NICK"
    m.JOIN = "JOIN"
    m.PING = "PING"
    m.PONG = "PONG"
    m.PRIVMSG = "PRIVMSG"
    m.PART = "PART"
    m.MOTD_START = "RPL_MOTDSTART"
    m.MOTD_START_D = "375"
    m.MOTD = "RPL_MOTD"
    m.MOTD_D = "372"
    m.MOTD_END = "RPL_ENDOFMOTD"
    m.MOTD_END_D = "376"
    m.CAP = "CAP"
    m.NOTICE = "NOTICE"
    ' Variables
    m.channel = ""
    m.socket = invalid
    m.data = createObject("roByteArray")
    m.data[2048] = 0
    m.data_size = 0
    ' Init
    init_logging()
    ' Events
    m.top.observeField("connect", m.PORT)
    m.top.observeField("disconnect", m.PORT)
    ' Task init
    m.top.functionName = "run"
    m.top.control = "RUN"
end function

' Main task loop
function run() as void
    printl(m.INFO, "Irc task started")
    while true
        ' Check for messages
        msg = m.PORT.getMessage()
        ' Field event
        if type(msg) = "roSGNodeEvent"
            if msg.getField() = "connect"
                connect(msg.getData())
            else if msg.getField() = "disconnect"
                disconnect()
            end if
        end if
        read_socket_data()
    end while
end function

' Read socket data
function read_socket_data() as void
    if m.socket = invalid or (not m.socket.isConnected()) or (not m.socket.isReadable())
        return
    end if
    bytes_received =  m.socket.receive(m.data, m.data_size, 1024)
    if bytes_received < 0
        return
    end if
    m.data_size += bytes_received
    m.data[m.data_size] = 0
    data = m.data.toAsciiString()
    if data <> ""
        split = m.NEW_LINE_REGEX.split(data)
        if not data.right(1) = chr(10)
            data = split[split.count() - 1]
            split.delete(split.count() - 1)
        else
            data = ""
        end if
        ' Handle the messages
        for each message in split
            printl(m.EXTRA, "IRC MESSAGE: " + message)
            message_parsed = parse_message(message)
            if message_parsed <> invalid
                handle_message(message_parsed)
            end if
        end for
    end if
    m.data.fromAsciiString(data)
    m.data_size = m.data.count()
    m.data[2048] = 0
end function

' Handle connecting
' A hastag(#) is prefixed to the streamer name
' If the streamer name is an empty string, this will act as a disconnect call
' @param streamer channel to connect to
function connect(streamer as string) as void
    disconnect()
    ' Create socket
    m.socket = createObject("roStreamSocket")
    ' Set address
    twitch_irc = createObject("roSocketAddress")
    twitch_irc.setHostName(m.IRC_HOST_NAME)
    twitch_irc.setPort(m.IRC_PORT)
    m.socket.setSendToAddress(twitch_irc)
    ' Connect
    if m.socket.connect():
        printl(m.INFO, "IRC socket connected")
        cmd(m.CAP, ["REQ", "twitch.tv/tags"])
        if m.top.getField("token") <> "" and m.top.getField("user_name") <> ""
            cmd(m.PASS, "oauth:" + m.top.getField("token"))
        end if
        if m.top.getField("user_name") <> ""
            cmd(m.NICK, m.top.getField("user_name"))
        else
            cmd(m.NICK, "justinfan" + rnd(&h7fffffff).toStr())
        end if
        cmd(m.JOIN, "#" + streamer)
    else
        printl(m.INFO, "Irc socket connection failed")
    end if
end function

' Disconnect from the channel and the server
function disconnect() as void
    if m.socket <> invalid and m.socket.isConnected()
        m.socket.close()
    end if
    m.channel = ""
    printl(m.INFO, "IRC socket disconnected")
end function

' Send a command to the IRC server
function cmd(command as string, args as object) as void
    if m.socket = invalid or not m.socket.isConnected()
        return
    end if
    formatted_args = ""
    if type(args) = "String" or type(args) = "string" or type(args) = "roString"
        args = [args]
    end if
    for arg_index = 0 to args.count() - 1
        if arg_index = args.count() - 1
            formatted_args += ":" + args[arg_index]
        else
            formatted_args += args[arg_index] + " "
        end if
    end for
    printl(m.EXTRA, "IRC COMMAND: " + command + " " + formatted_args)
    m.socket.sendStr(command + " " + formatted_args + chr(10))
end function

' Parse a message string
' @return assocarray of parsed message values or invalid on parse failure
function parse_message(message_string as string) as object
    match = m.MESSAGE_REGEX.match(message_string)
    if match.count() = 0
        return invalid
    end if
    printl(m.VERBOSE, "========================= COMMAND =========================")
    for each group in match
        printl(m.VERBOSE, "] " + group)
    end for
    message = {
        twitch_tags: parse_twitch_tags(match[1]),
        server_name: match[3],
        nick: match[3],
        user: match[4],
        host: match[5],
        command: match[6],
        params: parse_params(match[7])
    }
    return message
end function

' Parse Twitch tags into an associative array
function parse_twitch_tags(tags_string as dynamic) as object
    tags = {}
    if tags_string = invalid or tags_string = ""
        return tags
    end if
    ' No finditer implementation. The TWITCH_TAG_REGEX cannot be used directly
    ' for finding the matches. Tags are split at semicolons and equal signs 
    matches = tags_string.split(";")
    if matches.count() < 1
        return tags
    end if
    for each match in matches
        printl(m.VERBOSE, "] TAG: " + match)
        tag = match.split("=")
        tags[tag[0]] = tag[1]
    end for
    return tags
end function

' Parse IRC message params into an array
function parse_params(params_string as dynamic) as object
    params = []
    if params_string = invalid or params_string = ""
        return params
    end if
    ' Replace the first space
    if params_string.instr(" ") = 0
        params_string = params_string.mid(1)
    end if
    ' No finditer implementation. the PARAMS_REGEX cannot be used directly
    ' Middle params are replaced by spaces
    ' The last params starts with a colon and can have spaces
    matches = params_string.split(" ")
    ' Find middle params
    break = false
    for each match in matches
        if match.instr(":") <> -1
            goto middle_params
        end if
        params.push(match)
    end for
    middle_params:
    ' Add last param
    last_param_split = params_string.split(":")
    if last_param_split.count() >= 2
        params.push(last_param_split[last_param_split.count() - 1])
    end if
    ' Print params
    for each param in params
        printl(m.VERBOSE, "] PARAM: " + param)
    end for
    return params
end function

' Handle a parsed IRC message
' @param message assocarray of message values
function handle_message(message as object) as void
    printl(m.VERBOSE, message)
    ' Ping
    if message.command = m.PING:
        cmd(m.PONG, message.params[0])
    ' Notice
    else if message.command = m.NOTICE
        notice = ""
        for each param in message.params
            notice += param + " "
        end for
        printl(m.INFO, "IRC NOTICE: " + notice)
    ' Join
    else if message.command = m.JOIN
        m.channel = message.params[0]
        printl(m.INFO, "IRC JOIN: " + m.channel)
        chat_message = {
            name: tr("twitched"),
            message: tr("message_irc_connected"),
            color: "#ffffff"
        }
        m.top.setField("chat_message", chat_message)
    ' Part
    else if message.command = m.PART
        printl(m.INFO, "IRC PART: " + message.params[0])
        m.channel = ""
    ' Msg
    else if message.command = m.PRIVMSG
        handle_privmsg(message)
        
    end if
end function

' Parse a message for details and construct a clean message object to 
' set to a global field as a chat event
function handle_privmsg(message as object) as void
    name = message.nick
    display_name = message.twitch_tags["display-name"]
    if display_name <> invalid and display_name <> ""
        name = display_name
    end if
    chat_message = {
        name: name,
        message: message.params[1],
        color: message.twitch_tags.color,
        badges: message.twitch_tags.badges
    }
    m.top.setField("chat_message", chat_message)
end function