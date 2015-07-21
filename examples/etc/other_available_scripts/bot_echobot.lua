--[[

        bot_echobot.lua v0.02 by blastbeat

        - this script regs a simple echo bot

        - changelog 0.02:
          - updated script api, cached table lookups
 
]]--

--// settings begin //--

local scriptname = "bot_echobot"
local scriptversion = "0.02"

local nick = "[BOT]EchoBot"
local desc = "simple test bot"
local echo = "only a machine."

--// settings end //--

local hub_getuser = hub.getuser

hub.regbot{ nick = nick, desc = desc,
    client = function( bot, cmd )
        if cmd:fourcc( ) == "EMSG" then
            local user = hub_getuser( cmd:mysid( ) )
            if not user then
                return true
            end
            user:reply( echo, bot, bot )
            end
        return true
    end
}

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )