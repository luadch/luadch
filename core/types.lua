--[[

        types.lua by blastbeat

        - provides some type checking

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local type = use "type"
local next = use "next"
local pairs = use "pairs"
local error = use "error"

--// extern libs //--

local adclib = use "adclib"

--// extern lib methods //--

local adclib_isutf8 = adclib.isutf8

--// core scripts //--

--// core methods //--

--// functions //--

local add
local get
local check

--// tables //--

local _types
local _users
local _adccmds

local _

----------------------------------// DEFINITION //--

_types = { }

--// lua types //--

_types[ "string" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "string" then
        _ = noerror or error( "wrong type: string expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "number" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "number" then
        _ = noerror or error( "wrong type: number expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "boolean" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "boolean" then
        _ = noerror or error( "wrong type: boolean expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "table" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "table" then
        _ = noerror or error( "wrong type: table expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "function" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "function" then
        _ = noerror or error( "wrong type: function expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "thread" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "thread" then
        _ = noerror or error( "wrong type: thread expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "nil" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "nil" then
        _ = noerror or error( "wrong type: nil expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

_types[ "userdata" ] = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "userdata" then
        _ = noerror or error( "wrong type: userdata expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

--// luadch _types //--

_types.utf8 = function( data, traceback, noerror )
    local what = type( data )
    if what ~= "string" or not adclib_isutf8( data ) then
        _ = noerror or error( "wrong type: utf8 expected, got " .. what, traceback or 3 )
        return false
    end
    return true
end

check = function( data, what, traceback, noerror )
    _types[ what ]( data, traceback or 4, noerror )
    return nil
end

add = function( what, func )
    _types[ what ] = func
end

get = function( what )
    return _types[ what ]
end

----------------------------------// BEGIN //--

use "setmetatable" ( _types, { __index = function( ) return false end } )

----------------------------------// PUBLIC INTERFACE //--

return {

    add = add,
    get = get,
    check = check,

    utf8 = _types.utf8,

}