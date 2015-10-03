set RANDFILE=tmp.rnd
openssl rand -hex 16 -out uid.txt
(set /p uid=)<uid.txt
openssl ecparam -out cakey.pem -name prime256v1 -genkey
openssl req -new -x509 -days 3650 -key cakey.pem -out cacert.pem -subj /CN=%uid%
openssl ecparam -out serverkey.pem -name prime256v1 -genkey
openssl req -new -key serverkey.pem -out servercert.pem -subj /CN=%uid%
openssl x509 -req -days 3650 -in servercert.pem -CA cacert.pem -CAkey cakey.pem -set_serial 01 -out servercert.pem
del uid.txt
del tmp.rnd
pause