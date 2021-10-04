--[[

    cmd_redirect.lua by pulsar

        usage: [+!#]redirect <NICK> <URL>

        v0.6:
            - changed visuals
            - removed table lookups
            - simplify 'activate' logic

        v0.5:
            - added additional ucmd entry to redirect user to default url
            - changes in "onbmsg" function

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
local scriptversion = "0.6"

local cmd = "redirect"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local levelname = cfg.get( "levels" )
local activate = cfg.get( "cmd_redirect_activate" )
local permission = cfg.get( "cmd_redirect_permission" )
local redirect_level = cfg.get( "cmd_redirect_level" )
local redirect_url = cfg.get( "cmd_redirect_url" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "cmd_redirect_report" )
local report_hubbot = cfg.get( "cmd_redirect_report_hubbot" )
local report_opchat = cfg.get( "cmd_redirect_report_opchat" )
local llevel = cfg.get( "cmd_redirect_llevel" )

--// msgs
local help_title = lang.help_title or "usr_redirect.lua"
local help_usage = lang.help_usage or "[+!#]redirect <NICK> <URL>"
local help_desc = lang.help_desc or "Redirect user to url"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]redirect <NICK> <URL>"
local msg_god = lang.msg_god or "You are not allowed to redirect this user."
local msg_isbot = lang.msg_isbot or "User is a bot."
local msg_notonline = lang.msg_notonline or "User is offline."
local msg_redirect = lang.msg_redirect or "[ REDIRECT ]--> User:  %s  was redirected to:  %s"
local msg_report_redirect = lang.msg_report_redirect or "[ REDIRECT ]--> User:  %s  has redirected user:  %s  |  to:  %s"

local ucmd_menu_ct2_1 = lang.ucmd_menu_ct2_1 or { "Redirect", "default URL" }
local ucmd_menu_ct2_2 = lang.ucmd_menu_ct2_2 or { "Redirect", "custom URL" }

local ucmd_url = lang.ucmd_url or "Redirect url:"

local msg_report = lang.msg_report or "[ REDIRECT ]--> User:  %s  |  with level:  %s [ %s ]  |  was auto redirected to:  %s"

--// functions
local listener
local is_online
local onbmsg


----------
--[CODE]--
----------

if not activate then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local oplevel = util.getlowestlevel( permission )

listener = function( user )
    if redirect_level[ user:level() ] then
        local report_msg = utf.format( msg_report, user:nick(), user:level(), levelname[ user:level() ], redirect_url )
        user:redirect( redirect_url )
        report.send( report_activate, report_hubbot, report_opchat, llevel, report_msg )
    end
    return nil
end

--// check if target user is online
is_online = function( target )
    local target = hub.isnickonline( target )
    if target then
        if target:isbot() then
            return "bot"
        else
            return target, target:nick(), target:level()
        end
    end
    return nil
end

onbmsg = function( user, command, parameters )
    local target_nick, target_level
    local param, url = utf.match( parameters, "^(%S+) (%S+)" )
    --// [+!#]redirect <NICK> <URL>
    if ( param and url ) then
        if user:level() < oplevel then
            user:reply( msg_denied, hub.getbot() )
            return PROCESSED
        end
        local target, target_nick, target_level = is_online( param )
        if target then
            if target ~= "bot" then
                if ( ( permission[ user:level() ] or 0 ) < target_level ) then
                    user:reply( msg_god, hub.getbot() )
                    return PROCESSED
                end
                if url == "default" then url = redirect_url end
                target:redirect( url )
                user:reply( utf.format( msg_redirect, target_nick, url ), hub.getbot() )
                report.send( report_activate, report_hubbot, report_opchat, llevel,
                             utf.format( msg_report_redirect, user:nick(), target_nick, url ) )
                return PROCESSED
            else
                user:reply( msg_isbot, hub.getbot() )
                return PROCESSED
            end
        else
            user:reply( msg_notonline, hub.getbot() )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub.getbot() )
    return PROCESSED
end

--// script start
hub.setlistener( "onStart", {},
    function()
        --// help, ucmd, hucmd
        local help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, oplevel )
        end
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct2_1, cmd, { "%[userNI]", "default" }, { "CT2" }, oplevel )
            ucmd.add( ucmd_menu_ct2_2, cmd, { "%[userNI]", "%[line:" .. ucmd_url .. "]" }, { "CT2" }, oplevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

--// if user connects
hub.setlistener( "onConnect", {}, listener )

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )