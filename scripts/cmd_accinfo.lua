--[[

    cmd_accinfo.lua by blastbeat

        - this script adds a command "accinfo" get infos about a reguser
        - usage: [+!#]accinfo sid|nick <SID>|<NICK> / [+!#]accinfoop sid|nick <SID>|<NICK>

        v0.28: by pulsar
            - changed visuals

        v0.27: by pulsar
            - added tcp_ports_ipv6, ssl_ports_ipv6
            - changed visuals
            - hide port 0 addys  / thx Sopor

        v0.26: by pulsar
            - get "search_flag_blocked" from "cfg/cfg.tbl"
            - removed "search_flag_blocked" from language files
            - changed visuals

        v0.25: by pulsar
            - changed msg_god / thx Sopor

        v0.24: by pulsar
            - using lastseen instead of lastlogout
            - clean code

        v0.23: by pulsar
            - removed table lookups
            - shows expanded accinfo as default (op level)
            - fix #31 / thx Sopor
                - shows if user is banned or not

        v0.22: by pulsar
            - fix #107 / thx Sopor
                - shows if the user is blocked by trafficmanager/msgmanager

        v0.21: by pulsar
            - removed "by CID" (Easy cleanup of codebase milestone)

        v0.20: by pulsar
            - fix small bug  / thx Night & WitchHunter
            - small improvements with output msg  / thx Sopor

        v0.19: by pulsar
            - fix small bug for unreg users in "onBroadcast" listener

        v0.18: by pulsar
            - add additional cmd and ucmd's for oplevel to show accinfo with user comment

        v0.17: by pulsar
            - show reg description if exists

        v0.16: by pulsar
            - fix problem with "profile.is_online"

        v0.15: by pulsar
            - removed "cmd_accinfo_minlevel" import
            - removed "cmd_accinfo_oplevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_accinfo_oplevel"

        v0.14: by pulsar
            - using new luadch date style

        v0.13: by pulsar
            - add new minlevel definition

        v0.12: by pulsar
            - improved method to read lastlogout
            - removed lastconnect info (uninteresting)

        v0.11: by pulsar
            - fix problem with utf.match  / thx Kungen

        v0.10: by pulsar
            - added lastlogout info
            - rewrite some parts of the code

        v0.09: by pulsar
            - typo fix in lang var  / thx jrock
            - caching new table lookups
            - change output msg if param is missing  / thx Motnahp

        v0.08: by pulsar
            - possibility to toggle advanced ct2 rightclick (shows complete userlist)
                - export var to "cfg/cfg.tbl"

        v0.07: by pulsar
            - Last user connect:
                - check if user is online and if send info instead of time
                - check if user never been logged
            - caching some new table lookups
            - sort some parts of code

        v0.06: by pulsar
            - added Last user connect to output  / thx fly out to Kungen for the idea

        v0.05: by pulsar
            - fix rightclick permissions
            - removed CID from output
            - added levelname to output
            - changed visual output style

        v0.04: by pulsar
            - changed rightclick style

        v0.03: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.02: by pulsar
            - added: show hubname + address + keyprint (if active)

        v0.01: by blastbeat

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_accinfo"
local scriptversion = "0.28"

local cmd = "accinfo"
local cmd2 = "accinfoop"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local permission = cfg.get( "cmd_accinfo_permission" )
local tcp = cfg.get( "tcp_ports" )
local ssl = cfg.get( "ssl_ports" )
local tcp_ipv6 = cfg.get( "tcp_ports_ipv6" )
local ssl_ipv6 = cfg.get( "ssl_ports_ipv6" )
local host = cfg.get( "hub_hostaddress" )
local hname = cfg.get( "hub_name" )
local use_keyprint = cfg.get( "use_keyprint" )
local keyprint_type = cfg.get( "keyprint_type" )
local keyprint_hash = cfg.get( "keyprint_hash" )
local advanced_rc = cfg.get( "cmd_accinfo_advanced_rc" )
local msgmanager_activate = cfg.get( "etc_msgmanager_activate" )
local trafficmanager_activate = cfg.get( "etc_trafficmanager_activate" )
local ban = hub.import( "cmd_ban")
local bans_tbl = ban.bans
local search_flag_blocked = cfg.get( "etc_trafficmanager_flag_blocked" )

--// msgs
local help_title = lang.help_title or "cmd_accinfo.lua - Users"
local help_usage = lang.help_usage or "[+!#]accinfo sid|nick|cid <SID>|<NICK>"
local help_desc = lang.help_desc or "Sends accinfo about a reguser by SID or NICK; no arguments -> about yourself"

local help_title2 = lang.help_title2 or "cmd_accinfo.lua - Operators"
local help_usage2 = lang.help_usage2 or "[+!#]accinfoop sid|nick <SID>|<NICK>"
local help_desc2 = lang.help_desc2 or "Sends accinfo (expanded) about a reguser by SID or NICK; no arguments -> about yourself"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or  "Usage: [+!#]accinfo sid|nick <SID>|<NICK> / [+!#]accinfoop sid|nick <SID>|<NICK>"
local msg_off = lang.msg_off or "[ ACCINFO ]--> User not found/regged."
local msg_god = lang.msg_god or "You are not allowed to view the accinfo from this user"
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_unknown = lang.msg_unknown or "<unknown>"
local msg_online = lang.msg_online or "user is online"
local msg_keyprint = lang.msg_keyprint or "  (with Keyprint)"
local msg_accinfo = lang.msg_accinfo or [[


=== ACCINFO ==================================================================================================================

    Nickname: %s
    Password: %s

    Level: %s  [ %s ]

    Regged by: %s
    Regged since: %s
    Comment: %s

    Last seen: %s

    Traffic blocked: %s
    Messages blocked: %s
    Nickname is banned: %s

    Hubname: %s

    Hubaddress: %s
================================================================================================================== ACCINFO ===

   ]]

local msg_accinfo2 = lang.msg_accinfo2 or [[


=== ACCINFO ==================================================================================================================

    Nickname: %s
    Password: %s

    Level: %s  [ %s ]

    Regged by: %s
    Regged since: %s

    Last seen: %s

    Hubname: %s

    Hubaddress: %s
================================================================================================================== ACCINFO ===

   ]]

local ucmd_nick = lang.ucmd_nick or "Nick:"

local ucmd_menu_ct0 = lang.ucmd_menu_ct0 or { "About You", "show Accinfo" }
local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "User", "Accinfo", "default", "by Nick" }
local ucmd_menu_ct3 = lang.ucmd_menu_ct3 or { "Show", "Accinfo", "default" }
local ucmd_menu_ct4 = lang.ucmd_menu_ct4 or "User"
local ucmd_menu_ct5 = lang.ucmd_menu_ct5 or "Accinfo"
local ucmd_menu_ct6 = lang.ucmd_menu_ct6 or "by Nick from List"

local ucmd_menu_ct1_op = lang.ucmd_menu_ct1_op or { "User", "Accinfo" }
local ucmd_menu_ct3_op = lang.ucmd_menu_ct3_op or { "Show", "Accinfo" }
local ucmd_menu_ct4_op = lang.ucmd_menu_ct4_op or "User"
local ucmd_menu_ct5_op = lang.ucmd_menu_ct5_op or "Accinfo"
local ucmd_menu_ct6_op = lang.ucmd_menu_ct6_op or "by Nick from List"

local msg_msgmanager = lang.msg_msgmanager or "%s %s"
local msg_msgmanager_1 = lang.msg_msgmanager_1 or "YES / Blockmode: "
local msg_msgmanager_2 = lang.msg_msgmanager_2 or "NO"

local msg_trafficmanager_1 = lang.msg_trafficmanager_1 or "YES"
local msg_trafficmanager_2 = lang.msg_trafficmanager_2 or "NO"
local msg_bans_yes = lang.msg_bans_yes or "YES / banned by: %s / bantime remaining: %s"
local msg_bans_no = lang.msg_bans_no or "NO"
local msg_forever = lang.msg_forever or "forever"

--// database
local description_file = "scripts/data/cmd_reg_descriptions.tbl"
local msgmanager_file = "scripts/data/etc_msgmanager.tbl"


----------
--[CODE]--
----------

local addy = "\n"

local tbl_isEmpty = function( tbl )
    if next( tbl ) == nil then return true else return false end
end

local get_keyprint = function( str )
    if use_keyprint then
        return "\n\t" .. str .. keyprint_type .. keyprint_hash .. msg_keyprint .. "\n"
    else
        return "\n"
    end
end

--// tcp_ports
if not tbl_isEmpty( tcp ) and ( tcp[ 1 ] > 0 ) then
    addy = addy .. "\n\t[ IPv4 ]\n\n"
    if #tcp > 1 then
        for i, port in ipairs( tcp ) do
            addy = addy .. "\tadc://" .. host .. ":" .. port .. "\n"
        end
    else
        addy = addy .. "\tadc://" .. host .. ":" .. tcp[ 1 ] .. "\n"
    end
end
--// ssl_ports
if not tbl_isEmpty( ssl ) and ( ssl[ 1 ] > 0 ) then
    if #ssl > 1 then
        addy = addy .. "\n\t[ IPv4 SSL ]\n\n"
        for i, port in ipairs( ssl ) do
            addy = addy .. "\tadcs://" .. host .. ":" .. port .. get_keyprint( "adcs://" .. host .. ":" .. port )
        end
    else
        addy = addy .. "\n\t[ IPv4 SSL ]\n\n"
        addy = addy .. "\tadcs://" .. host .. ":" .. ssl[ 1 ] .. get_keyprint( "adcs://" .. host .. ":" .. ssl[ 1 ] )
    end
end
--// tcp_ports_ipv6
if not tbl_isEmpty( tcp_ipv6 ) and ( tcp_ipv6[ 1 ] > 0 ) then
    addy = addy .. "\n\t[ IPv6 ]\n\n"
    if #tcp_ipv6 > 1 then
        for i, port in ipairs( tcp_ipv6 ) do
            addy = addy .. "\tadc://" .. host .. ":" .. port .. "\n"
        end
    else
        addy = addy .. "\tadc://" .. host .. ":" .. tcp_ipv6[ 1 ] .. "\n"
    end
end
--// ssl_ports_ipv6
if not tbl_isEmpty( ssl_ipv6 ) and ( ssl_ipv6[ 1 ] > 0 ) then
    if #ssl_ipv6 > 1 then
        addy = addy .. "\n\t[ IPv6 SSL ]\n\n"
        for i, port in ipairs( ssl_ipv6 ) do
            addy = addy .. "\tadcs://" .. host .. ":" .. port .. get_keyprint( "adcs://" .. host .. ":" .. port )
        end
    else
        addy = addy .. "\n\t[ IPv6 SSL ]\n\n"
        addy = addy .. "\tadcs://" .. host .. ":" .. ssl_ipv6[ 1 ] .. get_keyprint( "adcs://" .. host .. ":" .. ssl_ipv6[ 1 ] )
    end
end

local get_lastseen = function( profile )
    local lastseen
    local ll = profile.lastseen
    local found = false
    for sid, user in pairs( hub.getusers() ) do
        if user:firstnick() == profile.nick then found = true break end
    end
    if found then
        lastseen = msg_online
    elseif ll then
        local sec, y, d, h, m, s = util.difftime( util.date(), ll )
        lastseen = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    else
        lastseen = msg_unknown
    end
    return lastseen
end

local get_regdescription = function( profile )
    local description_tbl = util.loadtable( description_file )
    local desc = ""
    for k, v in pairs( description_tbl ) do
        if k == profile.nick then
            desc = v[ "tReason" ]
            break
        end
    end
    return desc
end

local get_trafficmanager = function( profile )
    if trafficmanager_activate then
        local isBlocked = false
        for sid, user in pairs( hub.getusers() ) do
            if profile.nick == user:firstnick() then
                local isBlocked, b = string.find( user:description(), search_flag_blocked, 1, true )
                if isBlocked then return msg_trafficmanager_1 end
            end
        end
    end
    return msg_trafficmanager_2
end

local get_msgmanager = function( profile )
    if msgmanager_activate then
        local msgmanager_tbl = util.loadtable( msgmanager_file )
        local info = ""
        for k, v in pairs( msgmanager_tbl ) do
            if k == profile.nick then
                info = v
                break
            end
        end
        if info == "m" then return utf.format( msg_msgmanager, msg_msgmanager_1, "Main" ) end
        if info == "p" then return utf.format( msg_msgmanager, msg_msgmanager_1, "PM" ) end
        if info == "b" then return utf.format( msg_msgmanager, msg_msgmanager_1, "Main + PM" ) end
    end
    return msg_msgmanager_2
end

local is_banned = function( username )
    local by_nick, start, time, reason
    for k, v in pairs( bans_tbl ) do
        if v.nick == username then
            by_nick = v.by_nick
            start = v.start
            time = v.time
            reason = v.reason
            return by_nick, start, time, reason
        end
    end
    return nil
end

local get_bantime = function( remaining )
    if tostring( remaining ):find( "-" ) then
        return msg_forever
    else
        local d, h, m, s = util.formatseconds( remaining )
        return d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    end
end

local onbmsg = function( user, command, parameters )
    local level = user:level()
    if level < 10 then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local me = utf.match( parameters, "^(%S+)" )
    local by, id = utf.match( parameters, "^(%S+) (.*)" )
    local target
    local _, regnicks, regcids = hub.getregusers()
    local _, usersids = hub.getusers()
    if ( me == nil ) then
        local usercid, usernick = user:cid(), user:firstnick()
        target = regnicks[ usernick ] or regcids.TIGR[ usercid ]
    else
        if not ( ( by == "sid" or by == "nick" or by == "cid" ) and id ) then
            user:reply( msg_usage, hub.getbot() )
            return PROCESSED
        else
            target = (
            by == "nick" and regnicks[ id ] ) or
            ( by == "cid" and regcids.TIGR[ id ] ) or
            ( by == "sid" and ( usersids[ id ] and usersids[ id ]:isregged() and usersids[ id ]:profile() ) )    -- OMG
        end
    end
    if not target then
        user:reply( msg_off, hub.getbot() )
        return PROCESSED
    end
    local targetlevel = tonumber( target.level ) or 100
    local targetlevelname = cfg.get( "levels" )[ targetlevel ] or "Unreg"
    if not ( me == nil ) and ( ( permission[ level ] or 0 ) < targetlevel ) then
        user:reply( msg_god, hub.getbot() )
        return PROCESSED
    end
    local accinfo = utf.format(
        msg_accinfo2,
        target.nick or msg_unknown,
        target.password or msg_unknown,
        targetlevel or msg_unknown,
        targetlevelname or msg_unknown,
        target.by or msg_unknown,
        target.date or msg_unknown,
        get_lastseen( target ),
        hname or msg_unknown,
        addy or msg_unknown
    )
    user:reply( accinfo, hub.getbot(), hub.getbot() )
    return PROCESSED
end

hub.setlistener( "onBroadcast", {},
    function( user, adccmd, parameters )
        local level = user:level()
        local cmd, _ = utf.match( parameters, "^[+!#](%S+) (.+)" )
        local me = utf.match( parameters, "^[+!#]%S+ (%S+)" )
        local by, id = utf.match( parameters, "^[+!#]%S+ (%S+) (.*)" )
        if cmd == cmd2 then
            if level < 10 then
                user:reply( msg_denied, hub.getbot() )
                return PROCESSED
            end
            local target
            local _, regnicks, regcids = hub.getregusers()
            local _, usersids = hub.getusers()
            if ( me == nil ) then
                local usercid, usernick = user:cid(), user:firstnick()
                target = regnicks[ usernick ] or regcids.TIGR[ usercid ]
            else
                if not ( ( by == "sid" or by == "nick" or by == "cid" ) and id ) then
                    user:reply( msg_usage, hub.getbot() )
                    return PROCESSED
                else
                    target = (
                    by == "nick" and regnicks[ id ] ) or
                    ( by == "cid" and regcids.TIGR[ id ] ) or
                    ( by == "sid" and ( usersids[ id ] and usersids[ id ]:isregged() and usersids[ id ]:profile() ) )    -- OMG
                end
            end
            if not target then
                user:reply( msg_off, hub.getbot() )
                return PROCESSED
            end
            local targetlevel = tonumber( target.level ) or 100
            local targetlevelname = cfg.get( "levels" )[ targetlevel ] or "Unreg"
            if not ( user.profile() == target ) and ( ( permission[ level ] or 0 ) < targetlevel ) then
                user:reply( msg_god, hub.getbot() )
                return PROCESSED
            end

            local ban_msg = msg_bans_no
            local by_nick, start, time, reason = is_banned( target.nick )
            if by_nick then
                local remaining = time - os.difftime( os.time(), start )
                ban_msg = utf.format( msg_bans_yes, by_nick, get_bantime( remaining ) )
            end
            local accinfo = utf.format(
                msg_accinfo,
                target.nick or msg_unknown,
                target.password or msg_unknown,
                targetlevel or msg_unknown,
                targetlevelname or msg_unknown,
                target.by or msg_unknown,
                target.date or msg_unknown,
                get_regdescription( target ),
                get_lastseen( target ),
                get_trafficmanager( target ),
                get_msgmanager( target ),
                ban_msg,
                hname or msg_unknown,
                addy or msg_unknown
            )
            user:reply( accinfo, hub.getbot(), hub.getbot() )
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        local oplevel = util.getlowestlevel( permission )
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, 10 )
            help.reg( help_title2, help_usage2, help_desc2, oplevel )
        end
        local ucmd = hub.import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct0, cmd, { }, { "CT1" }, 10 )
            ucmd.add( ucmd_menu_ct1_op, cmd2, { "nick", "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_ct3_op, cmd2, { "sid", "%[userSID]" }, { "CT2" }, oplevel )

            if advanced_rc then
                local regusers, reggednicks, reggedcids = hub.getregusers()
                local usertbl = {}
                for i, user in ipairs( regusers ) do
                    if ( user.is_bot ~=1 ) and user.nick then
                      table.insert( usertbl, user.nick )
                    end
                end
                table.sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct4, ucmd_menu_ct5, ucmd_menu_ct6, nick }, cmd, { "nick", nick }, { "CT1" }, oplevel )
                    ucmd.add( { ucmd_menu_ct4_op, ucmd_menu_ct5_op, ucmd_menu_ct6_op, nick }, cmd2, { "nick", nick }, { "CT1" }, oplevel )
                end
            end
        end
        local hubcmd = hub.import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )