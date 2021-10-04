--[[

    etc_motd.lua by blastbeat

        - this script sends a message to users after login

        v0.08: by pulsar
            - removed table lookups

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
local scriptversion = "0.08"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local activate = cfg.get( "etc_motd_activate" )
local permission = cfg.get( "etc_motd_permission" )
local destination_main = cfg.get( "etc_motd_destination_main" )
local destination_pm = cfg.get( "etc_motd_destination_pm" )

--// msg
local msg_motd = lang.msg_motd or [[  no rules ]]


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

hub.setlistener( "onLogin", {},
    function( user )
        if permission[ user:level() ] then
            local msg = utf.format( msg_motd, user:firstnick() )
            if destination_main then user:reply( msg, hub.getbot() ) end
            if destination_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )