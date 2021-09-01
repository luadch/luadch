--[[

    etc_dummy_warning.lua by blastbeat

        - this script warns any level 100 user at login, if the default "dummy" account is still in the user.tbl

        v0.02: by pulsar
            - fix #103
                - add lang support

]]--

local scriptname = "etc_dummy_warning"
local scriptversion = "0.02"

--// imports
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local warning = lang.warning or [[


=== WARNING ============================================================

               Default hubowner account 'dummy' is still active! Please deactivate!

============================================================ WARNING ===
  ]]

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