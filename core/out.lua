--[[

        out.lua by blastbeat

        - this script logs events

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local select = use "select"
local ipairs = use "ipairs"
local tostring = use "tostring"

--// lua libs //--

local io = use "io"
local os = use "os"
local table = use "table"

--// lua lib methods //--

local io_open = io.open
local os_date = os.date
local io_write = io.write
local table_concat = table.concat

--// core scripts //--

local cfg = use "cfg"
local mem = use "mem"

--// core methods //--

local cfg_get = cfg.get

--// functions //--

local createlog
local setlistener

--// tables //--

local _buffer
local _listener

--// simple data types //--

local _

----------------------------------// DEFINITION //--

_buffer = { }
_listener = { }

setlistener = function( what, func )
    _listener[ what ] = func
end

createlog = function( name, file, id )
    return function( ... )
        if cfg_get( id ) then    -- is logging activated?
            local logfile, err = io_open( cfg_get "log_path" .. file, "a" )
            if not logfile then
                return nil, err
            end
            local c = 0
            for i = 1, select( "#", ... ) do
                c = c + 1
                _buffer[ i ] = tostring( select( i, ... ) )
            end
            local txt = "[" .. os_date( "%d.%m.%y %H:%M:%S" ) .. "] " .. table_concat( _buffer, "", 1, c )
            _ = cfg_get "debug" and io_write( "\n", txt )    -- debug to screen
            logfile:write( txt, "\n" )
            logfile:close( )
            _ = _listener[ name ] and _listener[ name ]( txt )
            return txt
        end
        return nil, "logfile not active"
    end
end

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

    put = createlog( "put", "event.log", "log_events" ),
    error = createlog( "error", "error.log", "log_errors" ),
    scriptmsg = createlog( "scriptmsg", "script.log", "log_scripts" ),

    setlistener = setlistener,

}
