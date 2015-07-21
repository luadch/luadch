--[[

        mem.lua by blastbeat

        - provides some memory managment

]]--

----------------------------------// DECLARATION //--

--// lua functions //--

local collectgarbage = use "collectgarbage"

--// functions //--

local free

--// tables //--

----------------------------------// DEFINITION //--

free = collectgarbage

----------------------------------// BEGIN //--

----------------------------------// PUBLIC INTERFACE //--

return {

    free = free,

}