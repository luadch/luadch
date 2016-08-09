--[[

    etc_ccpmblocker2.0.lua by blastbeat
        
        v2.0

            - This script controls the CCPM - Client to Client Private Message feature, but this time more clever.
            - It works like this: all users get their CCPM flag removed by default.
            - If two users are above op_level, and support both CCPM, and message each other, then CCPM flags will be send to both.
            - After that, CCPM can be established. So a user just needs to check, whether CCPM is available, after the first sent message.

]]--

local scriptname = "etc_ccpmblocker2.0"
local scriptversion = "2.0"

local op_level = 0

local tmp = { }
setmetatable( tmp, { __mode = "kv" } )      -- we need a weak table here

local remove_ccpm = function( user, cmd, su )
    local user_level = user:level( )
    local s, e = string.find( su, "CCPM" )
    if s then
        local new_su
        local l = #su
        if e < l then
            new_su = su:gsub( "CCPM,", "" )
        else
            new_su = su:gsub( ",CCPM", "" )
        end
        cmd:setnp( "SU", new_su )
    end
end

local inf_listener = function( user, cmd )
    local su = cmd:getnp "SU"
    if su then
        remove_ccpm( user, cmd, su )        -- remove CCPM from all users by default on inf
    end
    return nil
end

local connect_listener = function( user )
    local cmd = user:inf( )
    local su = cmd:getnp "SU"
    if su then
        remove_ccpm( user, cmd, su )        -- remove CCPM from all users by default on connect
    end
    return nil
end

local exchange = function( user, targetuser, adccmd )
    if tmp[ user ] ~= targetuser then
        if ( user:level( ) >= op_level ) and ( targetuser:level( ) >= op_level ) and ( user:hasccpm( ) and targetuser:hasccpm( ) ) then       -- if both users are above op_level, we simply send them their CCPM flags
            local usid, tsid = user:sid( ), targetuser:sid( )
            user:send( "BINF " .. tsid .. " SU" .. user:features( ) .. ",CCPM\n" )
            targetuser:send( "BINF " .. usid .. " SU" .. targetuser:features( ) .. ",CCPM\n" )
            tmp[ user ] = targetuser
            tmp[ targetuser ] = user        -- cache results, we dont want to send INFs each time they write a message
        end
    end
end

hub.setlistener( "onConnect", { }, connect_listener )
hub.setlistener( "onInf", { }, inf_listener )
hub.setlistener( "onPrivateMessage", { }, exchange )
hub.setlistener( "onSearchResult", { }, exchange )
hub.setlistener( "onRevConnectToMe", { }, exchange )
hub.setlistener( "onConnectToMe", { }, exchange )

hub.debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )