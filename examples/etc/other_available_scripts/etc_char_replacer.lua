--[[

        etc_char_replacer.lua v0.01 by blastbeat

        - this script replaces chars of incoming messages and exports a module for other scripts
 
]]--

--// settings begin //--

local scriptname = "etc_char_replacer"
local scriptversion = "0.01"

local char_table = {

    a = "α",
    b = "в",
    c = "c",
    d = "d",
    e = "ε",
    f = "ƒ",
    g = "g",
    h = "h",
    i = "ι",
    j = "j",
    k = "κ",
    l = "l",
    m = "m",
    n = "η",
    o = "σ",
    p = "þ",
    q = "q",
    r = "r",
    s = "ѕ",
    t = "†",
    u = "υ",
    v = "ν",
    w = "ω",
    x = "χ",
    y = "γ",
    z = "z",

    A = "Å",
    B = "В",
    C = "Ĉ",
    D = "Ð",
    --E = "€",
    F = "Ғ",
    --G
    --H
    --I
    --J
    K = "К",
    --L
    --M
    --N
    O = "Ө",
    --P
    Q = "Ω",
    R = "Ř",
    S = "Ŝ",
    --T
    U = "Ụ",
    --V
    --W
    X = "Χ",
    --Y
    --Z

}

--// settings end //--

local utf_gsub = utf.gsub

local hub_broadcast = hub.broadcast

local replace = function( char )
    return char_table[ char ] or char
end

hub.setlistener( "onBroadcast", { },
    function( user, cmd, txt )
        hub_broadcast( utf_gsub( txt, "%S", replace ), user )
        return PROCESSED
    end
)

hub.debug( "** Loaded "..scriptname.." "..scriptversion.." **" )

--// public //--

return {

    replacer = function( txt )
        return utf_gsub( txt, "%S", replace )
    end,

}