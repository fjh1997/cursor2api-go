@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

echo.
echo =========================================
echo   Cursor2API Launcher (Go)
echo =========================================
echo.
set GOPROXY=
set HTTPS_PROXY=http://127.0.0.1:10808
echo [INFO] GOPROXY=!GOPROXY!
echo [INFO] GOTOOLCHAIN=!GOTOOLCHAIN!

where go >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Go is not installed. Install Go 1.24+.
    echo [HINT] https://go.dev/dl/
    goto :fail
)

go version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to run go.
    echo [HINT] Check network access for toolchain download.
    goto :fail
)

for /f "tokens=3" %%i in ('go version') do set "GO_VERSION=%%i"
set "GO_VERSION=!GO_VERSION:go=!"
for /f "tokens=1,2 delims=." %%a in ("!GO_VERSION!") do (
    set "GO_MAJOR=%%a"
    set "GO_MINOR=%%b"
)
if !GO_MAJOR! LSS 1 (
    echo [ERROR] Go !GO_VERSION! is too old. Install Go 1.24+.
    goto :fail
)
if !GO_MAJOR! EQU 1 if !GO_MINOR! LSS 24 (
    echo [ERROR] Go !GO_VERSION! is too old. This project needs Go 1.24+.
    goto :fail
)
echo [OK] Go version: !GO_VERSION!

where node >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js is not installed. Install Node.js 18+.
    echo [HINT] https://nodejs.org/
    goto :fail
)

for /f "delims=" %%i in ('node --version') do set "NODE_VERSION=%%i"
set "NODE_VERSION=!NODE_VERSION:v=!"
for /f "tokens=1 delims=." %%a in ("!NODE_VERSION!") do set "NODE_MAJOR=%%a"
if !NODE_MAJOR! LSS 18 (
    echo [ERROR] Node.js !NODE_VERSION! is too old. Need Node.js 18+.
    goto :fail
)
echo [OK] Node.js version: !NODE_VERSION!

if not exist ".env" (
    if exist ".env.example" (
        copy /Y ".env.example" ".env" >nul
        echo [OK] Created .env from .env.example
    ) else (
        > ".env" (
            echo PORT=8002
            echo DEBUG=false
            echo API_KEY=0000
        )
        echo [OK] Created minimal .env
    )
) else (
    echo [OK] .env already exists
)

echo.
echo [INFO] Downloading Go modules...
go mod download
if errorlevel 1 (
    echo [ERROR] go mod download failed.
    goto :fail
)

echo [INFO] Building executable...
go build -o cursor2api-go.exe .
if errorlevel 1 (
    echo [ERROR] go build failed.
    goto :fail
)

if not exist "cursor2api-go.exe" (
    echo [ERROR] Build failed: cursor2api-go.exe not found.
    goto :fail
)

echo [OK] Build completed. Starting service...
echo.
cursor2api-go.exe
goto :eof

:fail
echo.
echo [INFO] Startup failed.
pause
exit /b 1
