--[[

    cmd_talk.lua by pulsar

        description: sends your msg without nickname

        usage: [+!#]talk <MSG>

        v1.0:
            - small fix  / thx Sopor
            - added description/usage to comment
            - using "onbmsg" function instead of "onBroadcast" listener

        v0.9:
            - added "msg_usage"
            - send "msg_usage" on missing param  / thx Sopor

        v0.8:
            - possibility to 'talk' in regchat and opchat, according with talk and chat permissions
            - add new table lookups and imports
            - code cleaning

        v0.7:
            - changed rightclick style

        v0.6:
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.5:
            - code cleaning

        v0.4:
            - Multilanguage Support
            - includet to rev279

        v0.3:
            - code cleaning
            - added: Help Feature (hub.import "cmd_help")

        v0.2:
            - sends your msg without nickname

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_talk"
local scriptversion = "1.0"

local cmd = "talk"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_debug = hub.debug
local hub_import = hub.import
local hub_broadcast = hub.broadcast
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local utf_match = utf.match

--// imports
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local minlevel = cfg_get( "cmd_talk_minlevel" )
local regchat = hub_import( "bot_regchat" )
local regchat_nick = cfg_get( "bot_regchat_nick" )
local regchat_activate = cfg_get( "bot_regchat_activate" )
local regchat_permission = cfg_get( "bot_regchat_permission" )
local opchat = hub_import( "bot_opchat" )
local opchat_nick = cfg_get( "bot_opchat_nick" )
local opchat_activate = cfg_get( "bot_opchat_activate" )
local opchat_permission = cfg_get( "bot_opchat_permission" )

--// msgs
local help_title = lang.help_title or "cmd_talk.lua"
local help_usage = lang.help_usage or "[+!#]talk <MSG>"
local help_desc = lang.help_desc or "Talk without nickname"

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local ucmd_menu = lang.ucmd_menu or { "User", "Messages", "Talk" }
local ucmd_what = lang.ucmd_what or "Message:"
local msg_usage = lang.msg_usage or "Usage: [+!#]talk <MSG>"


----------
--[CODE]--
----------

local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(%S+)$" )
    if param then
        hub_broadcast( param, hub_getbot )
        return PROCESSED
    end
    user:reply( msg_usage, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onPrivateMessage", {},
    function( user, target, adccmd, msg )
        local cmd1, cmd2 = utf_match( msg, "^[+!#](%a+) (.+)" )
        local user_level = user:level()
        local target_level = target:level()
        local target_nick = target:nick()
        if cmd1 == cmd and cmd2 then
            if target_nick == regchat_nick then
                if regchat_activate then
                    if ( ( user_level >= minlevel ) and regchat_permission[ user_level ] ) then
                        regchat.feed( cmd2 )
                    else
                        user:reply( msg_denied, hub_getbot, target )
                    end
                    return PROCESSED
                end
            end
            if target_nick == opchat_nick then
                if opchat_activate then
                    if ( ( user_level >= minlevel ) and opchat_permission[ user_level ] ) then
                        opchat.feed( cmd2 )
                    else
                        user:reply( msg_denied, hub_getbot, target )
                    end
                    return PROCESSED
                end
            end
        end
        return nil
    end
)

hub.setlistener( "onStart", {},
    function()
        local help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        local ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu, cmd, { "%[line:" .. ucmd_what .. "]" }, { "CT1" }, minlevel )
        end
        local hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )