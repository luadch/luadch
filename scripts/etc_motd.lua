--[[

    etc_motd.lua v0.03 by blastbeat

        - this script sends a message stored in a file to connecting users

        - v0.04: by pulsar
            - add user permissions
            - export scriptsettings to "/cfg/cfg.tbl"
            
        - v0.03: by blastbeat
            - clean up

        - v0.02: by blastbeat
            - updated script api

]]--

--// settings begin //--

local scriptname = "etc_motd"
local scriptversion = "0.04"

local permission = {}
local permission = cfg.get( "etc_motd_permission" )

local motd = cfg.get "etc_motd_motd"

--// settings end //--

local hub_getbot = hub.getbot()

hub.setlistener( "onLogin", { },
    function( user )
        local user_level = user:level() or 0
        if permission[ user_level ] then
            user:reply( motd, hub_getbot )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )