--[[

    etc_hide_opchat.lua by blastbeat

]]--

local scriptname = "etc_hide_opchat"
local scriptversion = "0.01"

local opchat = hub.import( "bot_opchat" )

if not opchat then
   hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " (not active) **" )
   return
end

hub.setlistener( "onLogin", {},
    function( user )
        if user:level() < cfg.get( "bot_opchat_oplevel" ) then
           user:send( "IQUI " .. opchat.bot:sid() .. "\n")
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
