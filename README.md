# Luadch - ADC Hub Server
[![Latest-Release](https://img.shields.io/github/v/release/luadch/luadch?include_prereleases)](https://github.com/luadch/luadch/releases)
[![GitHub license](https://img.shields.io/badge/license-GPLv3.0-blueviolet.svg)](https://github.com/luadch/luadch/blob/master/LICENSE)
[![Website](https://img.shields.io/website?down_message=offline&up_message=online&url=https%3A%2F%2Fluadch.github.io)](https://luadch.github.io/)
[![Platform](https://img.shields.io/badge/Platform-independend-orange.svg)](https://luadch.github.io/)

## Features:

    - Encryption, AES128 and AES256 cipher suites with TLSv1.3 support
    - Fast, stable and small (complete server has ~3 MB)
    - Supports ARM architecture
    - Easy to use Lua Scripting API
    - Many additional scripts available
    - Comfortable rightclick menu

## To run a Luadch Hub:

* Without encryption, start the Hub and login with:
```
    Nick: dummy
    Password: test
    Address: adc://127.0.0.1:5000
```
* With encryption:

    - go to: *“certs/”* and start *“make_cert.sh”* on Linux/Unix or *“make_cert.bat”* on Windows to generate the certificates
    - alternatively you can use the *Luadch Certmanager*
    - after that you can login with:
```
       Nick: dummy
       Password: test
       Address: adcs://127.0.0.1:5001
```
3. Register an own nickname for you, there are two possibilities to do that:

    - use rightclick menu: *User/Control/Reg*
    - use command: *+reg nick* ```<Nick>``` ```<Level>```

    Where ```<Nick>``` is your new nickname and ```<Level>``` should be the highest level *100*

4. Now delete the dummy account, there are two possibillities to do that:

    - use rightclick menu: *User/Control/Delreg*
    - use command: *+delreg nick* ```<Nick>```

5. After this first test you should adapt the hub to your needs:

    - open: *“cfg/cfg.tbl”* with a UTF-8 compatible Texteditor best with Lua syntax highlighting
    - Read the descriptions and set the values to your need, Luadch uses a fair and reasonable default user permissions, but nevertheless you should read all

6. If it's done, start your hub again and login, if he still runs there are two possibillities to enable your changes in the hub:

    - use rightclick menu: *Hub/Core/Hub reload*
    - use command: *+reload*

7. If you want to set other styles for lines or something:

    - go to: *“scripts/lang/”* here you can find all language files for each script, after that: *+reload*

### Done


## Note:

If you compiling the source from a Windows x64 host you need to know:
There is a 32bit/64bit bug in the Microsoft *"msvcrt"*, the size of *"time_t"* in *os.difftime()* was not
interpreted correctly. if you skirt this issue use the precompiled *"lua/tmp/lua.dll"*. if you want to
know more about this problem read this: [Marshunt article link](http://www.marshut.com/ikhziq/building-on-windows-from-scratch.html#inrpiz)


## How to make a Win32 + Linux/Unix Hybrid version

With Luadch you have the possibility to make a Hybrid version who runs on Win32 systems and one Linux/Unix system of your choice.
This could be very useful if:

- your "online" Hub runs on a Linux/Unix machine and you want to use a 1:1 copy of that for local tests on a Win32 machine.
- your "online" Hub runs on a Win32 machine and you want to use a 1:1 copy of that for local tests on a Linux/Unix machine.

Instruction:

1. unzip the Win32 build to a local folder

2. unzip the Linux/Unix build of your choice to a local folder

3. copy the *"lib"* folder from your Linux/Unix build to your Win32 build and skip all existing files during copy process

4. copy the following files from the root folder of your Linux/Unix build to the root folder of your Win32 build:

    - *"liblua.so"* and *"luadch"*

### Done

Important: The Win32 build and the Linux/Unix build must be the same build version!
