--[[

        hub_cmd_manager.lua v0.01 by blastbeat

        - this script mangages permissions for certain adc commands

]]--

local scriptname = "hub_cmd_manager"
local scriptversion = "0.01"

--// min levels to use a command //--

local ctmlevel = 0
local rcmlevel = 0
local schlevel = 0
local reslevel = 0
local msglevel = 0    -- mainchat message
local dmsglevel = 0    -- pm message

hub.setlistener( "onBroadcast", { },
    function( user )
        if user:level( ) < msglevel then
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onPrivateMessage", { },
    function( user )
        if user:level( ) < dmsglevel then
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onConnectToMe", { },
    function( user )
        if user:level( ) < ctmlevel then
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onRevConnectToMe", { },
    function( user )
        if user:level( ) < rcmlevel then
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onSearch", { },
    function( user )
        if user:level( ) < schlevel then
            return PROCESSED
        end
        return nil
    end
)

hub.setlistener( "onSearchResult", { },
    function( user )
        if user:level( ) < reslevel then
            return PROCESSED
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )