@echo off
setlocal
set "PHP_EXE=D:\php\php.exe"
set "PUBLIC_DIR=%~dp0public"
if not exist "%PHP_EXE%" (
  echo PHP bulunamadi: %PHP_EXE%
  echo PHP yolunu bu dosyada duzenleyin.
  pause
  exit /b 1
)
echo BEN API baslatiliyor: http://0.0.0.0:8080
"%PHP_EXE%" -S 0.0.0.0:8080 -t "%PUBLIC_DIR%"
endlocal
