--[[

        signal.lua by blastbeat

        - this script provides "communication" for other scripts

]]--

----------------------------------// DECLARATION //--

--// functions //--

local getsignal
local setsignal

--// tables //--

local _signals

----------------------------------// DEFINITION //--

_signals = { }

getsignal = function( signal )
    return _signals[ signal ]
end

setsignal = function( signal, status )
    _signals[ signal ] = status
end

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

    get = getsignal,
    set = setsignal,

}
