--[[

        usr_hub_slot_ratio.lua v0.02 by blastbeat

        - this script checks the hub/slot ratio of an user

        - changelog 0.02:
          - updated script api
  
]]--

--// settings begin //--

local scriptname = "usr_hub_slot_ratio"
local scriptversion = "0.02"
local scriptlang = cfg.get "language"

local godlevel = 60    -- users with levels above won't be checked

local ratio = 1    -- hub count / slot count has to be <= ratio

--// settings end //--

local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub.debug( err )

local msg_ratio = hub.escapeto( lang.msg_ratio or "Hub/Slot ratio: " )

local check = function( user )
    local slots = user:slots( )
    local hn, hr, ho = user:hubs( )
    if slots and hn and hr and ho and ( ( ( hn + hr + ho ) / slots ) > ratio ) then
        user:kill( "ISTA 120 " .. msg_ratio .. ratio .. "\n" )
        return PROCESSED
    end
    return nil
end

hub.setlistener( "onInf", { },
    function( user, cmd )
        if user:level( ) < godlevel and ( cmd:getnp "SL" or cmd:getnp "HN" or cmd:getnp "HR" or cmd:getnp "HO" ) then
            return check( user )
        end
        return nil
    end
)

hub.setlistener( "onConnect", { },
    function( user )
        if user:level( ) < godlevel then
            return check( user )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )