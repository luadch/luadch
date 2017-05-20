
--[[

    cmd_disconnect.lua by pulsar

        - Usage: [+!#]disconnect <NICK> <REASON>

        v1.1:
            - fix typo  / thx Motnahp

        v1.0:
            - imroved user:kill()

        v0.9:
            - removed send_report() function, using report import functionality now

        v0.8:
            - check if opchat is activated

        v0.7:
            - added some new table lookups
            - added possibility to send report as feed to opchat
            - using utf.format for output message

        v0.6:
            - bugfix in user send method
            - code cleaning

        v0.5:
            - bugfix in "user:kill" funktion

        v0.4:
            - changed rightclick style

        v0.3:
            - bugfix: disconnect bots

        v0.2:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.1:
            - simple script to disconnect users

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_disconnect"
local scriptversion = "1.1"

local cmd = "disconnect"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_broadcast = hub.broadcast
local hub_escapeto = hub.escapeto
local hub_import = hub.import
local hub_debug = hub.debug
local utf_match = utf.match
local utf_format = utf.format
local hub_isnickonline = hub.isnickonline

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local minlevel = cfg_get( "cmd_disconnect_minlevel" )
local sendmainmsg = cfg_get( "cmd_disconnect_sendmainmsg" )
local report = hub_import( "etc_report" )
local report_activate = cfg_get( "cmd_disconnect_report" )
local llevel = cfg_get( "cmd_disconnect_llevel" )
local report_hubbot = cfg_get( "cmd_disconnect_report_hubbot" )
local report_opchat = cfg_get( "cmd_disconnect_report_opchat" )

--// msgs
local help_title = lang.help_title or "disconnect"
local help_usage = lang.help_usage or "[+!#]disconnect <Nick> <Grund>"
local help_desc = lang.help_desc or "disconnected einen User"

local user_msg = lang.user_msg or "Du wurdest disconnected von: %s  Begründung: %s"
local report_msg = lang.report_msg or "Der User: %s  wurde disconnected von: %s  Begründung: %s"

local msg_denied1 = lang.msg_denied1 or "Du bist nicht berechtigt diesen Befehl zu nutzen!"
local msg_denied2 = lang.msg_denied2 or "Du kannst keinen disconnecten der ein höheres Level hat als du!"
local msg_denied3 = lang.msg_denied3 or "Du kannst dich nicht selbst disconnecten!"
local msg_denied4 = lang.msg_denied4 or "Der User ist offline!"
local msg_bot = lang.msg_bot or "Error: User is a bot."

local ucmd_target = lang.ucmd_target or "Username"
local ucmd_reason = lang.ucmd_reason or "Begründung"
local ucmd_menu1 = lang.ucmd_menu1 or { "User", "Control", "Disconnecten", "nach NICK" }
local ucmd_menu2 = lang.ucmd_menu2 or { "Disconnecten", "OK" }


----------
--[CODE]--
----------

local onbmsg = function( user, adccmd, parameters )
    local user_level = user:level()
    local user_nick = user:nick()
    local target = utf_match( parameters, "^(%S+)" )
    local reason = ( target and utf_match( parameters, "^%S+ (.*)" ) ) or ""
    local targetuser = hub_isnickonline( target )
    if not targetuser then
        user:reply( msg_denied4, hub_getbot )
        return PROCESSED
    end
    if targetuser:isbot() then
        user:reply( msg_bot, hub_getbot )
        return PROCESSED
    end
    local targetuser_level = targetuser:level()
    local targetuser_nick = targetuser:nick()
    if user_level < minlevel then
        user:reply( msg_denied1, hub_getbot )
        return PROCESSED
    end
    if user_level < targetuser_level then
        user:reply( msg_denied2, hub_getbot )
        return PROCESSED
    end
    if user_nick == targetuser_nick then
        user:reply( msg_denied3, hub_getbot )
        return PROCESSED
    end
    local msg_target = utf_format( user_msg, user_nick, reason )
    targetuser:kill( "ISTA 230 " .. hub_escapeto( msg_target ) .. "\n", "TL30" )
    local msg_report = utf_format( report_msg, targetuser_nick, user_nick, reason )
    if sendmainmsg then user:reply( msg_report, hub_getbot ) end
    report.send( report_activate, report_hubbot, report_opchat, llevel, msg_report )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu1, cmd, { "%[line:" .. ucmd_target .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu2, cmd, { "%[nick]", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .." **" )
