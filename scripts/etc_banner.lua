--[[

    etc_banner.lua

        - this script sends a banner in regular intervals to mainchat

        v0.11: by pulsar
            - removed table lookups
            - simplify 'activate' logic

        v0.10: by pulsar
            - removed "etc_banner_banner" from "cfg/cfg.tbl"
            - added lang files
                - added banner msg to the lang files

        v0.09: by pulsar
            - add "activate", possibility to activate/deactivate the banner
            - add new table lookups

        v0.08: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.07: by pulsar
            - cleaning code

        v0.06: by pulsar
            - small changes
            - fix doubleposting

        v0.05: by pulsar
            - small changes
            - option to send banner in main and/or pm
            - level choice

        v0.04: by pulsar
            - add 'time' variable

        v0.03: by blastbeat
            - clean up

        v0.02: by blastbeat
            - updated script api, cached table lookups

]]--



--------------
--[SETTINGS]--
--------------

local scriptname = "etc_banner"
local scriptversion = "0.11"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local time = cfg.get( "etc_banner_time" )
local destination_main = cfg.get( "etc_banner_destination_main" )
local destination_pm = cfg.get( "etc_banner_destination_pm" )
local permission = cfg.get( "etc_banner_permission" )
local activate = cfg.get( "etc_banner_activate" )

--// msgs
local msg_banner = lang.msg_banner or [[  no banner ]]


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local delay = time * 60 * 60
local start = os.time()

local check = function()
    for sid, user in pairs( hub.getusers() ) do
        if not user:isbot() then
            if permission[ user:level() ] then
                if destination_main then user:reply( msg_banner, hub.getbot() ) end
                if destination_pm then user:reply( msg_banner, hub.getbot(), hub.getbot() ) end
            end
        end
    end
end

hub.setlistener( "onTimer", { },
    function()
        if os.difftime( os.time() - start ) >= delay then
            check()
            start = os.time()
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )