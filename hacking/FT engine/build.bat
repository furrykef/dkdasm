@echo off
C:\MFS\cc65\bin\ca65 dk3ft.asm -D INC_MUSIC -D INC_MUSIC_ASM -I ./ft
if errorlevel 1 goto end
C:\MFS\cc65\bin\ld65 -C dk3.cfg -o dk3c.6h dk3ft.o
:end
pause
