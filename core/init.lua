--[[

        init.lua by blastbeat

        - this script starts the whole program
        - the main task is importing all extern libs and core scripts
        - every core script gets a "nacked" _G; globals are not allowed
        - benefits:
            - "mistyped var name" - bugs are gone
            - you are forced to use faster locals
            - no problems with lua modules which export global names ( because the main _G remains untouched )

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local type = type
local error = error
local pcall = pcall
local ipairs = ipairs
local assert = assert
local require = require
local setfenv = setfenv
local loadfile = loadfile
local tostring = tostring
local setmetatable = setmetatable
local collectgarbage = collectgarbage

--// lua libs //--

local os = os
local io = io
local package = package

--// lua lib methods //--

local write = io.write

--// functions //--

local use
local init
local import
local setenv
local loadscript

--// tables //--

local _env    -- replacement for _G in core scripts
local _core    -- array with names of core scripts
local _global    -- link to _G, could change in future
local _module    -- array with names of extern libs
local _optional    -- array with names of extern optional libs

--// simple data types //--

local _    -- dummy var
local _path    -- path to core scripts ( string )
local _filetype    -- extension of shared libraries ( string )

----------------------------------// DEFINITION //--

_path = "././core/"

_filetype = (    -- unix or windows libs?
    os.getenv "COMSPEC" and os.getenv "WINDIR" and ".dll"
) or ".so"

_global = _G

_core = {    -- luadch core, order is important

    "const",
    "mem",
    "signal",
    "util",
    "cfg",
    "out",
    --"doc",
    "server",
    "adc",
    "hub",
    "scripts",
    "types",
    --"test",

}

_module = {    -- extern libs

    "adclib",
    "unicode",
    "socket",

}

_optional = {    -- optional extern libs

    "ssl",
    "basexx",

}

loadscript = function( name )    -- this function loads a certain core script
    name = tostring( name )
    if _global[ name ] == false then    -- optional lib
        return nil
    end
    assert( not _global[ name ], "fatal error: namespace '" .. name .. "' already exists" )    -- UNSAFE: program termination
    local script, err = loadfile( _path .. name .. ".lua" )
    assert( script, err )    -- UNSAFE: program termination
    setfenv( script, _env )
    _global[ name ] = script( )
    write( "\ninit.lua: loaded '" .. name .. "'" )
    return _global[ name ]
end

import = function( )    -- this function loads all extern libs and the core
    write "init.lua: import libs"
    for i, lib in ipairs( _module ) do
        _global[ lib ] = _global[ lib ] or require( lib )
        write( "\ninit.lua: loaded '" .. lib .. "'" )
    end
    write "\ninit.lua: import optional libs"
    local succ
    for i, lib in ipairs( _optional ) do
        succ, ret = pcall( require, lib )
        _global[ lib ] = ( succ and ret ) or false
        _ = succ and write( "\ninit.lua: loaded '" .. lib .. "'" )
    end
    write "\ninit.lua: import core"
    for i, script in ipairs( _core ) do
        _ = _global[ script ] or loadscript( script )
    end
    write "\ninit.lua: init core modules"
    for i, script in ipairs( _core ) do
        _ = _global[ script ].init and _global[ script ].init( )
        _ = _global[ script ].init and write( "\ninit.lua: initialized '" .. script .. "'" )
    end
end

use = function( name )    -- this function imports any global var/namespace
    return nil
    or _global[ name ]
    or loadscript( name )
end

setenv = function( tbl )    -- this function creates a new env
    return setmetatable(
        tbl or {

            use = use,    -- the only global method a script can access

        },
        {    -- global vars are not allowed

            __index = function( tbl, key )
                error( "attempt to read undeclared var: '" .. tostring( key ) .. "'", 2 )
            end,

            __newindex = function( tbl, key, value )
                error( "attempt to write undeclared var: '" .. tostring( key ) .. " = " .. tostring( value ) .. "'", 2 )
            end,

        }
    )
end

init = function( )    -- this function is the start point
    _env = _env or setenv{ use = use }
    import( )
    write( "\n\n"
        .. const.PROGRAM_NAME
        .. " "
        .. const.VERSION
        .. " "
        --.. const.COPYRIGHT .. " (2007-" .. os.date( "%Y" ) .. ")"
        .. util.decode( 'c75d3b4cc292dbf99f02507e0b3e5f58bb939d19fae422' ) .. " (2007-" .. os.date( "%Y" ) .. ")"
        .. "\n\n"
    )
    signal.set( "start", os.time( ) )
    --doc.export( )
    --test( )
    mem.free( )
    local bol, err = pcall( hub.loop )
    if not bol and err then
        out.error( err )
    elseif err == "restart" then
        restartluadch( )
    end
    os.exit( )
end

----------------------------------// BEGIN //--

package.path = package.path .. ";"
    .. "././core/?.lua;"
    .. "././lib/?/?.lua;"
    .. "././lib/luasocket/lua/?.lua;"
    .. "././lib/luasec/lua/?.lua;"

package.cpath = package.cpath .. ";"
    .. "././lib/?/?" .. _filetype .. ";"
    .. "././lib/luasocket/?/?" .. _filetype .. ";"
    .. "././lib/luasec/?/?" .. _filetype .. ";"

init( )
