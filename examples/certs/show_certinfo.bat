rem  show_certinfo.bat
rem
rem   - shows informations about the servercert.pem

openssl x509 -noout -in servercert.pem -issuer -subject -dates
pause