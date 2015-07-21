--[[

    cmd_slots.lua by pulsar

        usage: [+!#]slots

        v0.1:
            - this script shows all users with free slots

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_slots"
local scriptversion = "0.1"

local cmd = "slots"

local minlevel = cfg.get "cmd_slots_minlevel"


----------
--[CODE]--
----------

--// table lookups
local utf_match = utf.match
local utf_format = utf.format
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_import = hub.import
local hub_debug = hub.debug

--// imports
local help, ucmd, hubcmd

--// msgs
local scriptlang = cfg.get( "language" )
local lang, err = cfg.loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub.debug( err )

local help_title = lang.help_title or "Slots"
local help_usage = lang.help_usage or "[+!#]slots"
local help_desc = lang.help_desc or "shows users with free slots"

local ucmd_menu = lang.ucmd_menu or { "User", "Free Slots" }

local msg_out = lang.msg_out or [[


=== FREE SLOTS ====================

%s
==================== FREE SLOTS ===
  ]]


local onbmsg = function( user )
    local tbl = {}
    for sid, user in pairs( hub_getusers() ) do
        if not user:isbot() then
            local nick = user:nick()
            local slots = user:slots()
            if slots > 0 then
                tbl[ #tbl + 1 ] = "  " .. nick .. "  |  " .. slots .. "\n"
            end
        end
    end
    tbl = table.concat( tbl )
    local msg = utf_format( msg_out, tbl )
    user:reply( msg, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", { },
    function( )
        help = hub_import( "cmd_help" )
        ucmd = hub_import( "etc_usercommands" )
        hubcmd = hub_import( "etc_hubcommands" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        if ucmd then ucmd.add( ucmd_menu, cmd, {}, { "CT1" }, minlevel ) end
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )