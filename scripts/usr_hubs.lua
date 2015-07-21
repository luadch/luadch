--[[

    usr_hubs.lua by blastbeat

        - this script checks the hub count of an user

        - v0.07: by pulsar
            - ban and send report to opchat/hubbot  / thx DerWahre
                - add "usr_hubs_block_time"
                - add "usr_hubs_report"
                - add "usr_hubs_report_hubbot"
                - add "usr_hubs_report_opchat"
                - add "usr_hubs_llevel"
        
        - v0.06: by pulsar
            - removed check "onConnect"
                - because: unjustified disconnects of slow clients
        
        - v0.05: by pulsar
            - added "max_hubs" permission
            - table lookups
            - changed visual output style
        
        - v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        - v0.03: by blastbeat
            - updated script api

        - v0.02: by blastbeat
            - added language files

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_hubs"
local scriptversion = "0.07"

----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_escapeto = hub.escapeto
local hub_import = hub.import
local utf_format = utf.format

local util_loadtable = util.loadtable
local util_savearray = util.savearray
local os_date = os.date
local os_time = os.time

--// imports
local user_max = cfg_get( "max_user_hubs" )
local reg_max = cfg_get( "max_reg_hubs" )
local op_max = cfg_get( "max_op_hubs" )
local hubs_max = cfg_get( "max_hubs" )
local godlevel = cfg_get( "usr_hubs_godlevel" )
local block_time = cfg_get( "usr_hubs_block_time" )
local report = cfg_get( "usr_hubs_report" )
local report_tohubbot = cfg_get( "usr_hubs_report_hubbot" )
local report_toopchat = cfg_get( "usr_hubs_report_opchat" )
local report_level = cfg_get( "usr_hubs_llevel" )

local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )

local bans_path = "scripts/data/cmd_ban_bans.tbl"
local bans = util_loadtable( bans_path ) or {}

local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

--// msgs
local msg_invalid = hub_escapeto( lang.msg_invalid or "Invalid hubcount" )
local msg_max = hub_escapeto( lang.msg_max or [[ 

=== USER HUBS CHECK ===================

You was disconnected because:

Max user hubs: %s  |  yours: %s
Max reg hubs: %s  |  yours: %s
Max op hubs: %s  |  yours: %s

Max hubs: %s  |  yours: %s

=================== USER HUBS CHECK ===
  ]] )

local block_msg = lang.block_msg or "You were banned for %s minutes because of exceeded users hub limit. check this and try again after bantime."
local report_msg = lang.report_msg or "%s were banned for %s minutes because of exceeded users hub limit."


----------
--[CODE]--
----------

local addban = function( target, reason )
    local bantime = block_time * 60
    bans[ #bans + 1 ] = {
        nick = target:nick() or "nick",
        cid = target:cid() or "cid",
        hash = target:hash() or "hash",
        ip = target:ip() or "ip",
        time = bantime,
        start = os_time( os_date( "*t" ) ),
        reason = reason,
        by_nick = scriptname .. ".lua",
        by_level = 100
    }
    util_savearray( bans, bans_path )
end

local send_report = function( nick )
    if report then
        local msg_out = utf_format( report_msg, nick, block_time )
        if report_tohubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= report_level then
                    user:reply( msg_out, hub_getbot, hub_getbot )
                end
            end
        end
        if report_toopchat then
            if opchat_activate then
                opchat.feed( msg_out )
            end
        end
    end
end

local check = function( user )
    local user_nick = user:nick()
    local hn, hr, ho = user:hubs()
    local hm = hn + hr + ho
    if not ( hn and hr and ho ) then
        user:kill( "ISTA 120 " .. msg_invalid .. "\n" )
        return PROCESSED
    elseif ( hn > user_max ) or ( hr > reg_max ) or ( ho > op_max ) or ( hm > hubs_max ) then
        local msg = utf_format( msg_max, user_max, hn, reg_max, hr, op_max, ho, hubs_max, hm )
        local msg_out = utf_format( block_msg, block_time )
        addban( user, msg_out )
        user:kill( "ISTA 120 " .. msg .. "\n" )
        send_report( user_nick )
        hub.restartscripts()
        hub.reloadusers()
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