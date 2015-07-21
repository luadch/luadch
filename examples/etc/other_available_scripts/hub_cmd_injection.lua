--[[

	hub_cmd_injection by pulsar

        v0.3
            - added hub.reloadusers() function to hub_commands()
            
        v0.2
            - Die "core/hci.lua" ist absofort eine Tabelle, macht die Sache performanter
            - "check_usercount" Funktion
                - Ermittelt die aktuelle Useranzahl und schreibt sie in die "hci.lua"
            - "check_hubshare" Funktion
                - Ermittelt den aktuellen Hubshare und schreibt ihn in die "hci.lua"

        v0.1
            - Befehls-Brücke zwischen Luadch GUI und Luadch
            - Ermöglicht es über die GUI einen "reload", "restart", "shutdown" auszuführen


        PS: Dies ist kein normales "Feature-Skript", also bitte nichts verändern!

]]--


--------------
--[SETTINGS]--
--------------

local scriptname = "hub_cmd_injection"
local scriptversion = "0.3"

local msg_reload = "*** Luadch GUI Command -> RELOAD"
local msg_restart = "*** Luadch GUI Command -> RESTART"
local msg_shutdown = "*** Luadch GUI Command -> SHUTDOWN"


----------
--[CODE]--
----------

local time = 2 --> sec
local delay = time
local os_time = os.time
local os_difftime = os.difftime
local start = os_time()
local hub_getbot = hub.getbot()
local hub_getusers = hub.getusers
local hub_broadcast = hub.broadcast
local util_loadtable = util.loadtable
local util_savetable = util.savetable
local hci_tbl, hub_commands, check_usercount, check_hubshare, hshare, ushare

local hci_file = "core/hci.lua"

hub_commands = function()
    hci_tbl = util_loadtable( hci_file )
    if hci_tbl.reload then
        hci_tbl.reload = false
        util_savetable( hci_tbl, "hci_tbl", hci_file )
        hub_broadcast( msg_reload, hub_getbot )
        hub.reloadusers()
        hub.reloadcfg()
        hub.restartscripts()
    end
    if hci_tbl.restart then
        hci_tbl.restart = false
        util_savetable( hci_tbl, "hci_tbl", hci_file )
        hub_broadcast( msg_restart, hub_getbot )
        hub.restart()
    end
    if hci_tbl.shutdown then
        hci_tbl.shutdown = false
        util_savetable( hci_tbl, "hci_tbl", hci_file )
        hub_broadcast( msg_shutdown, hub_getbot )
        hub.exit()
    end
end

check_usercount = function()
    hci_tbl = util_loadtable( hci_file )
    local users, _, _ = hub_getusers()
    local count = 0
    for key, value in pairs( users ) do
        count = count + 1
    end
    hci_tbl.usercount = count
    util_savetable( hci_tbl, "hci_tbl", hci_file )
end

check_hubshare = function()
    hci_tbl = util_loadtable( hci_file )
    hshare = 0
    for sid, user in pairs( hub_getusers() ) do
        if not user:isbot() then
            ushare = user:share() or 0
            hshare = hshare + ushare
        end
    end
    hci_tbl.hubshare = hshare
    util_savetable( hci_tbl, "hci_tbl", hci_file )
end

hub.setlistener( "onTimer", {},
    function()
        if os_difftime( os_time() - start ) >= delay then
            hub_commands()
            check_usercount()
            check_hubshare()
            start = os_time()
        end
        return nil
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

---------
--[END]--
---------
