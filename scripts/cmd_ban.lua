--[[

    cmd_ban.lua by blastbeat

        - this script adds a command "ban" to ban users by sid/nick/cid / or show all banned users
        - usage: [+!#]ban sid|nick|cid|ip <SID>|<nick>|<CID>|<IP> [<time> <reason>] / [+!#]ban show|clean
        - <time> are ban minutes; negative values means ban forever
        - <time> and <reason> are optional
        
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
local scriptversion = "0.27"

local cmd = "ban"
local bans_path = "scripts/data/cmd_ban_bans.tbl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local os_date = os.date
local os_time = os.time
local utf_match = utf.match
local utf_format = utf.format
local os_difftime = os.difftime
local table_remove = table.remove
local util_savearray = util.savearray
local hub_getbot = hub.getbot()
local hub_escapeto = hub.escapeto
local hub_escapefrom = hub.escapefrom
local hub_issidonline = hub.issidonline
local hub_iscidonline = hub.iscidonline
local hub_isnickonline = hub.isnickonline
local hub_isiponline = hub.isiponline
local hub_getusers = hub.getusers
local util_loadtable = util.loadtable
local util_formatseconds = util.formatseconds
local util_getlowestlevel = util.getlowestlevel
local math_floor = math.floor

--// imports
local hubcmd, help, ucmd
local default_time = cfg_get( "cmd_ban_default_time" )
local report = cfg_get( "cmd_ban_report" )
local permission = cfg_get( "cmd_ban_permission" )
local llevel = cfg_get( "cmd_ban_llevel" )
local scriptlang = cfg_get( "language" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local report_hubbot = cfg_get( "cmd_ban_report_hubbot" )
local report_opchat = cfg_get( "cmd_ban_report_opchat" )
local bans = util_loadtable( bans_path ) or {}

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "ban"
local help_usage = lang.help_usage or "[+!#]ban sid|nick|cid|ip <sid>|<nick>|<cid>|<ip> [<time> <reason>] / [+!#]ban show"
local help_desc = lang.help_desc or "bans user; <time> are ban minutes; negative values means ban forever"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_notint = lang.msg_notint or "It's not allowed to use decimal numbers for bantime."
local msg_import = lang.msg_import or "Error while importing additional module."
local msg_reason = lang.msg_reason or "No reason."
local msg_usage = lang.msg_usage or "Usage: [+!#]ban sid|nick|cid <sid>|<nick>|<cid> [<time> <reason>] / [+!#]ban show"
local msg_off = lang.msg_off or "User not found."
local msg_god = lang.msg_god or "You cannot ban user with higher level than you."
local msg_bot = lang.msg_bot or "User is a bot."
local msg_ban = lang.msg_ban or "You were banned by: %s  |  reason: %s  |  Remaining ban time: "  -- do not delete '%s'!
local msg_ok = lang.msg_ok or "%s  were banned by  %s  |  bantime: %s  |  reason: %s"
local msg_ban_added = lang.msg_ban_added or "%s:  %s  was banned by  %s"
local msg_ban_attempt = lang.msg_ban_attempt or "User:  %s  with lower level than you has tried to ban you! because: %s"
local msg_clean_bans = lang.msg_clean_bans or "Ban table was cleaned by: "

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
local ucmd_menu12 = lang.ucmd_menu12 or { "User", "Control", "Ban", "show bans" }
local ucmd_menu13 = lang.ucmd_menu13 or { "User", "Control", "Ban", "clean bans" }

local ucmd_time = lang.ucmd_time or "Time in minutes"
local ucmd_reason = lang.ucmd_reason or "Reason"

local lblNick = lang.lblNick or " Nick: "
local lblCid = lang.lblCid or " CID: "
local lblIp = lang.lblIp or " IP: "
local lblReason = lang.lblReason or " Reason: "
local lblBy = lang.lblBy or " banned by: "
local lblTime = lang.lblTime or " banned till: "

local msg_out = lang.msg_out or [[


=== BANS =====================================================================================
%s
===================================================================================== BANS ===
  ]]


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

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

local addban = function( by, id, bantime, reason, level, nick, victim )
    bans[ #bans + 1 ] = {
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
    util_savearray( bans, bans_path )
end

local send_report = function( msg, lvl )
    if report then
        if report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= lvl then
                    user:reply( msg, hub_getbot, hub_getbot )
                end
            end
        end
        if report_opchat then
            if opchat_activate then
                opchat.feed( msg )
            end
        end
    end
end

local showbans = function()
    local bans = util_loadtable( bans_path ) or {}
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

local cleanbans = function()
    local bans = {}
    util_savearray( bans, bans_path )
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
    
    if mode == "clean" then
        if level < 100 then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end 
        cleanbans()
        user:reply( msg_clean_bans .. user:nick(), hub_getbot )
        send_report( msg_clean_bans .. user:nick(), llevel )
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
        --add to ban list
        addban( by, id, bantime, reason, level, userfirstnick, nil )
        local message = utf_format( msg_ok, id, usernick, get_bantime( bantime ), reason )
        local msg = utf_format( msg_ban_added, by, id, userfirstnick ) 
        send_report( message, llevel )
        
        user:reply( msg, hub_getbot )
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
    --add to ban list
    addban( by, id, bantime, reason, level, userfirstnick, victim )
    target:reply( message, hub_getbot, hub_getbot )
    send_report( message, llevel )
    
    target:kill( "ISTA 230 " .. hub_escapeto( message ) .. " TL" .. bantime .. "\n" )
    if not victim then
        user:reply( utf_format( msg_ban_added, by, id, userfirstnick ), hub_getbot )
    end
    user:reply( message, hub_getbot )
    return PROCESSED
end

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
                    user:kill( "ISTA 231 " .. hub_escapeto( message ) .. " TL-1 \n" )
                    return PROCESSED
                else
                    message = utf_format( msg_ban, ban.by_nick, ban.reason ) .. get_bantime( remaining )
                    user:kill( "ISTA 231 " .. hub_escapeto( message ) .. " TL \n" )
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
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu9, cmd, { "nick", "%[line:User Nick]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu10, cmd, { "cid", "%[line:User CID]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu11, cmd, { "ip", "%[line:User IP]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu12, cmd, { "show" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu13, cmd, { "clean" }, { "CT1" }, 100 )
            
            ucmd.add( ucmd_menu1, cmd, { "sid", "%[userSID]", "60", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu2, cmd, { "sid", "%[userSID]", "120", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu3, cmd, { "sid", "%[userSID]", "360", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu4, cmd, { "sid", "%[userSID]", "720", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu5, cmd, { "sid", "%[userSID]", "1440", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu6, cmd, { "sid", "%[userSID]", "2880", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu7, cmd, { "sid", "%[userSID]", "10080", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu8, cmd, { "sid", "%[userSID]", "%[line:" .. ucmd_time .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
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

    bans = bans,
    bans_path = bans_path,

}
