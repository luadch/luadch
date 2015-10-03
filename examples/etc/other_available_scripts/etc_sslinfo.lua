--[[

    etc_sslinfo.lua by blastbeat

        - this script sends shows the ssl infos of a user at login

]]--


local scriptname = "etc_sslinfo"
local scriptversion = "0.01"

hub.setlistener( "onLogin", { },
    function( user )
    hub.debug( "*83794659348563479076we490863045876" )
        local info = user:sslinfo()
        if info then
            local buf = "\n\nSSL INFO:\n\n"
            for field, value in pairs( info ) do
                buf = buf .. tostring( field ) .. ": " .. tostring( value ) .. "\n"
            end
            user:reply( buf, hub.getbot( ) )
        end
        return nil
    end
)

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )