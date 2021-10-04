﻿--[[

    cmd_reg.lua by blastbeat

        - usage: [+!#]reg nick <NICK> <LEVEL> [<COMMENT>] / [+!#]reg desc <NICK> <COMMENT> (an empty comment removes an existing comment)

        - this script adds a command "reg" to reg users
        - note: be careful when using the nick prefix script: you should reg user nicks always WITHOUT prefix

        v0.28: by pulsar
            - changed visuals
            - removed table lookups

        v0.27: by pulsar
            - fix #47 -> https://github.com/luadch/luadch/issues/47
                - show comment from the registered user as default if exists

        v0.26: by pulsar
            - fix #83 -> https://github.com/luadch/luadch/issues/83
            - the script now sends the registration information to the user

        v0.25: by HypoManiac
            - fixed so comment can not be set on user of same or higher level
            - fixed so comment can not be set on unknown user

        v0.24: by pulsar
            - added min_length/max_length restrictions

        v0.23: by pulsar
            - usage/help msg improvement  / thx Sopor
            - small improvements with output msg  / thx Sopor

        v0.22: by pulsar
            - some typo fixes  / thx Sopor
            - removed send_report() function, using report import functionality now
            - added comment feature to add/change a comment to existing regusers

        v0.21: by pulsar
            - added possibility to add a description  / request by DerWahre

        v0.20: by pulsar
            - removed "cmd_reg_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_ban_minlevel"

        v0.19: by pulsar
            - check if opchat is activated

        v0.18: by pulsar
            - using "user:firstnick()" for "registered by" for "user.tbl"
            - add "deleted by" info to blacklist msg
            - fix CT2 RC doublereg bug if hub uses nicktags  / thx Motnahp

        v0.17: by pulsar
            - added some new table lookups
            - added possibility to send report as feed to opchat

        v0.16: by pulsar
            - now using auto generated passwords for regs
            - add some new table lookups and clean some parts of code

        v0.15: by pulsar
            - added levelname to output message

        v0.14: by pulsar
            - changed visual output style

        v0.13: by pulsar
            - show sorted levelnames in rightclick

        v0.12: by pulsar
            - changed rightclick style

        v0.11: by pulsar
            - changed database path and filename
            - from now on all scripts uses the same database folder

        v0.10: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.09: by pulsar
            - show user level

        v0.08: by pulsar
            - checks user whether blacklistet before registering or not

        v0.07: by pulsar
            - fix output style

        v0.06: by pulsar
          - add keyprint feature

        v0.05: by blastbeat
          - small fix in language files and ucmd

        v0.04: by blastbeat
          - updated script api
          - renamed command
          - regged hubcommand

        v0.03: by blastbeat
          - added accinfo, language files, ucmd

        v0.02: by blastbeat
          - updated script api

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_reg"
local scriptversion = "0.28"

local cmd = "reg"

--// imports
local hubcmd, help, ucmd
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )
local permission = cfg.get( "cmd_reg_permission" )
local tcp = cfg.get( "tcp_ports" )
local ssl = cfg.get( "ssl_ports" )
local host = cfg.get( "hub_hostaddress" )
local hname = cfg.get( "hub_name" )
local use_keyprint = cfg.get( "use_keyprint" )
local keyprint_type = cfg.get( "keyprint_type" )
local keyprint_hash = cfg.get( "keyprint_hash" )
local min_length = cfg.get( "min_nickname_length" )
local max_length = cfg.get( "max_nickname_length" )
local report = hub.import( "etc_report" )
local report_activate = cfg.get( "cmd_reg_report" )
local llevel = cfg.get( "cmd_reg_llevel" )
local report_hubbot = cfg.get( "cmd_reg_report_hubbot" )
local report_opchat = cfg.get( "cmd_reg_report_opchat" )

--// msgs
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_import = lang.msg_import or "Error while importing additional module."
local msg_report = lang.msg_report or "User  %s  registered  %s  with level  %d [ %s ]  Comment: %s"
local msg_nocomment = lang.msg_nocomment or "no comment defined"
local msg_level = lang.msg_level or "You are not allowed to reg this level."
local msg_usage = lang.msg_usage or "Usage: [+!#]reg nick <NICK> <LEVEL> [<COMMENT>] / [+!#]reg desc <NICK> <COMMENT> (an empty comment removes an existing comment)"
local msg_error = lang.msg_error or "An error occured: "
local msg_ok = lang.msg_ok or "[ REG ]--> User regged with following parameters: Nickname: %s | Password: %s | Level: %s [ %s ] | Comment: %s"
local msg_desc = lang.msg_desc or "[ REG ]--> User: %s  added/changed a comment to/from reguser: %s | comment: %s"
local msg_length = lang.msg_length or "Nickname restrictions min/max: %s/%s"
local msg_accinfo = lang.msg_accinfo or [[


=== ACCOUNT ========================================

    Nickname: %s
    Password: %s

    Level: %s  [ %s ]

    Hubname: %s
    Hubaddress: %s

======================================== ACCOUNT ===

        ]]

local help_title = lang.help_title or "cmd_reg.lua"
local help_usage = lang.help_usage or "[+!#]reg nick <NICK> <LEVEL> [<COMMENT>] / [+!#]reg desc <NICK> <COMMENT> (an empty comment removes an existing comment)"
local help_desc = lang.help_desc or "Regs a new user / add a comment to an existing user"

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or "User"
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or "Control"
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or "Reg"
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Reg" }
local ucmd_menu_ct3 = lang.ucmd_menu_ct3 or { "User", "Control", "Change", "Comment", "add//change comment of a reguser" }
local ucmd_menu_ct4 = lang.ucmd_menu_ct4 or { "Change", "Comment", "add//change comment of a reguser" }

local ucmd_level = lang.ucmd_level or "Level:"
local ucmd_nick = lang.ucmd_nick or "Nick:"
local ucmd_desc = lang.ucmd_desc or "Comment (optional):"
local ucmd_desc2 = lang.ucmd_desc2 or "Comment:"

local msg_blacklist1 = lang.msg_blacklist1 or "Error: This User blacklisted!"
local msg_blacklist2 = lang.msg_blacklist2 or "Reason: "
local msg_blacklist3 = lang.msg_blacklist3 or "Deleted on: "
local msg_blacklist4 = lang.msg_blacklist4 or "Deleted by: "

--// database
local blacklist_file = "scripts/data/cmd_delreg_blacklist.tbl"
local description_file = "scripts/data/cmd_reg_descriptions.tbl"


----------
--[CODE]--
----------

local minlevel = util.getlowestlevel( permission )
local blacklist_tbl, description_tbl
local addy = ""

if #tcp ~= 0 then
    if #tcp > 1 then
        --addy = addy .. "adc://" .. host .. ":" .. table.concat( tcp, ", " ) .. "    "
        addy = addy .. "\n"
        for i, port in ipairs( tcp ) do
            addy = addy .. "\t\tadc://" .. host .. ":" .. port .. "\n"
        end
    else
        addy = addy .. "adc://" .. host .. ":" .. table.concat( tcp, ", " ) .. "    "
    end
end
if #ssl ~= 0 then
    if #ssl > 1 then
        if use_keyprint then
            --addy = addy .. "adcs://" .. host .. ":" .. table.concat( ssl, ", " ) .. keyprint_type .. keyprint_hash
            addy = addy .. "\n"
            for i, port in ipairs( ssl ) do
                addy = addy .. "\n\t\tadcs://" .. host .. ":" .. port .. keyprint_type .. keyprint_hash
            end
        else
            --addy = addy .. "adcs://" .. host .. ":" .. table.concat( ssl, ", " )
            addy = addy .. "\n"
            for i, port in ipairs( ssl ) do
                addy = addy .. "\n\t\tadcs://" .. host .. ":" .. port
            end
        end
    else
        if use_keyprint then
            addy = addy .. "adcs://" .. host .. ":" .. table.concat( ssl, ", " ) .. keyprint_type .. keyprint_hash
        else
            addy = addy .. "adcs://" .. host .. ":" .. table.concat( ssl, ", " )
        end
    end
end

local description_add = function( targetnick, nick, reason )
    description_tbl = util.loadtable( description_file )
    description_tbl[ targetnick ] = {}
    description_tbl[ targetnick ][ "tBy" ] = nick
    description_tbl[ targetnick ][ "tReason" ] = reason
    util.savetable( description_tbl, "description_tbl", description_file )
end

local onbmsg = function( user, command, parameters )
    local user_nick = user:nick()
    local user_firstnick = user:firstnick()
    local user_level = user:level( )
    blacklist_tbl = util.loadtable( blacklist_file )
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local password = util.generatepass()
    local by, id, level, desc = utf.match( parameters, "^(%S+) (%S+) (%d+) ?(.*)" )
    local by2, id2, desc2 = utf.match( parameters, "^(%S+) (%S+) (.*)" )
    level = tonumber( level )
    if not ( ( by == "nick" and id ) or ( by2 == "desc" ) ) or not ( ( password and level ) or ( id2 and desc2 ) ) then
        user:reply( msg_usage, hub.getbot() )
        return PROCESSED
    end
    local levels = cfg.get( "levels" ) or { }
    if by == "nick" then
        if not levels[ level ] or ( permission[ user_level ] < level ) then
            user:reply( msg_level, hub.getbot() )
            return PROCESSED
        end
    end
    local target_firstnick
    local target_level = tonumber( level ) or "unbekannt"
    local target_levelname = cfg.get( "levels" )[ target_level ] or "Unreg"
    local target = hub.isnickonline( id ) or hub.isnickonline( id2 )
    if target then
        target_firstnick = target:firstnick()
    else
        target_firstnick = id or id2
    end
    if string.len( target_firstnick ) < min_length or string.len( target_firstnick ) > max_length then
        user:reply( utf.format( msg_length, min_length, max_length ), hub.getbot() )
        return PROCESSED
    end
    if blacklist_tbl[ target_firstnick ] then
        local date = blacklist_tbl[ target_firstnick ]["tDate"] or ""
        local by = blacklist_tbl[ target_firstnick ]["tBy"] or ""
        local reason = blacklist_tbl[ target_firstnick ]["tReason"] or ""
        user:reply( msg_blacklist1, hub.getbot() )
        user:reply( msg_blacklist2 .. reason, hub.getbot() )
        user:reply( msg_blacklist3 .. date, hub.getbot() )
        user:reply( msg_blacklist4 .. by, hub.getbot() )
        return PROCESSED
    end
    if ( by2 == "desc" and id2 and desc2 ) then
        local _, regnicks, _ = hub.getregusers()
        local target = regnicks[ target_firstnick ]
        if target then
            local target_level = target.level
            if ( target_level < user_level or user_level == 100 ) then
                description_add( target_firstnick, user_firstnick, desc2 )
                local msg = utf.format( msg_desc, user_firstnick, target_firstnick, desc2 )
                user:reply( msg, hub.getbot() )
                report.send( report_activate, report_hubbot, report_opchat, llevel, msg )
            else
                user:reply( msg_denied, hub.getbot() )
            end
        else
            user:reply( msg_usage, hub.getbot() )
        end
        return PROCESSED
    end
    if not blacklist_tbl[ target_firstnick ] then
        local bol, err = hub.reguser{ nick = target_firstnick, password = password, level = target_level, by = user:firstnick() }
        if not bol then
            user:reply( msg_error .. ( err or "" ), hub.getbot() )
        else
            local comment = desc
            if comment == "" then comment = msg_nocomment end
            local message = utf.format( msg_report, user_nick, target_firstnick, target_level, target_levelname, comment )
            report.send( report_activate, report_hubbot, report_opchat, llevel, message )
            local message2 = utf.format( msg_ok, target_firstnick, password, target_level, target_levelname, comment )
            user:reply( message2, hub.getbot() )
            user:reply( utf.format( msg_accinfo, target_firstnick, password, target_level, target_levelname, hname, addy ), hub.getbot(), hub.getbot() )
            if target then
                target:reply( utf.format( msg_accinfo, target_firstnick, password, target_level, target_levelname, hname, addy ), hub.getbot(), hub.getbot() )
            end
            if desc ~= "" then
                description_add( target_firstnick, user_firstnick, desc )
            end
        end
    end
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub.import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct3, cmd, { "desc", "%[line:" .. ucmd_nick .. "]", "%[line:" .. ucmd_desc2 .. "]" }, { "CT1" }, minlevel )
            local levels = cfg.get( "levels" ) or { }
            local tbl = {}
            local i = 1
            for k, v in pairs( levels ) do
                if k > 0 then
                    tbl[ i ] = k
                    i = i + 1
                end
            end
            table.sort( tbl )
            for _, level in pairs( tbl ) do
                ucmd.add( { ucmd_menu_ct1_1, ucmd_menu_ct1_2, ucmd_menu_ct1_3, levels[ level ] }, cmd, { "nick", "%[line:" .. ucmd_nick .. "]", level, "%[line:" .. ucmd_desc .. "]" }, { "CT1" }, minlevel )
            end
            ucmd.add( ucmd_menu_ct2, cmd, { "nick", "%[userNI]", "%[line:" .. ucmd_level .. "]", "%[line:" .. ucmd_desc .. "]" }, { "CT2" }, minlevel )
            ucmd.add( ucmd_menu_ct4, cmd, { "desc", "%[userNI]", "%[line:" .. ucmd_desc2 .. "]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
