--[[

    etc_motd.lua by blastbeat

        - this script sends a message stored in a file to connecting users

        v0.05: by pulsar
            - possibility to set target (main/pm/both)  / request by DerWahre
            - add new table lookups
            - code cleaning

        v0.04: by pulsar
            - add user permissions
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by blastbeat
            - clean up

        v0.02: by blastbeat
            - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_motd"
local scriptversion = "0.05"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local hub_getbot = hub.getbot()
local hub_debug = hub.debug

--// imports
local permission = cfg_get( "etc_motd_permission" )
local motd = cfg_get( "etc_motd_motd" )
local destination_main = cfg_get( "etc_motd_destination_main" )
local destination_pm = cfg_get( "etc_motd_destination_pm" )


----------
--[CODE]--
----------

hub.setlistener( "onLogin", { },
    function( user )
        local user_level = user:level()
        if permission[ user_level ] then
            if destination_main then user:reply( motd, hub_getbot ) end
            if destination_pm then user:reply( motd, hub_getbot, hub_getbot ) end
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )