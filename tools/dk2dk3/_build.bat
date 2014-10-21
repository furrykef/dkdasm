@echo off
dk2dk3.py roms/dkong.zip roms/dkong3
if errorlevel 1 goto end
call patch.bat
if errorlevel 1 goto end
del roms\dkong3\dk3c.7b
rename roms\dkong3\dk3c.7b.out dk3c.7b
:end
pause
