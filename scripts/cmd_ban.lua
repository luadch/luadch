--[[

    cmd_ban.lua by blastbeat

        - this script adds a command "ban" and "unban" to ban/unban users by sid/nick/cid or show/clear all banned users

        - usage ban: [+!#]ban sid|nick|cid|ip <SID>|<NICK>|<CID>|<IP> [<time> <reason>] / [+!#]ban show|showhis|clear|clearhis
        - usage unban: [+!#]unban ip|nick|cid <IP>|<NICK>|<CID>

            - <time> are ban minutes; negative values means ban forever
            - <time> and <reason> are optional


        v0.29: by pulsar
            - ban export function: add()
                - set default "user_level" from "100" to "60"
                    - if a script is using the ban import function then it uses level "60" if user = nil
            - added ban history  / requested by Kungen
                - added new vars, functions, table lookups, ucmds
                - added ban state active/expired  / requested by Sopor
            - improved user:kill()

        v0.28: by pulsar
            - changed "addban" function, added additional routine (routine written by Jerker) to check if the user still exists,
              and if, rewrite old ban with the new one  / thx Jerker, Sopor, Kungen
            - changing some parts of code
            - add ban export functionality to use the ban function in other scripts
            - add complete unban command functionality from cmd_unban.lua
            - removed send_report() function, using report import functionality now
            - show default bantime in "ucmd_time" (rightclick bantime dialog)  / requested by Sopor
            - using "clear" parameter instead of "clean"  / requested by Sopor

        v0.27: by pulsar
            - typo fix  / thx Kaas
            - fixed "get_bantime()"  / thx BlinG
            - add "msg_forever"

        v0.26: by pulsar
            - removed "cmd_ban_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_ban_minlevel"
            - add is_integer() function to check if the used bantime is integer  / thx sopor
            - add new cmd: [+!#]ban clean  / requested by Tork
                - cleans the complete ban table (only lvl 100)

        v0.25: by pulsar
            - check if opchat is activated

        v0.24: by pulsar
            - fix missing report msg if target was banned via CT1
            - using "user:firstnick()" for "banned by"
            - fix permissions
            - add command: [+!#]ban show
                - shows a list of all banned users

        v0.23: by pulsar
            - add function to calculate ban time in days, hours, minutes, seconds
            - add some new table lookups

        v0.22: by pulsar
            - add some new table lookups
            - add possibility to send report to opchat

        v0.21: by pulsar
            - changed listener: from "onLogin" to "onConnect"  / thx fly out to Kungen
                - fixes problem where banned users can see userlist on login

        v0.20: by Night
            - permission fix

        v0.19: by pulsar
            - changed rightclick style

        v0.18: by pulsar
            - changed database path and filename
            - from now on all scripts uses the same database folder

        v0.17: by pulsar
            - fix lang and rightclicks for the v0.16 modifications
            - fix permission bug
            - changed listener: from "onConnect" to "onLogin"
            - if target is online and has higher level then he becomes a report

        v0.16: by Night
            - disallow banning users with same or lower reglevel
            - allow higher reglevel than the banner to allways enter hub
            - allow banning offline users by nick, ip, cid
            - add [+!#]ban ip

        v0.15: by pulsar
            - bugfix: ban bots

        v0.14: by pulsar
            - export scriptsettings to "cfg/cfg.tbl"

        v0.13: by pulsar
            - ban user by firstnick (without nicktag)

        v0.12: by blastbeat
            - updated script api
            - regged hubcommand

        v0.11: by blastbeat
            - some clean ups

        v0.10: by blastbeat
            - added language module

        v0.09: by blastbeat
            - added usercommand

        v0.08: by blastbeat
            - added english and german language files

        v0.07: by blastbeat
            - added report function, removed opchat, some clean up

        v0.06: by blastbeat
            - updated script api, cached table lookups, cleaned up code

        v0.05: by blastbeat
            - added by_level to ban table

        v0.04: by blastbeat
            - renamend to cmd_ban.lua

        v0.03: by blastbeat
            - added ban by nick and cid
            - added perm ban via negative ban time
            - added public interface to banfile

        v0.02: by blastbeat
            - fixed typo
            - added opchat setting

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_ban"
local scriptversion = "0.29"

local cmd = "ban"
local cmd2 = "unban"

local bans_path = "scripts/data/cmd_ban_bans.tbl"
local history_path = "scripts/data/cmd_ban_history.tbl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_escapeto = hub.escapeto
local hub_escapefrom = hub.escapefrom
local hub_issidonline = hub.issidonline
local hub_iscidonline = hub.iscidonline
local hub_isnickonline = hub.isnickonline
local hub_isiponline = hub.isiponline
local hub_getusers = hub.getusers
local utf_match = utf.match
local utf_format = utf.format
local util_savearray = util.savearray
local util_savetable = util.savetable
local util_loadtable = util.loadtable
local util_formatseconds = util.formatseconds
local util_getlowestlevel = util.getlowestlevel
local util_date = util.date
local os_date = os.date
local os_time = os.time
local os_difftime = os.difftime
local math_floor = math.floor
local table_remove = table.remove
local table_insert = table.insert
local table_sort = table.sort

--// imports - ban
local hubcmd, help, ucmd
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local default_time = cfg_get( "cmd_ban_default_time" )
local permission = cfg_get( "cmd_ban_permission" )
local report_activate = cfg_get( "cmd_ban_report" )
local report_hubbot = cfg_get( "cmd_ban_report_hubbot" )
local report_opchat = cfg_get( "cmd_ban_report_opchat" )
local llevel = cfg_get( "cmd_ban_llevel" )
local bans = util_loadtable( bans_path ) or {}
local history = util_loadtable( history_path ) or {}
local report = hub_import( "etc_report" )

--// imports - unban
local permission2 = cfg_get( "cmd_unban_permission" )

--// msgs - ban
local help_title = lang.help_title or "cmd_ban.lua - Ban"
local help_usage = lang.help_usage or "[+!#]ban sid|nick|cid <SID>|<NICK>|<CID> [<TIME> <REASON>] / [+!#]ban show|showhis|clear|clearhis"
local help_desc = lang.help_desc or "bans user; <time> are ban minutes; negative values means ban forever"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_notint = lang.msg_notint or "It's not allowed to use decimal numbers for bantime."
local msg_import = lang.msg_import or "Error while importing additional module."
local msg_reason = lang.msg_reason or "No reason."
local msg_usage = lang.msg_usage or "Usage: [+!#]ban sid|nick|cid|ip <SID>|<NICK>|<CID>|<IP> [<TIME> <REASON>] / [+!#]ban show|showhis|clear|clearhis"
local msg_off = lang.msg_off or "User not found."
local msg_god = lang.msg_god or "You cannot ban user with higher level than you."
local msg_bot = lang.msg_bot or "User is a bot."
local msg_ban = lang.msg_ban or "You were banned by: %s  |  reason: %s  |  Remaining ban time: "  -- do not delete '%s'!
local msg_ok = lang.msg_ok or "%s  were banned by  %s  |  bantime: %s  |  reason: %s"
local msg_ban_added = lang.msg_ban_added or "%s:  %s  was banned by  %s"
local msg_ban_attempt = lang.msg_ban_attempt or "User:  %s  with lower level than you has tried to ban you! because: %s"
local msg_clean_bans = lang.msg_clean_bans or "Ban table was cleared by: "
local msg_clean_banhistory = lang.msg_clean_banhistory or "Ban history was cleared by: "

local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_forever = lang.msg_forever or "forever"

local ucmd_menu1 = lang.ucmd_menu1 or { "Ban", "1 hour" }
local ucmd_menu2 = lang.ucmd_menu2 or { "Ban", "2 hours" }
local ucmd_menu3 = lang.ucmd_menu3 or { "Ban", "6 hours" }
local ucmd_menu4 = lang.ucmd_menu4 or { "Ban", "12 hours" }
local ucmd_menu5 = lang.ucmd_menu5 or { "Ban", "1 day" }
local ucmd_menu6 = lang.ucmd_menu6 or { "Ban", "2 days" }
local ucmd_menu7 = lang.ucmd_menu7 or { "Ban", "1 week" }
local ucmd_menu8 = lang.ucmd_menu8 or { "Ban", "other" }
local ucmd_menu9 = lang.ucmd_menu9 or { "User", "Control", "Ban", "by NICK" }
local ucmd_menu10 = lang.ucmd_menu10 or { "User", "Control", "Ban", "by CID" }
local ucmd_menu11 = lang.ucmd_menu11 or { "User", "Control", "Ban", "by IP" }
local ucmd_menu12 = lang.ucmd_menu12 or { "User", "Control", "Ban", "show", "bans" }
local ucmd_menu13 = lang.ucmd_menu13 or { "User", "Control", "Ban", "clear", "bans" }
local ucmd_menu14 = lang.ucmd_menu14 or { "User", "Control", "Ban", "show", "ban history" }
local ucmd_menu15 = lang.ucmd_menu15 or { "User", "Control", "Ban", "clear", "ban history" }

local ucmd_time = lang.ucmd_time or "Time in minutes (default: %s)"
local ucmd_reason = lang.ucmd_reason or "Reason"

local lblNick = lang.lblNick or " Nick: "
local lblCid = lang.lblCid or " CID: "
local lblIp = lang.lblIp or " IP: "
local lblReason = lang.lblReason or " Reason: "
local lblBy = lang.lblBy or " banned by: "
local lblTime = lang.lblTime or " banned till: "

local msg_his_nick = lang.msg_his_nick or "Nick: "
local msg_his_ban = lang.msg_his_ban or "Ban #"
local msg_his_date = lang.msg_his_date or "Date: "
local msg_his_bantime = lang.msg_his_bantime or "Bantime: "
local msg_his_reason = lang.msg_his_reason or "Reason: "
local msg_his_by = lang.msg_his_by or "Banned by: "
local msg_his_state = lang.msg_his_state or "State: "
local msg_his_active = lang.msg_his_active or "active"
local msg_his_expired = lang.msg_his_expired or "expired"

local msg_out = lang.msg_out or [[


=== BANS =====================================================================================
%s
===================================================================================== BANS ===
  ]]

local msg_out2 = lang.msg_out2 or [[


=== BAN HISTORY ===============================================================================
%s
=============================================================================== BAN HISTORY ===
  ]]


--// msgs - unban
local help_title2 = lang.help_title2 or "cmd_ban.lua - Unban"
local help_usage2 = lang.help_usage2 or "[+!#]unban ip|nick|cid <IP>|<nick>|<CID>"
local help_desc2 = lang.help_desc2 or "unbans user by IP or nick or CID"

local msg_usage2 = lang.msg_usage2 or "Usage: [+!#]unban ip|nick|cid <IP>|<nick>|<CID>"
local msg_god2 = lang.msg_god2 or "You are not allowed to unban this user."
local msg_ok2 = lang.msg_ok2 or "User %s removed ban of %s."

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "User", "Control", "Unban", "by NICK" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "User", "Control", "Unban", "by CID" }
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or { "User", "Control", "Unban", "by IP" }

local ucmd_ip = lang.ucmd_ip or "IP:"
local ucmd_cid = lang.ucmd_cid or "CID:"
local ucmd_nick = lang.ucmd_nick or "Nick:"


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )
local minlevel2 = util_getlowestlevel( permission2 )

local is_integer = function( num )
    return num == math_floor( num )
end

local get_bantime = function( remaining )
    if tostring( remaining ):find( "-" ) then
        return msg_forever
    else
        local d, h, m, s = util_formatseconds( remaining )
        return d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    end
end

local parsedate = function( date )
    local str = tostring( date )
    local Y, M, D = str:sub( 1, 4 ), str:sub( 5, 6 ), str:sub( 7, 8 )
    local h, m, s = str:sub( 9, 10 ), str:sub( 11, 12 ), str:sub( 13, 14 )
    return Y .. "-" .. M .. "-" .. D .. " / " .. h .. ":" .. m .. ":" .. s
end

local genOrderedIndex = function( t )
    local orderedIndex = {}
    for key in pairs( t ) do table_insert( orderedIndex, key ) end
    table_sort( orderedIndex )
    return orderedIndex
end

local orderedNext = function( t, state )
    local key = nil
    if state == nil then
        t.orderedIndex = genOrderedIndex( t )
        key = t.orderedIndex[ 1 ]
    else
        for i = 1, #t.orderedIndex do
            if t.orderedIndex[ i ] == state then key = t.orderedIndex[ i + 1 ] end
        end
    end
    if key then return key, t[ key ] end
    t.orderedIndex = nil
    return
end

local orderedPairs = function( t )
    return orderedNext, t, nil
end

local add = function( user, target, bantime, reason, script )  -- ban export function
    local key = #bans + 1
    local user_firstnick, user_level
    if user then
        user_firstnick = user:firstnick()
        user_level = user:level()
    else
        user_firstnick = ""
        user_level = 60
    end
    local target_firstnick = target:firstnick()
    local target_cid = target:cid()
    local target_hash = target:hash()
    local target_ip = target:ip()
    if not script then script = user_firstnick end
    for i, bantbl in ipairs( bans ) do
        if bantbl.nick == target_firstnick then
            key = i
            break
        end
        if bantbl.cid == target_cid then
            key = i
            break
        end
        if bantbl.ip == target_ip then
            key = i
            break
        end
    end
    bans[ key ] = {
        nick = target_firstnick,
        cid = target_cid,
        hash = target_hash,
        ip = target_ip,
        time = bantime,
        start = os_time( os_date( "*t" ) ),
        reason = reason,
        by_nick = script,
        by_level = user_level
    }
    local i
    if type( history[ target_firstnick ] ) == "nil" then
        history[ target_firstnick ] = {}
        i = 1
    else
        i = #history[ target_firstnick ] + 1
    end
    history[ target_firstnick ][ i ] = { date = util_date(), reason = reason, bantime = bantime, by_nick = script, start = os_time( os_date( "*t" ) ), }
    util_savearray( bans, bans_path )
    util_savetable( history, "history_tbl", history_path )
    local target_msg = utf_format( msg_ban, script, reason ) .. get_bantime( bantime )
    target:kill( "ISTA 231 " .. hub_escapeto( target_msg ) .. "\n", "TL" .. bantime )
    --local report_msg = utf_format( msg_ok, target_firstnick, script, get_bantime( bantime ), reason )
    --report.send( report_activate, report_hubbot, report_opchat, llevel, report_msg )
    return PROCESSED
end

local addban = function( by, id, bantime, reason, level, nick, victim )
    local key = #bans + 1
    if not victim then
        for i, bantbl in ipairs( bans ) do
            if ( by == "nick" and bantbl.nick == id ) then
                key = i
                break
            elseif ( by == "cid" and bantbl.cid == id and bantbl.hash == "TIGR" ) then
                key = i
                break
            elseif ( by == "ip" and bantbl.ip == id ) then
                key = i
                break
            end
        end
    end
    bans[ key ] = {
        nick = victim and victim:firstnick() or by == "nick" and id or "",
        cid = victim and victim:cid() or by == "cid" and id or "",
        hash = victim and victim:hash() or "TIGR",
        ip = victim and victim:ip() or by == "ip" and id or "",
        time = bantime,
        start = os_time( os_date( "*t" ) ),
        reason = reason,
        by_nick = nick,
        by_level = level
    }
    local n, i = victim and victim:firstnick() or by == "nick" and id or "", nil
    if n ~= "" then
        if type( history[ n ] ) == "nil" then
            history[ n ] = {}
            i = 1
        else
            i = #history[ n ] + 1
        end
        history[ n ][ i ] = { date = util_date(), reason = reason, bantime = bantime, by_nick = nick, start = os_time( os_date( "*t" ) ), }
    end
    util_savearray( bans, bans_path )
    util_savetable( history, "history_tbl", history_path )
end

local showbans = function()
    local msg = ""
    for i, banstbl in ipairs( bans ) do
        local remaining = banstbl.time - os_difftime( os_time(), banstbl.start )
        msg = msg .. "\n [" .. i .. "]\n\t" ..
              lblNick .. "\t" .. banstbl.nick .. "\n\t" ..
              lblCid .. "\t" .. banstbl.cid .. "\n\t" ..
              lblIp .. "\t" .. banstbl.ip .. "\n\t" ..
              lblReason .. "\t" .. banstbl.reason .. "\n\t" ..
              lblBy .. "\t" .. banstbl.by_nick .. "\n\t" ..
              lblTime .. "\t" .. get_bantime( remaining ) .. "\n"
    end
    return utf_format( msg_out, msg )
end

local showhistory = function()
    local msg = ""
    for k, v in orderedPairs( history ) do
        msg = msg .. "\n" .. msg_his_nick .. k .. "\n"
        for i, t in ipairs( v ) do
            local remaining = t.bantime - os_difftime( os_time(), t.start )
            local state = msg_his_active
            if tostring( remaining ):find( "-" ) then state = msg_his_expired end
            msg = msg .. "\n\t" .. msg_his_ban .. i .. ":\n" ..
                  "\t\t" .. msg_his_state .. state .. "\n" ..
                  "\t\t" .. msg_his_date .. parsedate( t.date ) .. "\n" ..
                  "\t\t" .. msg_his_bantime .. get_bantime( t.bantime ) .. "\n" ..
                  "\t\t" .. msg_his_reason .. t.reason .. "\n" ..
                  "\t\t" .. msg_his_by .. t.by_nick .. "\n"
        end
    end
    return utf_format( msg_out2, msg )
end

local cleanbans = function()
    bans = {}
    util_savearray( bans, bans_path )
end

local cleanhistory = function()
    history = {}
    util_savetable( history, "history_tbl", history_path )
end

local onbmsg = function( user, command, parameters )
    local level = user:level( )
    if level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local by, id = utf_match( parameters, "^(%S+) (%S+)" )
    local mode = utf_match( parameters, "^(%S+)" )
    local time = tonumber( utf_match( parameters, "^%S+ %S+ ([-]?%S+)" ) )
    local reason = ( time and utf_match( parameters, "^%S+ %S+ [-]?%S+ (.*)" ) ) or ( ( time == nil ) and utf_match( parameters, "^%S+ %S+ (.*)" ) )
    time = time or default_time
    reason = reason or msg_reason
    local bantime = time * 60
    local usernick = hub_escapefrom( user:nick() )
    local userfirstnick = hub_escapefrom( user:firstnick() )
    if mode == "show" then
        user:reply( showbans(), hub_getbot )
        return PROCESSED
    end
    if mode == "clear" then
        if level < 100 then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        cleanbans()
        user:reply( msg_clean_bans .. user:nick(), hub_getbot )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg_clean_bans .. user:nick() )
        return PROCESSED
    end

    if mode == "showhis" then
        user:reply( showhistory(), hub_getbot )
        return PROCESSED
    end
    if mode == "clearhis" then
        if level < 100 then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        cleanhistory()
        user:reply( msg_clean_banhistory .. user:nick(), hub_getbot )
        report.send( report_activate, report_hubbot, report_opchat, llevel, msg_clean_banhistory .. user:nick() )
        return PROCESSED
    end

    if not is_integer( time ) then
        user:reply( msg_notint, hub_getbot )
        return PROCESSED
    end
    if not ( ( by == "sid" or by == "nick" or by == "cid" or by == "ip" ) and id ) then
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    local target = (
    by == "nick" and hub_isnickonline( id ) ) or
    ( by == "sid" and hub_issidonline( id ) ) or
    ( by == "cid" and hub_iscidonline( id ) ) or
    ( by == "ip" and hub_isiponline( id ) )
    if not target then
        if by == "sid" then
            user:reply( msg_off, hub_getbot )
            return PROCESSED
        end
        addban( by, id, bantime, reason, level, userfirstnick, nil )
        local message = utf_format( msg_ok, id, usernick, get_bantime( bantime ), reason )
        report.send( report_activate, report_hubbot, report_opchat, llevel, message )
        user:reply( message, hub_getbot )
        return PROCESSED
    end
    if target:isbot() then
        user:reply( msg_bot, hub_getbot )
        return PROCESSED
    end
    if permission[ level ] < target:level( ) then
        user:reply( msg_god, hub_getbot )
        target:reply( utf_format( msg_ban_attempt, usernick, hub_escapefrom( reason ) ), hub_getbot, hub_getbot )
        return PROCESSED
    end
    local targetnick = target:nick()
    local message = utf_format( msg_ok, hub_escapefrom( targetnick ), usernick, get_bantime( bantime ), reason )
    -- This is special:
    -- SID ban is with rightclick function so its good to assume its for online user,
    -- so lets ban by nick, cid, ip ( easier unbanning by nick as the only reason really.. )
    -- Otherwise its probobly better to respect the ban criteria since the user is really
    -- writing a command that spesifies only one ban criteria. (by Night)
    local victim = nil
    if by == "sid" then
        victim = target
    end
    addban( by, id, bantime, reason, level, userfirstnick, victim )
    report.send( report_activate, report_hubbot, report_opchat, llevel, message )
    target:kill( "ISTA 230 " .. hub_escapeto( message ) .. "\n", "TL" .. bantime )
    --[[
    if not victim then
        user:reply( utf_format( msg_ban_added, by, id, userfirstnick ), hub_getbot )
    end
    ]]
    user:reply( message, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, txt )
        local user_nick = user:nick()
        local user_level = user:level()
        local cmd = utf_match( txt, "^[+!#](%S+)" )
        local by, id = utf_match( txt, "^[+!#]%S+ (%S+) (%S+)" )
        if cmd == cmd2 then
            if user_level < minlevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            if not ( ( by == "ip" or by == "nick" or by == "cid" ) and id ) then
                user:reply( msg_usage2, hub_getbot )
                return PROCESSED
            end
            for i, ban_tbl in ipairs( bans ) do
                if ban_tbl[ by ] == id then
                    if permission2[ user_level ] < ( ban_tbl.by_level or 100 ) then
                        user:reply( msg_god2, hub_getbot )
                        return PROCESSED
                    end
                    table_remove( bans, i )
                    util_savearray( bans, bans_path )
                    local message = utf_format( msg_ok2, user_nick, id )
                    report.send( report_activate, report_hubbot, report_opchat, llevel, message )
                    user:reply( message, hub_getbot )
                    return PROCESSED
                end
            end
            user:reply( msg_off, hub_getbot )
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onConnect", {},
    function( user )
        local nick, cid, hash, ip = user:firstnick(), user:cid(), user:hash(), user:ip()
        local what, key, ban
        for i, bantbl in ipairs( bans ) do
            key = i
            ban = bantbl
            if ban.nick == nick then
                what = "nick"
                break
            elseif ban.cid == cid and ban.hash == hash then
                what = "cid"
                break
            elseif ban.ip == ip then
                what = "ip"
                break
            end
        end
        if what then
            if user:level() >= tonumber( ban.by_level ) then
                table_remove( bans, key )  -- remove ban entry
                util_savearray( bans, bans_path )  -- save table
                user:reply( utf_format( msg_ban_attempt, ban.by_nick, ban.reason ), hub_getbot, hub_getbot )  -- and send info
                return nil  -- user can login without problems
            end
            local remaining, bantime, banstart = nil, tonumber( ban.time ), tonumber( ban.start )
            if bantime < 0 then
                remaining = 1  -- ban 1 sec forever ^^
            else
                remaining = ban.time - os_difftime( os_time(), banstart )
            end
            if remaining > 0 then
                local message
                if remaining == 1 then
                    message = utf_format( msg_ban, ban.by_nick, ban.reason ) .. msg_forever
                    user:kill( "ISTA 231 " .. hub_escapeto( message ) .. "\n", "TL-1" )
                    return PROCESSED
                else
                    message = utf_format( msg_ban, ban.by_nick, ban.reason ) .. get_bantime( remaining )
                    user:kill( "ISTA 231 " .. hub_escapeto( message ) .. "\n", "TL" .. remaining )
                    return PROCESSED
                end
            else
                table_remove( bans, key )
                util_savearray( bans, bans_path )
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function( )
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
            help.reg( help_title2, help_usage2, help_desc2, minlevel2 )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            local ucmd_time = utf_format( ucmd_time, default_time )
            -- ban
            ucmd.add( ucmd_menu9, cmd, { "nick", "%[line:User Nick]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu10, cmd, { "cid", "%[line:User CID]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu11, cmd, { "ip", "%[line:User IP]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu12, cmd, { "show" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu13, cmd, { "clear" }, { "CT1" }, 100 )
            ucmd.add( ucmd_menu14, cmd, { "showhis" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu15, cmd, { "clearhis" }, { "CT1" }, 100 )

            ucmd.add( ucmd_menu1, cmd, { "sid", "%[userSID]", "60", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu2, cmd, { "sid", "%[userSID]", "120", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu3, cmd, { "sid", "%[userSID]", "360", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu4, cmd, { "sid", "%[userSID]", "720", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu5, cmd, { "sid", "%[userSID]", "1440", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu6, cmd, { "sid", "%[userSID]", "2880", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu7, cmd, { "sid", "%[userSID]", "10080", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu8, cmd, { "sid", "%[userSID]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            -- unban
            ucmd.add( ucmd_menu_ct1_1, cmd2, { "nick", "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, minlevel2 )
            ucmd.add( ucmd_menu_ct1_2, cmd2, { "cid", "%[line:" .. ucmd_cid .. "]" }, { "CT1" }, minlevel2 )
            ucmd.add( ucmd_menu_ct1_3, cmd2, { "ip", "%[line:" .. ucmd_ip .. "]" }, { "CT1" }, minlevel2 )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert(  hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {    -- export bans

    add = add,  -- use ban = hub.import( "cmd_ban"); ban.add( user, target, bantime, reason, script ) in other scripts to ban a user (bantime = seconds)
    bans = bans,
    bans_path = bans_path,

}
