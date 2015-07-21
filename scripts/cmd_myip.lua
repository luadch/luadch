--[[

    cmd_myip.lua by pulsar

        usage: [+!#]myip

        v0.2:
            - added userlist rightclick
            - caching some new table lookups
            
        v0.1:
            - shows your ip

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_myip"
local scriptversion = "0.2"

local cmd = "myip"

local minlevel = 0


----------
--[CODE]--
----------

--// table lookups
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local hub_isnickonline = hub.isnickonline
local hub_getusers = hub.getusers
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_match = utf.match
local utf_format = utf.format

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )

local help_title = lang.help_title or "myip"
local help_usage = lang.help_usage or "[+!#]myip"
local help_desc = lang.help_desc or "shows your ip"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show IP" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "IP" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command!"
local msg_ip = lang.msg_ip or "Your IP is: "
local msg_targetip = lang.msg_targetip or "Username: %s  |  IP: %s"


local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    local user_ip = user:ip()
    local target_firstnick, target_ip
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(%S+)$" )
    if param then
        for sid, target in pairs( hub_getusers() ) do
            if ( target:nick() == param ) or ( target:firstnick() == param ) then
                target_firstnick = target:firstnick()
                target_ip = target:ip()
                local msg = utf_format( msg_targetip, target_firstnick, target_ip )
                user:reply( msg, hub_getbot )
                return PROCESSED
            end
        end
    end
    user:reply( msg_ip .. user_ip, hub_getbot )
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
            ucmd.add( ucmd_menu_ct1, cmd, {}, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "%[userNI]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )