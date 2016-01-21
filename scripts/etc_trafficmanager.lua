--[[

    etc_trafficmanager.lua by pulsar

        based on my etc_transferblocker.lua

        usage:

        [+!#]trafficmanager block <NICK>  -- blocks downloads (d), uploads (u) and search (s)
        [+!#]trafficmanager unblock <NICK>  -- unblock user
        [+!#]trafficmanager show settings  -- shows current settings from "cfg/cfg.tbl"
        [+!#]trafficmanager show blocks  -- shows all blockes users and her blockmodes

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
local scriptversion = "1.0"

local cmd = "trafficmanager"
local cmd_b = "block"
local cmd_u = "unblock"
local cmd_s = "show"

local block_file = "scripts/data/etc_trafficmanager.tbl"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getbot = hub.getbot()
local hub_isnickonline = hub.isnickonline
local hub_getusers = hub.getusers
local hub_escapeto = hub.escapeto
local hub_sendtoall = hub.sendtoall
local utf_format = utf.format
local utf_match = utf.match
local utf_len = utf.len
local utf_sub = utf.sub
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_getlowestlevel = util.getlowestlevel
local os_time = os.time
local os_difftime = os.difftime

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local activate = cfg_get( "etc_trafficmanager_activate" )
local permission = cfg_get( "etc_trafficmanager_permission" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "etc_trafficmanager_report" )
local report_hubbot = cfg_get( "etc_trafficmanager_report_hubbot" )
local report_opchat = cfg_get( "etc_trafficmanager_report_opchat" )
local llevel = cfg_get( "etc_trafficmanager_llevel" )
local blocklevel_tbl = cfg_get( "etc_trafficmanager_blocklevel_tbl" )
local sharecheck = cfg_get( "etc_trafficmanager_sharecheck" )
local oplevel = cfg_get( "etc_trafficmanager_oplevel" )
local login_report = cfg_get( "etc_trafficmanager_login_report" )
local report_main = cfg_get( "etc_trafficmanager_report_main" )
local report_pm = cfg_get( "etc_trafficmanager_report_pm" )
local desc_prefix_activate = cfg_get( "usr_desc_prefix_activate" )
local desc_prefix_permission = cfg_get( "usr_desc_prefix_permission" )
local desc_prefix_table = cfg_get( "usr_desc_prefix_prefix_table" )
local send_loop = cfg_get( "etc_trafficmanager_send_loop" )
local loop_time = cfg_get( "etc_trafficmanager_loop_time" )
local block_tbl = util_loadtable( block_file )

--// flags
local flag_blocked = "[BLOCKED] "

--// msgs
local help_title = lang.help_title or "etc_trafficmanager.lua - Operators"
local help_usage = lang.help_usage or "[+!#]trafficmanager show settings|blocks"
local help_desc = lang.help_desc or "Shows current settings from 'cfg/cfg.tbl' | Shows all blockes users and their blockmodes"

local help_title2 = lang.help_title2 or "etc_trafficmanager.lua - Owners"
local help_usage2 = lang.help_usage2 or "[+!#]trafficmanager block|unblock <NICK>"
local help_desc2 = lang.help_desc2 or "Blocks downloads ( d ), uploads ( u ) and search ( s ) | Unblock user"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_god = lang.msg_god or "You are not allowed to block this user."
local msg_notonline = lang.msg_notonline or "Traffic Manager: User is offline."
local msg_notfound = lang.msg_notfound or "Traffic Manager: User isn't blocked."
local msg_stillblocked = lang.msg_stillblocked or "Traffic Manager: The level of this user is already auto-blocked."
local msg_isbot = lang.msg_isbot or "Traffic Manager: User is a bot."
local msg_block = lang.msg_block or "Traffic Manager: Block user: %s"
local msg_unblock = lang.msg_unblock or "Traffic Manager: Unblock user: %s"
local msg_op_report_block = lang.msg_op_report_block or "Traffic Manager:  %s  has blocked user: %s"
local msg_op_report_unblock = lang.msg_op_report_unblock or "Traffic Manager:  %s  has unblocked user: %s"
local msg_autoblock = lang.msg_autoblock or "Traffic Manager: This user was autoblocked by script permissions."
local msg_onsearch = lang.msg_onsearch or "Traffic Manager: Your search function is disabled."

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "Hub", "etc", "Traffic Manager", "show", "Settings" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "Hub", "etc", "Traffic Manager", "show", "Blocked users" }
local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Traffic Manager", "block" }
local ucmd_menu_ct2_3 = lang.ucmd_menu_ct2_3 or { "Traffic Manager", "unblock" }

local report_msg = lang.report_msg or [[


=== TRAFFIC MANAGER =====================================

     Hello %s, your level in this hub:  %s [ %s ]

     Downloads, Uploads and Searches are blocked.

===================================== TRAFFIC MANAGER ===
  ]]

local report_msg_2 = lang.report_msg_2 or [[


=== TRAFFIC MANAGER =====================================

     Hello %s, your share: 0  B

     Downloads, Uploads and Searches are blocked.

===================================== TRAFFIC MANAGER ===
  ]]

local report_msg_3 = lang.report_msg_3 or [[


=== TRAFFIC MANAGER =====================================

     Hello %s, your nick is on the blocklist:

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

 [+!#]trafficmanager block <NICK>  -- blocks downloads ( d ), uploads ( u ) and search ( s )
 [+!#]trafficmanager unblock <NICK>  -- unblock user
 [+!#]trafficmanager show settings  -- shows current settings from "cfg/cfg.tbl"
 [+!#]trafficmanager show blocks  -- shows all blockes users and her blockmodes

=========================================================== TRAFFIC MANAGER ===
  ]]

local msg_users = lang.msg_users or [[


=== TRAFFIC MANAGER ================================

%s
================================ TRAFFIC MANAGER ===
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


----------
--[CODE]--
----------

local delay = loop_time * 60 * 60
local start = os_time()

local masterlevel = util_getlowestlevel( permission )

--// get all levelnames from blocked table in sorted order
get_blocklevels = function()
    local levels = cfg_get( "levels" ) or {}
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
            if user_share == 0 then
                result = true
            end
        end
    end
    return result
end

--// check if target user is still autoblocked
is_autoblocked = function( target )
    if target then
        local target_firstnick = target:firstnick()
        local target_level = target:level()
        for sid, user in pairs( hub_getusers() ) do
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
        for sid, user in pairs( hub_getusers() ) do
            if blocklevel_tbl[ target_level ] or check_share( target ) or block_tbl[ target_firstnick ] then
                return true
            end
        end
    end
    return false
end

--// user report msg on timer
send_user_report = function()
    if send_loop then
        for sid, user in pairs( hub_getusers() ) do
            local user_level = user:level()
            local user_firstnick = user:firstnick()
            local msg
            if blocklevel_tbl[ user_level ] then
                local levelname = cfg_get( "levels" )[ user_level ] or "Unreg"
                msg = utf_format( report_msg, user_firstnick, user_level, levelname )
                if report_main then user:reply( msg, hub_getbot ) end
                if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
            elseif check_share( user ) then
                msg = utf_format( report_msg_2, user_firstnick )
                if report_main then user:reply( msg, hub_getbot ) end
                if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
            elseif block_tbl[ user_firstnick ] then
                msg = utf_format( report_msg_3, user_firstnick )
                if report_main then user:reply( msg, hub_getbot ) end
                if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
            end
        end
    end
end

--// add/remove description flag
format_description = function( flag, listener, target, cmd )
    local desc, new_desc = "", ""
    if listener == "onStart" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub_escapeto( desc_prefix_table[ target:level() ] )
            local desc = target:description() or ""
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub_escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub_escapeto( flag )
            local desc = target:description() or ""
            new_desc = prefix .. desc
        end
    end
    if listener == "onExit" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local prefix = hub_escapeto( flag )
            local desc = target:description() or ""
            new_desc = utf_sub( desc, utf_len( prefix ) + 1, -1 )
        else
            local prefix = hub_escapeto( flag )
            local desc = target:description() or ""
            new_desc = utf_sub( desc, utf_len( prefix ) + 1, -1 )
        end
    end
    if listener == "onInf" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub_escapeto( desc_prefix_table[ target:level() ] )
            local desc = cmd:getnp "DE"
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub_escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub_escapeto( flag )
            local desc = cmd:getnp "DE"
            new_desc = prefix .. desc
        end
    end
    if listener == "onConnect" then
        if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
            local desc_tag = hub_escapeto( desc_prefix_table[ target:level() ] )
            local desc = target:description() or ""
            local desc_part1 = desc:sub( 1, #desc_tag )
            local desc_part2 = desc:sub( #desc_tag + 1, #desc )
            local prefix = hub_escapeto( flag )
            new_desc = desc_part1 .. prefix .. desc_part2
        else
            local prefix = hub_escapeto( flag )
            local desc = target:description() or ""
            new_desc = prefix .. desc
        end
    end
    return new_desc
end

if activate then
    --// if user logs in
    hub.setlistener( "onLogin", {},
        function( user )
            local user_level = user:level()
            local user_firstnick = user:firstnick()
            local msg
            if user_level < masterlevel then
                if blocklevel_tbl[ user_level ] then
                    if login_report then
                        local levelname = cfg_get( "levels" )[ user_level ] or "Unreg"
                        msg = utf_format( report_msg, user_firstnick, user_level, levelname )
                        if report_main then user:reply( msg, hub_getbot ) end
                        if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
                    end
                elseif check_share( user ) then
                    if login_report then
                        msg = utf_format( report_msg_2, user_firstnick )
                        if report_main then user:reply( msg, hub_getbot ) end
                        if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
                    end
                elseif block_tbl[ user_firstnick ] then
                    if login_report then
                        msg = utf_format( report_msg_3, user_firstnick )
                        if report_main then user:reply( msg, hub_getbot ) end
                        if report_pm then user:reply( msg, hub_getbot, hub_getbot ) end
                    end
                end
            end
            return nil
        end
    )
    --// hubcmd
    onbmsg = function( user, command, parameters )
        local user_nick = user:nick()
        local user_level = user:level()
        local target_firstnick, target_level, target_sid
        local p1, p2 = utf_match( parameters, "^(%S+) (%S+)" )
        --// [+!#]trafficmanager show settings
        if ( ( p1 == cmd_s ) and ( p2 == "settings" ) ) then
            if user_level < oplevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            local msg = utf_format( opmsg,
                                    get_bool( activate ),
                                    get_bool( login_report ),
                                    get_bool( send_loop ),
                                    get_bool( report_main ),
                                    get_bool( report_pm ),
                                    get_blocklevels(),
                                    get_bool( sharecheck )
            )
            user:reply( msg, hub_getbot )
            return PROCESSED
        end
        --// [+!#]trafficmanager show blocks
        if ( ( p1 == cmd_s ) and ( p2 == "blocks" ) ) then
            if user_level < oplevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            local msg = ""
            for k, v in pairs( block_tbl ) do
                msg = msg .. "\t" .. k .. "\n"
            end
            local msg_out = utf_format( msg_users, msg )
            user:reply( msg_out, hub_getbot )
            return PROCESSED
        end
        --// [+!#]trafficmanager block <NICK>
        if ( ( p1 == cmd_b ) and p2 ) then
            local target = hub_isnickonline( p2 )
            if target then
                if target:isbot() then
                    user:reply( msg_isbot, hub_getbot )
                    return PROCESSED
                else
                    target_firstnick = target:firstnick()
                    target_level = target:level()
                end
            else
                user:reply( msg_notonline, hub_getbot )
                return PROCESSED
            end
            if is_blocked( target ) then
                user:reply( msg_stillblocked, hub_getbot )
                return PROCESSED
            else
                if ( permission[ user_level ] or 0 ) < target_level or target_level >= masterlevel then
                    user:reply( msg_god, hub_getbot )
                    return PROCESSED
                else
                    block_tbl[ target_firstnick ] = true
                    util_savetable( block_tbl, "block_tbl", block_file )
                    local msg = utf_format( msg_block, target_firstnick )
                    user:reply( msg, hub_getbot )
                    local msg_report = utf_format( msg_op_report_block, user_nick, target_firstnick )
                    report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
                    --// add description flag
                    for sid, buser in pairs( hub_getusers() ) do
                        if buser:firstnick() == target_firstnick then
                            local new_desc = format_description( flag_blocked, "onStart", buser, nil )
                            buser:inf():setnp( "DE", new_desc )
                            hub_sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
                        end
                    end
                    return PROCESSED
                end
            end
        end
        --// [+!#]trafficmanager unblock <NICK>
        if ( ( p1 == cmd_u ) and p2 ) then
            if user_level < masterlevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            local target = hub_isnickonline( p2 )
            if target then
                target_firstnick = target:firstnick()
                target_sid = target:sid()
            else
                target_firstnick = p2
            end
            if target then
                if is_autoblocked( target ) then
                    user:reply( msg_autoblock, hub_getbot )
                    return PROCESSED
                end
            end
            local found = false
            if target and block_tbl[ target:firstnick() ] then
                --// remove description flag
                local new_desc
                if desc_prefix_activate and desc_prefix_permission[ target:level() ] then
                    local prefix = hub_escapeto( flag_blocked )
                    local desc_tag = hub_escapeto( desc_prefix_table[ target:level() ] )
                    local desc = utf_sub( target:description(), utf_len( desc_tag ) + 1, -1 )
                    local desc = utf_sub( desc, utf_len( prefix ) + 1, -1 )
                    new_desc = desc_tag .. desc
                else
                    local prefix = hub_escapeto( flag_blocked )
                    local desc = target:description() or ""
                    new_desc = utf_sub( desc, utf_len( prefix ) + 1, -1 )
                end
                target:inf():setnp( "DE", new_desc or "" )
                hub_sendtoall( "BINF " .. target_sid .. " DE" .. new_desc .. "\n" )
                block_tbl[ k ] = nil
                found = true
            end
            if found then
                util_savetable( block_tbl, "block_tbl", block_file )
                local msg = utf_format( msg_unblock, target_firstnick )
                user:reply( msg, hub_getbot )
                local msg_report = utf_format( msg_op_report_unblock, user_nick, target_firstnick )
                report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
                return PROCESSED
            else
                user:reply( msg_notfound, hub_getbot )
                return PROCESSED
            end
        end
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    --// check if user need to be blocked
    local need_block = function( user )
        if user then
            if blocklevel_tbl[ user:level() ] or check_share( user ) or block_tbl[ user:firstnick() ] then return true end
        end
        return false
    end
    --// block CTM
    hub.setlistener( "onConnectToMe", {},
        function( user, target, adccmd )
            if user:level() < masterlevel then
                if need_block( user ) then
                    --user:reply( "Traffic Manager: [CTM] Your download/upload function is disabled.", hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [CTM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [CTM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub_getbot ) -- debug
                    return PROCESSED
                end
                if need_block( target ) then
                    --user:reply( "Traffic Manager: [CTM] The download/upload function of the user you tried to connect is disabled.", hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [CTM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [CTM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub_getbot ) -- debug
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
                    --user:reply( "Traffic Manager: [RCM] Your download/upload function is disabled.", hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [RCM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [RCM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub_getbot ) -- debug
                    return PROCESSED
                end
                if need_block( target ) then
                    --user:reply( "Traffic Manager: [RCM] The download/upload function of the user you tried to connect is disabled.", hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [RCM] User: " .. user:firstnick() .. " | Target: " .. target:firstnick(), hub_getbot )  -- debug
                    --user:reply( "Traffic Manager: [RCM] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub_getbot ) -- debug
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
                user:reply( msg_onsearch, hub_getbot )
                --user:reply( "Traffic Manager: [SCH] adccmd:\n\n" .. table.concat( adccmd, ", " ) .. "\n", hub_getbot ) -- debug
                return PROCESSED
            end
            return nil
        end
    )
    --// script start
    hub.setlistener( "onStart", {},
        function()
            --// help, ucmd, hucmd
            local help = hub_import( "cmd_help" )
            if help then
                help.reg( help_title, help_usage, help_desc, oplevel )
                help.reg( help_title2, help_usage2, help_desc2, masterlevel )
            end
            local ucmd = hub_import( "etc_usercommands" )
            if ucmd then
                ucmd.add( ucmd_menu_ct1_1, cmd, { cmd_s, "settings" }, { "CT1" }, oplevel )
                ucmd.add( ucmd_menu_ct1_2, cmd, { cmd_s, "blocks" }, { "CT1" }, oplevel )
                ucmd.add( ucmd_menu_ct2_1, cmd, { cmd_b, "%[userNI]" }, { "CT2" }, masterlevel )
                ucmd.add( ucmd_menu_ct2_3, cmd, { cmd_u, "%[userNI]" }, { "CT2" }, masterlevel )
            end
            local hubcmd = hub_import( "etc_hubcommands" )
            assert( hubcmd )
            assert( hubcmd.add( cmd, onbmsg ) )
            --// add description flag
            for sid, user in pairs( hub_getusers() ) do
                if blocklevel_tbl[ user:level() ] or check_share( user ) or block_tbl[ user:firstnick() ] then
                    local new_desc = format_description( flag_blocked, "onStart", user, nil )
                    user:inf():setnp( "DE", new_desc )
                    hub_sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
                end
            end
            return nil
        end
    )
    --// script exit
    hub.setlistener( "onExit", {},
        function()
            --// remove description flag
            for sid, user in pairs( hub_getusers() ) do
                if blocklevel_tbl[ user:level() ] or check_share( user ) or block_tbl[ user:firstnick() ] then
                    local new_desc = format_description( flag_blocked, "onExit", user, nil )
                    user:inf():setnp( "DE", new_desc or "" )
                    hub_sendtoall( "BINF " .. sid .. " DE" .. new_desc .. "\n" )
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
                if blocklevel_tbl[ user:level() ] or check_share( user ) or block_tbl[ user:firstnick() ] then
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
            if blocklevel_tbl[ user:level() ] or check_share( user ) or block_tbl[ user:firstnick() ] then
                local new_desc = format_description( flag_blocked, "onConnect", user, nil )
                user:inf():setnp( "DE", new_desc )
            end
            return nil
        end
    )
    --// send user report on timer
    hub.setlistener( "onTimer", { },
        function()
            if os_difftime( os_time() - start ) >= delay then
                send_user_report()
                start = os_time()
            end
            return nil
        end
    )
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )