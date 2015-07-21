--[[

    etc_blacklist.lua by pulsar

        v0.6:
            - add table lookups
            - fix permission
            - cleaning code
            - fix database import  / thx DerWahre
            - add "deleted by" info

        v0.5:
            - changed database path and filename
            - from now on all scripts uses the same database folder

        v0.4:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.3:
            - added: seperate levelcheck for delete feature

        v0.2:
            - added: hub.restartscripts() & hub.reloadusers()

        v0.1:
            - show blacklisted users
            - delete blacklisted users

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "etc_blacklist"
local scriptversion = "0.6"

local cmd = "blacklist"
local cmd_p_show = "show"
local cmd_p_del = "del"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_restartscripts = hub.restartscripts
local hub_reloadusers = hub.reloadusers
local utf_match = utf.match
local utf_format = utf.format
local hub_getbot = hub.getbot()
local util_loadtable = util.loadtable
local util_savetable = util.savetable

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local oplevel = cfg_get( "etc_blacklist_oplevel" )
local masterlevel = cfg_get( "etc_blacklist_masterlevel" )
local blacklist_file = "scripts/data/cmd_delreg_blacklist.tbl"

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "Blacklist"
local help_usage = lang.help_usage or "[+!#]blacklist show"
local help_desc = lang.help_desc or "show blacklisted users"

local help_title2 = lang.help_title2 or "Blacklist"
local help_usage2 = lang.help_usage2 or "[+!#]blacklist del <nick>"
local help_desc2 = lang.help_desc2 or "delete user from blacklist" 

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_usage = lang.msg_usage or "Usage: [+!#]blacklist show  /  [+!#]blacklist del <nick>"

local msg_01 = lang.msg_01 or "\t  Username: "
local msg_02 = lang.msg_02 or "\t  Deleted on: "
local msg_06 = lang.msg_06 or "\t  Deleted by: "
local msg_03 = lang.msg_03 or "\t  Reason: "
local msg_04 = lang.msg_04 or "The following user was deleted from Blacklist: "
local msg_05 = lang.msg_05 or "Error: User not found."

local ucmd_menu_show = lang.ucmd_menu_show or { "Hub", "etc", "Blacklist", "show" }
local ucmd_menu_del = lang.ucmd_menu_del or { "Hub", "etc", "Blacklist", "user delete" }
local ucmd_nick = lang.ucmd_nick or "Username:"

local msg_out = lang.msg_out or [[


=== BLACKLIST =========================================================================================
%s
========================================================================================= BLACKLIST ===
  ]]


----------
--[CODE]--
----------

local onbmsg = function( user, adccmd, parameters )
    local blacklist_tbl = util_loadtable( blacklist_file ) or {}
    local param1 = utf_match( parameters, "^(%S+)" )
    local param2 = utf_match( parameters, "^%a+ (%S+)" )
    local user_level = user:level()
    if param1 == cmd_p_show then
        if user_level >= oplevel then
            local msg = ""
            for k, v in pairs( blacklist_tbl ) do
                local date = blacklist_tbl[ k ][ "tDate" ] or ""
                local by = blacklist_tbl[ k ][ "tBy" ] or ""
                local reason = blacklist_tbl[ k ][ "tReason" ] or ""
                msg = msg .. "\n" ..
                msg_01 .. k .. "\n" ..
                msg_02 .. date .. "\n" ..
                msg_06 .. by .. "\n" ..
                msg_03 .. reason .. "\n"
            end
            local blacklist = utf_format( msg_out, msg )
            user:reply( blacklist, hub_getbot )
            return PROCESSED
        else
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
    end
    if param1 == cmd_p_del then
        if user_level >= masterlevel then
            if blacklist_tbl[ param2 ] then
                blacklist_tbl[ param2 ] = nil
                util_savetable( blacklist_tbl, "blacklist_tbl", blacklist_file )
                user:reply( msg_04 .. param2, hub_getbot )
                hub_restartscripts()
                hub_reloadusers()
                return PROCESSED
            else
                user:reply( msg_05, hub_getbot )
                return PROCESSED
            end
        else
            user:reply( msg_denied, hub_getbot )
            return PROCESSED
        end
    end
    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, oplevel )
            help.reg( help_title, help_usage2, help_desc, masterlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_show, cmd, { cmd_p_show }, { "CT1" }, oplevel )
            ucmd.add( ucmd_menu_del, cmd, { cmd_p_del, "%[line:" .. ucmd_nick .. "]" }, { "CT1" }, masterlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .." **" )