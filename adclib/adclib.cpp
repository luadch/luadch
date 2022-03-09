/*
 * This code is partially copied from 
 *  - DCNet-X ADC Server Project ( http://dcnet-x.sourceforge.net )
 *  - ADCH++ ( http://sourceforge.net/projects/adchpp )
 *  - DC++ ( http://sourceforge.net/projects/dcplusplus )
 * 
 */

#include <cstdint>
#include <cstddef>
#include <string>

#include "includes.h"
#include "base32.h"
#include "tiger.h"

extern "C" {

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

}

enum {SIZE = 192/8};

int utf8ToWc(const char* str, wchar_t& c) {
        const auto c0 = static_cast<uint8_t>(str[0]);
        const auto bytes = 2 + !!(c0 & 0x20) + ((c0 & 0x30) == 0x30);

        if ((c0 & 0xc0) == 0xc0) {                  // 11xx xxxx
                                                    // # bytes of leading 1's; check for 0 next
                const auto check_bit = 1 << (7 - bytes);
                if (c0 & check_bit)
                        return -1;

                c = (check_bit - 1) & c0;

                // 2-4 total, or 1-3 additional, bytes
                // Can't run off end of str so long as has sub-0x80-terminator
                for (auto i = 1; i < bytes; ++i) {
                        const auto ci = static_cast<uint8_t>(str[i]);
                        if ((ci & 0xc0) != 0x80)
                                return -i;
                        c = (c << 6) | (ci & 0x3f);
                }

                // Invalid UTF-8 code points
                if (c > 0x10ffff || (c >= 0xd800 && c <= 0xdfff)) {
                        // "REPLACEMENT CHARACTER": used to replace an incoming character
                        // whose value is unknown or unrepresentable in Unicode
                        c = 0xfffd;
                        return -bytes;
                }

                return bytes;
        } else if ((c0 & 0x80) == 0) {             // 0xxx xxxx
                c = static_cast<unsigned char>(str[0]);
                return 1;
        } else {                                   // 10xx xxxx
                return -1;
        }
}

// NOTE: this won't handle UTF-16 surrogate pairs
void wcToUtf8(wchar_t c, std::string& str) {
        // https://tools.ietf.org/html/rfc3629#section-3
        if (c > 0x10ffff || (c >= 0xd800 && c <= 0xdfff)) {
                // Invalid UTF-8 code point
                // REPLACEMENT CHARACTER: http://www.fileformat.info/info/unicode/char/0fffd/index.htm
                wcToUtf8(0xfffd, str);
        } else if (c >= 0x10000) {
                str += (char)(0x80 | 0x40 | 0x20 | 0x10 | (c >> 18));
                str += (char)(0x80 | ((c >> 12) & 0x3f));
                str += (char)(0x80 | ((c >> 6) & 0x3f));
                str += (char)(0x80 | (c & 0x3f));
        } else if (c >= 0x0800) {
                str += (char)(0x80 | 0x40 | 0x20 | (c >> 12));
                str += (char)(0x80 | ((c >> 6) & 0x3f));
                str += (char)(0x80 | (c & 0x3f));
        } else if (c >= 0x0080) {
                str += (char)(0x80 | 0x40 | (c >> 6));
                str += (char)(0x80 | (c & 0x3f));
        } else {
                str += (char)c;
        }
}

std::string sanitizeUtf8(const std::string& str) noexcept {
        std::string tgt;
        tgt.reserve(str.length());

        const auto n = str.length();
        for (std::string::size_type i = 0; i < n; ) {
                wchar_t c = 0;
                int x = utf8ToWc(str.c_str() + i, c);
                if (x < 0) {
                        tgt.insert(i, abs(x), '_');
                } else {
                        wcToUtf8(c, tgt);
                }

                i += abs(x);
        }

        return tgt;
}

bool validateUtf8(const std::string& str) noexcept {
        std::string::size_type i = 0;
        while (i < str.length()) {
                wchar_t dummy = 0;
                int j = utf8ToWc(&str[i], dummy);
                if (j < 0)
                        return false;
                i += j;
        }
        return true;
}

int sanitize_utf8(lua_State* L)
{
    size_t length;
    std::string buf = luaL_checklstring(L, 1, &length);
    std::string result = sanitizeUtf8(buf);
    lua_pushlstring(L, result.c_str(), result.length());
    return 1;
}

int is_valid_utf8(lua_State* L)
{
    size_t length;
    std::string buf = luaL_checklstring(L, 1, &length);
    validateUtf8(buf) ? lua_pushboolean(L, 1) : lua_pushboolean(L, 0);
    return 1;
}

int hash_pid(lua_State* L)
{
    std::string pid = (std::string) luaL_checkstring(L, 1);
    unsigned char cid[SIZE];

    memset(cid, 0, sizeof(cid));
    ADCLIB::BASE32::FROMBASE32(pid.c_str(), cid, sizeof(cid));
    ADCLIB::TigerHash Tiger;
    Tiger.update(cid, SIZE);
    Tiger.finalize();
    std::string result = ADCLIB::BASE32::TOBASE32(Tiger.getResult(), ADCLIB::TigerHash::HASH_SIZE);
    lua_pushlstring(L, result.c_str(), result.length());
    return 1;
}

int hash_pas(lua_State* L)
{
    std::string password = (std::string) luaL_checkstring(L, 1);
    std::string salt = (std::string) luaL_checkstring(L, 2);
    size_t saltBytes = salt.size()*5/8;
    unsigned char chunk[saltBytes];

    memset(chunk, 0, saltBytes);
    ADCLIB::BASE32::FROMBASE32(salt.c_str(), chunk, saltBytes);
    ADCLIB::TigerHash Tiger;
    Tiger.update(password.data(), password.length());
    Tiger.update(chunk, saltBytes);
    Tiger.finalize();
    std::string result = ADCLIB::BASE32::TOBASE32(Tiger.getResult(), ADCLIB::TigerHash::HASH_SIZE);
    lua_pushlstring(L, result.c_str(), result.length());
    return 1;
}

int hash_pas_oldschool(lua_State* L)
{
    std::string password = (std::string) luaL_checkstring(L, 1);
    std::string salt = (std::string) luaL_checkstring(L, 2);
    std::string cid = (std::string) luaL_checkstring(L, 3);
    size_t saltBytes = salt.size()*5/8;
    unsigned char chunk1[saltBytes];
    unsigned char chunk2[SIZE];
    memset(chunk1, 0, saltBytes);
    memset(chunk2, 0, sizeof(chunk2));
    ADCLIB::BASE32::FROMBASE32(salt.c_str(), chunk1, saltBytes);
    ADCLIB::BASE32::FROMBASE32(cid.c_str(), chunk2, sizeof(chunk2));
    ADCLIB::TigerHash Tiger;
    Tiger.update(chunk2, SIZE);
    Tiger.update(password.data(), password.length());
    Tiger.update(chunk1, saltBytes);
    Tiger.finalize();
    std::string result = ADCLIB::BASE32::TOBASE32(Tiger.getResult(), ADCLIB::TigerHash::HASH_SIZE);
    lua_pushlstring(L, result.c_str(), result.length());
    return 1;
}

int escape(lua_State* L)
{
    std::string s = (std::string) luaL_optstring(L, 1, "");
    std::string out = "";
    out.reserve(out.length() + static_cast<size_t>(s.length()*1.1));
    std::string::const_iterator send = s.end();
    for(std::string::const_iterator i = s.begin(); i != send; ++i)
    {
        switch(*i)
        {
            case ' ': out += "\\s"; break;
            case '\n': out += "\\n"; break;
            case '\\': out += "\\\\"; break;
            default: out += *i;
        }
    }
    lua_pushlstring(L, out.c_str(), out.length());
    return 1;
}

int unescape(lua_State* L)
{
    std::string s = (std::string) luaL_optstring(L, 1, "");
    std::string out = "";
    out.reserve(out.length() + static_cast<size_t>(s.length()*1.1));
    std::string::const_iterator send = s.end();
    for(std::string::const_iterator i = s.begin(); i != send; ++i)
    {
        switch(*i)
        {
            case '\\':
                if ((i + 1) != send)
                {
                    ++i;
                    if ('s' == *i)
                        out += ' ';
                    if ('n' == *i)
                        out += '\n';
                    if ('\\' == *i)
                        out += '\\';
                }
                break;
            default: out += *i;
        }
    }
    lua_pushlstring(L, out.c_str(), out.length());
    return 1;
}

static const luaL_reg adclib[] = {
    {"hash", hash_pid},
    {"hashpas", hash_pas},
    {"hasholdpas", hash_pas_oldschool},
    {"escape", escape},
    {"unescape", unescape},
    {"isutf8", is_valid_utf8},
    {"sanitize_utf8", sanitize_utf8},
    {NULL, NULL}
};

extern "C" int luaopen_adclib(lua_State* L)
{
    luaL_register(L, "adclib", adclib);
    return 0;
}

