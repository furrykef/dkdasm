@echo off
C:\MFS\cc65\bin\ca65 adpcm.asm
if errorlevel 1 goto end
C:\MFS\cc65\bin\ld65 -C adpcm-nsf.cfg -o adpcm.nsf adpcm.o
:end
pause
