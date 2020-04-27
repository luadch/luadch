--[[

    etc_report.lua by blastbeat

        - this script provides report functions for other scripts

        Usage: local report = hub.import( "etc_report" ); report.send( report_activate, report_hubbot, report_opchat, llevel, msg )

        v0.05 by blastbeat:
            - get rid of opchat activate var

        v0.04: by pulsar
            - removed old broadcast() function
            - renamed old send() function to broadcast()
            - added new send() function

        v0.03: by pulsar
            - added broadcast() function

        v0.02: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_report"
local scriptversion = "0.04"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local cfg_get = cfg.get

--// imports
local opchat = hub_import( "bot_opchat" )

--// functions
local send
local broadcast

----------
--[CODE]--
----------

send = function( report_activate, report_hubbot, report_opchat, llevel, msg )
    if report_activate then
        if report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                if user:level() >= llevel then
                    user:reply( msg, hub_getbot, hub_getbot )
                end
            end
        end
        if report_opchat then
            if opchat then
                opchat.feed( msg )
            end
        end
    end
end

broadcast = function( msg, llevel, ulevel, from, pm )
    llevel = llevel or 0    -- lower level <= user level
    ulevel = ulevel or 100    -- user level <= upper level
    for sid, user in pairs( hub_getusers( ) ) do
        local level = user:level( )
        if ( llevel <= level ) and ( level <= ulevel ) then
            user:reply( msg, from, pm )
        end
    end
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {

    send = send,
    broadcast = broadcast,

}
