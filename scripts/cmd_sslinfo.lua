--[[

    cmd_sslinfo.lua by blastbeat

    usage: [+!#]sslinfo [<SID>]
    
    description: Shows SSL informations about the client to hub connection by you or other users

    v0.02: by pulsar
        - removed onLogin listener (written for testing purposes by blastbeat)
        - added lang, help and ucmd support

    v0.01: by blatbeat
        - this script sends shows the ssl infos of a user at login

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_sslinfo"
local scriptversion = "0.02"

local cmd = "sslinfo"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local hub_import = hub.import
local utf_format = utf.format
local utf_match = utf.match
local hub_issidonline = hub.issidonline

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )
local minlevel = cfg_get( "cmd_sslinfo_minlevel" )

--// msgs

local help_title = lang.help_title or "cmd_sslinfo.lua"
local help_usage = lang.help_usage or "[+!#]sslinfo [<SID>]"
local help_desc = lang.help_desc or "Shows SSL informations about the client to hub connection by you or other users"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show Client2Hub SSL info" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Client2Hub SSL info" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."

local msg_out = lang.msg_out or [[


=== SSL INFO =====================================

    Client to Hub SSL connection info

    User:  %s

%s
===================================== SSL INFO ===
  ]]


----------
--[CODE]--
----------

local get_sslinfo = function( user )
    local buf, info = "", user:sslinfo()
    local sep = string.rep( " ", 8 )
    if info then
        for field, value in pairs( info ) do
            buf = buf .. sep .. tostring( field ) .. ":  " .. tostring( value ) .. "\n"
        end
    end
    return buf
end

local onbmsg = function( user, command, parameters )
    local user_nick = user:nick()
    local user_level = user:level()
    local target, info, msg
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local sid = utf_match( parameters, "^(%S+)$" )
    if sid then
        target = hub_issidonline( sid )
        if target then
            info = get_sslinfo( target )
            msg = utf_format( msg_out, target:nick(), info )
            user:reply( msg, hub_getbot )
            return PROCESSED
        end
    end
    info = get_sslinfo( user )
    msg = utf_format( msg_out, user_nick, info )
    user:reply( msg, hub_getbot )
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
            ucmd.add( ucmd_menu_ct1, cmd, { "%[userSID]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "%[userSID]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )