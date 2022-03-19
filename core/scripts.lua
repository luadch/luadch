--[[

        scripts.lua by blastbeat

        - this script manages custom user scripts

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local type = use "type"
local error = use "error"
local pairs = use "pairs"
local pcall = use "pcall"
local ipairs = use "ipairs"
local setfenv = use "setfenv"
local loadfile = use "loadfile"
local tostring = use "tostring"
local setmetatable = use "setmetatable"

--// lua libs //--

local io = use "io"
local _G = use "_G"

--// lua lib methods //--

local io_open = io.open

--// extern libs //--

local adclib = use "adclib"
local unicode = use "unicode"

--// extern lib methods //--

local utf = unicode.utf8

local utf_sub = utf.sub
local adclib_isUtf8 = adclib.isutf8

--// core scripts //--

local adc = use "adc"
local cfg = use "cfg"
local out = use "out"
local mem = use "mem"
local util = use "util"

--// core methods //--

local cfg_get = cfg.get
local out_put = out.put
local mem_free = mem.free
local out_error = out.error
local handlebom = util.handlebom
local checkfile = util.checkfile

--// functions //--

local init
local index
local newindex

local import
local setenv
local killscripts
local firelistener
local startscripts
local listenermethod

--// tables //--

local _code
local _loaded
local _scripts
local _listeners

local _
local _len    -- len of listeners array

----------------------------------// DEFINITION //--

_len = 0

_loaded = { }
_scripts = { }    -- script names
_listeners = { }    -- array auf listeners tables of scripts

_code = {    -- mhh...

    hubbypass = 2,
    hubdispatch = 1,
    scriptsbypass = 8,
    scriptsdispatch = 4,

}

index = function( tbl, key )
    error( "attempt to read undeclared var: '" .. tostring( key ) .. "'", 2 )
end

newindex = function( tbl, key, value )
    error( "attempt to write undeclared var: '" .. tostring( key ) .. " = " .. tostring( value ) .. "'", 2 )
end

setenv = function( tbl )
    local mtbl = { }
    mtbl.__index = index
    mtbl.__newindex = newindex
    return setmetatable( tbl, mtbl )
end

listenermethod = function( arg, scriptid )
    if arg == "set" then
        local listeners = { }
        _listeners[ scriptid ] = listeners
        _len = _len + 1
        return function( ltype, id, func )
            listeners[ ltype ] = listeners[ ltype ] or { }
            listeners[ ltype ][ id ] = func
        end
    elseif arg == "get" then
        return function( ltype )
            local listeners = _listeners[ scriptid ]
            return listeners and listeners[ ltype ]
        end
    end
    -- TODO: add remove method
end

firelistener = function( ltype, a1, a2, a3, a4, a5 )
    local ret, dispatch
    for k = 1, _len do
        local listeners = _listeners[ k ][ ltype ]
        if listeners then
            for i, func in pairs( listeners ) do
                local bol, sret = pcall( func, a1, a2, a3, a4, a5 )
                if bol then
                    ret = ret or sret
                elseif ltype ~= "onError" then    -- no endless loops ^^
                    out_error( "scripts.lua: script error: ", sret, " (listener: ", ltype, "; script: '", _scripts[ k ], "')" )
                end
            end

            --// ugly shit //--

            --[[if ret == 6 or ret == 10 then
                dispatch = dispatch or 0
            end
            if ret == 5 or ret == 9 then
                dispatch = dispatch or 1
            end
            if ret == 9 or ret == 10 then
                break
            end]]

            if ret == 10 then    -- PROCESSED should be enough
                return true
            end
        end
    end
    --return ( dispatch == 0 )
    return false
end

startscripts = function( hub )
    for key, scriptname in ipairs( cfg_get "scripts" ) do
        local path = cfg_get( "script_path" ) .. scriptname
        local ret, err = checkfile( path )
        if not ret then
            out_error( "scripts.lua: format error in script '", scriptname, "': ", err )
        else
            ret, err = loadfile( path )
            if not ret then
                out_error( "scripts.lua: syntax error in script '", scriptname, "': ", err )
            else
                local hubobject = { }
                for name, method in pairs( hub ) do
                    if utf_sub( name, 1, 1 ) ~= "_" then    -- no "hidden" functions...
                        hubobject[ name ] = method
                    end
                end
                local key = _len + 1
                hubobject.setlistener = listenermethod( "set", key )    -- this is needed to execute listeners in script order
                hubobject.getlistener = listenermethod( "get", key )
                local env =  { }

                --// useful constants //--

                --env.DISPATCH_HUB = _code.hubdispatch
                --env.DISCARD_HUB = _code.hubbypass
                --env.DISPATCH_SCRIPTS = _code.scriptsdispatch
                --env.DISCARD_SCRIPTS = _code.scriptsbypass

                env.PROCESSED = _code.scriptsbypass + _code.hubbypass    -- should be enough

                for i, k in pairs( _G ) do
                    env[ i ] = k
                end
                env.hub = hubobject
                env.utf = utf
                env.string = utf
                if cfg_get "no_global_scripting" then
                    setenv( env )
                end
                setfenv( ret, env )
                local bol, ret = pcall( ret )
                if not bol then
                    out_error( "scripts.lua: lua error in script '", scriptname, "': ", ret )
                else
                    _loaded[ scriptname ] = ret
                    _scripts[ key ] = scriptname
                end
            end
        end
    end
    firelistener "onStart"
end

killscripts = function( )
    firelistener "onExit"
    _loaded = { }
    _scripts = { }
    _listeners = { }
    _len = 0
    mem_free( )
end

import = function( script )
    script = tostring( script )
    local tbl = _loaded[ script ] or _loaded[ script .. ".lua" ]
    if type( tbl ) == "table" then
        local ctbl = { }
        for i, k in pairs( tbl ) do
            ctbl[ i ] = k
        end
        return setmetatable( ctbl, { __mode = "v" } )
    else
        return tbl
    end
end

init = function( )
    out.setlistener( "error", function( msg ) firelistener( "onError", tostring( msg ) ) end )
end

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

    init = init,

    kill = killscripts,
    start = startscripts,
    import = import,
    firelistener = firelistener,

}
