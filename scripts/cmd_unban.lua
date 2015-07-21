--[[

    cmd_unban.lua by blastbeat

        - this script adds a command "unban" to unban users by ip/nick/cid
        - usage: [+!#]unban ip|nick|cid <IP>|<NICK>|<CID>

        v0.11: by pulsar
            - removed "cmd_unban_minlevel" import
                - using util.getlowestlevel( tbl ) instead of "cmd_unban_minlevel"
        
        v0.10: by pulsar
            - check if opchat is activated
        
        v0.09: by pulsar
            - added some new table lookups
            - added possibility to send report as feed to opchat
        
        v0.08: by pulsar
            - changed rightclick style
            
        v0.07: by Night
            - fix unbanning by IP
        
        v0.06: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"
            
        v0.05: by blastbeat
            - updated script api
            - regged hubcommand

        v0.04: by blastbeat
            - some clean ups, added language file, ucmds

        v0.03: by blastbeat
            - updated script api

        v0.02: by blastbeat
            - added level checking

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_unban"
local scriptversion = "0.11"

local cmd = "unban"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_getusers = hub.getusers
local hub_getbot = hub.getbot( )
local utf_match = utf.match
local utf_format = utf.format
local table_remove = table.remove
local hub_escapefrom = hub.escapefrom
local util_getlowestlevel = util.getlowestlevel

local opchat
local bans
local path
local hubcmd

--// imports
local permission = cfg_get( "cmd_unban_permission" )
local report = cfg_get( "cmd_unban_report" )
local llevel = cfg_get( "cmd_unban_llevel" )
local scriptlang = cfg_get( "language" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local report_hubbot = cfg_get( "cmd_unban_report_hubbot" )
local report_opchat = cfg_get( "cmd_unban_report_opchat" ) 

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_import = lang.msg_import or "Error while importing additional module."
local msg_usage = lang.msg_usage or "Usage: [+!#]unban ip|nick|cid <IP>|<nick>|<CID>"
local msg_off = lang.msg_off or "User not found."
local msg_god = lang.msg_god or "You are not allowed to unban this user."
local msg_ok = lang.msg_ok or "User %s removed ban of %s."

local help_title = lang.help_title or "unban"
local help_usage = lang.help_usage or "[+!#]unban ip|nick|cid <IP>|<nick>|<CID>"
local help_desc = lang.help_desc or "unbans user by IP or nick or CID"

local ucmd_menu_ct1_1 = lang.ucmd_menu_ct1_1 or { "User", "Control", "Unban", "by NICK" }
local ucmd_menu_ct1_2 = lang.ucmd_menu_ct1_2 or { "User", "Control", "Unban", "by CID" }
local ucmd_menu_ct1_3 = lang.ucmd_menu_ct1_3 or { "User", "Control", "Unban", "by IP" }

local ucmd_ip = lang.ucmd_ip or "IP:"
local ucmd_cid = lang.ucmd_cid or "CID:"
local ucmd_nick = lang.ucmd_nick or "Nick:"


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

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

local onbmsg = function( user, command, parameters )
    local user_level = user:level( )
    --[[
    if not permission[ user_level ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    ]]
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end  
    local by, id = utf_match( parameters, "^(%S+) (%S+)" )
    if not ( ( by == "ip" or by == "nick" or by == "cid" ) and id ) then
        user:reply( msg_usage, hub_getbot )
        return PROCESSED
    end
    for i, ban_tbl in ipairs( bans ) do
        if ban_tbl[ by ] == id then
            if permission[ user_level ] < ( ban_tbl.by_level or 100 ) then
                user:reply( msg_god, hub_getbot )
                return PROCESSED
            end
            table_remove( bans, i )
            util.savearray( bans, path )
            local user_nick = hub_escapefrom( user:nick( ) )
            local status_message = utf_format( msg_ok, user_nick, id )
            send_report( status_message, llevel )
            user:reply( status_message, hub_getbot )
            return PROCESSED
        end
    end
    user:reply( msg_off, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        local ban = hub_import( "cmd_ban" )
        if not ban then
            error( msg_import )
        end
        bans = ban.bans
        path = ban.bans_path
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )    -- reg help
        end
        local ucmd = hub_import( "etc_usercommands" )    -- add usercommand
        if ucmd then
            ucmd.add( ucmd_menu_ct1_1, cmd, { "nick", "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_2, cmd, { "cid", "%[line:" .. ucmd_cid .. "]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct1_3, cmd, { "ip", "%[line:" .. ucmd_ip .. "]" }, { "CT1" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )    -- add hubcommand
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
