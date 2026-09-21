# local-agent/run.ps1
# Runs one scan-and-upload pass of agent.js. Register this in Windows Task
# Scheduler (Action: "Start a program", Program: powershell.exe, Arguments:
# -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\local-agent\run.ps1")
# on a repeating trigger (e.g. every 5 minutes) — see README.md.
$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot
node agent.js
