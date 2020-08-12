@echo off

rem IP or name of the node requested via qsub
set node_ip=%1

rem Port number mapped on the "docker create" command
set port=%2

rem User on all remote machines
set user=%3

rem Key path on the user's machine
set local_key_path=%4

rem Key path on the cluster
set remote_key_path=%5

rem IP or name of the cluster
set remote_ip=%6

call ^
ssh -t -L %port%:127.0.0.1:%port% -i "%local_key_path%" "%user%"@"%remote_ip%" ^
ssh -L %port%:127.0.0.1:%port% -i "%remote_key_path%" "%user%"@"%node_ip%"
