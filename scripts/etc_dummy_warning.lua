--[[

    etc_dummy_warning.lua by blastbeat

        - this script warns any level 100 user at login, if the default "dummy" account is still in the user.tbl

]]--

local scriptname = "etc_dummy_warning"
local scriptversion = "0.01"

local warning = "\n\n\n\n-----------> WARNING: Default hubowner account 'dummy' is still active! Please deactivate! <-----------\n\n\n\n"

hub.setlistener( "onLogin", {},
    function( user )
        local first_reguser = hub.getregusers()[1]
        if (first_reguser.nick == "dummy") and (first_reguser.password == "test") and (first_reguser.level == 100) and (user:level() == 100) then
           user:reply(warning, hub.getbot())
           user:reply(warning, hub.getbot(), hub.getbot()) -- send via pm too
        end
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )
