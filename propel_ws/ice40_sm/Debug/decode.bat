@echo off
rem copy /y ..\..\..\tb\code.log .
copy /y ..\..\..\tb\data.log .
perl sim_decode.pl ice40_nano.lst ..\..\..\tb\code.log > code.log
start gvim code.log data.log ice40_nano.lst

