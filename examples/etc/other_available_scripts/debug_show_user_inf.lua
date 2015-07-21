
--[[

    debug_show_user_inf.lua by pulsar

        v0.1

            - shows INF flags

    PS: als vorletztes Skript in die cfg.tbl eintragen!

]]--


----------------
--[ SETTINGS ]--
----------------

local scriptname = "debug_show_user_inf"
local scriptversion = "0.1"

local levelcheck = { --> checks users by level (yes=true/no=false)

    [ 0 ] = true,  --> unreg
    [ 10 ] = true,  --> guest
    [ 20 ] = true,  --> reg
    [ 30 ] = true,  --> vip
    [ 40 ] = true,  --> svip
    [ 50 ] = true,  --> server
    [ 60 ] = true,  --> operator
    [ 70 ] = true,  --> supervisor
    [ 80 ] = true,  --> admin
    [ 100 ] = true,  --> hubowner

}

--> show user inf to op's
local oplevel = 100
local op_report_main = false
local op_report_pm = true

--> show user inf to himself?
local user_report = false
local user_report_main = false
local user_report_pm = true

local sep = "\t====================================================="

local msg1 = "\n\n\t    user:inf()   von   "
local msg2 = ":\n\n\t    "


------------
--[ CODE ]--
------------

local showINF = function( user )    
    local user_inf = user:inf()
    local show_inf = table.concat( user_inf , "\n\t    ", 1, user_inf.length )
    
    local user_nick = user:nick( )
    local user_level = user:level( )
    local hub_getbot = hub.getbot( )
    local hub_getusers = hub.getusers( )
    
    if levelcheck[ user_level ] then
        for sid, user in pairs( hub_getusers ) do
            local opuser = user:level()
            if opuser >= oplevel then
                if op_report_main then
                    user:reply( "\n\n\n" .. sep .. msg1 .. user_nick .. msg2 .. show_inf .. sep .. "\n\n", hub_getbot )
                end
                if op_report_pm then
                    user:reply( "\n\n\n" .. sep .. msg1 .. user_nick .. msg2 .. show_inf .. sep .. "\n\n", hub_getbot, hub_getbot )
                end
            end
        end
        if user_report then
            if user_report_main then
                user:reply( "\n\n\n" .. sep .. msg1 .. user_nick .. msg2 .. show_inf .. sep .. "\n\n", hub_getbot )
            end
            if user_report_pm then
                user:reply( "\n\n\n" .. sep .. msg1 .. user_nick .. msg2 .. show_inf .. sep .. "\n\n", hub_getbot, hub_getbot )
            end
        end
    end
    return nil
end

hub.setlistener( "onLogin", {}, showINF )
--hub.setlistener( "onInf", {}, showINF )

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

-----------
--[ END ]--
-----------