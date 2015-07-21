--[[

        etc_hubcommands.lua v0.01 by blastbeat

        - this script exports a module to reg hubcommands

]]--

--// settings begin //--

--// settings end //--

local scriptname = "etc_hubcommands"
local scriptversion = "0.01"

local utf_match = utf.match

local hub_getbot = hub.getbot

local commands = { }

local add = function( cmd, func )    -- quick and dirty...
    if commands[ cmd ] then
        return false
    else
        commands[ cmd ] = func
        return true
    end
end

hub.setlistener( "onBroadcast", { },
    function( user, adccmd, txt )
        local cmd, parameters = utf_match( txt, "^[+!#](%a+) ?(.*)" )
        local func = commands[ cmd ]
        if func then
            user:reply( "[command] " .. txt, hub_getbot( ) )
            return func( user, cmd, parameters, txt )
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

--// public //--

return {

    add = add,

}