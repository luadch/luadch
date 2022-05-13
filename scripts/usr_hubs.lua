--[[

    usr_hubs.lua by blastbeat

        - this script checks the hub count of a user

        v0.12: by pulsar
            - show more detailed output msg
            - using permission table instead of godlevel

        v0.11: by pulsar
            - added redirect function

        v0.10: by pulsar
            - changed visuals
            - removed table lookups

        v0.09: by pulsar
            - imroved user:kill()

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
local scriptversion = "0.12"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local user_max = cfg.get( "max_user_hubs" )
local reg_max = cfg.get( "max_reg_hubs" )
local op_max = cfg.get( "max_op_hubs" )
local hubs_max = cfg.get( "max_hubs" )
local godlevel = cfg.get( "usr_hubs_godlevel" )
local block_time = cfg.get( "usr_hubs_block_time" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "usr_hubs_report" )
local report_hubbot = cfg.get( "usr_hubs_report_hubbot" )
local report_opchat = cfg.get( "usr_hubs_report_opchat" )
local llevel = cfg.get( "usr_hubs_llevel" )
local ban = hub.import( "cmd_ban" )
local redirect_url = cfg.get( "cmd_redirect_url" )
local usr_hubs_redirect = cfg.get( "usr_hubs_redirect" )

--// msgs
local msg_reason = lang.msg_reason or "Exceeded users hub limit"
local report_msg = lang.report_msg or "[ USER HUBS ]--> User:  %s  |  was banned for:  %s  |  reason: exceeded users hub limit. Hubs:  %s  (total:  %s hubs)  |  allowed:  %s  (max.  %s  hubs total)"
local report_msg_redirect = lang.report_msg_redirect or "[ USER HUBS ]--> User:  %s  |  was redirected  |  reason: exceeded users hub limit. Hubs:  %s  (total:  %s hubs)  |  allowed:  %s  (max.  %s  hubs total)"
local msg_redirect = lang.msg_redirect or "[ USER HUBS ]--> You got redirected because: exceeded users hub limit. Hubs: "
local msg_invalid = lang.msg_invalid or "Invalid hubcount"
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
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
        user:kill( "ISTA 120 " .. msg_invalid .. "\n", "TL300" )
        return PROCESSED
    elseif ( hn > user_max ) or ( hr > reg_max ) or ( ho > op_max ) or ( hm > hubs_max ) then
        local hubs = hn .. "/" .. hr .. "/" .. ho
        local hubs_allowed = user_max .. "/" .. reg_max .. "/" .. op_max
        local bantime = block_time * 60
        local y, d, h, m, s = util.formatseconds( bantime )
        local msg_bantime =  y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        if usr_hubs_redirect then
            local redirect_msg = hub.escapeto( msg_redirect .. hubs )
            user:redirect( redirect_url, redirect_msg )
            --// report
            local msg_out = utf.format( report_msg_redirect, user_nick, hubs, hm, hubs_allowed, hubs_max )
            report.send( report_activate, report_hubbot, report_opchat, llevel, msg_out )
            return PROCESSED
        else
            local msg = utf.format( msg_max, user_max, hn, reg_max, hr, op_max, ho, hubs_max, hm )
            user:reply( msg, hub.getbot() )
            ban.add( nil, user, bantime, msg_reason, "USER HUBS CHECK" )
            --// report
            local msg_out = utf.format( report_msg, user_nick, msg_bantime, hubs, hm, hubs_allowed, hubs_max )
            report.send( report_activate, report_hubbot, report_opchat, llevel, msg_out )
            return PROCESSED
        end
    end
    return nil
end

hub.setlistener( "onInf", {},
    function( user, cmd )
        if ( cmd:getnp "HN" or cmd:getnp "HR" or cmd:getnp "HO" ) and ( not godlevel[ user:level() ] ) then
            return check( user )
        end
        return nil
    end
)
--[[
hub.setlistener( "onLogin", {},
    function( user )
        if not godlevel[ user:level() ] then
            return check( user )
        end
        return nil
    end
)
]]
hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )