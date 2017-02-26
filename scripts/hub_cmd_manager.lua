--[[

        hub_cmd_manager.lua v0.02 by blastbeat

        - this script mangages permissions for certain adc commands

        v0.02: by blastbeat (20170226)
            - added blacklist and onIncoming hook

]]--

local scriptname = "hub_cmd_manager"
local scriptversion = "0.02"

--// min levels to use a command //--

local ctmlevel = 0
local rcmlevel = 0
local schlevel = 0
local reslevel = 0
local msglevel = 0    -- mainchat message
local dmsglevel = 0    -- pm message

local blacklist = { }    -- forbidden cmds

blacklist.EINF = true
blacklist.DINF = true
blacklist.FINF = true
blacklist.BQUI = true
blacklist.FQUI = true
blacklist.EQUI = true
blacklist.DQUI = true
blacklist.FRES = true
blacklist.BRES = true
blacklist.ERES = true

hub.setlistener( "onIncoming", { },
    function( t, cmd, adccmd, user, targetuser )
        local fourcc = adccmd:fourcc( )
        if blacklist[ fourcc ] then
             user.write( "ISTA 125 FC" .. fourcc .. "\n" )
            return PROCESSED
        end
        return nil
    end
)

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

hub.debug( "** Loaded ".. scriptname .. " " .. scriptversion .. " **" )