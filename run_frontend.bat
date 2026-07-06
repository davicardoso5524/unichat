@echo off
echo ========================================
echo    UniChat - Script de Execucao
echo ========================================
echo.

echo [1/4] Verificando dependencias Flutter...
cd /d C:\Users\cardo\Desktop\unichat\frontend
call flutter pub get
echo.

echo [2/4] Iniciando emulador Pixel 8...
start "" "C:\Users\cardo\AppData\Local\Android\Sdk\emulator\emulator.exe" -avd Pixel_8

echo.
echo [3/4] Aguardando emulador iniciar...
echo    Aguardando device aparecer no ADB...
"C:\Users\cardo\AppData\Local\Android\Sdk\platform-tools\adb.exe" wait-for-device

echo    Device detectado! Aguardando boot completo...

:wait_boot
timeout /t 3 /nobreak >nul
for /f "tokens=*" %%i in ('"C:\Users\cardo\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell getprop sys.boot_completed 2^>nul') do set BOOT=%%i
if not "%BOOT%"=="1" (
    echo    Ainda iniciando...
    goto wait_boot
)
echo    Emulador pronto!

echo.
echo [4/4] Rodando UniChat no emulador...
flutter run -d emulator-5554

pause
