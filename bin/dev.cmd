@echo off
setlocal

:: Default to port 3000 if not specified
if "%PORT%"=="" set PORT=3000

:: Let the debug gem allow remote connections
set RUBY_DEBUG_OPEN=true
set RUBY_DEBUG_LAZY=true

echo Starting Rails development environment...

:: Clean up stale PID file if it exists
if exist "tmp\pids\server.pid" (
  echo Cleaning up stale server.pid...
  del tmp\pids\server.pid
)

:: Start processes in new windows
start "Rails Server (Port %PORT%)" cmd /k "ruby bin\rails server -p %PORT%"
start "TailwindCSS Watcher" cmd /k "ruby bin\rails tailwindcss:watch"

echo Processes started in separate windows. Close those windows to stop the servers.
