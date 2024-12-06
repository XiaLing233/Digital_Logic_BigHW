@echo off
set bin_path=C:\\WorkSpace\\ModelSim\\win32pe
call %bin_path%/vsim  -c -do "do {sel_display7_tb_compile.do}" -l compile.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
