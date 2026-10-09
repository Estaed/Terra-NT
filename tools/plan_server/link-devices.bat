@echo off
rem Links every connected emulator and USB phone to this laptop's planning server:
rem the app's PLAN_API_URL is http://127.0.0.1:8787 on the device, carried over USB.
for /f "skip=1 tokens=1,2" %%a in ('adb devices') do if "%%b"=="device" (
  adb -s %%a reverse tcp:8787 tcp:8787 >nul && echo Linked %%a
)
