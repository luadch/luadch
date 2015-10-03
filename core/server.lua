--[[

        server.lua by blastbeat

        - this script contains the server loop of the program
        - other scripts can reg a server here

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

local id
local stop
local loop
local stats
local idfalse
local addtimer
local closeall
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

--// tables //--

local _server
local _readlist
local _timerlist
local _sendlist
local _socketlist
local _closelist
local _readtimes
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
local _readtimeout

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
_readtimes = { }   -- key = handler, value = timestamp of last data reading
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

_checkinterval = 60    -- interval in secs to check idle clients
_sendtimeout = 60    -- allowed send idle time in secs
_readtimeout = 6 * 60 * 60    -- allowed read idle time in secs

_cleanqueue = false    -- clean bufferqueue after using

_maxclientsperserver = 1000

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
        handler.sendbuffer = idfalse
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
            out_error "server.lua: wrong server sslctx"
            return nil, "wrong server sslctx"
        end
        sslctx, err = ssl_newcontext( sslctx )
        if not sslctx then
            err = err or "wrong sslctx parameters"
            out_error( "server.lua: ", err )
            return nil, err
        end
        ssl = true
    else
        out_put( "server.lua: ssl not enabled on ", serverport )
    end

    local accept = socket.accept

    --// public methods of the object //--

    local handler = { }

    handler.shutdown = function( ) end

    handler.ssl = function( )
        return ssl
    end
    handler.id = function( )
        return id
    end
    handler.remove = function( )
        connections = connections - 1
    end
    handler.kill = idfalse
    handler.close = function( )
        out_put "server.lua: try to close server handler, closing connected clients..."
        handler.readbuffer = idfalse    -- dont read anymore
        for socket, handler in pairs( _socketlist ) do
            if handler.serverport( ) == serverport then
                handler.kill( "server closed" )
            end
        end
        _readlistlen = removesocket( _readlist, socket, _readlistlen )
        _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
        _socketlist[ socket ] = nil
        _writetimes[ handler ] = nil
        _readtimes[ handler ] = nil
        _closelist[ handler ] = nil
        _server[ serverport ] = nil
        socket:close( )
        handler = nil
        socket = nil
        mem_free( )
        out_put "server.lua: closed server handler and removed socket from lists"
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
            out_put( "server.lua: refused new client connection: server full" )
            return false
        end
        local client, err = accept( socket )    -- try to accept
        if client then
            local clientip, clientport = client:getpeername( )
            client:settimeout( 0 )
            local handler, client, err = wrapconnection( handler, listeners, client, serverip, clientip, serverport, clientport, pattern, sslctx, startssl )    -- wrap new client socket
            if err then    -- error while wrapping ssl socket
                return false
            end
            connections = connections + 1
            out_put( "server.lua: accepted new client connection from ", clientip, ":", clientport, " to ", serverport )
            return dispatch( handler )
        elseif err then    -- maybe timeout or something else
            out_put( "server.lua: error with new client connection: ", err )
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

--[[
    handler.send = function( _, data, i, j )
        return send( socket, data, i, j )
    end
    handler.receive = function( pattern, prefix )
        return receive( socket, pattern, prefix )
    end
    handler.shutdown = function( pattern )
        return shutdown( socket, pattern )
    end
]]

    handler.kill = function( reason )
        disconnect( handler, reason or fatalerror or "closed" )    -- disconnect handler
        if not fatalerror and ( bufferqueuelen ~= 0 ) then
            send( socket, table_concat( bufferqueue, "", 1, bufferqueuelen ), 1, bufferlen )    -- forced send
        end
        _readlistlen = removesocket( _readlist, socket, _readlistlen )
        _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
        _socketlist[ socket ] = nil
        _writetimes[ handler ] = nil
        _readtimes[ handler ] = nil
        _closelist[ handler ] = nil
        socket:close( )
        handler = nil
        socket = nil
        mem_free( )
        _ = server and server.remove( )
        out_put "server.lua: closed client handler and removed socket from lists"
    end
    handler.close = function( forced )
        out_put "server.lua: try to close client handler..."
        handler.readbuffer = idfalse    -- dont read anymore
        handler.write = idfalse    -- dont write anymore
        if forced then    -- close immediately
            _closelist[ handler ] = forced    -- cannot close the client at the moment, have to wait to the end of the cycle
        else    -- wait to empty bufferqueue
            _readlistlen = removesocket( _readlist, socket, _readlistlen )
            _readtimes[ handler ] = nil
            toclose = true
            out_put "server.lua: waiting for unsent data..."
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
--[[
    handler.bufferqueue = function( )
        return bufferqueue
    end
    handler.socket = function( )
        return socket
    end]]
    handler.pattern = function( new )
        pattern = new or pattern
        return pattern
    end
    handler.bufferlen = function( readlen, sendlen )
        maxsendlen = sendlen or maxsendlen
        maxreadlen = readlen or maxreadlen
        return maxreadlen, maxsendlen
    end
--[[    handler.lock = function( switch )
        if switch == true then
            handler.write = idfalse
            local tmp = _sendlistlen
            _sendlistlen = removesocket( _sendlist, socket, _sendlistlen )
            _writetimes[ handler ] = nil
            if _sendlistlen ~= tmp then
                nosend = true
            end
            tmp = _readlistlen
            _readlistlen = removesocket( _readlist, socket, _readlistlen )
            _readtimes[ handler ] = nil
            if _readlistlen ~= tmp then
                noread = true
            end
        elseif switch == false then
            handler.write = write
            if noread then
                noread = false
                _readlistlen = _readlistlen + 1
                _readlist[ socket ] = _readlistlen
                _readlist[ _readlistlen ] = socket
                _readtimes[ handler ] = _currenttime
            end
            if nosend then
                nosend = false
                write( "" )
            end
        end
        return noread, nosend
    end]]

    local timeouts = 0
    local wantreads = 0

    local do_nothing = function( ) end

    local try_sending_on_write
    local try_reading_on_write
    local try_sending_on_read
    local try_reading_on_read

    local _readbuffer

    _readbuffer = function( )    -- this function reads data
        local buffer, err, part = receive( socket, pattern )    -- receive buffer with "pattern"
        --[[if err == "timeout" then
            timeouts = timeouts + 1
            wantreads = 0
        elseif err == "wantread" then
            timeouts = 0
            wantreads = wantreads + 1
        else
            timeouts = 0
            wantreads = 0
        end
        if ( timeouts > 5 ) or ( wantreads > 5 ) then
            out_put( "server.lua: client ", clientip, ":", clientport, " error: ", err )
            fatalerror = err or "fatal error"
            handler.close( fatalerror )
            return false
        end]]
        if ( not err ) or ( part and ( ( err == "wantread" ) or ( err == "wantwrite" ) or ( err == "timeout" ) ) ) then    -- received something
            local buffer = buffer or part
            local len = string_len( buffer )
            if len > maxreadlen then
                handler.close( "receive buffer exceeded" )
                return false
            end
            local count = len * STAT_UNIT
            readtraffic = readtraffic + count
            _readtraffic = _readtraffic + count
            _readtimes[ handler ] = _currenttime

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
            out_put( "server.lua: read data '", buffer, "', error: ", err )
            return dispatch( handler, buffer, err )
        else    -- connections was closed or fatal error
            out_put( "server.lua: client ", clientip, ":", clientport, " error: ", err )
            fatalerror = err or "fatal error"
            handler.close( fatalerror )
            return false
        end
    end

    local _sendbuffer

    _sendbuffer = function( )    -- this function sends data
        local buffer = table_concat( bufferqueue, "", 1, bufferqueuelen )
        --if buffer == "" then return true end    -- nothing to send
        local succ, err, byte = send( socket, buffer, 1, bufferlen )
        local count = ( succ or byte or 0 ) * STAT_UNIT
        sendtraffic = sendtraffic + count
        _sendtraffic = _sendtraffic + count
        _ = _cleanqueue and clean( bufferqueue )
        out_put( "server.lua: sended '", buffer, "', bytes: ", succ, ", error: ", err, ", part: ", byte, ", to: ", clientip, ":", clientport )
        if succ then    -- sending succesful
            bufferqueuelen = 0
            bufferlen = 0
            if toclose then
                handler.close( "regular close" )
                return true
            end
            --_ = needtls and handler.starttls( true )      -- not needed in luadch
            --_sendlistlen = removesocket( _sendlist, socket, _sendlistlen )    -- delete socket from writelist
            _writetimes[ handler ] = nil
            try_sending_on_write = _sendbuffer
            try_sending_on_read = do_nothing
            return true
        elseif byte and ( err ~= "closed" ) then    -- want write
            buffer = string_sub( buffer, byte + 1, bufferlen )    -- new buffer
            bufferqueue[ 1 ] = buffer    -- insert new buffer in queue
            bufferqueuelen = 1
            bufferlen = bufferlen - byte
            _writetimes[ handler ] = _currenttime
            if ( err ~= "wantread" ) then
              if not _sendlist[ socket ] then   -- add socket to writelist again
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
            out_put( "server.lua: client ", clientip, ":", clientport, " error: ", err )
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
                        out_put( "server.lua: ssl handshake done" )
                        _sendlistlen = ( wrote and removesocket( _sendlist, socket, _sendlistlen ) ) or _sendlistlen
                        handler.readbuffer = handle_read_event   -- when handshake is done, replace the handshake function with regular functions
                        handler.sendbuffer = handle_write_event
                        --return dispatch( handler )
                        return true
                    else
                        out_put( "server.lua: error during ssl handshake: ", err )
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
                fatalerror = "max handshake attemps exceeded"
                handler.close( fatalerror )    -- forced disconnect
                return false    -- handshake failed
            end
        )
        if startssl then    -- ssl now?
            out_put( "server.lua: starting ssl handshake" )
            local err
            socket, err = ssl_wrap( socket, sslctx )    -- wrap socket
            if err then
                out_put( "server.lua: ssl error: ", err )
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
                    out_put "server.lua: we need to do tls, but delaying until later"
                    needtls = true
                    return
                end
                out_put( "server.lua: attempting to start tls on " .. tostring( socket ) )
                local oldsocket, err = socket
                socket, err = ssl_wrap( socket, sslctx )    -- wrap socket
                out_put( "server.lua: sslwrapped socket is " .. tostring( socket ) )
                if err then
                    out_put( "server.lua: error while starting tls on client: ", err )
                    return nil, err    -- fatal error
                end

                socket:settimeout( 0 )

                -- add the new socket to our system

                send = socket.send
                receive = socket.receive
                shutdown = id

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
    shutdown = ( ssl and id ) or socket.shutdown

    _socketlist[ socket ] = handler
    _readlistlen = _readlistlen + 1
    _readlist[ _readlistlen ] = socket
    _readlist[ socket ] = _readlistlen

    return handler, socket
end

id = function( )
end

idfalse = function( )
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
    out_put( "server.lua: autossl on ", port, " is ", startssl )
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
        out_error( "server.lua: ", err )
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

addserver = function( listeners, port, addr, pattern, sslctx, maxconnections, startssl )    -- this function provides a way for other scripts to reg a server
    local err
    out_put( "server.lua: autossl on ", port, " is ", startssl )
    if type( listeners ) ~= "table" then
        err = "invalid listener table"
    end
    if not type( port ) == "number" or not ( port >= 0 and port <= 65535 ) then
        err = "invalid port"
    elseif _server[ port ] then
        err =  "listeners on port '" .. port .. "' already exist"
    elseif sslctx and not luasec then
        err = "luasec not found"
    end
    if err then
        out_error( "server.lua: ", err )
        return nil, err
    end
    addr = addr or "*"
    local server, err = socket_bind( addr, port )
    if err then
        out_error( "server.lua: ", err )
        return nil, err
    end
    local addr, port = server:getsockname( )
    local handler, err = wrapserver( listeners, server, addr, port, pattern, sslctx, maxconnections, startssl )    -- wrap new server socket
    if not handler then
        server:close( )
        return nil, err
    end
    server:settimeout( 0 )
    _readlistlen = _readlistlen + 1
    _readlist[ _readlistlen ] = server
    _server[ port ] = handler
    _socketlist[ server ] = handler
    out_put( "server.lua: new server listener on '", addr, ":", port, "'" )
    return handler
end

closeall = function( )
    for socket, handler in pairs( _socketlist ) do
        handler.close( )
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
    return _selecttimeout, _sleeptime, _maxsendlen, _maxreadlen, _checkinterval, _sendtimeout, _readtimeout, _cleanqueue, _maxclientsperserver
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
    _readtimeout = tonumber( new.readtimeout ) or _readtimeout
    _cleanqueue = new.cleanqueue
    _maxclientsperserver = new._maxclientsperserver or _maxclientsperserver
    return true
end

addtimer = function( listener )
    if type( listener ) ~= "function" then
        return nil, "invalid listener function"
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
                out_put "server.lua: found no handler and closed socket (writelist)"    -- this should not happen
            end
        end
        for i, socket in ipairs( read ) do    -- receive data
            local handler = _socketlist[ socket ]
            if handler then
                handler.readbuffer( )
            else
                closesocket( socket )
                out_put "server.lua: found no handler and closed socket (readlist)"    -- this can happen
            end
        end
        _currenttime = os_time( )
        if os_difftime( _currenttime - _timer ) >= 1 then
            for i = 1, _timerlistlen do
                _timerlist[ i ]( )    -- fire timers
            end
            _timer = _currenttime
        end
        for handler, err in pairs( _closelist ) do
            handler.kill( err )    -- close, kill, delete handler/socket
        end
        clean( _closelist )
        socket_sleep( _sleeptime )    -- wait some time
        --collectgarbage( )
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
        local difftime = os_difftime( _currenttime - _starttime )
        if difftime > _checkinterval then
            _starttime = _currenttime
            for handler, timestamp in pairs( _writetimes ) do
                if os_difftime( _currenttime - timestamp ) > _sendtimeout then
                    handler.close( "timeout" )    -- forced disconnect
                end
            end
            for handler, timestamp in pairs( _readtimes ) do
                if os_difftime( _currenttime - timestamp ) > _readtimeout then
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
    closeall = closeall,
    addtimer = addtimer,
    addclient = addclient,
    addserver = addserver,
    getsettings = getsettings,
    changesettings = changesettings,

}
