@echo off
netsh advfirewall firewall add rule name="BEN API 8080" dir=in action=allow protocol=TCP localport=8080
if %errorlevel% neq 0 (
  echo Bu dosyayi Yonetici olarak calistirin.
  pause
  exit /b 1
)
echo Windows Firewall: 8080 acildi.
pause
