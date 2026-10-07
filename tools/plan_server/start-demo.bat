@echo off
rem Double-click to run the Terra NT planning server on the internet for the demo.
rem The app built with PLAN_API_URL=https://passable-random-rebuttal.ngrok-free.dev reaches it
rem from any network; no cable, hotspot or adb. Keep both windows open.
cd /d "%~dp0..\.."
set PYTHONUTF8=1
start "ngrok" ngrok http --url=passable-random-rebuttal.ngrok-free.dev 8787
python tools\plan_server\server.py --port 8787
pause
