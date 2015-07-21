--[[

    cmd_nickchange.lua by pulsar

        description: this script adds a command "nickchange" to change the nick of your own
        usage: [+!#]nickchange <new_nick>
        note: this script needs "nick_change = true" in "cfg/cfg.tbl"

        v1.0:
            - check if opchat is activated
            
        v0.9:
            - removed new method to save userdatabase
        
        v0.8:
            - improved method to save userdatabase
        
        v0.7:
            - added possibility to send report as feed to opchat
        
        v0.6:
            - additional ct1 rightclick
            - possibility to toggle advanced ct2 rightclick (shows complete userlist)
                - export var to "cfg/cfg.tbl"
        
        v0.5:
            - add missing level check to cmd_param_3
            - changes in isTacken() function
        
        v0.4:
            - fix nick taken bug
            - rewriting some code

        v0.3:
            - fix permission bug in cmd_param_1

        v0.2:
            - new check if new nick is already taken
            - possibility to change nick from other users (e.g. for OP)
            - caching new table lookups

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_nickchange"
local scriptversion = "1.0"

local cmd = "nickchange"
local cmd_param_1 = "mynick"
local cmd_param_2 = "othernick"
local cmd_param_3 = "othernicku"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_match = utf.match
local utf_format = utf.format
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers
local hub_reloadusers = hub.reloadusers
local hub_escapeto = hub.escapeto
local hub_import = hub.import
local hub_debug = hub.debug
local hub_isnickonline = hub.isnickonline
local util_loadtable = util.loadtable
local util_savearray = util.savearray
local table_insert = table.insert
local table_sort = table.sort
local string_len = string.len

--// imports
local nick_change = cfg_get( "nick_change" )
local minlevel = cfg_get( "cmd_nickchange_minlevel" )
local oplevel = cfg_get( "cmd_nickchange_oplevel" )
local report = cfg_get( "cmd_nickchange_report" )
local maxnicklength = cfg_get( "cmd_nickchange_maxnicklength" )
local activate = cfg_get( "usr_nick_prefix_activate" )
local prefix_table = cfg_get( "usr_nick_prefix_prefix_table" )
local advanced_rc = cfg_get( "cmd_nickchange_advanced_rc" )
local scriptlang = cfg_get( "language" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local report_hubbot = cfg_get( "cmd_nickchange_report_hubbot" )
local report_opchat = cfg_get( "cmd_nickchange_report_opchat" )

--// user database
local user_db = "cfg/user.tbl"

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local help_title = lang.help_title or "nickchange"
local help_usage = lang.help_usage or "[+!#]nickchange mynick <new_nick>  /  [+!#]nickchange othernick <old_nick> <new_nick>"
local help_desc = lang.help_desc or "change the nickname"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_denied2 = lang.msg_denied2 or "You are not allowed to change the nick of this user."
local msg_nochange = lang.msg_nochange or "There are no changes needed."
local msg_nicktaken = lang.msg_nicktaken or "Nick is already taken!"
local msg_ok = lang.msg_ok or "Nickname was changed to: "
local msg_disconnect = lang.msg_disconnect or "Nickchange successful, please reconnect with your new nick."
local msg_usage = lang.msg_usage or "Usage: [+!#]nickchange <new_nick>"
local msg_length = lang.msg_length or "Nickname is too long, maximum length is: "
local msg_op = lang.msg_op or "User %s changed his own nickname to: %s"
local msg_op2 = lang.msg_op2 or "User %s changed nickname from user: %s  to: %s"

local ucmd_menu_ct1_0 = lang.ucmd_menu_ct1_0 or { "User", "Control", "Change", "Nickname", "by Nick" }
local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "About You", "change nickname" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or "User"
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or "Control"
local ucmd_menu_ct1_4 = lang.ucmd_menu_ct1_4 or "Change"
local ucmd_menu_ct1_5 = lang.ucmd_menu_ct1_5 or "Nickname"
local ucmd_menu_ct1_6 = lang.ucmd_menu_ct1_6 or "by Nick from list"
local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Change", "nickname" }
local ucmd_popup = lang.ucmd_popup or "New nickname:"
local ucmd_popup2 = lang.ucmd_popup2 or "Nickname"

--// functions and imports
local onbmsg, help, ucmd, hubcmd


----------
--[CODE]--
----------

local send_report = function( msg, minlevel )
    if report then
        if report_hubbot then
            for sid, user in pairs( hub_getusers() ) do
                local user_level = user:level()
                if user_level >= minlevel then
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

--// check if nick is taken
local isTacken = function( oldnick, newnick )
    local regusers, reggednicks, reggedcids = hub_getregusers()
    for i, user in ipairs( regusers ) do
        if user.nick ~= oldnick then
            if user.nick == newnick then
                return true
            end
        end
    end
    return false
end

onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local user_nick = user:nick()
    local user_firstnick = user:firstnick()

    if not user:isregged() then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end

    local user_tbl = util_loadtable( user_db )
    local param_1, newnick = utf_match( parameters, "^(%S+)%s(%S+)$" )
    local param_2, oldnickfrom, newnickfrom = utf_match( parameters, "^(%S+)%s(%S+)%s(%S+)$" )

    if ( param_1 == cmd_param_1 ) and newnick then
        if not nick_change then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        if string_len( newnick ) > maxnicklength then
            user:reply( msg_length .. maxnicklength, hub_getbot )
            return PROCESSED
        end
        if user_firstnick == newnick then
            user:reply( msg_nochange, hub_getbot )
            return PROCESSED
        end
        if isTacken( user_firstnick, newnick ) then
            user:reply( msg_nicktaken, hub_getbot )
            return PROCESSED
        else
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == user_firstnick then
                    user_tbl[ k ].nick = newnick
                    user:reply( msg_ok .. newnick, hub_getbot )
                    user:kill( "ISTA 230 " .. hub_escapeto( msg_disconnect ) .. "\n" )
                    util_savearray( user_tbl, user_db )
                    --cfg.saveusers( hub.getregusers() )
                    hub_reloadusers()
                    local msg = utf_format( msg_op, user_firstnick, newnick )
                    send_report( msg, oplevel )
                    return PROCESSED
                end
            end
        end
    elseif ( param_2 == cmd_param_2 ) and newnickfrom then
        if user_level < oplevel then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        if oldnickfrom == newnickfrom then
            user:reply( msg_nochange, hub_getbot )
            return PROCESSED
        end
        if string_len( newnickfrom ) > maxnicklength then
            user:reply( msg_length .. maxnicklength, hub_getbot )
            return PROCESSED
        end
        if isTacken( oldnickfrom, newnickfrom ) then
            user:reply( msg_nicktaken, hub_getbot )
            return PROCESSED
        else
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == oldnickfrom then
                    local prefix, target_user
                    local target_level = user_tbl[ k ].level
                    if user_level < target_level then
                        user:reply( msg_denied2, hub_getbot )
                        return PROCESSED
                    end
                    if activate then
                        prefix = hub_escapeto( prefix_table[ target_level ] )
                        target_user = hub_isnickonline( prefix .. oldnickfrom )
                    else
                        target_user = hub_isnickonline( oldnickfrom )
                    end
                    user_tbl[ k ].nick = newnickfrom
                    user:reply( msg_ok .. newnickfrom, hub_getbot )
                    if target_user then
                        target_user:reply( msg_ok .. newnickfrom, hub_getbot, hub_getbot )
                        target_user:kill( "ISTA 230 " .. hub_escapeto( msg_disconnect ) .. "\n" )
                    end
                    util_savearray( user_tbl, user_db )
                    --cfg.saveusers( hub.getregusers() )
                    hub_reloadusers()
                    local msg = utf_format( msg_op2, user_firstnick, oldnickfrom, newnickfrom )
                    send_report( msg, oplevel )
                    return PROCESSED
                end
            end
        end
    elseif ( param_2 == cmd_param_3 ) and newnickfrom then
        local target_level, target_nick, target_firstnick
        if user_level < oplevel then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        for sid, users in pairs( hub_getusers() ) do
            if users:nick() == oldnickfrom then
                target_level = users:level()
                target_nick = users:nick()
                target_firstnick = users:firstnick()
            end
        end
        if target_firstnick == newnickfrom then
            user:reply( msg_nochange, hub_getbot )
            return PROCESSED
        end
        if string_len( newnickfrom ) > maxnicklength then
            user:reply( msg_length .. maxnicklength, hub_getbot )
            return PROCESSED
        end
        if isTacken( target_firstnick, newnickfrom ) then
            user:reply( msg_nicktaken, hub_getbot )
            return PROCESSED
        else
            if user_level < target_level then
                user:reply( msg_denied2, hub_getbot )
                return PROCESSED
            end
            local target = hub_isnickonline( target_nick )
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == target_firstnick then
                    user_tbl[ k ].nick = newnickfrom
                    user:reply( msg_ok .. newnickfrom, hub_getbot )
                    target:reply( msg_ok .. newnickfrom, hub_getbot, hub_getbot )
                    target:kill( "ISTA 230 " .. hub_escapeto( msg_disconnect ) .. "\n" )
                    util_savearray( user_tbl, user_db )
                    --cfg.saveusers( hub.getregusers() )
                    hub_reloadusers()
                    local msg = utf_format( msg_op2, user_firstnick, target_firstnick, newnickfrom )
                    send_report( msg, oplevel )
                    return PROCESSED
                end
            end
        end
    else
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { cmd_param_1, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_0, cmd, { cmd_param_2, "%[line:" .. ucmd_popup2 .. "]", "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, oplevel )
            if advanced_rc then
                local regusers, reggednicks, reggedcids = hub_getregusers()
                local usertbl = {}
                for i, user in ipairs( regusers ) do
                    if ( user.is_bot ~=1 ) and user.nick then
                      table_insert( usertbl, user.nick )
                    end
                end
                table_sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct1_2, ucmd_menu_ct1_3, ucmd_menu_ct1_4, ucmd_menu_ct1_5, ucmd_menu_ct1_6, nick }, cmd, { cmd_param_2, nick, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, oplevel )
                end
            end
            ucmd.add( ucmd_menu_ct2_1, cmd, { cmd_param_3, "%[userNI]", "%[line:" .. ucmd_popup .. "]" }, { "CT2" }, oplevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )