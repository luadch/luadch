--[[

    etc_dhtblocker.lua by pulsar

        v0.9: by pulsar
            - simplify 'activate' logic
            - removed table lookups
            - code cleanup

        v0.8: by blastbeat
            - fixed report stuff

        v0.7:
            - small fix in check_dht() function  / thx Sopor

        v0.6:
            - fixed bot restart bug
            - removed "addban" function, using new cmd_ban export function now
            - removed "block_msg" var
            - added "msg_reason" var
            - removed unneeded table lookups
            - removed send_report() function, using report import functionality now

        v0.5:
            - check if opchat is activated

        v0.4:
            - export scriptsettings to "cfg/cfg.tbl"

        v0.3:
            - small typo fix
            - small permission fix
                - add check table to choose which levels should be checked

        v0.2:
            - using ban instead of disconnect
                - prevents possible report message spams
            - check onConnect
            - possibility to send report as feed to opchat
            - caching table lookups
            - add multilanguage support

        v0.1:
            - check if user has active DHT function

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_dhtblocker"
local scriptversion = "0.9"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local activate = cfg.get( "etc_dhtblocker_activate" )
local block_level = cfg.get( "etc_dhtblocker_block_level" )
local block_time = cfg.get( "etc_dhtblocker_block_time" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "etc_dhtblocker_report" )
local report_tohubbot = cfg.get( "etc_dhtblocker_report_tohubbot" )
local report_toopchat = cfg.get( "etc_dhtblocker_report_toopchat" )
local report_level = cfg.get( "etc_dhtblocker_report_level" )
local ban = hub.import( "cmd_ban" )

--// msgs
local report_msg = lang.report_msg or "%s were banned for %s minutes because of active DHT function."
local msg_reason = lang.msg_reason or "Active DHT function"


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local check_dht = function( user )
    local dht1 = user:supports( "DHT0" )
    local dht2 = user:supports( "ADDHT0" )
    if block_level[ user:level() ] and ( dht1 or dht2 ) then
        local bantime = block_time * 60
        ban.add( nil, user, bantime, msg_reason, "DHT BLOCKER" )
        local msg_out = utf.format( report_msg, user:nick(), block_time )
        report.send( report_activate, report_tohubbot, report_toopchat, report_level, msg_out )
        return PROCESSED
    end
end

hub.setlistener( "onInf", {},
    function( user, cmd )
        if cmd:getnp "NI" then
            check_dht( user )
        end
        return nil
    end
)
hub.setlistener( "onConnect", {},
    function( user )
        check_dht( user )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )