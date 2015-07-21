--[[

        server.lua by blastbeat

        - this script contains the server loop of the program
        - other scripts can reg a server here

]]--

----------------------------------// DECLARATION //--

--// constants //--

local STAT_UNIT = 1 / ( 1024 * 1024 )    -- mb

--// lua functions //--

local type = use "type"
local pairs = use "pairs"
local ipairs = use "ipairs"
local tostring = use "tostring"
local collectgarbage = use "collectgarbage"

--// lua libs //--

local table = use "table"
local coroutine = use "coroutine"

--// lua lib methods //--

local table_concat = table.concat
local table_remove = table.remove
local string_sub = use'string'.sub
local coroutine_wrap = coroutine.wrap
local coroutine_yield = coroutine.yield

--// extern libs //--

local luasec = use "ssl"
local luasocket = use "socket"

--// extern lib methods //--

local ssl_wrap = ( luasec and luasec.wrap )
local socket_bind = luasocket.bind
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
local loop
local stats
local addtimer
local closeall
local addserver
local firetimer
local wrapserver
local closesocket
local removesocket
local wrapconnection

--// tables //--

local _server
local _readlist
local _timerlist
local _writelist
local _socketlist

--// simple data types //--

local _
local _readlen = 0    -- length of readlist
local _writelen = 0    -- lenght of writelist
local _timerlen = 0    -- lenght of timerlist

local _sendstat = 0
local _receivestat = 0

----------------------------------// DEFINITION //--

_server = { }    -- key = port, value = table; list of listening servers
_readlist = { }    -- array with sockets to read from
_timerlist = { }    -- array of timers
_writelist = { }    -- arrary with sockets to write to
_socketlist = { }    -- key = socket, value = wrapped socket

id = function( ) end

stats = function( )
    return _receivestat, _sendstat
end

wrapserver = function( listeners, socket, ip, serverport, mode, sslctx )    -- this function wraps a server

    local dispatch, disconnect = listeners.incoming, listeners.disconnect    -- dangerous

    local err

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
    end

    local accept = socket.accept

    --// public methods of the object //--

    local handler = { }

    handler.shutdown = function( ) end

    --[[handler.listener = function( data, err )
        return ondata( handler, data, err )
    end]]
    handler.ssl = function( )
        return sslctx and true or false
    end
    handler.close = function( closed )
        _ = not closed and socket:close( )
        _writelen = removesocket( _writelist, socket, _writelen )
        _readlen = removesocket( _readlist, socket, _readlen )
        _socketlist[ socket ] = nil
        handler = nil
        socket = nil
        for _, handler in pairs( _socketlist ) do
            if handler.serverport == serverport then
                --handler.dispatchdata( true )
                handler.disconnect( handler, "server closed" )
                handler.close( )
                _socketlist[ _ ] = nil
            end
        end
        mem_free( )
        out_put "server.lua: closed server handler and removed sockets from list"
    end
    handler.ip = function( )
        return ip
    end
    handler.serverport = function( )
        return serverport
    end
    handler.socket = function( )
        return socket
    end
    handler.receivedata = function( )
        local client, err = accept( socket )    -- try to accept
        if client then
            local ip, clientport = client:getpeername( )
            client:settimeout( 0 )
            local handler, client, err = wrapconnection( listeners, client, ip, serverport, clientport, mode, sslctx )    -- wrap new client socket
            if err then    -- error while wrapping ssl socket
                return false
            end
            out_put( "server.lua: accepted new client connection from ", ip, ":", clientport )
            return dispatch( handler )
        elseif err then    -- maybe timeout or something else
            out_put( "server.lua: error with new client connection: ", err )
            return false
        end
    end
    return handler
end

wrapconnection = function( listeners, socket, ip, serverport, clientport, mode, sslctx )    -- this function wraps a client to a handler object

    local ssl = false

    if sslctx then    -- ssl?
        local err
        socket, err = ssl_wrap( socket, sslctx )    -- wrap socket
        if err then
            out_put( "server.lua: ssl error: ", err )
            writequeue, socket = nil, nil
            mem_free( )
            return nil, nil, err    -- fatal error
        end
        ssl = true
        socket:settimeout( 0 )
    end

    --// private closures of the object //--

    local dispatch, disconnect = listeners.incoming, listeners.disconnect

    local writequeue = { }

    local eol   -- end of buffer

    local sstat, rstat = 0, 0

    --// local import of socket methods //--

    local send = socket.send
    local receive = socket.receive
    local shutdown = ( ssl and id ) or socket.shutdown

    --// public methods of the object //--

    local handler = writequeue

    handler.dispatch = function( func )
        dispatch = func or dispatch or func
        return dispatch
    end
    handler.disconnect = function( func )
        disconnect = func or disconnect
        return disconnect
    end
    handler.getstats = function( )
        return rstat, sstat
    end
    handler.ssl = function( )
        return ssl
    end
    handler.send = function( _, data, i, j )
        return send( socket, data, i, j )
    end
    handler.receive = function( pattern, prefix )
        return receive( socket, pattern, prefix )
    end
    handler.shutdown = function( pattern )
        return shutdown( socket, pattern )
    end
    handler.close = function( )
        shutdown( socket )
        socket:close( )
        _writelen = ( eol and removesocket( _writelist, socket, _writelen ) ) or _writelen
        _readlen = removesocket( _readlist, socket, _readlen )
        _socketlist[ socket ] = nil
        handler = nil
        socket = nil
        mem_free( )
        out_put "server.lua: closed client handler and removed socket from list"
    end
    handler.ip = function( )
        return ip
    end
    handler.serverport = function( )
        return serverport
    end
    handler.clientport = function( )
        return clientport
    end
    handler.write = function( data )
        if not eol then
            _writelen = _writelen + 1
            _writelist[ _writelen ] = socket
            eol = 0
        end
        eol = eol + 1
        writequeue[ eol ] = data
    end
    handler.writequeue = function( )
        return writequeue
    end
    handler.socket = function( )
        return socket
    end
    handler.mode = function( )
        return mode
    end
    local _receivedata = function( )
        local data, err, part = receive( socket, mode )    -- receive data in "mode"
        if not err or ( err == "timeout" or err == "wantread" ) then    -- received something
            local data = data or part or ""
            local count = #data * STAT_UNIT
            rstat = rstat + count
            _receivestat = _receivestat + count
            out_put( "server.lua: read data '", data, "', error: ", err )
            return dispatch( handler, data, err )
        else    -- connections was closed or fatal error
            out_put( "server.lua: client ", ip, ":", clientport, " error: ", err )
            disconnect( handler, err )
            handler.close( )
            return false
        end
    end
    local _dispatchdata = function( )    -- this function writes data to handlers
        local buffer = table_concat( writequeue, "", 1, eol )
        local succ, err, byte = send( socket, buffer )
        local count = ( succ or 0 ) * STAT_UNIT
        sstat = sstat + count
        _sendstat = _sendstat + count
        out_put( "server.lua: sended '", buffer, "', bytes: ", succ, ", error: ", err, ", part: ", byte, ", to: ", ip, ":", clientport )
        if succ then    -- sending succesful
            --writequeue = { }
            eol = nil
            _writelen = removesocket( _writelist, socket, _writelen )    -- delete socket from writelist
            return true
        elseif byte and ( err == "timeout" or err == "wantwrite" ) then    -- want write
            buffer = string_sub( buffer, byte + 1, -1 )    -- new buffer
            writequeue[ 1 ] = buffer    -- insert new buffer in queue
            eol = 1
            return true
        else    -- connection was closed during sending or fatal error
            out_put( "server.lua: client ", ip, ":", clientport, " error: ", err )
            disconnect( handler, err )
            handler.close( )
            return false
        end
    end
    if ssl then    -- ssl connection
        local wrote
        local handshake = coroutine_wrap( function( client )
                local err
                for i = 1, 10 do    -- 10 handshake attemps
                    _, err = client:dohandshake( )
                    if not err then
                        out_put( "server.lua: ssl handshake done" )
                        _writelen = ( wrote and removesocket( _writelist, socket, _writelen ) ) or _writelen
                        handler.receivedata = _receivedata    -- when handshake is done, replace the handshake function with regular functions
                        handler.dispatchdata = _dispatchdata
                        --return dispatch( handler )
                        return true
                    else
                        out_put( "server.lua: error during ssl handshake: ", err )
                        if err == "wantwrite" and not wrote then
                            _writelen = _writelen + 1
                            _writelist[ _writelen ] = client
                            wrote = true
                        end
                        --coroutine_yield( handler, nil, err )    -- handshake not finished
                        coroutine_yield( )
                    end
                end
                disconnect( handler, err )
                handler.close( )
                return false    -- handshake failed
            end
        )
        handler.receivedata = handshake
        handler.dispatchdata = handshake
        handshake( socket )    -- do handshake
    else    -- normal connection
        handler.receivedata = _receivedata
        handler.dispatchdata = _dispatchdata
    end
    _socketlist[ socket ] = handler
    _readlen = _readlen + 1
    _readlist[ _readlen ] = socket
    return handler, socket
end

addtimer = function( listener )
    _timerlen = _timerlen + 1
    _timerlist[ _timerlen ] = listener
end

firetimer = function( listener )
    for i = 1, _timerlen do
        _timerlist[ i ]( )
    end
end

addserver = function( listeners, port, addr, mode, sslctx )    -- this function provides a way for other scripts to reg a server
    local err
    if type( listeners ) ~= "table" then
        err = "invalid listener table"
    else
        for name, func in pairs( listeners ) do
            if type( func ) ~= "function" then
                err = "invalid listener function"
                break
            end
        end
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
    local handler, err = wrapserver( listeners, server, addr, port, mode, sslctx )    -- wrap new server socket
    if not handler then
        server:close( )
        return nil, err
    end
    server:settimeout( 0 )
    _readlen = _readlen + 1
    _readlist[ _readlen ] = server
    _server[ port ] = handler
    _socketlist[ server ] = handler
    out_put( "server.lua: new server listener on '", addr, ":", port, "'" )
    return handler
end

local removeserver = function( port )
    local handler = _server[ port ]
    if not handler then
        return nil, "no server found on port '" .. tostring( port ) "'"
    end
    handler.close( )
    return true
end

removesocket = function( tbl, socket, len )    -- this function removes sockets from a list
    for i = 1, len do
        if tbl[ i ] == socket then
            len = len - 1
            table_remove( tbl, i )
            return len
        end
    end
    return len
end

closeall = function( )
    for _, handler in pairs( _socketlist ) do
        handler.close( )
        _socketlist[ _ ] = nil
    end
    _readlen = 0
    _writelen = 0
    _timerlen = 0
    _server = { }
    _readlist = { }
    _writelist = { }
    _timerlist = { }
    _socketlist = { }
    mem_free( )
end

closesocket = function( socket )
    _writelen = removesocket( _writelist, socket, _writelen )
    _readlen = removesocket( _readlist, socket, _readlen )
    _socketlist[ socket ] = nil
    socket:close( )
    socket = nil
    mem_free( )
end

loop = function( )    -- this is the main loop of the program

    if not _readlist[ 1 ] then
        return
    end

    signal_set( "hub", "run" )
    repeat

        for i = 1, _writelen do

            local read, write, err = socket_select( nil, { _writelist[ i ] }, 0 )    -- 1 sec timeout, nice for timers
            for i, socket in ipairs( write ) do    -- send data waiting in writequeues
                local handler = _socketlist[ socket ]
                if handler then
                    handler.dispatchdata( )
                else
                    closesocket( socket )
                    out_put "server.lua: found no handler and closed socket (writelist)"    -- this should not happen
                end
            end

        end

        for i = 2, _readlen do

            local read, write, err = socket_select( { _readlist[ i ] }, nil, 0 )    -- 1 sec timeout, nice for timers

            for i, socket in ipairs( read ) do    -- receive data
                local handler = _socketlist[ socket ]
                if handler then
                    handler.receivedata( )
                else
                    closesocket( socket )
                    out_put "server.lua: found no handler and closed socket (readlist)"    -- this can happen
                end
            end

        end

        local read, write, err = socket_select( { _readlist[ 1 ] }, nil, 0.00001 )    -- 1 sec timeout, nice for timers

        for i, socket in ipairs( read ) do    -- receive data
            local handler = _socketlist[ socket ]
            if handler then
                handler.receivedata( )
            else
                closesocket( socket )
                out_put "server.lua: found no handler and closed socket (readlist)"    -- this can happen
            end
        end

        firetimer( )
        collectgarbage( )
    until signal_get "hub" ~= "run"
    return signal_get "hub"
end

----------------------------------// BEGIN //--

use "setmetatable" ( _socketlist, { __mode = "k" } )

----------------------------------// PUBLIC INTERFACE //--

return {

    add = addserver,
    loop = loop,
    stats = stats,
    closeall = closeall,
    addtimer = addtimer,

}
