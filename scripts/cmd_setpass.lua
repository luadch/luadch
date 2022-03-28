--[[

    cmd_setpas.lua by blastbeat

        - this script adds a command "setpas" to set or change the password of your own or an user by nick
        - usage: [+!#]setpass nick <nick> <password>
        - [+!#]setpass myself <password> sets your own pasword

        v0.19: by pulsar
            - changed check order  / thx Sopor

        v0.18: by pulsar
            - fix #101 / thx Sopor
                - fix typo
                - removed table lookups
            - add permission check to change own password

        v0.17: by blastbeat
            - use hub.getregusers() to fix #25

        v0.16: by pulsar
            - renamed "cmd_setpass_min_length" to "min_password_length"
            - added "max_password_length"
            - renamed "msg_length" to "msg_min_length"
            - added "msg_max_length"

        v0.15: by pulsar
            - renamed "cmd_setpas_permission" to "cmd_setpass_permission"
            - renamed "cmd_setpas_advanced_rc" to "cmd_setpass_advanced_rc"
            - renamed "cmd_setpas_min_length" to "cmd_setpass_min_length"

        v0.14: by pulsar
            - changed command "setpas" to "setpass"  / requested by Sopor
            - add "cmd_setpas_min_length" to set min length of the password  / requested by Sopor

        v0.13: by pulsar
            - removed "cmd_setpas_oplevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_setpas_oplevel"

        v0.12: by pulsar
            - removed new method to save userdatabase

        v0.11: by pulsar
            - improved method to save userdatabase

        v0.10: by pulsar
            - fix bug with target user object
            - additional ct1 rightclick
            - possibility to toggle advanced ct2 rightclick (shows complete userlist)
                - export var to "cfg/cfg.tbl"

        v0.09: by pulsar
            - fix small bug with "undeclared var"

        v0.08: by pulsar
            - possibility to change the password of the users over the userlist rightklick (oplevel)
            - caching new table lookups

        v0.07: by pulsar
            - fix missing var "msg_usage"

        v0.06: by pulsar
            - the password of an offline user can change now too
            - rewriting code
            - added oplevel for advanced rightclick

        v0.05: by pulsar
            - changed rightclick style

        v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by pulsar
            - fixed bug: user can change her own password now

        v0.02: by blastbeat
            - updated script api
            - regged hubcommand

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_setpass"
local scriptversion = "0.19"

local cmd = "setpass"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// imports
local onbmsg, help, ucmd, hubcmd
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local permission = cfg.get( "cmd_setpass_permission" ) or { }
local permission_own_pw = cfg.get( "cmd_setpass_permission_own_pw" ) or { }
local activate = cfg.get( "usr_nick_prefix_activate" )
local prefix_table = cfg.get( "usr_nick_prefix_prefix_table" )
local advanced_rc = cfg.get( "cmd_setpass_advanced_rc" )
local min_length = cfg.get( "min_password_length" )
local max_length = cfg.get( "max_password_length" )

--// msgs
local help_title = lang.help_title or "setpas"
local help_usage = lang.help_usage or "[+!#]setpass nick <NICK> <PASS>  /  [+!#]setpass nick myself <PASS>"
local help_desc = lang.help_desc or "Sets password of a user or yourself"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_nochange = lang.msg_nochange or "There are no changes needed."
local msg_god = lang.msg_god or "You are not allowed to change the nick of this user."
local msg_reg = lang.msg_reg or "User is not regged or a bot."
local msg_ok = lang.msg_ok or "Password was changed to: "
local msg_ok2 = lang.msg_ok2 or "Your Password was changed to: "
local msg_usage = lang.msg_usage or "Usage: [+!#]setpass nick <NICK> <PASS>  /  [+!#]setpass nick myself <PASS>"
local msg_min_length = lang.msg_min_length or "Minimum length of the Password is: %s"
local msg_max_length = lang.msg_max_length or "Maximum length of the Password is: %s"

local ucmd_menu_ct1_0 = lang.ucmd_menu_ct1_0 or { "User", "Control", "Change", "Password", "by Nick" }
local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "About You", "change password" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or "User"
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or "Control"
local ucmd_menu_ct1_4 = lang.ucmd_menu_ct1_4 or "Change"
local ucmd_menu_ct1_5 = lang.ucmd_menu_ct1_5 or "password"
local ucmd_menu_ct1_6 = lang.ucmd_menu_ct1_6 or "by Nick from List"
local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Change", "password" }

local ucmd_pass = lang.ucmd_pass or "Password:"
local ucmd_nick = lang.ucmd_nick or "Nickname:"

local user_db = "cfg/user.tbl"


----------
--[CODE]--
----------

local oplevel = util.getlowestlevel( permission )

onbmsg = function( user, command, parameters )
    local user_tbl = hub.getregusers()
    local user_nick = user:nick()
    local user_level = user:level()
    local user_firstnick = user:firstnick()
    local target, prefix
    local myself = false
    local target_isbot = true
    local target_isregged = false
    local target_firstnick, target_nick, target_level, target_prefix

    if not user:isregged() then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end

    local by, targetname, pass = utf.match( parameters, "^(%S+) (%S+) (%S+)$" )

    if not pass then
        user:reply( msg_usage, hub.getbot() )
        return PROCESSED
    end

    if targetname == "myself" then
        myself = true
        targetname = user_firstnick
    end
    if myself then
        if not permission_own_pw[ user_level ] then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
    end

    if pass:len() < min_length then
        user:reply( utf.format( msg_min_length, min_length ), hub.getbot() )
        return PROCESSED
    end
    if pass:len() > max_length then
        user:reply( utf.format( msg_max_length, max_length ), hub.getbot() )
        return PROCESSED
    end

    if by == "nicku" then target_prefix = true end

    if not target_prefix then
        for k, v in pairs( user_tbl ) do
            if not user_tbl[ k ].is_bot then
                if user_tbl[ k ].nick == targetname then
                    target_isbot = false
                    target_isregged = true
                    target_nick = user_tbl[ k ].nick
                    target_level = user_tbl[ k ].level
                    if target_nick == user_firstnick then
                        if user_tbl[ k ].password == pass then
                            user:reply( msg_nochange, hub.getbot() )
                            return PROCESSED
                        else
                            user_tbl[ k ].password = pass
                            user:reply( msg_ok .. pass, hub.getbot() )
                            util.savearray( user_tbl, user_db )
                            return PROCESSED
                        end
                    end
                    if ( permission[ user_level ] or 0 ) < target_level then
                        user:reply( msg_god, hub.getbot() )
                        return PROCESSED
                    else
                        if activate then
                            prefix = hub.escapeto( prefix_table[ target_level ] )
                            target = hub.isnickonline( prefix .. target_nick )
                        else
                            target = hub.isnickonline( target_nick )
                        end
                        if user_tbl[ k ].password == pass then
                            user:reply( msg_nochange, hub.getbot() )
                            return PROCESSED
                        else
                            user_tbl[ k ].password = pass
                            user:reply( msg_ok .. pass, hub.getbot() )
                            if target then
                                target:reply( msg_ok2 .. pass, hub.getbot(), hub.getbot() )
                            end
                            util.savearray( user_tbl, user_db )
                            return PROCESSED
                        end
                    end
                end
            end
        end
    else
        for sid, target in pairs( hub.getusers() ) do
            if target:nick() == targetname then
                target_level = target:level()
                target_firstnick = target:firstnick()
                for k, v in pairs( user_tbl ) do
                    if not user_tbl[ k ].is_bot then
                        if user_tbl[ k ].nick == target_firstnick then
                            target_isbot = false
                            target_isregged = true
                            if target_firstnick == user_firstnick then
                                if user_tbl[ k ].password == pass then
                                    user:reply( msg_nochange, hub.getbot() )
                                    return PROCESSED
                                else
                                    user_tbl[ k ].password = pass
                                    user:reply( msg_ok .. pass, hub.getbot() )
                                    util.savearray( user_tbl, user_db )
                                    return PROCESSED
                                end
                            end
                            if ( permission[ user_level ] or 0 ) < target_level then
                                user:reply( msg_god, hub.getbot() )
                                return PROCESSED
                            else
                                if user_tbl[ k ].password == pass then
                                    user:reply( msg_nochange, hub.getbot() )
                                    return PROCESSED
                                else
                                    user_tbl[ k ].password = pass
                                    user:reply( msg_ok .. pass, hub.getbot() )
                                    target:reply( msg_ok2 .. pass, hub.getbot(), hub.getbot() )
                                    util.savearray( user_tbl, user_db )
                                    return PROCESSED
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if not target_isregged then
        user:reply( msg_reg, hub.getbot() )
        return PROCESSED
    end
    if target_isbot then
        user:reply( msg_reg, hub.getbot() )
        return PROCESSED
    end
end

hub.setlistener( "onStart", { },
    function( )
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, 10 )    -- reg help
        end
        ucmd = hub.import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { "nick", "myself", "%[line:" .. ucmd_pass .. "]" }, { "CT1" }, 10 )
            ucmd.add( ucmd_menu_ct1_0, cmd, { "nick", "%[line:" .. ucmd_nick .. "]", "%[line:" .. ucmd_pass .. "]" }, { "CT1" }, oplevel )
            if advanced_rc then
                local regusers, reggednicks, reggedcids = hub.getregusers( )
                local usertbl = {}
                for i, user in ipairs( regusers ) do
                    if ( user.is_bot ~=1 ) and user.nick then
                      table.insert( usertbl, user.nick )
                    end
                end
                table.sort( usertbl )
                for _, nick in pairs( usertbl ) do
                    ucmd.add( { ucmd_menu_ct1_2, ucmd_menu_ct1_3, ucmd_menu_ct1_4, ucmd_menu_ct1_5, ucmd_menu_ct1_6, nick }, cmd, { "nick", nick, "%[line:" .. ucmd_pass .. "]" }, { "CT1" }, oplevel )
                end
            end
            ucmd.add( ucmd_menu_ct2_1, cmd, { "nicku", "%[userNI]", "%[line:" .. ucmd_pass .. "]" }, { "CT2" }, oplevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )