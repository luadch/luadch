--[[

    etc_trafficmanager.lua by pulsar

        based on my etc_transferblocker.lua

        usage:

        [+!#]trafficmanager block <NICK> [<REASON>] -- blocks downloads, uploads and search requests
        [+!#]trafficmanager unblock <NICK>  -- unblock user
        [+!#]trafficmanager show settings  -- shows current settings from "cfg/cfg.tbl"
        [+!#]trafficmanager show blocks  -- shows all blockes users and her blockmodes


        v1.6:
            - simplify 'activate' logic
            - changed some parts of code

        v1.5:
            - changed visuals

        v1.4:
            - some modifications based on issue #37  / thx Sopor
                - fix #37 -> https://github.com/luadch/luadch/issues/37
            - removed table lookups
            - add "del()" function for export feature

        v1.3:
            - users with lower level can't block or unblock higher levels or the same level

        v1.2:
            - added "etc_trafficmanager_check_minshare"
                - block user instead of disconnect if usershare < minshare
            - small typo fix  / thx WitchHunter

        v1.1:
            - possibility to set a reason on block
            - using target:nick() instead of target:firstnick() for output msgs
            - send msg to target on block/unblock
            - send block reason to target on login/rotation msg
            - using new util.spairs() function for blocked users list
            - added block export function
            - small permission fix
            - save/show nickname of blocker to/from db too

        v1.0:
            - there is only one block method now: download + upload + search
            - fix problem with passive users
            - users with permissions can download from blocked users now
            - removed unneeded code parts
            - new default description tag for blocked users is: "[BLOCKED] "
            - added "msg_onsearch"  / requested by Sopor

        v0.9:
            - small fix in "onbmsg" function
            - added "is_autoblocked()" function
            - changed "msg_notfound" msg
            - code cleanup

        v0.8:
            - possibility to send the user report msg as loop every x hours  / requested by DerWahre
            - fix output messages to prevent possible client emotions  / thx Sopor
            - fix small bug in "onExit" listener
            - fix small bug in "onStart" listener  / thx Sopor
            - removed send_report() function, using report import functionality now
            - send specific msg to user if targetuser was autoblocked by script  / thx Sopor

        v0.7:
            - small bugfix  / thx Mocky

        v0.6:
            - check if target is a bot  / thx Kaas
            - fix "msg_notonline"  / thx Sopor
            - add "is_blocked()"
                - fix double block issue  / thx Sopor

        v0.5:
            - possibility to block/unblock single users from userlist  / requested by Sopor
            - show list of all blocked users
            - show settings
            - show blockmode in user description
            - add new table lookups, imports, msgs
            - rewrite some parts of code

        v0.4:
            - possibility to block users with 0 B share

        v0.3:
            - small fix in "onLogin" listener
                - remove return PROCESSED
                - add return nil

        v0.2:
            - add missing permission check  / thx Kaas

        v0.1:
            - option to block download for specified levels
            - option to block upload for specified levels
            - option to block search for specified levels

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_trafficmanager"
local scriptversion = "1.6"

local cmd = "trafficmanager"
local cmd_b = "block"
local cmd_u = "unblock"
local cmd_s = "show"

local block_file = "scripts/data/etc_trafficmanager.tbl"


--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local activate = cfg.get( "etc_trafficmanager_activate" )
local permission = cfg.get( "etc_trafficmanager_permission" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "etc_trafficmanager_report" )
local report_hubbot = cfg.get( "etc_trafficmanager_report_hubbot" )
local report_opchat = cfg.get( "etc_trafficmanager_report_opchat" )
local llevel = cfg.get( "etc_trafficmanager_llevel" )
local blocklevel_tbl = cfg.get( "etc_trafficmanager_blocklevel_tbl" )
local sharecheck = cfg.get( "etc_trafficmanager_sharecheck" )
local minsharecheck = cfg.get( "etc_trafficmanager_check_minshare" )
local min_share = cfg.get( "min_share" )
local oplevel = cfg.get( "etc_trafficmanager_oplevel" )
local login_report = cfg.get( "etc_trafficmanager_login_report" )
local report_main = cfg.get( "etc_trafficmanager_report_main" )
local report_pm = cfg.get( "etc_trafficmanager_report_pm" )
local desc_prefix_activate = cfg.get( "usr_desc_prefix_activate" )
local desc_prefix_permission = cfg.get( "usr_desc_prefix_permission" )
local desc_prefix_table = cfg.get( "usr_desc_prefix_prefix_table" )
local send_loop = cfg.get( "etc_trafficmanager_send_loop" )
local loop_time = cfg.get( "etc_trafficmanager_loop_time" )
local block_tbl = util.loadtable( block_file )

--// flags
local flag_blocked = "[BLOCKED] "

--// msgs
local help_title = lang.help_title or "etc_trafficmanager.lua - Operators"
local help_usage = lang.help_usage or "[+!#]trafficmanager show settings|blocks"
local help_desc = lang.help_desc or "Shows current settings from 'cfg/cfg.tbl' | Shows all blockes users and their blockmodes"

local help_title2 = lang.help_title2 or "etc_trafficmanager.lua - Owners"
local help_usage2 = lang.help_usage2 or "[+!#]trafficmanager block <NICK> [<REASON>] | unblock <NICK>"
local help_desc2 = lang.help_desc2 or "Blocks downloads ( d ), uploads ( u ) and search ( s ) | Unblock user"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_god = lang.msg_god or "You are not allowed to block/unblock this user."
local msg_notonline = lang.msg_notonline or "[ TRAFFICMANAGER ]--> User is offline."
local msg_notfound = lang.msg_notfound or "[ TRAFFICMANAGER ]--> User isn't blocked."
local msg_stillblocked = lang.msg_stillblocked or "[ TRAFFICMANAGER ]--> User:  %s  is already blocked by:  %s  |  reason:  %s"
local msg_stillautoblocked = lang.msg_stillautoblocked or "[ TRAFFICMANAGER ]--> The level of this user is already auto-blocked."
local msg_isbot = lang.msg_isbot or "[ TRAFFICMANAGER ]--> User is a bot."
local msg_block = lang.msg_block or "[ TRAFFICMANAGER ]--> Block user:  %s  |  reason:  %s"
local msg_unblock = lang.msg_unblock or "[ TRAFFICMANAGER ]--> Unblock user:  %s"
local msg_op_report_block = lang.msg_op_report_block or "[ TRAFFICMANAGER ]--> User:  %s  |  has blocked user:  %s  |  reason:  %s"
local msg_op_report_unblock = lang.msg_op_report_unblock or "[ TRAFFICMANAGER ]--> User:  %s  |  has unblocked user:  %s"
local msg_autoblock = lang.msg_autoblock or "[ TRAFFICMANAGER ]--> This user was autoblocked by script permissions."
local msg_onsearch = lang.msg_onsearch or "[ TRAFFICMANAGER ]--> Your search function is disabled."
local msg_unknown = lang.msg_unknown or "<UNKNOWN>"
local msg_reason = lang.msg_reason or "Reason:"
local msg_blocked_by = lang.msg_blocked_by or "Blocked by:"
local msg_target_block = lang.msg_target_block or "[ TRAFFICMANAGER ]--> You were blocked by:  %s  |  reason:  %s"
local msg_target_unblock = lang.msg_target_unblock or "[ TRAFFICMANAGER ]--> You were unblocked by:  %s"

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "Hub", "etc", "Traffic Manager", "show", "Settings" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "Hub", "etc", "Traffic Manager", "show", "Blocked users" }
local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Traffic Manager", "block" }
local ucmd_menu_ct2_3 = lang.ucmd_menu_ct2_3 or { "Traffic Manager", "unblock" }
local ucmd_desc = lang.ucmd_desc or "Reason:"

local report_msg = lang.report_msg or [[


=== TRAFFIC MANAGER =====================================

     Hello %s, your level in this hub:  %s [ %s ]

     Downloads, Uploads and Searches are blocked.

===================================== TRAFFIC MANAGER ===
  ]]

local report_msg_2 = lang.report_msg_2 or [[


=== TRAFFIC MANAGER =====================================

     Hello %s,
     your sharesize does not meet the minshare requirements:

     Downloads, Uploads and Searches are blocked.

===================================== TRAFFIC MANAGER ===
  ]]

local report_msg_3 = lang.report_msg_3 or [[


=== TRAFFIC MANAGER =====================================

     Hello %s, your nick is on the blocklist.

     Blocked by: %s
     Reason: %s

     Downloads, Uploads and Searches are blocked.

===================================== TRAFFIC MANAGER ===
  ]]

local opmsg = lang.opmsg or [[


=== TRAFFIC MANAGER =====================================

   Script is active:  %s
   Send report to blocked users on login:  %s
   Send report to blocked users on timer:  %s

         Send to Main:  %s
         Send to PM:  %s

   Blocked levels:

%s
   Block users with 0 B share:  %s

===================================== TRAFFIC MANAGER ===
  ]]

local msg_usage = lang.msg_usage or [[


=== TRAFFIC MANAGER ===========================================================

Usage:

 [+!#]trafficmanager block <NICK> [<REASON>]  -- blocks downloads ( d ), uploads ( u ) and search ( s )
 [+!#]trafficmanager unblock <NICK>  -- unblock user
 [+!#]trafficmanager show settings  -- shows current settings from "cfg/cfg.tbl"
 [+!#]trafficmanager show blocks  -- shows all blockes users and her blockmodes

=========================================================== TRAFFIC MANAGER ===
  ]]

local msg_users = lang.msg_users or [[


=== TRAFFIC MANAGER ========================================================================
%s
======================================================================== TRAFFIC MANAGER ===
  ]]

--// functions
local onbmsg
local get_blocklevels
local get_bool
local check_share
local is_blocked
local is_autoblocked
local send_user_report
local format_description
local add, del


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local delay = loop_time * 60 * 60
local start = os.time()

local masterlevel = util.getlowestlevel( permission )

--// get all levelnames from blocked table in sorted order
get_blocklevels = function()
    local levels = cfg.get( "levels" ) or {}
    local tbl = {}
    local i = 1
    local msg = ""
    for k, v in pairs( blocklevel_tbl ) do
        if k >= 0 then
            if v then
                tbl[ i ] = k
                i = i + 1
            end
        end
    end
    table.sort( tbl )
    for _, level in pairs( tbl ) do
        msg = msg .. "\t" .. levels[ level ] .. "\n"
    end
    return msg
end

--// returns value of a bool as string
get_bool = function( var )
    local msg = "false"
    if var then msg = "true" end
    return msg
end

--// check if user has no share
check_share = function( user )
    local user_level = user:level()
    local user_share = user:share()
    local result = false
    if user_level < oplevel then
        if sharecheck then
            if user_share == 0 then result = true end
        end
        if minsharecheck then
            local min = min_share[ user_level ] * 1024 * 1024 * 1024
            if user_share < min then result = true end
        end
    end
    return result
end

--// check if target user is still autoblocked
is_autoblocked = function( target )
    if target then
        local target_firstnick = target:firstnick()
        local target_level = target:level()
        for sid, user in pairs( hub.getusers() ) do
            if blocklevel_tbl[ target_level ] or check_share( target ) then
                return true
            end
        end
    end
    return false
end

--// check if target user is still blocked
is_blocked = function( target )
    if target then
        local target_firstnick = target:firstnick()
        local target_level = target:level()
        for sid, user in pairs( hub.getusers() ) do
            if type( block_tbl[ target_firstnick ] ) ~= "nil" then
                return true
            end
        end
    end
    return false
end

--// user report msg on timer
send_user_report = function()
    if send_loop then
        for sid, user in pairs( hub.getusers() ) do
            local user_level = user:level()
            local user_firstnick = user:firstnick()
            local msg
            local need_save = false
            if blocklevel_tbl[ user_level ] then
                local levelname = cfg.get( "levels" )[ user_level ] or "Unreg"
                msg = utf.format( report_msg, user_firstnick, user_level, levelname )
                if report_main then user:reply( msg, hub.getbot() ) end
                if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
            elseif check_share( user ) then
                msg = utf.format( report_msg_2, user_firstnick )
                if report_main then user:reply( msg, hub.getbot() ) end
                if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
            elseif type( block_tbl[ user_firstnick ] ) ~= "nil" then
                if type( block_tbl[ user_firstnick ] ) == "boolean" then  -- downward compatibility with older versions
                    block_tbl[ user_firstnick ] = nil
                    block_tbl[ user_firstnick ] = {}
                    block_tbl[ user_firstnick ][ 1 ] = msg_unknown
                    block_tbl[ user_firstnick ][ 2 ] = msg_unknown
                    need_save = true
                elseif type( block_tbl[ user_firstnick ] ) == "string" then  -- downward compatibility with older versions
                    local reason = block_tbl[ user_firstnick ]
                    block_tbl[ user_firstnick ] = nil
                    block_tbl[ user_firstnick ] = {}
                    block_tbl[ user_firstnick ][ 1 ] = msg_unknown
                    block_tbl[ user_firstnick ][ 2 ] = reason
                    need_save = true
                end
                msg = utf.format( report_msg_3, user_firstnick, block_tbl[ user_firstnick ][ 1 ], block_tbl[ user_firstnick ][ 2 ] )
                if report_main then user:reply( msg, hub.getbot() ) end
                if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
                if need_save then util.savetable( block_tbl, "block_tbl", block_file ) end
            end
        end
    end
end

--// add/remove description flag
format_description = function( flag, listener, target, cmd )
    local desc, new_desc = "", ""
    if listener == "onStart" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub.escapeto( desc_prefix_table[ target:level() ] )
            local desc = target:description() or ""
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub.escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub.escapeto( flag )
            local desc = target:description() or ""
            new_desc = prefix .. desc
        end
    end
    if listener == "onExit" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local prefix = hub.escapeto( flag )
            local desc = target:description() or ""
            new_desc = utf.sub( desc, utf.len( prefix ) + 1, -1 )
        else
            local prefix = hub.escapeto( flag )
            local desc = target:description() or ""
            new_desc = utf.sub( desc, utf.len( prefix ) + 1, -1 )
        end
    end
    if listener == "onInf" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub.escapeto( desc_prefix_table[ target:level() ] )
            local desc = cmd:getnp "DE"
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub.escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub.escapeto( flag )
            local desc = cmd:getnp "DE"
            new_desc = prefix .. desc
        end
    end
    if listener == "onConnect" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub.escapeto( desc_prefix_table[ target:level() ] )
            local desc = target:description() or ""
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub.escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub.escapeto( flag )
            local desc = target:description() or ""
            new_desc = prefix .. desc
        end
    end
    return new_desc
end

--// export function
add = function( target, script, reason )
    local err
    if not script then
        err = "Scriptname expected, got nil."
        return false, err
    end
    if not reason then reason = msg_unknown end
    reason = reason .. " (blocked by: " .. script .. ")"
    local target = hub.isnickonline( target )
    if target then
        if target:isbot() then
            err = "The target is a bot."
            return false, err
        else
            target_nick = target:nick()
            target_firstnick = target:firstnick()
            target_level = target:level()
        end
    else
        err = "The target is offline."
        return false, err
    end
    if is_autoblocked( target ) then
        err = "The target is still auto-blocked."
        return false, err
    elseif is_blocked( target ) then
        err = "The target is still blocked by user."
        return false, err
    else
        if target_level >= masterlevel then
            err = "The target can't get blocked, level is to high."
            return false, err
        else
            block_tbl[ target_firstnick ] = {}
            block_tbl[ target_firstnick ][ 1 ] = script
            block_tbl[ target_firstnick ][ 2 ] = reason
            util.savetable( block_tbl, "block_tbl", block_file )
            local msg_target = utf.format( msg_target_block, script, reason )
            target:reply( msg_target, hub.getbot(), hub.getbot() )
            local msg_report = utf.format( msg_op_report_block, script, target_nick, reason )
            report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
            --// add description flag
            for sid, buser in pairs( hub.getusers() ) do
                if buser:firstnick() == target_firstnick then
                    local new_desc = format_description( flag_blocked, "onStart", buser, nil )
                    buser:inf():setnp( "DE", new_desc )
                    hub.sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
                end
            end
            return PROCESSED
        end
    end
end

--// export function
del = function( target )
    if block_tbl[ target ] ~= nil then
        block_tbl[ target ] = nil
        util.savetable( block_tbl, "block_tbl", block_file )
    end
end

--// if user logs in
hub.setlistener( "onLogin", {},
    function( user )
        local msg
        local need_save = false
        if user:level() < masterlevel then
            if blocklevel_tbl[ user:level() ] then
                if login_report then
                    local levelname = cfg.get( "levels" )[ user:level() ] or "Unreg"
                    msg = utf.format( report_msg, user:firstnick(), user:level(), levelname )
                    if report_main then user:reply( msg, hub.getbot() ) end
                    if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
                end
            elseif check_share( user ) then
                if login_report then
                    msg = utf.format( report_msg_2, user:firstnick() )
                    if report_main then user:reply( msg, hub.getbot() ) end
                    if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
                end
            elseif type( block_tbl[ user:firstnick() ] ) ~= "nil" then
                if login_report then
                    if type( block_tbl[ user:firstnick() ] ) == "boolean" then  -- downward compatibility with older versions
                        block_tbl[ user:firstnick() ] = nil
                        block_tbl[ user:firstnick() ] = {}
                        block_tbl[ user:firstnick() ][ 1 ] = msg_unknown
                        block_tbl[ user:firstnick() ][ 2 ] = msg_unknown
                        need_save = true
                    elseif type( block_tbl[ user:firstnick() ] ) == "string" then  -- downward compatibility with older versions
                        local reason = block_tbl[ user:firstnick() ]
                        block_tbl[ user:firstnick() ] = nil
                        block_tbl[ user:firstnick() ] = {}
                        block_tbl[ user:firstnick() ][ 1 ] = msg_unknown
                        block_tbl[ user:firstnick() ][ 2 ] = reason
                        need_save = true
                    end
                    msg = utf.format( report_msg_3, user:firstnick(), block_tbl[ user:firstnick() ][ 1 ], block_tbl[ user:firstnick() ][ 2 ] )
                    if report_main then user:reply( msg, hub.getbot() ) end
                    if report_pm then user:reply( msg, hub.getbot(), hub.getbot() ) end
                    if need_save then util.savetable( block_tbl, "block_tbl", block_file ) end
                end
            end
        end
        return nil
    end
)

--// hubcmd
onbmsg = function( user, command, parameters )
    local target_nick, target_firstnick, target_level, target_sid
    local p1, p2, p3 = utf.match( parameters, "^(%S+) (%S+) ?(.*)" )
    if p3 == "" then p3 = msg_unknown end
    --// [+!#]trafficmanager show settings
    if ( ( p1 == cmd_s ) and ( p2 == "settings" ) ) then
        if user:level() < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        local msg = utf.format( opmsg,
                                get_bool( activate ),
                                get_bool( login_report ),
                                get_bool( send_loop ),
                                get_bool( report_main ),
                                get_bool( report_pm ),
                                get_blocklevels(),
                                get_bool( sharecheck )
        )
        user:reply( msg, hub.getbot() )
        return PROCESSED
    end
    --// [+!#]trafficmanager show blocks
    if ( ( p1 == cmd_s ) and ( p2 == "blocks" ) ) then
        if user:level() < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        local msg = ""
        local blocker, reason
        for k, v in util.spairs( block_tbl ) do
            if type( v ) == "boolean" then  -- downward compatibility with older versions
                blocker = msg_unknown
                reason = msg_unknown
            elseif type( v ) == "string" then  -- downward compatibility with older versions
                blocker = msg_unknown
                reason = v
            elseif type( v ) == "table" then
                blocker = v[ 1 ] or msg_unknown
                reason = v[ 2 ] or msg_unknown
            end
            msg = msg .. "\n" .. k ..
                         "\n\n\t" .. msg_blocked_by .. " " .. blocker ..
                         "\n\t" .. msg_reason .. " " .. reason .. "\n"
        end
        local msg_out = utf.format( msg_users, msg )
        user:reply( msg_out, hub.getbot() )
        return PROCESSED
    end
    --// [+!#]trafficmanager block <NICK>
    if ( ( p1 == cmd_b ) and p2 ) then
        local target = hub.isnickonline( p2 )
        if target then
            if target:isbot() then
                user:reply( msg_isbot, hub.getbot() )
                return PROCESSED
            else
                target_nick = target:nick()
                target_firstnick = target:firstnick()
                target_level = target:level()
            end
        else
            user:reply( msg_notonline, hub.getbot() )
            return PROCESSED
        end
        if is_autoblocked( target ) then
            user:reply( msg_stillautoblocked, hub.getbot() )
            return PROCESSED
        elseif is_blocked( target ) then
            local by = block_tbl[ target_firstnick ][ 1 ]
            local reason = block_tbl[ target_firstnick ][ 2 ]
            user:reply( utf.format( msg_stillblocked, target_firstnick, by, reason ), hub.getbot() )
            return PROCESSED
        else
            if ( permission[ user:level() ] or 0 ) < target_level then
                user:reply( msg_god, hub.getbot() )
                return PROCESSED
            else
                block_tbl[ target_firstnick ] = {}
                block_tbl[ target_firstnick ][ 1 ] = user:nick()
                block_tbl[ target_firstnick ][ 2 ] = p3
                util.savetable( block_tbl, "block_tbl", block_file )
                local msg_user = utf.format( msg_block, target_nick, p3 )
                user:reply( msg_user, hub.getbot() )
                local msg_target = utf.format( msg_target_block, user:nick(), p3 )
                target:reply( msg_target, hub.getbot(), hub.getbot() )
                local msg_report = utf.format( msg_op_report_block, user:nick(), target_nick, p3 )
                report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
                --// add description flag
                for sid, buser in pairs( hub.getusers() ) do
                    if buser:firstnick() == target_firstnick then
                        local new_desc = format_description( flag_blocked, "onStart", buser, nil )
                        buser:inf():setnp( "DE", new_desc )
                        hub.sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
                    end
                end
                return PROCESSED
            end
        end
    end
    --// [+!#]trafficmanager unblock <NICK>
    if ( ( p1 == cmd_u ) and p2 ) then
        if user:level() < masterlevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        local target = hub.isnickonline( p2 )
        if target then
            target_firstnick = target:firstnick()
            target_sid = target:sid()
        else
            user:reply( msg_notonline, hub.getbot() )
            return PROCESSED
        end
        if ( permission[ user:level() ] or 0 ) < target:level( ) then
            user:reply( msg_god, hub.getbot() )
            return PROCESSED
        end
        if is_autoblocked( target ) then
            user:reply( msg_autoblock, hub.getbot() )
            return PROCESSED
        end
        local found = false
        if type( block_tbl[ target:firstnick() ] ) ~= "nil" then
            --// remove description flag
            local new_desc
            if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
                local prefix = hub.escapeto( flag_blocked )
                local desc_tag = hub.escapeto( desc_prefix_table[ target:level() ] )
                local desc = utf.sub( target:description(), utf.len( desc_tag ) + 1, -1 )
                local desc = utf.sub( desc, utf.len( prefix ) + 1, -1 )
                new_desc = desc_tag .. desc
            else
                local prefix = hub.escapeto( flag_blocked )
                local desc = target:description() or ""
                new_desc = utf.sub( desc, utf.len( prefix ) + 1, -1 )
            end
            target:inf():setnp( "DE", new_desc or "" )
            hub.sendtoall( "BINF " .. target_sid .. " DE" .. new_desc .. "\n" )
            --// remove database entry
            block_tbl[ target:firstnick() ] = nil
            found = true
        end
        if found then
            util.savetable( block_tbl, "block_tbl", block_file )
            local msg_user = utf.format( msg_unblock, target_firstnick )
            user:reply( msg_user, hub.getbot() )
            local msg_target = utf.format( msg_target_unblock, user:nick() )
            target:reply( msg_target, hub.getbot(), hub.getbot() )
            local msg_report = utf.format( msg_op_report_unblock, user:nick(), target_firstnick )
            report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
            return PROCESSED
        else
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

--// check if user needs to be blocked
local need_block = function( user )
    if user then
        if blocklevel_tbl[ user:level() ] or check_share( user ) or type( block_tbl[ user:firstnick() ] ) ~= "nil" then return true end
    end
    return false
end

--// block CTM
hub.setlistener( "onConnectToMe", {},
    function( user, target, adccmd )
        if user:level() < masterlevel then
            if need_block( user ) then
                --user:reply( "Traffic Manager: [CTM] Your download/upload function is disabled.", hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [CTM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [CTM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub.getbot() ) -- debug
                return PROCESSED
            end
            if need_block( target ) then
                --user:reply( "Traffic Manager: [CTM] The download/upload function of the user you tried to connect is disabled.", hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [CTM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [CTM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub.getbot() ) -- debug
                return PROCESSED
            end
            return nil
        end
        return nil
    end
)

--// block RCM
hub.setlistener( "onRevConnectToMe", {},
    function( user, target, adccmd )
        if user:level() < masterlevel then
            if need_block( user ) then
                --user:reply( "Traffic Manager: [RCM] Your download/upload function is disabled.", hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [RCM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [RCM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub.getbot() ) -- debug
                return PROCESSED
            end
            if need_block( target ) then
                --user:reply( "Traffic Manager: [RCM] The download/upload function of the user you tried to connect is disabled.", hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [RCM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub.getbot() )  -- debug
                --user:reply( "Traffic Manager: [RCM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub.getbot() ) -- debug
                return PROCESSED
            end
            return nil
        end
        return nil
    end
)

--// block SCH
hub.setlistener( "onSearch", {},
    function( user, adccmd )
        if need_block( user ) then
            user:reply( msg_onsearch, hub.getbot() )
            --user:reply( "Traffic Manager: [SCH] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub.getbot() ) -- debug
            return PROCESSED
        end
        return nil
    end
)

--// script start
hub.setlistener( "onStart", {},
    function()
        --// help, ucmd, hucmd
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, oplevel )
            help.reg( help_title2, help_usage2, help_desc2, masterlevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { cmd_s, "settings" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_ct1_2, cmd, { cmd_s, "blocks" }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_ct2_1, cmd, { cmd_b, "%[userNI]", "%[line:" .. ucmd_desc .. "]" }, { "CT2" }, masterlevel )
            ucmd.add( ucmd_menu_ct2_3, cmd, { cmd_u, "%[userNI]" }, { "CT2" }, masterlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        --// add description flag
        for sid, user in pairs( hub.getusers() ) do
            --if blocklevel_tbl[ user:level() ] or check_share( user ) or type( block_tbl[ user:firstnick() ] ) ~= "nil" then
            if need_block( user ) then
                local new_desc = format_description( flag_blocked, "onStart", user, nil )
                user:inf():setnp( "DE", new_desc )
                hub.sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
            end
        end
        return nil
    end
)

--// script exit
hub.setlistener( "onExit", {},
    function()
        --// remove description flag
        for sid, user in pairs( hub.getusers() ) do
            --if blocklevel_tbl[ user:level() ] or check_share( user ) or type( block_tbl[ user:firstnick() ] ) ~= "nil" then
            if need_block( user ) then
                local new_desc = format_description( flag_blocked, "onExit", user, nil )
                user:inf():setnp( "DE", new_desc or "" )
                hub.sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
            end
        end
        return nil
    end
)

--// incoming INF
hub.setlistener( "onInf", {},
    function( user, cmd )
        local desc = cmd:getnp "DE"
        if desc then
            --// add/update description flag
            --if blocklevel_tbl[ user:level() ] or check_share( user ) or type( block_tbl[ user:firstnick() ] ) ~= "nil" then
            if need_block( user ) then
                local new_desc = format_description( flag_blocked, "onInf", user, cmd )
                cmd:setnp( "DE", new_desc )
                user:inf():setnp( "DE", new_desc )
            end
        end
        return nil
    end
)

--// user connects to hub
hub.setlistener( "onConnect", {},
    function( user )
        --// add description flag
        --if blocklevel_tbl[ user:level() ] or check_share( user ) or type( block_tbl[ user:firstnick() ] ) ~= "nil" then
        if need_block( user ) then
            local new_desc = format_description( flag_blocked, "onConnect", user, nil )
            user:inf():setnp( "DE", new_desc )
        end
        return nil
    end
)

--// send user report on timer
hub.setlistener( "onTimer", { },
    function()
        if os.difftime( os.time() - start ) >= delay then
            send_user_report()
            start = os.time()
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )

--// public //--

return {    -- export

    add = add,  -- use: block = hub.import( "etc_trafficmanager"); block.add( target, script, reason )  -- to block a user
    del = del,  -- use: block = hub.import( "etc_trafficmanager"); block.del( target_firstnick )  -- to unblock a user; return false if target is not found

}
