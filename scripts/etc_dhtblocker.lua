--[[

    etc_dhtblocker.lua by pulsar

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
local scriptversion = "0.7"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getusers = hub.getusers
local hub_getbot = hub.getbot()
local os_date = os.date
local os_time = os.time
local utf_format = utf.format

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local activate = cfg_get( "etc_dhtblocker_activate" )
local block_level = cfg_get( "etc_dhtblocker_block_level" )
local block_time = cfg_get( "etc_dhtblocker_block_time" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "etc_dhtblocker_report" )
local report_tohubbot = cfg_get( "etc_dhtblocker_report_tohubbot" )
local report_toopchat = cfg_get( "etc_dhtblocker_report_toopchat" )
local report_level = cfg_get( "etc_dhtblocker_report_level" )
local ban = hub_import( "cmd_ban" )

--// msgs
local report_msg = lang.report_msg or "%s were banned for %s minutes because of active DHT function."
local msg_reason = lang.msg_reason or "Active DHT function"


----------
--[CODE]--
----------

local check_dht = function( user )
    local dht1 = user:supports( "DHT0" )
    local dht2 = user:supports( "ADDHT0" )
    local user_nick = user:nick()
    local user_level = user:level()
    if dht1 or dht2 then
        if block_level[ user_level ] then
            local bantime = block_time * 60
            ban.add( nil, user, bantime, msg_reason, "DHT BLOCKER" )
            local msg_out = utf_format( report_msg, user_nick, block_time )
            report.send( report_activate, report_hubbot, report_opchat, llevel, msg_out )
            return PROCESSED
        end
    end
end

if activate then
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
    hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
end