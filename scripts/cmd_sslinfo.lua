--[[

    cmd_sslinfo.lua by blastbeat

    usage: [+!#]sslinfo [<NICK>]

    description: Shows SSL information about the client to hub connection by you or other users

    v0.04: by pulsar
        - fix showing my own SSL info instead of users SSL info  / thx Tantrix
            - fix #180 -> https://github.com/luadch/luadch/issues/180
        - removed table lookups

    v0.03: by pulsar
        - catch error if user is a bot  / thx Kaas
        - show "User not found" instead of own sslinfo if user was not found
        - use NICK instead of SID

    v0.02: by pulsar
        - removed onLogin listener (written for testing purposes by blastbeat)
        - added lang, help and ucmd support

    v0.01: by blastbeat
        - this script sends shows the ssl infos of a user at login

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_sslinfo"
local scriptversion = "0.04"

local cmd = "sslinfo"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local minlevel = cfg.get( "cmd_sslinfo_minlevel" )

--// msgs

local help_title = lang.help_title or "cmd_sslinfo.lua"
local help_usage = lang.help_usage or "[+!#]sslinfo [<NICK>]"
local help_desc = lang.help_desc or "Shows SSL information about the client to hub connection by you or other users"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show Client2Hub SSL info" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Client2Hub SSL info" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_isbot = lang.msg_isbot or "User is a bot."
local msg_notfound = lang.msg_notfound or "User not found."

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
    if user_level < minlevel then
        user:reply( msg_denied, hub.getbot() )
        return PROCESSED
    end
    local nick = utf.match( parameters, "^(%S+)$" )
    if nick then
        local target = hub.isnickonline( nick )
        if target then
            if not target:isbot() then
                user:reply( utf.format( msg_out, target:nick(), get_sslinfo( target ) ), hub.getbot() )
                return PROCESSED
            else
                user:reply( msg_isbot, hub.getbot() )
                return PROCESSED
            end
        else
            user:reply( msg_notfound, hub.getbot() )
            return PROCESSED
        end
    end
    user:reply( utf.format( msg_out, user_nick, get_sslinfo( user ) ), hub.getbot() )
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
            ucmd.add( ucmd_menu_ct1, cmd, { "%[userNI]" }, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "%[userNI]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )