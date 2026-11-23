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
REM Local development default: user ID 1 is the BEN admin for testing.
REM Set BEN_ADMIN_USER_IDS before launching to override this default.
if not defined BEN_ADMIN_USER_IDS (
  set "BEN_ADMIN_USER_IDS=1"
)
echo BEN yonetici kullanici ID'leri: %BEN_ADMIN_USER_IDS%
echo BEN API baslatiliyor: http://0.0.0.0:8080
"%PHP_EXE%" -d upload_max_filesize=32M -d post_max_size=40M -d max_execution_time=120 -d max_input_time=120 -S 0.0.0.0:8080 -t "%PUBLIC_DIR%"
endlocal
