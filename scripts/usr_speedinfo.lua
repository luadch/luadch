--[[

    usr_speedinfo.lua by blastbeat

    - Usage:   +csi <SID> <connection speed info about user>
    - Example: +csi ABED 100/10
    - Minimum permission: Default is 100.
    - Above command will permanently change the email of the user to the given connection speed info.
    - Instead of the Email, one can use any other field of the INF. This is controlled by the variable "field".

]]--

local scriptname = "usr_speedinfo"
local scriptversion = "0.01"

local minlevel = 100
local field = "EM"
local cmd = "csi"
local ucmd_menu_ct2 = { "Change Speed Info" }
local ucmd_line = "New Speed:"
local msg_denied = "You are not allowed to use this command."
local msg_fail = "User not found."
local msg_ok = "Entry changed."

local onbmsg = function( user, command, parameters )
    if user:level( ) < minlevel then
        user:reply( msg_denied, hub.getbot( ) )
        return PROCESSED
    end
    local sid, speed = utf.match( parameters, "^(%S+) (.*)" )
    local target = hub.issidonline( sid )
    if not target then
        user:reply( msg_fail, hub.getbot( ) )
        return PROCESSED
    end
    hub.sendtoall( "BINF " .. sid .. " " .. field .. hub.escapeto( speed ) .. "\n" )
    if target:isregged( ) then
        target:profile( ).speedinfo = speed
        local regs = hub.getregusers( )
        cfg.saveusers( regs )
        local inf = target:inf( )
        inf:setnp( field, speed )
    end
    user:reply( msg_ok, hub.getbot( ) )
    return PROCESSED
end

local hook_1 = function( user )
    if user:isregged( ) then
        local inf = user:inf( )
        local value = inf:getnp( field )
        local speed = user:profile( ).speedinfo or value or ""
        inf:setnp( field, speed )
    end
    return nil
end

local hook_2 = function( user, cmd )
    local value = cmd:getnp( field )
    if value then
        if user:isregged( ) then
            local speed = user:profile( ).speedinfo or value
            cmd:setnp( field, speed )
        end
    end  
    return nil
end

hub.setlistener( "onConnect", { }, hook_1 )
hub.setlistener( "onInf", { }, hook_2 )
hub.setlistener( "onStart", { },
    function( )
        local ucmd = hub.import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct2, cmd, { "%[userSID]", "%[line:" .. ucmd_line .. "]" }, { "CT2" }, minlevel )
        end
        local hubcmd = hub.import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)


hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )