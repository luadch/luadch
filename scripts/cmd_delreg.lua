--[[

    cmd_delreg.lua by blastbeat

        - this script adds a command "delreg" to delreg users by nick
        - usage: [+!#]delreg nick <NICK>   / or:  [+!#]delreg nick <NICK> <DESCRIPTION>

        v0.21: by pulsar
            - remove description from "cmd_reg_descriptions.tbl" if user was delregged and description exists

        v0.20: by pulsar
            - removed "cmd_delreg_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_delreg_minlevel"

        v0.19: by pulsar
            - removed "hub.restartscripts()"
            - typo fix

        v0.18: by pulsar
            - check if opchat is activated

        v0.17: by pulsar
            - add "deleted by" info for blacklist entry
            - added "msg_ok2": if user was delregged with reason then the script shows it
            - add "blacklist_add" function and rewrite some parts of code

        v0.16: by pulsar
            - changing type of permission table (array of integer instead of array of boolean)

        v0.15: by pulsar
            - added some new table lookups
            - added possibility to send report as feed to opchat

        v0.14: by pulsar
            - fix bug with target user object

        v0.13: by pulsar
            - add some new table lookups
            - fix problem with disconnect users after delreg if using ct1 rightclick an user has nicktag
            - send error msg if user is not regged

        v0.12: by Night
            - permission fix

        v0.11: by pulsar
            - changed rightclick style

        v0.10: by pulsar
            - changed database path and filename
            - from now on all scripts uses the same database folder

        v0.09: by pulsar
            - bugfix: small error when delreg over CT1

        v0.08: by pulsar
            - bugfix: delreg bots

        v0.07: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.06: by pulsar
            - added blacklist function

        v0.05: by blastbeat
            - updated script api
            - regged hubcommand

        v0.04: by blastbeat
            - fixed report bug

        v0.03: by blastbeat
            - added language files, ucmds

        v0.02: by blastbeat
            - added report function

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_delreg"
local scriptversion = "0.21"

local cmd = "delreg"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local hub_escapeto = hub.escapeto
local hub_escapefrom = hub.escapefrom
local hub_isnickonline = hub.isnickonline
local hub_iscidonline = hub.iscidonline
local utf_match = utf.match
local utf_format = utf.format
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_getlowestlevel = util.getlowestlevel
local os_date = os.date
local hub_getusers = hub.getusers
local hub_getregusers = hub.getregusers

--// imports
local hubcmd, help, ucmd
local llevel = cfg_get( "cmd_delreg_llevel" )
local report = cfg_get( "cmd_delreg_report" )
local permission = cfg_get( "cmd_delreg_permission" )
local scriptlang = cfg_get( "language" )
local activate = cfg_get( "usr_nick_prefix_activate" )
local prefix_table = cfg_get( "usr_nick_prefix_prefix_table" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local report_hubbot = cfg_get( "cmd_delreg_report_hubbot" )
local report_opchat = cfg_get( "cmd_delreg_report_opchat" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this command or to delreg targets with this level."
local msg_import = lang.msg_import or "Error while importing additional module."
local msg_reason = lang.msg_reason or "No reason."
local msg_usage = lang.msg_usage or "Usage: [+!#]delreg nick <NICK>  /  or del with blacklist entry:  [+!#]delreg nick <NICK> <DESCRIPTION>"
local msg_error = lang.msg_error or "An error occured: "
local msg_del = lang.msg_del or "You were delregged."
local msg_bot = lang.msg_bot or "Error: User is a bot."
local msg_ok = lang.msg_ok or "%s  was delregged by  %s"
local msg_ok2 = lang.msg_ok2 or "%s  was delregged and blacklisted by  %s  reason: %s"
local msg_notfound = lang.msg_notfound or "User is not regged."

local help_title = lang.help_title or "delreg"
local help_usage = lang.help_usage or "[+!#]delreg nick <NICK>  /  or del with blacklist entry:  [+!#]delreg nick <NICK> <DESCRIPTION>"
local help_desc = lang.help_desc or "delregs a new user by nick or cid"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "User", "Control", "Delreg" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Delreg" }
local ucmd_nick = lang.ucmd_nick or "Nick:"
local ucmd_reason = lang.ucmd_reason or "Reason: (no blacklist entry if empty)"

--// database
local blacklist_file = "scripts/data/cmd_delreg_blacklist.tbl"
local description_file = "scripts/data/cmd_reg_descriptions.tbl"


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )
local blacklist_tbl, description_tbl

local cmd_options = { nick = "nick", cid = "cid", nicku = "nicku" }

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

local dateparser = function()
    if scriptlang == "de" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local datum = day .. "." .. month .. "." .. year
        return datum
    elseif scriptlang == "en" then
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local datum = month .. "/" .. day .. "/" .. year
        return datum
    else
        local day = os_date( "%d" )
        local month = os_date( "%m" )
        local year = os_date( "%Y" )
        local datum = day .. "." .. month .. "." .. year
        return datum
    end
end

local blacklist_add = function( targetnick, nick, reason )
    blacklist_tbl = util_loadtable( blacklist_file )
    blacklist_tbl[ targetnick ] = {}
    blacklist_tbl[ targetnick ][ "tDate" ] = dateparser()
    blacklist_tbl[ targetnick ][ "tReason" ] = reason
    blacklist_tbl[ targetnick ][ "tBy" ] = nick
    util_savetable( blacklist_tbl, "blacklist_tbl", blacklist_file )
end

local description_del = function( targetnick )
    description_tbl = util_loadtable( description_file )
    for k, v in pairs( description_tbl ) do
        if k == targetnick then
            description_tbl[ k ] = nil
        end
    end
    util_savetable( description_tbl, "description_tbl", description_file )
end

local onbmsg = function( user, command, parameters )
    local user_nick = user:nick()
    local user_firstnick = user:firstnick()
    local user_level = user:level()
    local option, arg, reason = utf_match( parameters, "^(%S+) (%S+) ?(.*)" )
    if not ( option and arg ) or not cmd_options[ option ] then
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end

    local prefix, target, target_firstnick, target_nick, target_level, bol, err = nil, nil, nil, nil, nil, nil, "unknown"

    if option == "nicku" then
        target = hub_isnickonline( arg )
        if target then
            target_firstnick = target:firstnick()
            target_nick = target:nick()
            target_level = target:level()
            if target:isbot() then
                user:reply( msg_bot, hub_getbot )
                return PROCESSED
            end
            if ( ( permission[ user_level ] or 0 ) < target_level ) then
                user:reply( msg_denied, hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_notfound, hub_getbot )
            return PROCESSED
        end
        if reason ~= "" then
            blacklist_add( target_firstnick, user_nick, reason )
            bol, err = hub.delreguser( target_firstnick )
        else
            bol, err = hub.delreguser( target_firstnick )
        end
        description_del( target_firstnick )
    end

    if option == "nick" then
        local regusers, reggednicks, reggedcids = hub_getregusers()
        local is_regged = false
        for i, usr in ipairs( regusers ) do
            if usr.nick == arg then
                if usr.is_bot == 1 then
                    user:reply( msg_bot, hub_getbot )
                    return PROCESSED
                else
                    target_firstnick = usr.nick
                    target_level = usr.level
                    is_regged = true
                end
            end
        end
        if is_regged then
            if activate then
                prefix = hub_escapeto( prefix_table[ target_level ] )
                target = hub_isnickonline( prefix .. target_firstnick )
                target_nick = prefix .. target_firstnick
            else
                target = hub_isnickonline( target_firstnick )
                target_nick = target_firstnick
            end
        else
            user:reply( msg_notfound, hub_getbot )
            return PROCESSED
        end
        if ( ( permission[ user_level ] or 0 ) < target_level ) then
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
        if reason ~= "" then
            blacklist_add( target_firstnick, user_nick, reason )
            bol, err = hub.delreguser( target_firstnick )
        else
            bol, err = hub.delreguser( target_firstnick )
        end
        description_del( target_firstnick )
    end
    if not bol then
        user:reply( msg_error .. err, hub_getbot )
    else
        local message
        if reason ~= "" then
            message = utf_format( msg_ok2, target_nick, user_nick, reason )
        else
            message = utf_format( msg_ok, target_nick, user_nick )
        end
        user:reply( message, hub_getbot )
        send_report( message, llevel )
        description_del( target_nick )
        if target then target:kill( "ISTA 230 " .. hub_escapeto( msg_del ) .. "\n" ) end
    end
    --hub.restartscripts()
    hub.reloadusers()
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )  -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, { "nick", "%[line:" .. ucmd_nick .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "nicku", "%[userNI]", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )  -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )