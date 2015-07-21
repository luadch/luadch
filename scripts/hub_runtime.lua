--[[

    hub_runtime.lua by pulsar

        v0.3:
            - small fix

        v0.2:
            - using new luadch date style

        v0.1:
            - saves the hub runtime

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_runtime"
local scriptversion = "0.3"

local file = "core/hci.lua"


----------------------------
--[DEFINITION/DECLARATION]--
----------------------------

--// table lookups
local hub_debug = hub.debug
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local util_date = util.date
local util_difftime = util.difftime
local util_convertepochdate = util.convertepochdate
local os_time = os.time
local os_difftime = os.difftime


----------
--[CODE]--
----------

local minutes = 5
local delay = minutes * 60
local start = os_time()

local set_hubruntime = function()
    local hci_tbl = util_loadtable( file )
    local hrt = hci_tbl.hubruntime
    local hrt_lc = hci_tbl.hubruntime_last_check
    if hrt_lc == 0 then hrt_lc = util_date() end
    local hrt_lc_str = tostring( hrt_lc )
    if #hrt_lc_str ~= 14 then hrt_lc = util_convertepochdate( hrt_lc ) end
    local sec, y, d, h, m, s = util_difftime( util_date(), hrt_lc )
    local new_time = hrt + sec
    hci_tbl.hubruntime = new_time
    hci_tbl.hubruntime_last_check = util_date()
    util_savetable( hci_tbl, "hci_tbl", file )
end

hub.setlistener( "onTimer", {},
    function()
        if os_difftime( os_time() - start ) >= delay then
            set_hubruntime()
            start = os_time()
        end
        return nil
    end
)

hub_debug( "** Loaded " .. scriptname .. " " .. scriptversion .. " **" )