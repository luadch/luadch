--[[

    usr_slots.lua by blastbeat

        - this script checks the slots of an user

        v0.08: by pulsar
            - changed visuals
            - removed table lookups

        v0.07: by pulsar
            - added "usr_slots_redirect"
                - use redirect instead of disconnect

        v0.06: by pulsar
            - improved user:kill()

        v0.05: by pulsar
            - using min/max slots tables to check slots separate for each level
            - add table lookups
            - code cleaning

        v0.04: by pulsar
            - export scriptsettings to "/cfg/cfg.tbl"

        v0.03: by blastbeat
            - updated script api

        v0.02: by blastbeat
            - added language files

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "usr_slots"
local scriptversion = "0.08"

--// imports
local scriptlang = cfg.get( "language" )
local min_slots = cfg.get( "min_slots" )
local max_slots = cfg.get( "max_slots" )
local usr_slots_redirect = cfg.get( "usr_slots_redirect" )
local redirect_url = cfg.get( "cmd_redirect_url" )

--// msgs
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )
local msg_slotlimits = lang.msg_slotlimits or "[ USER SLOTS ]--> Hub min slots:  %s  |  Hub max slots:  %s  |  Your slots:  %s"
local msg_redirect = lang.msg_redirect or "[ USER SLOTS ]--> You got redirected because:  "


----------
--[CODE]--
----------

local check = function( user )
    local user_level = user:level()
    local user_slots = user:slots()
    local min = min_slots[ user_level ]
    local max = max_slots[ user_level ]
    if ( user_slots < min ) or ( user_slots > max ) then
        if usr_slots_redirect then
            local msg_out = hub.escapeto( utf.format( msg_slotlimits, min, max, user_slots ) )
            local msg_redirect = hub.escapeto( msg_redirect )
            user:redirect( redirect_url, msg_redirect .. msg_out )
            return PROCESSED
        else
            local msg_out = hub.escapeto( utf.format( msg_slotlimits, min, max, user_slots ) )
            user:kill( "ISTA 120 " .. msg_out .. "\n", "TL300" )
            return PROCESSED
        end
    end
    return nil
end

hub.setlistener( "onInf", {},
    function( user, cmd )
        if cmd:getnp "SL" then
            return check( user )
        end
        return nil
    end
)

hub.setlistener( "onConnect", {},
    function( user )
        return check( user )
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )