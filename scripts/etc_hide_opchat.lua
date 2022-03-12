--[[

    etc_hide_opchat.lua by blastbeat

        v0.02: by pulsar
            - added onStart listener; Fix #73


]]--

local scriptname = "etc_hide_opchat"
local scriptversion = "0.02"

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

hub.setlistener( "onStart", {},
    function()
        for sid, user in pairs( hub.getusers() ) do
            if not user:isbot() and user:level() < cfg.get( "bot_opchat_oplevel" ) then
                user:send( "IQUI " .. opchat.bot:sid() .. "\n")
            end
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )