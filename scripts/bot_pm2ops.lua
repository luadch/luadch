--[[

    bot_pm2ops.lua by pulsar

        v0.4:
            - check if opchat is activated
        
        v0.3:
            - removed "opchat_check"
            
        v0.2:
            - small permission fix
            - check if opchat is active (for feeds)
            
        v0.1:
            - this script regs a PmToOps Bot to send messages to OpChat

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "bot_pm2ops"
local scriptversion = "0.4"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_getbot = hub.getbot()
local hub_getuser = hub.getuser
local hub_getusers = hub.getusers
local hub_import = hub.import
local hub_debug = hub.debug
local hub_escapefrom = hub.escapefrom
local utf_format = utf.format

--// imports
local activate = cfg_get( "bot_pm2ops_activate" )
local nick = cfg_get( "bot_pm2ops_nick" )
local desc = cfg_get( "bot_pm2ops_desc" )
local permission = cfg_get( "bot_pm2ops_permission" )
local scriptlang = cfg_get( "language" )
local opchat = hub_import( "bot_opchat" )
local opchat_activate = cfg_get( "bot_opchat_activate" )

--// msgs
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this chat."
local msg_send = lang.msg_send or "Done, your message was successfully send to all Operators."
local msg_toops = lang.msg_toops or "New  %s  message  |  From: %s  |  Msg: %s"


----------
--[CODE]--
----------

if activate then
    if opchat_activate then
        local client = function( bot, cmd )
            if cmd:fourcc() == "EMSG" then
                local user = hub_getuser( cmd:mysid() )
                if not user then return true end
                local bot_nick, user_nick, user_level = bot:nick(), user:nick(), user:level()
                local msg = hub_escapefrom( cmd:pos( 4 ) )
                local msg_out = utf_format( msg_toops, bot_nick, user_nick, msg )
                if not permission[ user_level ] then
                    user:reply( msg_denied, bot, bot )
                    return true
                end
                user:reply( msg, bot, bot )
                opchat.feed( msg_out )
                user:reply( msg_send, bot, bot )
            end
            return true
        end
        local pm2ops, err = hub.regbot{ nick = nick, desc = desc, client = client }
        err = err and error( err )
    end
end

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )