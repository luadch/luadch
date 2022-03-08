--[[

        server.lua by blastbeat

        - this script contains the server loop of the program
        - other scripts can reg a server here

            v0.09: by blastbeat
                - fixed client keeping alive issue

            v0.08: by pulsar
                - improved out_put/out_error messages

            v0.07: by blastbeat
                - added "handler.getsslinfo()" function

            v0.06: by pulsar
                - fix occasional unwanted disconnects in big hubs

            v0.05: by pulsar
                - increase timeout to prevent disconnects

            v0.04: by blastbeat
                - small fix

            v0.03: by blastbeat
                - try to manage SSL nightmare to fix Kungens disconnect bug

            v0.02: by pulsar
                - small fix


]]--

----------------------------------// DECLARATION //--

local clean = use "cleantable"

--// constants //--

local STAT_UNIT = 1    -- byte

--// lua functions //--

local type = use "type"
local pairs = use "pairs"
local ipairs = use "ipairs"
local tostring = use "tostring"
local collectgarbage = use "collectgarbage"

--// lua libs //--

local os = use "os"
local table = use "table"
local string = use "string"
local coroutine = use "coroutine"

--// lua lib methods //--

local os_time = os.time
local os_difftime = os.difftime
local table_concat = table.concat
local table_remove = table.remove
local string_len = string.len
local string_sub = string.sub
local coroutine_wrap = coroutine.wrap
local coroutine_yield = coroutine.yield

--// extern libs //--

local luasec = use "ssl"
local luasocket = use "socket"

--// extern lib methods //--

local ssl_wrap = ( luasec and luasec.wrap )
local socket_tcp = luasocket.tcp
local socket_bind = luasocket.bind
local socket_sleep = luasocket.sleep
local socket_select = luasocket.select
local ssl_newcontext = ( luasec and luasec.newcontext )

--// core scripts //--

local doc = use "doc"
local cfg = use "cfg"
local out = use "out"
local mem = use "mem"
local signal = use "signal"

--// core methods //--

local cfg_get = cfg.get
local out_put = out.put
local mem_free = mem.free
local out_error = out.error
local signal_set = signal.set
local signal_get = signal.get

--// functions //--

local stop
local loop
local stats

local killall
local addtimer
local addclient
local addserver
local wrapclient
local wrapserver
local getsettings
local closesocket
local removesocket
local changetimeout
local wrapconnection
local changesettings

local return_false
local do_nothing

--// tables //--

local _server
local _readlist
local _timerlist
local _sendlist
local _socketlist
local _closelist
local _activitytimes
local _writetimes

--// simple data types //--

local _
local _readlistlen
local _sendlistlen
local _timerlistlen

local _sendtraffic
local _readtraffic

local _selecttimeout
local _sleeptime

local _starttime
local _currenttime

local _maxsendlen
local _maxreadlen

local _checkinterval
local _sendtimeout
local _max_idle_time

local _cleanqueue

local _timer

local _maxclientsperserver

local _run

----------------------------------// DEFINITION //--

_server = { }    -- key = port, value = table; list of listening servers
_readlist = { }    -- array with sockets to read from
_sendlist = { }    -- arrary with sockets to write to
_timerlist = { }    -- array of timer functions
_socketlist = { }    -- key = socket, value = wrapped socket (handlers)
_activitytimes = { }   -- key = handler, value = timestamp of last activity
_writetimes = { }   -- key = handler, value = timestamp of last data writing/sending
_closelist = { }    -- handlers to close

_readlistlen = 0    -- length of readlist
_sendlistlen = 0    -- length of sendlist
_timerlistlen = 0    -- lenght of timerlist

_sendtraffic = 0    -- some stats
_readtraffic = 0

_selecttimeout = 1    -- timeout of socket.select
_sleeptime = 0.01    -- time to wait at the end of every loop

_maxsendlen = 1024 * 1024    -- max len of send buffer
_maxreadlen = 1024 * 1024    -- max len of read buffer

_checkinterval = 120    -- interval in secs to check clients for acitivty and
_sendtimeout = 60   -- allowed send idle time in secs
_max_idle_time = 30 * 60    -- allowed time of no read/write client activity in secs

_cleanqueue = false    -- clean bufferqueue after using

_maxclientsperserver = 10000

_run = true

----------------------------------// PRIVATE //--

wrapclient = function( client, listeners, pattern, sslctx, startssl, id )

    local dispatch, disconnect = listeners.incoming or listeners.listener, listeners.disconnect

    local failure = listeners.failure

    local handler = { }    -- tmp handler

    handler.sendbuffer = function( )
        local serverip, serverport = client:getpeername( )
        local clientip, clientport = client:getsockname( )
        local wrappedhandler, socket, err = wrapconnection( nil, listeners, client, serverip, clientip, serverport, clientport, pattern, sslctx, startssl, id )
        if not wrappedhandler then
            failure( id, err or "wrapping handler failed" )
        else
            dispatch( wrappedhandler )
        end
        _writetimes[ handler ] = nil    -- remove tmp handler
        _socketlist[ client ] = nil
        _sendlistlen = removesocket( _sendlist, client, _sendlistlen )
        handler = nil
        return true
    end
    handler.close = function( )
        handler.sendbuffer = return_false
        _closelist[ handler ] = "connection timeout"
        _writetimes[ handler ] = nil
        _socketlist[ client ] = nil
        _sendlistlen = removesocket( _sendlist, client, _sendlistlen )
    end
    handler.kill = function( )
        _closelist[ handler ] = nil
        failure( id, "connection timeout" )
        handler = nil
    end

    _writetimes[ handler ] = _currenttime
    _socketlist[ client ] = handler
    _sendlistlen = _sendlistlen + 1
    _sendlist[ _sendlistlen ] = client
    _sendlist[ client ] = _sendlistlen

    return handler
end

wrapserver = function( listeners, socket, serverip, serverport, pattern, sslctx, maxconnections, startssl )    -- this function wraps a server

    local id = { }    -- connection id

    maxconnections = maxconnections or _maxclientsperserver

    local connections = 0

    local dispatch, disconnect = listeners.incoming or listeners.listener, listeners.disconnect

    local err

    local ssl = false

    if sslctx then
        if not ssl_newcontext then
            return nil, "luasec not found"
        elseif not cfg_get "use_ssl" then
            return nil, "ssl is deactivated"
        end
        if type( sslctx ) ~= "table" then
            out_error "server.lua: function 'wrapserver': wrong server sslctx"
            return nil, "wrong server sslctx"
        end
        sslctx, err = ssl_newcontext( sslctx )
        if not sslctx then
            err = err or "wrong sslctx parameters"
            out_error( "server.lua: function 'wrapserver': wrong sslctx parameters: ", err )
            return nil, err
        end
        ssl = true
    else
        out_put( "server.lua: function 'wrapserver': ssl not enabled on ", serverport )
    end

    local accept = socket.accept

    --// public methods of the object //--

    local handler = { }

    handler.shutdown = function( )
        for _, h in pairs( _socketlist ) do
            if h.serverport( ) == serverport then
                h.close( )
            end
        end
        handler.readbuffer = return_false    -- dont accept anymore
    end

    handler.ssl = function( )
        return ssl
    end
    handler.id = function( )
        return id
    end
    handler.remove = function( )
        connections = connections - 1
    end
    handler.close = function( )
        _closelist[ handler ] = "closed"
    end
    handler.kill = function( )
        out_put "server.lua: function 'wrapserver': try to close server handler, closing connected clients..."
        handler.readbuffer = return_false    -- dont read anymore
        _readlistlen = removesocket( _readlist, socket, _readlistlen )
        _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
        _socketlist[ socket ] = nil
        _writetimes[ handler ] = nil
        _activitytimes[ handler ] = nil
        _closelist[ handler ] = nil
        _server[ serverport ] = nil
        socket:close( )
        handler = nil
        socket = nil
        mem_free( )
        out_put "server.lua: function 'wrapserver': closed server handler and removed socket from lists"
    end
    handler.ip = function( )
        return serverip
    end
    handler.serverip = handler.ip
    handler.serverport = function( )
        return serverport
    end
    handler.socket = function( )
        return socket
    end
    handler.readbuffer = function( )
        if connections > maxconnections then
            out_put( "server.lua: function 'wrapserver': refused new client connection: server full" )
            return false
        end
        local client, err = accept( socket )    -- try to accept
        if client then
            local clientip, clientport = client:getpeername( )
            client:settimeout( 0 )
            local _, err = client:setoption( "reuseaddr", true )
            local _, err2 = client:setoption( "keepalive", true )
            if err or err2 then
                out_put( "server.lua: function 'wrapserver', luasocket socket setoption: ", err or err2 )
                return false
            end
            local handler, client, err = wrapconnection( handler, listeners, client, serverip, clientip, serverport, clientport, pattern, sslctx, startssl )    -- wrap new client socket
            if err then    -- error while wrapping ssl socket
                return false
            end
            connections = connections + 1
            out_put( "server.lua: function 'wrapserver': accepted new client connection from ", clientip, ":", clientport, " to ", serverport )
            return dispatch( handler )
        elseif err then    -- maybe timeout or something else
            out_put( "server.lua: function 'wrapserver': error with new client connection: ", err )
            return false
        end
    end
    return handler
end

wrapconnection = function( server, listeners, socket, serverip, clientip, serverport, clientport, pattern, sslctx, startssl, id )    -- this function wraps a client to a handler object

    id = id or { }

    socket:settimeout( 0 )

    --// local import of socket methods //--

    local send
    local receive
    local shutdown

    --// private closures of the object //--

    local ssl

    local dispatch = listeners.incoming or listeners.listener
    local disconnect = listeners.disconnect

    local bufferqueue = { }    -- buffer array
    local bufferqueuelen = 0    -- end of buffer array

    local toclose
    local fatalerror
    local needtls

    local bufferlen = 0

    local noread = false
    local nosend = false

    local sendtraffic, readtraffic = 0, 0

    local maxsendlen = _maxsendlen
    local maxreadlen = _maxreadlen

    --// public methods of the object //--

    local handler = { }

    handler.id = function( )
        return id
    end
    handler.dispatch = function( )
        return dispatch
    end
    handler.disconnect = function( )
        return disconnect
    end
    handler.setlistener = function( listeners )
        dispatch = listeners.incoming
        disconnect = listeners.disconnect
    end
    handler.getstats = function( )
        return readtraffic, sendtraffic
    end
    handler.getsslinfo = function( )
        if ssl then
            return socket:info( )
        end
        return nil
    end
    handler.ssl = function( )
        return ssl
    end

    handler.kill = function( reason )
        disconnect( handler, reason or fatalerror or "closed" )    -- disconnect handler
        if not fatalerror and ( bufferqueuelen ~= 0 ) then
            send( socket, table_concat( bufferqueue, "", 1, bufferqueuelen ), 1, bufferlen )    -- forced send
        end
        _readlistlen = removesocket( _readlist, socket, _readlistlen )
        _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
        _socketlist[ socket ] = nil
        _writetimes[ handler ] = nil
        _activitytimes[ handler ] = nil
        _closelist[ handler ] = nil
        socket:close( )
        handler = nil
        socket = nil
        mem_free( )
        _ = server and server.remove( )
        out_put "server.lua: function 'wrapconnection': closed client handler and removed socket from lists"
    end
    handler.close = function( forced )
        out_put "server.lua: function 'wrapconnection': try to close client handler..."
        handler.readbuffer = return_false    -- dont read anymore
        handler.write = return_false    -- dont write anymore
        _activitytimes[ handler ] = nil   -- no activity check anymore
        if forced then    -- close immediately
            _closelist[ handler ] = forced    -- cannot close the client at the moment, have to wait to the end of the cycle
        else    -- wait to empty bufferqueue
            _readlistlen = removesocket( _readlist, socket, _readlistlen )
            toclose = true
            out_put "server.lua: function 'wrapconnection': waiting for unsent data..."
        end
        return true
    end
    handler.ip = function( )
        return clientip
    end
    handler.clientip = handler.ip
    handler.clientport = function( )
        return clientport
    end
    handler.serverip = function( )
        return serverip
    end
    handler.serverport = function( )
        return serverport
    end
    local write = function( data )
        bufferlen = bufferlen + string_len( data )
        if bufferlen > maxsendlen then
            handler.close( "send buffer exceeded" )
            return false
        elseif not _sendlist[ socket ] then
            _sendlistlen = _sendlistlen + 1
            _sendlist[ _sendlistlen ] = socket
            _sendlist[ socket ] = _sendlistlen
        end
        bufferqueuelen = bufferqueuelen + 1
        bufferqueue[ bufferqueuelen ] = data
        _writetimes[ handler ] = _writetimes[ handler ] or _currenttime
        return true
    end
    handler.write = write
    handler.pattern = function( new )
        pattern = new or pattern
        return pattern
    end
    handler.bufferlen = function( readlen, sendlen )
        maxsendlen = sendlen or maxsendlen
        maxreadlen = readlen or maxreadlen
        return maxreadlen, maxsendlen
    end

    local try_sending_on_write
    local try_reading_on_write
    local try_sending_on_read
    local try_reading_on_read

    local _readbuffer

    _readbuffer = function( )    -- this function reads data
        local buffer, err, part = receive( socket, pattern )    -- receive buffer with "pattern"
        _activitytimes[ handler ] = _currenttime
        if ( not err ) or ( part and ( ( err == "wantread" ) or ( err == "wantwrite" ) ) ) then    -- received something; "timeout" is considered as fatal error, as luadch uses the *l pattern in receive
            local buffer = buffer or part
            local len = string_len( buffer )
            if len > maxreadlen then
                handler.close( "receive buffer exceeded" )
                return false
            end
            local count = len * STAT_UNIT
            readtraffic = readtraffic + count
            _readtraffic = _readtraffic + count

            try_reading_on_write = do_nothing
            try_reading_on_read = _readbuffer

            if ( err == "wantwrite" ) then
              try_reading_on_write = _readbuffer
              try_reading_on_read = do_nothing
              if not _sendlist[ socket ] then   -- add socket to writelist
                _sendlistlen = _sendlistlen + 1
                _sendlist[ _sendlistlen ] = socket
                _sendlist[ socket ] = _sendlistlen
              end
            end
            out_put( "server.lua: function 'wrapconnection': read data '", buffer, "', error: ", err )
            return dispatch( handler, buffer, err )
        else    -- connections was closed or fatal error
            out_put( "server.lua: function 'wrapconnection': client ", clientip, ":", clientport, " error: ", err )
            fatalerror = err or "fatal error"
            handler.close( fatalerror )
            return false
        end
    end

    local _sendbuffer

    _sendbuffer = function( )    -- this function sends data
        local buffer = table_concat( bufferqueue, "", 1, bufferqueuelen )
        local succ, err, byte = send( socket, buffer, 1, bufferlen )
        local count = ( succ or byte or 0 ) * STAT_UNIT
        sendtraffic = sendtraffic + count
        _sendtraffic = _sendtraffic + count
        _ = _cleanqueue and clean( bufferqueue )
        out_put( "server.lua: function 'wrapconnection': sent '", buffer, "', bytes: ", succ, ", error: ", err, ", part: ", byte, ", to: ", clientip, ":", clientport )
        if succ then    -- sending succesful
            bufferqueuelen = 0
            bufferlen = 0
            if toclose then
                handler.close( "regular close" )
                return true
            end
            _writetimes[ handler ] = nil
            _activitytimes[ handler ] = _currenttime
            try_sending_on_write = _sendbuffer
            try_sending_on_read = do_nothing
            return true
        elseif byte and ( err ~= "closed" ) then    -- sending not finished yet
            buffer = string_sub( buffer, byte + 1, bufferlen )    -- new buffer
            bufferqueue[ 1 ] = buffer    -- insert new buffer in queue
            bufferqueuelen = 1
            bufferlen = bufferlen - byte
            _writetimes[ handler ] = _currenttime
            if ( err ~= "wantread" ) then
              if not _sendlist[ socket ] then   -- add socket to sendlist again
                _sendlistlen = _sendlistlen + 1
                _sendlist[ _sendlistlen ] = socket
                _sendlist[ socket ] = _sendlistlen
              end
              try_sending_on_write = _sendbuffer
              try_sending_on_read = do_nothing
            else  -- "wantread"...
              try_sending_on_write = do_nothing
              try_sending_on_read = _sendbuffer
            end
            return true
        else    -- connection was closed during sending or fatal error
            out_put( "server.lua: function 'wrapconnection': client ", clientip, ":", clientport, " error: ", err )
            fatalerror = err or "fatal error"
            handler.close( fatalerror )
            return false
        end
    end

    -- default behaviour

    try_sending_on_write = _sendbuffer
    try_reading_on_write = do_nothing
    try_sending_on_read = do_nothing
    try_reading_on_read = _readbuffer

    local handle_write_event = function( )
      _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )    -- delete socket from writelist in any case
      try_sending_on_write( )
      try_reading_on_write( )
    end

    local handle_read_event = function( )
      try_sending_on_read( )
      try_reading_on_read( )
    end

    if sslctx then    -- ssl?
        ssl = true
        local wrote
        local handshake = coroutine_wrap( function( client )    -- create handshake coroutine
                local err
                for i = 1, 20 do    -- 20 handshake attemps
                    _, err = client:dohandshake( )
                    if not err then
                        out_put( "server.lua: function 'wrapconnection': ssl handshake done" )
                        _sendlistlen = ( wrote and removesocket( _sendlist, socket, _sendlistlen ) ) or _sendlistlen
                        handler.readbuffer = handle_read_event   -- when handshake is done, replace the handshake function with regular functions
                        handler.sendbuffer = handle_write_event
                        --return dispatch( handler )
                        return true
                    else
                        out_put( "server.lua: function 'wrapconnection': error during ssl handshake: ", err )
                        if err == "wantwrite" then
                          if not wrote then
                            _sendlistlen = _sendlistlen + 1
                            _sendlist[ _sendlistlen ] = client
                            wrote = true
                          end
                        elseif err == "wantread" then
                            if wrote then
                              _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
                              wrote = false
                            end
                        else
                          break
                        end
                        --coroutine_yield( handler, nil, err )    -- handshake not finished
                        coroutine_yield( )
                    end
                end
                err = err or "?"
                fatalerror = "max handshake attemps exceeded (last error: " .. tostring( err ) .. ")"
                handler.close( fatalerror )    -- forced disconnect
                return false    -- handshake failed
            end
        )
        if startssl then    -- ssl now?
            out_put( "server.lua: function 'wrapconnection': starting ssl handshake" )
            local err
            socket, err = ssl_wrap( socket, sslctx )    -- wrap socket
            if err then
                out_put( "server.lua: function 'wrapconnection': ssl error: ", err )
                mem_free( )
                return nil, nil, err    -- fatal error
            end
            socket:settimeout( 0 )
            handler.readbuffer = handshake
            handler.sendbuffer = handshake
            handshake( socket )    -- do handshake
        else
            handler.starttls = function( now )
                if not now then
                    out_put "server.lua: function 'wrapconnection': we need to do tls, but delaying until later"
                    needtls = true
                    return
                end
                out_put( "server.lua: function 'wrapconnection': attempting to start tls on " .. tostring( socket ) )
                local oldsocket, err = socket
                socket, err = ssl_wrap( socket, sslctx )    -- wrap socket
                out_put( "server.lua: function 'wrapconnection': sslwrapped socket is " .. tostring( socket ) )
                if err then
                    out_put( "server.lua: function 'wrapconnection': error while starting tls on client: ", err )
                    return nil, err    -- fatal error
                end

                socket:settimeout( 0 )

                -- add the new socket to our system

                send = socket.send
                receive = socket.receive
                shutdown = do_nothing

                _socketlist[ socket ] = handler
                _readlistlen = _readlistlen + 1
                _readlist[ _readlistlen ] = socket
                _readlist[ socket ] = _readlistlen

                -- remove traces of the old socket

                _readlistlen = removesocket( _readlist, oldsocket, _readlistlen )
                _sendlistlen = removesocket( _sendlist, oldsocket, _sendlistlen )
                _socketlist[ oldsocket ] = nil

                handler.starttls = nil
                needtls = nil

                handler.receivedata = handler.handshake
                handler.dispatchdata = handler.handshake
                handshake( socket )    -- do handshake
            end
            handler.readbuffer = handle_read_event
            handler.sendbuffer = handle_write_event
        end
    else    -- normal connection
      ssl = false
      handler.readbuffer = handle_read_event
      handler.sendbuffer = handle_write_event
    end

    send = socket.send
    receive = socket.receive
    shutdown = ( ssl and do_nothing ) or socket.shutdown

    _socketlist[ socket ] = handler
    _readlistlen = _readlistlen + 1
    _readlist[ _readlistlen ] = socket
    _readlist[ socket ] = _readlistlen

    return handler, socket
end


do_nothing = function( )
end

return_false = function( )
    return false
end

removesocket = function( list, socket, len )    -- this function removes sockets from a list (copied from copas)
    local pos = list[ socket ]
    if pos then
        list[ socket ] = nil
        local last = list[ len ]
        list[ len ] = nil
        if last ~= socket then
            list[ last ] = pos
            list[ pos ] = last
        end
        return len - 1
    end
    return len
end

closesocket = function( socket )
    _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
    _readlistlen = removesocket( _readlist, socket, _readlistlen )
    _socketlist[ socket ] = nil
    socket:close( )
    mem_free( )
end

----------------------------------// PUBLIC //--

addclient = function( address, port, listeners, pattern, sslctx, startssl )
    local err
    out_put( "server.lua: function 'addclient': autossl on ", port, " is ", startssl )
    if type( listeners ) ~= "table" then
        err = "invalid listener table"
    end
    if not type( port ) == "number" or not ( port >= 0 and port <= 65535 ) then
        err = "invalid port"
    --elseif _server[ port ] then
    --    err =  "listeners on port '" .. port .. "' already exist"
    elseif sslctx and not luasec then
        err = "luasec not found"
    end
    if err then
        out_error( "server.lua: function 'addclient': ", err )
        return nil, err
    end
    local client, err = socket_tcp( )
    if err then
        return nil, err
    end
    local handler
    local id = { }    -- connection id
    client:settimeout( 0 )
    _, err = client:connect( address, port )
    if err == "timeout" then    -- try again
        wrapclient( client, listeners, pattern, sslctx, startssl, id )
    else
        local serverip, serverport = client:getpeername( )
        local clientip, clientport = client:getsockname( )
        handler, client, err = wrapconnection( nil, listeners, client, serverip, clientip, serverport, clientport, pattern, sslctx, startssl, id )
    end
    return handler, err, id
end

addserver = function( p ) -- listeners, port, addr, pattern, sslctx, maxconnections, startssl, family )    -- this function provides a way for other scripts to reg a server
    local err
    out_put( "server.lua: function 'addserver': autossl on ", p.port, " is ", p.startssl )
    if type( p.listeners ) ~= "table" then
        err = "invalid listener table"
    end
    if not type( p.port ) == "number" or not ( p.port >= 0 and p.port <= 65535 ) then
        err = "invalid port"
    elseif _server[ p.port ] then
        err =  "listeners on port '" .. p.port .. "' already exist"
    elseif p.sslctx and not luasec then
        err = "luasec not found"
    end
    if err then
        out_error( "server.lua: function 'addserver': ", err )
        return nil, err
    end
    p.addr = p.addr or "*"
    local server, err
    if p.family == "ipv6" then
        server, err = luasocket.tcp6( )
    else
        server, err = luasocket.tcp4( )
    end
    if err then
        out_error( "server.lua: function 'addserver', luasocket cannot create master obejct: ", err )
        return nil, err
    end
    local num, err = server:bind( p.addr, p.port )
    if err then
        out_error( "server.lua: function 'addserver', luasocket socket bind: ", err )
        return nil, err
    end
    local num, err = server:listen( )
    if err then
        out_error( "server.lua: function 'addserver', luasocket socket listen: ", err )
        return nil, err
    end
    local addr, port = server:getsockname( )
    local handler, err = wrapserver( p.listeners, server, addr, port, p.pattern, p.sslctx, p.maxconnections, p.startssl )    -- wrap new server socket
    if not handler then
        server:close( )
        return nil, err
    end
    server:settimeout( 0 )
    local _, err = server:setoption( "reuseaddr", true )
    local _, err2 = server:setoption( "keepalive", true )
    if err or err2 then
        out_error( "server.lua: function 'addserver', luasocket socket setoption: ", err or err2 )
        return nil, err
    end
    _readlistlen = _readlistlen + 1
    _readlist[ _readlistlen ] = server
    _server[ port ] = handler
    _socketlist[ server ] = handler
    out_put( "server.lua: function 'addserver': new server listener on '", addr, ":", port, "'" )
    return handler
end

killall = function( )
    local tmp = { }
    for socket, handler in pairs( _socketlist ) do
        tmp[ socket ] = handler
    end
    for socket, handler in pairs( tmp ) do
        handler.kill( )
        _socketlist[ socket ] = nil
    end
    _readlistlen = 0
    _sendlistlen = 0
    _timerlistlen = 0
    _server = { }
    _readlist = { }
    _sendlist = { }
    _timerlist = { }
    _socketlist = { }
    mem_free( )
end

getsettings = function( )
    return _selecttimeout, _sleeptime, _maxsendlen, _maxreadlen, _checkinterval, _sendtimeout, _max_idle_time, _cleanqueue, _maxclientsperserver
end

changesettings = function( new )
    if type( new ) ~= "table" then
        return nil, "invalid settings table"
    end
    _selecttimeout = tonumber( new.timeout ) or _selecttimeout
    _sleeptime = tonumber( new.sleeptime ) or _sleeptime
    _maxsendlen = tonumber( new.maxsendlen ) or _maxsendlen
    _maxreadlen = tonumber( new.maxreadlen ) or _maxreadlen
    _checkinterval = tonumber( new.checkinterval ) or _checkinterval
    _sendtimeout = tonumber( new.sendtimeout ) or _sendtimeout
    _max_idle_time = tonumber( new.readtimeout ) or _max_idle_time
    _cleanqueue = new.cleanqueue
    _maxclientsperserver = new._maxclientsperserver or _maxclientsperserver
    return true
end

addtimer = function( listener )
    if ( type( listener ) ~= "function" ) and ( type( listener ) ~= "thread" ) then
        return nil, "invalid listener type '" .. type( listener ) .. "'"
    end
    _timerlistlen = _timerlistlen + 1
    _timerlist[ _timerlistlen ] = listener
    return true
end

stats = function( )
    return _readtraffic, _sendtraffic, _readlistlen, _sendlistlen, _timerlistlen
end

loop = function( )    -- this is the main loop of the program
    signal_set( "hub", "run" )
    repeat
        local read, write, err = socket_select( _readlist, _sendlist, _selecttimeout )
        for i, socket in ipairs( write ) do    -- send data waiting in writequeues
            local handler = _socketlist[ socket ]
            if handler then
                handler.sendbuffer( )
            else
                closesocket( socket )
                out_put "server.lua: function 'loop': found no handler and closed socket (writelist)"    -- this should not happen
            end
        end
        for i, socket in ipairs( read ) do    -- receive data
            local handler = _socketlist[ socket ]
            if handler then
                handler.readbuffer( )
            else
                closesocket( socket )
                out_put "server.lua: function 'loop': found no handler and closed socket (readlist)"    -- this can happen
            end
        end
        _currenttime = os_time( )
        if os_difftime( _currenttime, _timer ) >= 1 then
            local dead = { }
            for i = 1, _timerlistlen do
                local timer = _timerlist[ i ]
                if type( timer ) == "thread" then
                    local status = coroutine.status( timer )
                    if status == "dead" then
                        dead[ i ] = true
                    elseif status ~= "running" then
                        coroutine.resume(timer)
                    end
                else
                    timer( )
                end
            end
            for i = _timerlistlen, 1, -1 do -- remove dead coroutines; don't use swap and pop to preserve order of timers (see http://lua-users.org/lists/lua-l/2013-11/msg00031.html)
                if dead[ i ] then
                    table.remove( _timerlist, i )
                    _timerlistlen = _timerlistlen - 1
                end
            end
            _timer = _currenttime
        end
        for handler, err in pairs( _closelist ) do
            handler.kill( err )    -- close, kill, delete handler/socket
        end
        clean( _closelist )
        socket_sleep( _sleeptime )    -- wait some time
        collectgarbage( )
    until signal_get "hub" ~= "run"
    return signal_get "hub"
end

stop = function( bol )
    _run = bol
end

----------------------------------// BEGIN //--

_timer = os_time( )
_starttime = os_time( )

addtimer( function( )
        local difftime = os_difftime( _currenttime, _starttime )
        if difftime >= _checkinterval then
            _starttime = _currenttime
            for handler, timestamp in pairs( _writetimes ) do
                if os_difftime( _currenttime, timestamp ) >= _sendtimeout then
                    handler.close( "timeout" )    -- forced disconnect
                end
            end
            for handler, timestamp in pairs( _activitytimes ) do
                if os_difftime( _currenttime, timestamp ) >= _max_idle_time then
                    handler.close( "timeout" )    -- forced disconnect
                end
            end
        end
    end
)

----------------------------------// PUBLIC INTERFACE //--

return {

    stop = stop,
    loop = loop,
    stats = stats,
    killall = killall,
    addtimer = addtimer,
    addclient = addclient,
    addserver = addserver,
    getsettings = getsettings,
    changesettings = changesettings,

}
