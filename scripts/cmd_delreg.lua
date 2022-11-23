--[[

    cmd_delreg.lua by blastbeat

        - this script adds a command "delreg" to delreg users by nick
        - usage: [+!#]delreg nick <NICK>  |  [+!#]delreg nick <NICK> <DESCRIPTION>


        v0.29: by pulsar
            - refresh "cfg/user.tbl.bak" if a user gets delregged

        v0.28: by pulsar
            - rewrite some parts
            - add comments for a better understanding
            - removed unused vars

        v0.27: by pulsar
            - changed visuals

        v0.26: by pulsar
            - fix #98 / thx Sopor
                - added missing import of ban function
            - fix #95 / thx Sopor
                - import trafficmanager block function
                    - remove user from blocks if exists
                - removed table lookups

        v0.25: by pulsar
            - remove delregged user from bans if exists  / thx Sopor
            - removed "hub.reloadusers()"
            - removed unused table lookups

        v0.24: by pulsar
            - fix typo  / thx Motnahp

        v0.23: by pulsar
            - imroved user:kill()

        v0.22: by pulsar
            - removed send_report() function, using report import functionality now
            - changed "os.date()" output style, consistent output of date (win/linux/etc)  / thx Sopor

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
local scriptversion = "0.29"

local cmd = "delreg"


--// imports
local hubcmd, help, ucmd
local permission = cfg.get( "cmd_delreg_permission" )
local scriptlang = cfg.get( "language" )
local activate = cfg.get( "usr_nick_prefix_activate" )
local prefix_table = cfg.get( "usr_nick_prefix_prefix_table" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "cmd_delreg_report" )
local llevel = cfg.get( "cmd_delreg_llevel" )
local report_hubbot = cfg.get( "cmd_delreg_report_hubbot" )
local report_opchat = cfg.get( "cmd_delreg_report_opchat" )
local ban = hub.import( "cmd_ban")
local block = hub.import( "etc_trafficmanager" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local msg_denied = lang.msg_denied or "[ DELREG ]--> You are not allowed to use this command or to delreg targets with this level."
local msg_reason = lang.msg_reason or "No reason."
local msg_usage = lang.msg_usage or "Usage: [+!#]delreg nick <NICK>  /  or del with blacklist entry:  [+!#]delreg nick <NICK> <DESCRIPTION>"
local msg_error = lang.msg_error or "[ DELREG ]--> An error occurred: "
local msg_del = lang.msg_del or "[ DELREG ]--> You were delregged."
local msg_bot = lang.msg_bot or "[ DELREG ]--> User is a bot."
local msg_ok = lang.msg_ok or "[ DELREG ]--> User  %s  was delregged by  %s"
local msg_ok2 = lang.msg_ok2 or "[ DELREG ]--> User  %s  was delregged and blacklisted by  %s  reason: %s"
local msg_notfound = lang.msg_notfound or "[ DELREG ]--> User is not registered."

local help_title = lang.help_title or "delreg"
local help_usage = lang.help_usage or "[+!#]delreg nick <NICK>  /  or del with blacklist entry:  [+!#]delreg nick <NICK> <DESCRIPTION>"
local help_desc = lang.help_desc or "delregs a new user by nick or cid"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "User", "Control", "Delreg", "by NICK" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Delreg", "OK" }
local ucmd_nick = lang.ucmd_nick or "Nick:"
local ucmd_reason = lang.ucmd_reason or "Reason: (no blacklist entry if empty)"

--// database
local blacklist_file = "scripts/data/cmd_delreg_blacklist.tbl"
local description_file = "scripts/data/cmd_reg_descriptions.tbl"


----------
--[CODE]--
----------

local minlevel = util.getlowestlevel( permission )
local cmd_options = { nick = "nick", nicku = "nicku" }

local blacklist_add = function( targetnick, nick, reason )
    local blacklist_tbl = util.loadtable( blacklist_file )
    blacklist_tbl[ targetnick ] = {}
    blacklist_tbl[ targetnick ][ "tDate" ] = os.date( "%Y-%m-%d / %H:%M:%S" )
    blacklist_tbl[ targetnick ][ "tReason" ] = reason
    blacklist_tbl[ targetnick ][ "tBy" ] = nick
    util.savetable( blacklist_tbl, "blacklist_tbl", blacklist_file )
end

local description_del = function( targetnick )
    local description_tbl = util.loadtable( description_file )
    for k, v in pairs( description_tbl ) do
        if k == targetnick then
            description_tbl[ k ] = nil
            util.savetable( description_tbl, "description_tbl", description_file )
            break
        end
    end
end

local onbmsg = function( user, command, parameters )
    local user_nick = user:nick()
    local user_level = user:level()
    --// permission with regard to the minlevel
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end

    local option, arg, reason = utf.match( parameters, "^(%S+) (%S+) ?(.*)" )

    if not ( option and arg ) or not cmd_options[ option ] then
        user:reply( msg_usage, hub.getbot() )
        return PROCESSED
    end

    local target, target_firstnick, target_nick, target_level = nil, nil, nil, nil

    --// CT1 rightclick
    if option == "nick" then
        local regusers, reggednicks, reggedcids = hub.getregusers()
        local is_regged = false
        for i, usr in ipairs( regusers ) do
            if usr.nick == arg then
                if usr.is_bot == 1 then
                    user:reply( msg_bot, hub.getbot() )
                    return PROCESSED
                else
                    target_firstnick = usr.nick
                    target_level = usr.level
                    is_regged = true
                end
                break
            end
        end
        if is_regged then
            if activate then
                local prefix = hub.escapeto( prefix_table[ target_level ] )
                target_nick = prefix .. target_firstnick
            else
                target_nick = target_firstnick
            end
            target = hub.isnickonline( target_nick )
        else
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
    end
    --// CT2 rightclick
    if option == "nicku" then
        target = hub.isnickonline( arg )
        if target then
            if target:isbot() then
                user:reply( msg_bot, hub.getbot() )
                return PROCESSED
            else
                target_firstnick = target:firstnick()
                target_nick = target:nick()
                target_level = target:level()
            end
        else
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
    end
    --// permission with regard to the target
    if ( ( permission[ user_level ] or 0 ) < target_level ) then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    --// delreg
    local _, err = hub.delreguser( target_firstnick )
    if err then
        user:reply( msg_error .. err, hub.getbot() )
    else
        description_del( target_firstnick ) -- remove reg description if it exists (cmd_reg_descriptions.tbl)
        if ban then ban.del( target_firstnick ) end -- remove ban if it exists (cmd_ban_bans.tbl)
        if block then block.del( target_firstnick ) end -- remove block if it exists (etc_trafficmanager.tbl)
        --// report
        local message
        if reason ~= "" then
            blacklist_add( target_firstnick, user_nick, reason ) -- add target to blacklist
            message = utf.format( msg_ok2, target_nick, user_nick, reason )
        else
            message = utf.format( msg_ok, target_nick, user_nick )
        end
        user:reply( message, hub.getbot() )
        report.send( report_activate, report_hubbot, report_opchat, llevel, message )
        --// if target is online: disconnect
        if target then target:kill( "ISTA 230 " .. hub.escapeto( msg_del ) .. "\n", "TL-1" ) end
        --// refresh "cfg/user.tbl.bak"
        cfg.checkusers()
    end
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub.import( "etc_usercommands" )  -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, { "nick", "%[line:" .. ucmd_nick .. "]", "%[line:" .. ucmd_reason .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "nicku", "%[userNI]", "%[line:" .. ucmd_reason .. "]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )  -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )