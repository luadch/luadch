--[[

        etc_report.lua by blastbeat

        - this script provides a report function for other scripts

        v0.03: by pulsar
            - added: broadcast() function
        
        v0.02: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_report"
local scriptversion = "0.03"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot
local hub_getusers = hub.getusers
local cfg_get = cfg.get

--// imports
--local opchat, err
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )

--// functions
local send
local broadcast


----------
--[CODE]--
----------

send = function( msg, llevel, ulevel, from, pm )
    llevel = llevel or 0    -- lower level <= user level
    ulevel = ulevel or 100    -- user level <= upper level
    for sid, user in pairs( hub_getusers( ) ) do
        local level = user:level( )
        if ( llevel <= level ) and ( level <= ulevel ) then
            user:reply( msg, from, pm )
        end
    end
end

broadcast = function( sname, msg )
    local err
    local report, report_hubbot, report_opchat, llevel
    if type( sname ) == "string" then
        report = sname .. "_report"
        report = cfg_get( report )
        report_hubbot = sname .. "_report_hubbot"
        report_hubbot = cfg_get( report_hubbot )
        report_opchat = sname .. "_opchat"
        report_opchat = cfg_get( report_opchat )
        llevel = sname .. "_llevel"
        llevel = cfg_get( llevel )
    end
    if type( sname ) == "table" then
        report = sname[ 1 ]
        report_hubbot = sname[ 2 ]
        report_opchat = sname[ 3 ]
        llevel = sname[ 4 ]
    end
    if not ( type( report ) == "boolean" ) then
        err = scriptname .. ".lua: error in function broadcast: invalid arg1: report, boolean expected, got " .. type( report )
        hub_debug( err )
    end
    if not ( type( report_hubbot ) == "boolean" ) then
        err = scriptname .. ".lua: error in function broadcast: invalid arg1: report_hubbot, boolean expected, got " .. type( report_hubbot )
        hub_debug( err )
    end
    if not ( type( report_opchat ) == "boolean" ) then
        err = scriptname .. ".lua: error in function broadcast: invalid arg1: report_opchat, boolean expected, got " .. type( report_opchat )
        hub_debug( err )
    end
    if not ( type( llevel ) == "number" ) then
        err = scriptname .. ".lua: error in function broadcast: invalid arg1: llevel, number expected, got " .. type( llevel )
        hub_debug( err )
    end
    if report then
        if report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= lvl then
                    user:reply( msg, hub_getbot(), hub_getbot() )
                end
            end
        end
        if report_opchat then
            if opchat_activate then
                opchat.feed( msg )
            end
        end
    end
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {

    -- use this with hub.import( "etc_report" )
    send = send,
    broadcast = broadcast,

}