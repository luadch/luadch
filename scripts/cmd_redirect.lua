--[[

    cmd_redirect.lua by pulsar

        usage: [+!#]redirect <NICK> <URL>

        v0.4:
            - removed send_report() function, using report import functionality now
            - small fix

        v0.3:
            - renamed script from "usr_redirect.lua" to "cmd_redirect.lua"
                - therefore changed import vars from cfg.tbl

        v0.2:
            - possibility to redirect single users from userlist  / requested by Andromeda
            - add new table lookups, imports, msgs

        v0.1:
            - this script redirects users, level specified according to redirect_level table

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_redirect"
local scriptversion = "0.4"

local cmd = "redirect"


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
local utf_format = utf.format
local utf_match = utf.match
local util_getlowestlevel = util.getlowestlevel

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local levelname = cfg_get( "levels" )
local activate = cfg_get( "cmd_redirect_activate" )
local permission = cfg_get( "cmd_redirect_permission" )
local redirect_level = cfg_get( "cmd_redirect_level" )
local redirect_url = cfg_get( "cmd_redirect_url" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "cmd_redirect_report" )
local report_hubbot = cfg_get( "cmd_redirect_report_hubbot" )
local report_opchat = cfg_get( "cmd_redirect_report_opchat" )
local llevel = cfg_get( "cmd_redirect_llevel" )

--// msgs
local help_title = lang.help_title or "usr_redirect.lua"
local help_usage = lang.help_usage or "[+!#]redirect <NICK> <URL>"
local help_desc = lang.help_desc or "Redirect user to url"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]redirect <NICK> <URL>"
local msg_god = lang.msg_god or "You are not allowed to redirect this user."
local msg_isbot = lang.msg_isbot or "User is a bot."
local msg_notonline = lang.msg_notonline or "User is offline."
local msg_redirect = lang.msg_redirect or "User: %s  was redirected to: %s"
local msg_report_redirect = lang.msg_report_redirect or "%s  has redirected user: %s  to: %s"

local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Redirect", "OK" }
local ucmd_url = lang.ucmd_url or "Redirect url:"

local msg_report = lang.msg_report or "User  %s  with level  %s [ %s ]  was auto redirected to: %s"

--// functions
local listener
local is_online
local onbmsg


----------
--[CODE]--
----------

local oplevel = util_getlowestlevel( permission )

listener = function( user )
    if activate then
        local user_nick = user:nick()
        local user_level = user:level()
        if redirect_level[ user_level ] then
            local report_msg = utf_format( msg_report, user_nick, user_level, levelname[ user_level ], redirect_url )
            user:redirect( redirect_url )
            report.send( report_activate, report_hubbot, report_opchat, llevel, report_msg )
        end
    end
    return nil
end

--// check if target user is online
is_online = function( target )
    local target = hub_isnickonline( target )
    if target then
        if target:isbot() then
            return "bot"
        else
            return target, target:nick(), target:level()
        end
    end
    return nil
end

if activate then
    onbmsg = function( user, command, parameters )
        local user_nick = user:nick()
        local user_level = user:level()
        local target_nick, target_level
        local param, url = utf_match( parameters, "^(%S+) (%S+)" )
        --// [+!#]redirect <NICK> <URL>
        if ( param and url ) then
            if user_level < oplevel then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
            local target, target_nick, target_level = is_online( param )
            if target then
                if target ~= "bot" then
                    if ( ( permission[ user_level ] or 0 ) < target_level ) then
                        user:reply( msg_god, hub_getbot )
                        return PROCESSED
                    end
                    target:redirect( url )
                    local msg = utf_format( msg_redirect, target_nick, url )
                    user:reply( msg, hub_getbot )
                    msg = utf_format( msg_report_redirect, user_nick, target_nick, url )
                    report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
                    return PROCESSED
                else
                    user:reply( msg_isbot, hub_getbot )
                    return PROCESSED
                end
            else
                user:reply( msg_notonline, hub_getbot )
                return PROCESSED
            end
        end
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    --// script start
    hub.setlistener( "onStart", {},
        function()
            --// help, ucmd, hucmd
            local help = hub_import( "cmd_help" )
            if help then
                help.reg( help_title, help_usage, help_desc, oplevel )
            end
            local ucmd = hub_import( "etc_usercommands" )
            if ucmd then
                ucmd.add( ucmd_menu_ct2_1, cmd, { "%[userNI]", "%[line:" .. ucmd_url .. "]" }, { "CT2" }, oplevel )
            end
            local hubcmd = hub_import( "etc_hubcommands" )
            assert( hubcmd )
            assert( hubcmd.add( cmd, onbmsg ) )
            return nil
        end
    )
    --// if user connects
    hub.setlistener( "onConnect", {}, listener )
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )