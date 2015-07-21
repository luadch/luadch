--[[

        pre.lua by blastbeat

        - this script prepares the core files ( for debug/release mode )

]]--

----------------------------------// DECLARATION //--

--// lua lib methods //--

local open = io.open
local gsub = string.gsub

--// tables //--

local _core

----------------------------------// DEFINITION //--

_core = {    -- luadch core

    "adc",
    "hub",
    "server",
    "scripts",

}

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

     processor = function( release )
        local pattern, repl = "\n%-%-([^\n]*)out_put", "\n%1out_put"
        if release then
            pattern, repl = "\n([^\n]*)out_put", "\n--%1out_put"
        end
        for i, script in ipairs( _core ) do
            local file, err = open( "core/" .. script .. ".lua", "r" )
            assert( file, err )
            local chunk = file:read( "*a" )
            file:close( )
            file, err = open( "core/" .. script .. ".lua", "w+" )
            assert( file, err )
            chunk = gsub( chunk, pattern, repl )
            file:write( chunk )
            file:close( )
        end
    end

}