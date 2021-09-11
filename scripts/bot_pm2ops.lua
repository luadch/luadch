--[[

    bot_pm2ops.lua by pulsar

        v0.6: by pulsar
            - removed table lookups

        v0.5: by blastbeat:
            - simplify 'activate' logic

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
local scriptversion = "0.6"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// imports
local activate = cfg.get( "bot_pm2ops_activate" )
local nick = cfg.get( "bot_pm2ops_nick" )
local desc = cfg.get( "bot_pm2ops_desc" )
local permission = cfg.get( "bot_pm2ops_permission" )
local scriptlang = cfg.get( "language" )
local opchat = hub.import( "bot_opchat" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local msg_denied = lang.msg_denied or "You are not allowed to use this chat."
local msg_send = lang.msg_send or "Done, your message was successfully send to all Operators."
local msg_toops = lang.msg_toops or "New  %s  message  |  From: %s  |  Msg: %s"


----------
--[CODE]--
----------

if (not activate) or (not opchat) then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

local client = function( bot, cmd )
    if cmd:fourcc() == "EMSG" then
        local user = hub.getuser( cmd:mysid() )
        if not user then return true end
        local bot_nick, user_nick, user_level = bot:nick(), user:nick(), user:level()
        local msg = hub.escapefrom( cmd:pos( 4 ) )
        local msg_out = utf.format( msg_toops, bot_nick, user_nick, msg )
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

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )