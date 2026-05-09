<# :
@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$BatchDir='%~dp0'; iex ((Get-Content -LiteralPath '%~f0' -Raw))"
exit /b
#>

# Use the directory passed from the Batch header
$ScriptDir = $BatchDir.TrimEnd('\')

$Scripts = @(
    @{ Name = "Milling Speed/Feed Calc";   Path = Join-Path $ScriptDir "MillingSpeedFeedCalc.bat" }
    @{ Name = "Turning Speed/Feed Calc";   Path = Join-Path $ScriptDir "TurningSpeedFeedCalc.bat" }
    @{ Name = "Drilling Speed/Feed Calc";  Path = Join-Path $ScriptDir "DrillingSpeedFeedCalc.bat" }
    @{ Name = "Arc Feed Rate Comp Calc";   Path = Join-Path $ScriptDir "ArcFeedRateCompCalc.bat" }
    @{ Name = "Naka Drilling HP Calc";     Path = Join-Path $ScriptDir "NakaDrillingHpCalc - v2.bat" }
    @{ Name = "A51-61NX Drilling HP Calc"; Path = Join-Path $ScriptDir "A51-61NXDrillingHpCalc - v2.bat" }
    @{ Name = "EXIT";                      Path = $null }
)

$SelectedIndex = 0
$Running = $true
[Console]::CursorVisible = $false
Clear-Host

function Flush-Buffer {
    while ([Console]::KeyAvailable) { $null = [Console]::ReadKey($true) }
}

try {
    while ($Running) {
        # Instant redraw at top-left
        [Console]::SetCursorPosition(0,0)
        
        Write-Host "======================================" -ForegroundColor Gray
        Write-Host "      MACHINING CALCULATOR MENU       " -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Gray
        Write-Host " [Up/Down] to Select  |  [Enter] to Run`n" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $Scripts.Count; $i++) {
            $displayName = "  $($Scripts[$i].Name)  ".PadRight(38)
            if ($i -eq $SelectedIndex) {
                Write-Host " > $displayName" -BackgroundColor Cyan -ForegroundColor Black
            } else {
                Write-Host "   $displayName"
            }
        }

        # Blocks until a key is hit
        $KeyInfo = [Console]::ReadKey($true)
        $Key = $KeyInfo.Key

        if ($Key -eq "UpArrow") {
            $SelectedIndex = if ($SelectedIndex -gt 0) { $SelectedIndex - 1 } else { $Scripts.Count - 1 }
        }
        elseif ($Key -eq "DownArrow") {
            $SelectedIndex = if ($SelectedIndex -lt $Scripts.Count - 1) { $SelectedIndex + 1 } else { 0 }
        }
        elseif ($Key -eq "Enter") {
            $Selection = $Scripts[$SelectedIndex]
            
            if ($Selection.Name -eq "EXIT") {
                $Running = $false
            } elseif ($Selection.Path) {
                if (Test-Path -LiteralPath $Selection.Path) {
                    [Console]::CursorVisible = $true
                    Clear-Host
                    
                    # Call batch file
                    cmd.exe /c "`"$($Selection.Path)`""
                    
                    # Instant Cleanup: Clear buffer and go straight back to menu
                    Flush-Buffer
                    Clear-Host
                    [Console]::CursorVisible = $false
                } else {
                    Write-Host "`n[!] ERROR: Cannot find file at:" -ForegroundColor Red
                    Write-Host "$($Selection.Path)" -ForegroundColor White
                    Start-Sleep -Seconds 3
                    Clear-Host
                }
            }
        }
    }
}
finally {
    [Console]::CursorVisible = $true
    Clear-Host
}