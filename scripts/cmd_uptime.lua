--[[

	cmd_uptime.lua by Night

        usage: [+!#]uptime

        v0.7: by pulsar
            - changes in get_hubuptime() and get_hubruntime()
        
        v0.6: by pulsar
            - using new luadch date style
        
        v0.5: by pulsar
            - shows the complete hub runtime since the first hubstart
        
        v0.4: by pulsar
            - improved get_hubuptime() and get_lastconnect() function
        
        v0.3: by pulsar
            - add users uptime
            - change output style
            - code cleanup

        v0.2: by pulsar
            - added multilanguage support
            - completed some code

        v0.1: by Night
            - adds uptime command

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "cmd_uptime"
local scriptversion = "0.7"

local cmd = "uptime"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local cfg_get = cfg.get
local cfg_loadlanguage = cfg.loadlanguage
local hub_import = hub.import
local hub_debug = hub.debug
local hub_getbot = hub.getbot()
local signal_get = signal.get
local os_time = os.time
local os_difftime = os.difftime
local utf_format = utf.format
local util_formatseconds = util.formatseconds
local util_loadtable = util.loadtable
local math_floor = math.floor
local util_date = util.date
local util_difftime = util.difftime

--// imports
local help, hubcmd
local minlevel = cfg_get( "cmd_uptime_minlevel" )
local scriptlang = cfg_get( "language" )
local lang, err = cfg_loadlanguage( scriptlang, scriptname ); lang = lang or {}; err = err and hub_debug( err )

--// msgs
local help_title = lang.help_title or "uptime"
local help_usage = lang.help_usage or "[+!#]uptime"
local help_desc = lang.help_desc or "Show hub uptime"
local msg_denied = lang.msg_denied or "You are not allowed to use this command."
local msg_years = lang.msg_years or " years, "
local msg_days = lang.msg_days or " days, "
local msg_hours = lang.msg_hours or " hours, "
local msg_minutes = lang.msg_minutes or " minutes, "
local msg_seconds = lang.msg_seconds or " seconds"
local msg_unknown = lang.msg_unknown or "<unknown>"
local msg_uptime = lang.msg_uptime or [[


=== UPTIME ==========================================================

                  Hub uptime (complete):  %s
                  Hub uptime (session):  %s
                  
                  Your uptime:  %s

========================================================== UPTIME ===
  ]]


----------
--[CODE]--
----------

local formatdays = function( d )
    return math_floor( d / 365 ), math_floor( d ) % 365
end
    
local get_lastconnect = function( user )
    local lastconnect
    local profile = user:profile()
    local lc = profile.lastconnect
    local lc_str = tostring( lc )
    if not lc then
        lastconnect = msg_unknown
    else
        if #lc_str == 14 then
            local sec, y, d, h, m, s = util_difftime( util_date(), lc )
            lastconnect = y .. msg_years .. d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        else
            local d, h, m, s = util_formatseconds( os_difftime( os_time(), lc ) )
            lastconnect = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
        end
    end
    return lastconnect
end

local get_hubuptime = function()
    local hubuptime
    local start = signal_get( "start" ) or os_time()
    if not start then
        hubuptime = msg_unknown
    else
        local d, h, m, s = util_formatseconds( os_difftime( os_time(), start ) )
        if d > 365 then
            local years, days = formatdays( d )
            d = years .. msg_years .. days
        else
            d = "0" .. msg_years .. d
        end
        hubuptime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    end
    return hubuptime
end

local get_hubruntime = function()
    local hci_tbl = util_loadtable( "core/hci.lua" )
    local hubruntime = hci_tbl.hubruntime
    local d, h, m, s = util_formatseconds( hubruntime )
    if d > 365 then
        local years, days = formatdays( d )
        d = years .. msg_years .. days
    else
        d = "0" .. msg_years .. d
    end
    hubruntime = d .. msg_days .. h .. msg_hours .. m .. msg_minutes .. s .. msg_seconds
    return hubruntime
end

local onbmsg = function( user )
    local user_level = user:level()
    if user_level < minlevel then
        user:reply( msg_denied, hub_getbot )
        return PROCESSED
    end
	local msg = utf_format( msg_uptime, get_hubruntime(), get_hubuptime(), get_lastconnect( user ) )
    user:reply( msg, hub_getbot )
    return PROCESSED
end

hub.setlistener( "onStart", {},
    function( )
        help = hub_import( "cmd_help" )
        if help then help.reg( help_title, help_usage, help_desc, minlevel ) end
        hubcmd = hub_import( "etc_hubcommands" )
        assert( hubcmd )
        assert( hubcmd.add( cmd, onbmsg ) )
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )