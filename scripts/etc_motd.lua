--[[

    etc_motd.lua by blastbeat

        - this script sends a message to users after login

        v0.07: by pulsar
            - removed "etc_motd_motd" from "cfg/cfg.tbl"
            - added lang files
                - added banner msg to the lang files

        v0.06: by pulsar
            - possibility to activate/deactivate the script
            - possibility to use %s in the motd to get users nickname (without nicktag)

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
local scriptversion = "0.07"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local utf_format = utf.format

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local activate = cfg_get( "etc_motd_activate" )
local permission = cfg_get( "etc_motd_permission" )
local destination_main = cfg_get( "etc_motd_destination_main" )
local destination_pm = cfg_get( "etc_motd_destination_pm" )

--// msg
local msg_motd = lang.msg_motd or [[  no rules ]]


----------
--[CODE]--
----------

hub.setlistener( "onLogin", {},
    function( user )
        local user_level = user:level()
        local user_firstnick = user:firstnick()
        if activate then
            if permission[ user_level ] then
                local msg = utf_format( msg_motd, user_firstnick )
                if destination_main then user:reply( msg, hub_getbot ) end
                if destination_pm then user:reply( msg, hub_getbot, hub_getbot ) end
            end
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )