--[[

        hub_keeping_alive.lua v0.04 by blastbeat

        - this script sends in regular intervals an empty message to all connected clients

        - changelog 0.04:
          - updated script api

        - changelog 0.03:
          - hub sends faked DCTM's now to trigger a response

        - changelog 0.02:
          - complete rewrote, first version did nothing useful
 
]]--

--// settings begin //--

local scriptname = "hub_keeping_alive"
local scriptversion = "0.04"

local ipdelay = 10    -- time in seconds to check ip change of the hub

local ghostdelay = 60    -- seconds; when a client doesn't send any data in this time, it will be considered as ghost

local hubaddress = cfg.get "hub_hostaddress" or "your.hub.addy.no-ip.org"    -- your extern hub address (hostname)

--// settings end //--

local os_time = os.time
local os_difftime = os.difftime

local ipof = socket.dns.toip

local hub_getusers = hub.getusers

local iptime = os_time( )
local ghosttime = os_time( )

local hubip

local hubbotsid = hub.getbot( ).sid( )

hub.setlistener( "onTimer", { },
    function( )
        local time = os_time( )
        if os_difftime( time - iptime ) >= ipdelay then
            local ip = ipof( hubaddress )
            hubip = hubip or ip
            if hubip ~= ip then    -- ip of hub has changed, kill all users
                local _, _, allusers = hub_getusers( )
                for sid, user in pairs( allusers ) do
                    if not user:isbot( ) then
                        user.kill( )
                    end
                end
                hubip = ip
            end
            iptime = time
        end
        return nil
    end
)

hub.setlistener( "onTimer", { },
    function( )
        local time = os_time( )
        if os_difftime( time - ghosttime ) >= ghostdelay then
            local _, _, allusers = hub_getusers( )
            for sid, user in pairs( allusers ) do
                if not user.alive then    -- user seems to be a ghost
                    user.kill( )
                elseif not user:isbot( ) then
                    user.alive = nil
                    user.write( "DCTM " .. hubbotsid .. " " .. user:sid( ) .. " ADC/0.10 1 T\n" )
                end
            end
            ghosttime = time
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )