@echo off
rem Double-click to run the Terra NT planning server for the demo.
rem Plugged a phone in after starting? Double-click link-devices.bat.
cd /d "%~dp0..\.."
set PYTHONUTF8=1
call "%~dp0link-devices.bat"
python tools\plan_server\server.py --port 8787
pause
