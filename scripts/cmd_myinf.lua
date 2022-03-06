--[[

    cmd_myinf.lua by pulsar

        usage: [+!#]myinf [<NICK>]

        v0.1: by blastbeat
            - Improve formatting

        v0.1:
            - Shows client INF from a user or yourself

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_myinf"
local scriptversion = "0.1"

local cmd = "myinf"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_getbot = hub.getbot()
local hub_debug = hub.debug
local hub_import = hub.import
local hub_isnickonline = hub.isnickonline
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local utf_match = utf.match
local utf_format = utf.format
local util_getlowestlevel = util.getlowestlevel
local table_concat = table.concat

--// imports
local help, ucmd, hubcmd
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or { }; err = err and hub_debug( err )
local permission = cfg_get( "cmd_myinf_permission" )

--// msgs
local help_title = lang.help_title or "cmd_myinf.lua"
local help_usage = lang.help_usage or "[+!#]myinf [<NICK>]"
local help_desc = lang.help_desc or "Shows client INF from a user or yourself"

local ucmd_menu_ct1 = lang.ucmd_menu_ct1 or { "About You", "show Client INF" }
local ucmd_menu_ct2 = lang.ucmd_menu_ct2 or { "Show", "Client INF" }

local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_unknown = lang.msg_unknown or "unknown"
local msg_inf = lang.msg_inf or [[


=== USER CLIENT INF ===============================================================

User: %s

%s
=============================================================== USER CLIENT INF ===
  ]]


----------
--[CODE]--
----------

local minlevel = util_getlowestlevel( permission )

local get_inf = function( target )
    local target_inf = target:inf()
    local buf = "SID: " .. target_inf[4] .. "\n"
    for i = 6, #target_inf, 3 do
        buf = buf .. target_inf[i] .. ": " .. hub.escapefrom( ( target_inf[i + 1] or "" ) ) .. "\n"
    end    
    return buf
end

local onbmsg = function( user, command, parameters )
    local user_level = user:level()
    if not permission[ user_level ] then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
    local param = utf_match( parameters, "^(%S+)$" )
    if param then
        local target = hub_isnickonline( param )
        if target then
            user:reply( utf_format( msg_inf, target:nick(), get_inf( target ), hub_getbot ) )
            return PROCESSED
        end
    end
    user:reply( utf_format( msg_inf, user:nick(), get_inf( user ), hub_getbot ) )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function()
        help = hub_import( "cmd_help" )
        if help then
            help.reg( help_title, help_usage, help_desc, minlevel )
        end
        ucmd = hub_import( "etc_usercommands" )
        if ucmd then
            ucmd.add( ucmd_menu_ct1, cmd, {}, { "CT1" }, minlevel )
            ucmd.add( ucmd_menu_ct2, cmd, { "%[userNI]" }, { "CT2" }, minlevel )
        end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )