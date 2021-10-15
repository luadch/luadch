--[[

    cmd_nickchange.lua by pulsar

        description: this script adds a command "nickchange" to change the nick of your own

        usage: [+!#]nickchange <new_nick>

        note: this script needs "nick_change = true" in "cfg/cfg.tbl"

        v1.6:
            - added "hub.updateusers()"
                - fix #140 -> https://github.com/luadch/luadch/issues/140
            - changed visuals
            - removed table lookups

        v1.5:
            - fix #128
                - detect unknown nicks

        v1.4: by pulsar
            - removed "hub.reloadusers()"
            - using "hub.getregusers()" instead of "util.loadtable()"

        v1.3:
            - added min_length/max_length restrictions

        v1.2:
            - imroved user:kill()

        v1.1:
            - removed send_report() function, using report import functionality now
            - added description_check() function to change nick in the "cmd_reg_descriptions.tbl" too  / thx Sopor

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
            - changes in isTaken() function

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
local scriptversion = "1.6"

local cmd = "nickchange"
local cmd_param_1 = "mynick"
local cmd_param_2 = "othernick"
local cmd_param_3 = "othernicku"

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local nick_change = cfg.get( "nick_change" )
local min_length = cfg.get( "min_nickname_length" )
local max_length = cfg.get( "max_nickname_length" )
local minlevel = cfg.get( "cmd_nickchange_minlevel" )
local oplevel = cfg.get( "cmd_nickchange_oplevel" )
local activate = cfg.get( "usr_nick_prefix_activate" )
local prefix_table = cfg.get( "usr_nick_prefix_prefix_table" )
local advanced_rc = cfg.get( "cmd_nickchange_advanced_rc" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "cmd_nickchange_report" )
local report_hubbot = cfg.get( "cmd_nickchange_report_hubbot" )
local report_opchat = cfg.get( "cmd_nickchange_report_opchat" )

--// database
local user_db = "cfg/user.tbl"
local user_tbl = hub.getregusers()
local description_file = "scripts/data/cmd_reg_descriptions.tbl"

--// msgs
local help_title = lang.help_title or "nickchange"
local help_usage = lang.help_usage or "[+!#]nickchange mynick <new_nick>  /  [+!#]nickchange othernick <old_nick> <new_nick>"
local help_desc = lang.help_desc or "change the nickname"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_denied2 = lang.msg_denied2 or "You are not allowed to change the nick of this user."
local msg_nochange = lang.msg_nochange or "[ NICKCHANGE ]--> There are no changes needed."
local msg_nicktaken = lang.msg_nicktaken or "[ NICKCHANGE ]--> Nick is already taken!"
local msg_ok = lang.msg_ok or "[ NICKCHANGE ]--> Nickname was changed to: "
local msg_disconnect = lang.msg_disconnect or "[ NICKCHANGE ]--> Nickchange successful, please reconnect with your new nick."
local msg_usage = lang.msg_usage or "Usage: [+!#]nickchange mynick <NEW_NICK>  /  [+!#]nickchange othernick <OLD_NICK> <NEW_NICK>"
local msg_length = lang.msg_length or "[ NICKCHANGE ]--> Nickname restrictions min/max: %s/%s"
local msg_op = lang.msg_op or "[ NICKCHANGE ]--> User %s changed his own nickname to: %s"
local msg_op2 = lang.msg_op2 or "[ NICKCHANGE ]--> User %s changed nickname from user: %s  to: %s"
local msg_notfound = lang.msg_notfound or "[ NICKCHANGE ]--> Nick not found."

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

--// functions
local onbmsg, isTaken, isRegged, description_check


----------
--[CODE]--
----------

description_check = function( new_nick, old_nick )
    local tbl = util.loadtable( description_file )
    for k, v in pairs( tbl ) do
        if k == old_nick then
            local v1 = v[ "tBy" ]
            local v2 = v[ "tReason" ]
            tbl[ new_nick ] = {}
            tbl[ new_nick ][ "tBy" ] = v1
            tbl[ new_nick ][ "tReason" ] = v2
            tbl[ old_nick ] = nil
        end
    end
    util.savetable( tbl, "description_tbl", description_file )
end

--// check if new nick is taken
isTaken = function( oldnick, newnick )
    for i, user in ipairs( user_tbl ) do
        if user.nick ~= oldnick then
            if user.nick == newnick then
                return true
            end
        end
    end
    return false
end

--// check if nick is regged
isRegged = function( nick )
    for i, user in ipairs( user_tbl ) do
        if user.nick == nick then
            return true
        end
    end
    return false
end

onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local user_nick = user:nick()
    local user_firstnick = user:firstnick()
    if not user:isregged() then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local param_1, newnick = utf.match( parameters, "^(%S+)%s(%S+)$" )
    local param_2, oldnickfrom, newnickfrom = utf.match( parameters, "^(%S+)%s(%S+)%s(%S+)$" )

    if ( param_1 == cmd_param_1 ) and newnick then
        if not nick_change then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        if string.len( newnick ) > max_length or string.len( newnick ) < min_length then
            user:reply( utf.format( msg_length, min_length, max_length ), hub.getbot() )
            return PROCESSED
        end
        if user_firstnick == newnick then
            user:reply( msg_nochange, hub.getbot() )
            return PROCESSED
        end
        if isTaken( user_firstnick, newnick ) then
            user:reply( msg_nicktaken, hub.getbot() )
            return PROCESSED
        else
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == user_firstnick then
                    user_tbl[ k ].nick = newnick
                    user:reply( msg_ok .. newnick, hub.getbot() )
                    user:kill( "ISTA 230 " .. hub.escapeto( msg_disconnect ) .. "\n", "TL300" )
                    util.savearray( user_tbl, user_db )
                    hub.updateusers()
                    description_check( newnick, user_firstnick )
                    local msg = utf.format( msg_op, user_firstnick, newnick )
                    report.send( report_activate, report_hubbot, report_opchat, oplevel, msg )
                    return PROCESSED
                end
            end
        end
    elseif ( param_2 == cmd_param_2 ) and newnickfrom then
        if user_level < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        if oldnickfrom == newnickfrom then
            user:reply( msg_nochange, hub.getbot() )
            return PROCESSED
        end
        if string.len( newnickfrom ) > max_length or string.len( newnickfrom ) < min_length then
            user:reply( utf.format( msg_length, min_length, max_length ), hub.getbot() )
            return PROCESSED
        end
        if not isRegged( oldnickfrom ) then
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
        if isTaken( oldnickfrom, newnickfrom ) then
            user:reply( msg_nicktaken, hub.getbot() )
            return PROCESSED
        else
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == oldnickfrom then
                    local prefix, target_user
                    local target_level = user_tbl[ k ].level
                    if user_level < target_level then
                        user:reply( msg_denied2, hub.getbot() )
                        return PROCESSED
                    end
                    if activate then
                        prefix = hub.escapeto( prefix_table[ target_level ] )
                        target_user = hub.isnickonline( prefix .. oldnickfrom )
                    else
                        target_user = hub.isnickonline( oldnickfrom )
                    end
                    user_tbl[ k ].nick = newnickfrom
                    user:reply( msg_ok .. newnickfrom, hub.getbot() )
                    if target_user then
                        target_user:reply( msg_ok .. newnickfrom, hub.getbot(), hub.getbot() )
                        target_user:kill( "ISTA 230 " .. hub.escapeto( msg_disconnect ) .. "\n", "TL300" )
                    end
                    util.savearray( user_tbl, user_db )
                    hub.updateusers()
                    description_check( newnickfrom, oldnickfrom )
                    local msg = utf.format( msg_op2, user_firstnick, oldnickfrom, newnickfrom )
                    report.send( report_activate, report_hubbot, report_opchat, oplevel, msg )
                    return PROCESSED
                end
            end
        end
    elseif ( param_2 == cmd_param_3 ) and newnickfrom then
        local target_level, target_nick, target_firstnick
        if user_level < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        for sid, users in pairs( hub.getusers() ) do
            if users:nick() == oldnickfrom then
                target_level = users:level()
                target_nick = users:nick()
                target_firstnick = users:firstnick()
            end
        end
        if target_firstnick == newnickfrom then
            user:reply( msg_nochange, hub.getbot() )
            return PROCESSED
        end
        if string.len( newnickfrom ) > max_length or string.len( newnickfrom ) < min_length then
            user:reply( utf.format( msg_length, min_length, max_length ), hub.getbot() )
            return PROCESSED
        end
        if isTaken( target_firstnick, newnickfrom ) then
            user:reply( msg_nicktaken, hub.getbot() )
            return PROCESSED
        else
            if user_level < target_level then
                user:reply( msg_denied2, hub.getbot() )
                return PROCESSED
            end
            local target = hub.isnickonline( target_nick )
            for k, v in pairs( user_tbl ) do
                if user_tbl[ k ].nick == target_firstnick then
                    user_tbl[ k ].nick = newnickfrom
                    user:reply( msg_ok .. newnickfrom, hub.getbot() )
                    target:reply( msg_ok .. newnickfrom, hub.getbot(), hub.getbot() )
                    target:kill( "ISTA 230 " .. hub.escapeto( msg_disconnect ) .. "\n", "TL300" )
                    util.savearray( user_tbl, user_db )
                    hub.updateusers()
                    description_check( newnickfrom, target_firstnick )
                    local msg = utf.format( msg_op2, user_firstnick, target_firstnick, newnickfrom )
                    report.send( report_activate, report_hubbot, report_opchat, oplevel, msg )
                    return PROCESSED
                end
            end
        end
    else
        user:reply( msg_usage, hub.getbot() )
        return PROCESSED
    end
end

hub.setlistener( "onStart", {},
    function()
        help = hub.import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { cmd_param_1, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_0, cmd, { cmd_param_2, "%[line:" .. ucmd_popup2 .. "]", "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, oplevel )
            if advanced_rc then
                local user_tbl = hub.getregusers()
                local usertbl = {}
                for i, user in ipairs( user_tbl ) do
                    if ( user.is_bot ~=1 ) and user.nick then
                      table.insert( usertbl, user.nick )
                    end
                end
                table.sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct1_2, ucmd_menu_ct1_3, ucmd_menu_ct1_4, ucmd_menu_ct1_5, ucmd_menu_ct1_6, nick }, cmd, { cmd_param_2, nick, "%[line:" .. ucmd_popup .. "]" }, { "CT1" }, oplevel )
                end
            end
            ucmd.add( ucmd_menu_ct2_1, cmd, { cmd_param_3, "%[userNI]", "%[line:" .. ucmd_popup .. "]" }, { "CT2" }, oplevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )