--[[

    usr_hubs.lua by blastbeat

        - this script checks the hub count of a user

        v0.08: by pulsar
            - small typo fix
            - fixed bot restart bug  / thx Kungen
            - removed addban() function, using ban export functionality now
            - added amount of hubs to report msg  / requested by DerWahre
            - removed "block_msg" var
            - added "msg_reason" var
            - removed unneeded table lookups
            - removed send_report() function, using report import functionality now

        v0.07: by pulsar
            - ban and send report to opchat/hubbot  / thx DerWahre
                - add "usr_hubs_block_time"
                - add "usr_hubs_report"
                - add "usr_hubs_report_hubbot"
                - add "usr_hubs_report_opchat"
                - add "usr_hubs_llevel"

        v0.06: by pulsar
            - removed check "onConnect"
                - because: unjustified disconnects of slow clients

        v0.05: by pulsar
            - added "max_hubs" permission
            - table lookups
            - changed visual output style

        v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by blastbeat
            - updated script api

        v0.02: by blastbeat
            - added language files

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_hubs"
local scriptversion = "0.08"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local utf_format = utf.format
local os_date = os.date
local os_time = os.time

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local user_max = cfg_get( "max_user_hubs" )
local reg_max = cfg_get( "max_reg_hubs" )
local op_max = cfg_get( "max_op_hubs" )
local hubs_max = cfg_get( "max_hubs" )
local godlevel = cfg_get( "usr_hubs_godlevel" )
local block_time = cfg_get( "usr_hubs_block_time" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "usr_hubs_report" )
local report_hubbot = cfg_get( "usr_hubs_report_hubbot" )
local report_opchat = cfg_get( "usr_hubs_report_opchat" )
local llevel = cfg_get( "usr_hubs_llevel" )
local ban = hub_import( "cmd_ban" )

--// msgs
local msg_reason = lang.msg_reason or "Exceeded users hub limit"
local report_msg = lang.report_msg or "%s was banned for %s minutes because of exceeded users hub limit. Hubs: %s"
local msg_invalid = lang.msg_invalid or "Invalid hubcount"
local msg_max = lang.msg_max or [[


=== USER HUBS CHECK ===================

You was disconnected because:

Max user hubs: %s  |  yours: %s
Max reg hubs: %s  |  yours: %s
Max op hubs: %s  |  yours: %s

Max hubs: %s  |  yours: %s

=================== USER HUBS CHECK ===
  ]]


----------
--[CODE]--
----------

local check = function( user )
    local user_nick = user:nick()
    local hn, hr, ho = user:hubs()
    local hm = hn + hr + ho
    if not ( hn and hr and ho ) then
        user:kill( "ISTA 120 " .. msg_invalid .. "\n" )
        return PROCESSED
    elseif ( hn > user_max ) or ( hr > reg_max ) or ( ho > op_max ) or ( hm > hubs_max ) then
        local hubs = hn .. "/" .. hr .. "/" .. ho
        local bantime = block_time * 60
        local msg = utf_format( msg_max, user_max, hn, reg_max, hr, op_max, ho, hubs_max, hm )
        user:reply( msg, hub_getbot )
        ban.add( nil, user, bantime, msg_reason, "USER HUBS CHECK" )
        local msg_out = utf_format( report_msg, user_nick, block_time, hubs )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg_out )
        return PROCESSED
    end
    return nil
end

hub.setlistener( "onInf", {},
    function( user, cmd )
        if ( cmd:getnp "HN" or cmd:getnp "HR" or cmd:getnp "HO" ) and user:level() < godlevel then
            return check( user )
        end
        return nil
    end
)
--[[
hub.setlistener( "onConnect", {},
    function( user )
        if user:level() < godlevel then
            return check( user )
        end
        return nil
    end
)
]]
hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )