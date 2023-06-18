# Luadch - ADC Hub Server

[![Latest-Release](https://img.shields.io/github/v/release/luadch/luadch?include_prereleases)](https://github.com/luadch/luadch/releases)
[![GitHub license](https://img.shields.io/badge/license-GPLv3.0-blueviolet.svg)](https://github.com/luadch/luadch/blob/master/LICENSE)
[![Website](https://img.shields.io/website?down_message=offline&up_message=online&url=https%3A%2F%2Fluadch.github.io)](https://luadch.github.io/)
[![Platform](https://img.shields.io/badge/platform-independent-orange.svg)](https://luadch.github.io/)
![GitHub all releases](https://img.shields.io/github/downloads/luadch/luadch/total)


## Features:

    - Encryption: AES128 and AES256 cipher suites with TLSv1.3 support
    - Fast, stable and small (complete server is ~3 MB in size)
    - Supports ARM architecture
    - Easy to use Lua Scripting API
    - Many additional scripts available
    - Comfortable rightclick menu


## To run a Luadch Hub:

1. Please read the manual: [Luadch_Manual.pdf](https://github.com/luadch/luadch/blob/master/docs/Luadch_Manual.pdf)

2. *(Optional)* Enable transport encryption

    - Go to: `certs/` and start `make_cert.sh` on Linux/Unix or `make_cert.bat` on Windows to generate the certificates
    - Alternatively you can use the [Luadch Certmanager](https://github.com/luadch/certmanager)

3. Start the Hub and log in with the following credentials:

    ```
        Nick: dummy
        Password: test
        Address: adcs://127.0.0.1:5001
    ```

    Use these if you **did not** create certificates in step 2:

    ```
        Nick: dummy
        Password: test
        Address: adc://127.0.0.1:5000
    ```

4. Register your own nickname. There are two possibilities to do that:

    - Use rightclick menu: *User/Control/Reg*
    - Use command: *+reg nick* ```<Nick>``` ```<Level>```

    Where ```<Nick>``` is your new nickname and ```<Level>``` should be the highest level *100*

5. Now delete the dummy account. There are two possibilities to do that:

    - Use rightclick menu: *User/Control/Delreg*
    - Use command: *+delreg nick* ```<Nick>```

6. After this first test, you should adapt the hub to your needs:

    - Open `cfg/cfg.tbl` with a UTF-8 compatible text editor, preferably with Lua syntax highlighting
    - Read the descriptions and set the values to your need. Luadch uses a fair and reasonable default user permissions, but nevertheless you should read all

7. Once it's done, start your hub again and log in. If it still runs, there are two possibilities to enable your changes in the hub:

    - Use rightclick menu: *Hub/Core/Hub reload*
    - Use command: *+reload*

8. If you want to set other styles for lines or something:

    - Go to `scripts/lang/` here you can find all language files for each script, after that: *+reload*


## How to make a Win32 + Linux/Unix Hybrid version

With Luadch you have the possibility to make a Hybrid version who runs on Win32 systems and one Linux/Unix system of your choice.
This could be very useful if:

- Your "online" Hub runs on a Linux/Unix machine and you want to use a 1:1 copy of that for local tests on a Win32 machine.
- Your "online" Hub runs on a Win32 machine and you want to use a 1:1 copy of that for local tests on a Linux/Unix machine.

Instruction:

1. Unzip the Win32 build to a local folder

2. Unzip the Linux/Unix build of your choice to a local folder

3. Copy the `lib` folder from your Linux/Unix build to your Win32 build and skip all existing files during copy process

4. Copy the following files from the root folder of your Linux/Unix build to the root folder of your Win32 build:

    - `liblua.so` and `luadch`


**Important**: The Win32 build and the Linux/Unix build must be the same build version!
