@echo off
title Nakamura WY-100II Drilling HP Calculator

:START
cls

powershell -NoProfile -Command ^
    "Write-Host '===========================================================================' -ForegroundColor Gray; " ^
    "Write-Host '             NAKAMURA-TOME WY-100II DRILLING HP CALCULATOR' -ForegroundColor Red; " ^
    "Write-Host '===========================================================================' -ForegroundColor Gray; " ^
    "Write-Host ''; " ^
    "Write-Host ' --- Pu REFERENCE LIST (hp/in3/min) ---' -ForegroundColor Red; " ^
    "Write-Host ''; " ^
    "Write-Host ' [NON-FERROUS]' -ForegroundColor Red; " ^
    "Write-Host ' Magnesium Alloys:        0.15 - 0.20' -ForegroundColor White; " ^
    "Write-Host ' Aluminum (6061-T6):      0.25 - 0.30' -ForegroundColor White; " ^
    "Write-Host ' Aluminum (7075/High Si): 0.35 - 0.40' -ForegroundColor White; " ^
    "Write-Host ' Brass (Free Cutting):    0.20 - 0.25' -ForegroundColor White; " ^
    "Write-Host ' Bronze (Hard):           0.45 - 0.50' -ForegroundColor White; " ^
    "Write-Host ' Copper (Pure):           0.40 - 0.55' -ForegroundColor White; " ^
    "Write-Host ''; " ^
    "Write-Host ' [CAST IRONS]' -ForegroundColor Red; " ^
    "Write-Host ' Gray Iron (Soft):        0.30 - 0.35' -ForegroundColor White; " ^
    "Write-Host ' Gray Iron (Hard):        0.45 - 0.50' -ForegroundColor White; " ^
    "Write-Host ' Nodular/Ductile:         0.55 - 0.70' -ForegroundColor White; " ^
    "Write-Host ''; " ^
    "Write-Host ' [STEELS - CARBON/ALLOY]' -ForegroundColor Red; " ^
    "Write-Host ' Free Machine (12L14):    0.45 - 0.55' -ForegroundColor White; " ^
    "Write-Host ' Carbon (1018/1020):      0.55 - 0.65' -ForegroundColor White; " ^
    "Write-Host ' Carbon (1045/1144):      0.70 - 0.85' -ForegroundColor White; " ^
    "Write-Host ' Alloy (4140 Annealed):   0.70 - 0.85' -ForegroundColor White; " ^
    "Write-Host ' Alloy (4140 @ 32 HRC):   1.00 - 1.20' -ForegroundColor White; " ^
    "Write-Host ' Alloy (4140 @ 42 HRC):   1.30 - 1.50' -ForegroundColor White; " ^
    "Write-Host ' Die Steel (Hardened):    1.60 - 1.80' -ForegroundColor White; " ^
    "Write-Host ''; " ^
    "Write-Host ' [STAINLESS STEELS]' -ForegroundColor Red; " ^
    "Write-Host ' Stainless 303:           0.85 - 0.95' -ForegroundColor White; " ^
    "Write-Host ' Stainless 304/316:       1.00 - 1.15' -ForegroundColor White; " ^
    "Write-Host ' Stainless 17-4 PH:       1.10 - 1.30' -ForegroundColor White; " ^
    "Write-Host ' Duplex Stainless:        1.35 - 1.55' -ForegroundColor White; " ^
    "Write-Host ''; " ^
    "Write-Host ' [EXOTICS / TITANIUM]' -ForegroundColor Red; " ^
    "Write-Host ' Titanium (6Al-4V):       1.15 - 1.35' -ForegroundColor White; " ^
    "Write-Host ' Inconel 625:             1.60 - 1.80' -ForegroundColor White; " ^
    "Write-Host ' Inconel 718:             1.80 - 2.10' -ForegroundColor White; " ^
    "Write-Host ' Hastelloy/Waspaloy:      1.90 - 2.20' -ForegroundColor White; " ^
    "Write-Host ' -------------------------------------------------------------------------' -ForegroundColor Gray; " ^
    "Write-Host ' Note: Use the higher end of the range for dull tools or hard materials.' -ForegroundColor White; " ^
    "Write-Host ''; " ^
    "Write-Host '--- INPUT PARAMETERS ---' -ForegroundColor Red; " ^
    "$DIA = [double](Read-Host ' [1] Enter Drill Diameter (in) '); " ^
    "$SFM = [double](Read-Host ' [2] Enter Surface Feet/Min (SFM)'); " ^
    "$IPR = [double](Read-Host ' [3] Enter Feed Rate (IPR)     '); " ^
    "$PU  = [double](Read-Host ' [4] Enter Unit Power (Pu)     '); " ^
    "$pi = [math]::Pi; " ^
    "$rpm = ($SFM * 12) / ($pi * $DIA); " ^
    "$ipm = $IPR * $rpm; " ^
    "$mrr = ($pi * [math]::Pow($DIA, 2) / 4) * $ipm; " ^
    "$hps = $mrr * $PU; " ^
    "$hpm = $hps / 0.85; " ^
    "$torque = if ($rpm -gt 0) { ($hps * 63025) / $rpm } else { 0 }; " ^
    "$kw = $hpm * 0.7457; " ^
    "Write-Host ''; " ^
    "Write-Host '----------------------- ' -NoNewline -ForegroundColor Gray; " ^
    "Write-Host 'CALCULATION RESULTS' -NoNewline -ForegroundColor Red; " ^
    "Write-Host ' -----------------------' -ForegroundColor Gray; " ^
    "Write-Host ' Spindle Speed:           ' -NoNewline -ForegroundColor White; Write-Host ('{0:N0} RPM' -f $rpm) -ForegroundColor Cyan; " ^
    "Write-Host ' Feed Rate:               ' -NoNewline -ForegroundColor White; Write-Host ('{0:N2} IPM' -f $ipm) -ForegroundColor Cyan; " ^
    "Write-Host ' Material Removal Rate:   ' -NoNewline -ForegroundColor White; Write-Host ('{0:N3} in3/min' -f $mrr) -ForegroundColor Cyan; " ^
    "Write-Host ' Spindle Torque:          ' -NoNewline -ForegroundColor White; Write-Host ('{0:N2} in-lbs' -f $torque) -ForegroundColor Cyan; " ^
    "Write-Host '-------------------------------------------------------------------' -ForegroundColor Gray; " ^
    "Write-Host ' THEORETICAL HP:          ' -NoNewline -ForegroundColor White; Write-Host ('{0:N2} hp' -f $hps) -ForegroundColor Cyan; " ^
    "Write-Host ' 85%% MOTOR HP:            ' -NoNewline -ForegroundColor White; Write-Host ('{0:N2} hp' -f $hpm) -ForegroundColor Cyan; " ^
    "Write-Host ' 85%% MOTOR KW:            ' -NoNewline -ForegroundColor White; Write-Host ('{0:N2} kW' -f $kw) -ForegroundColor Cyan; " ^
    "Write-Host '-------------------------------------------------------------------' -ForegroundColor Gray; " ^
    "if ($kw -ge 15.0) { " ^
    "  Write-Host ' >>> ' -NoNewline -ForegroundColor White; Write-Host 'RESULT: OVERLOAD - EXCEEDS 15kW PEAK' -NoNewline -ForegroundColor Red; Write-Host ' <<<' -ForegroundColor White " ^
    "} elseif ($kw -ge 11.0) { " ^
    "  Write-Host ' >>> ' -NoNewline -ForegroundColor White; Write-Host 'RESULT: WARNING - PEAK ZONE 30 MIN (11-15kW)' -NoNewline -ForegroundColor Yellow; Write-Host ' <<<' -ForegroundColor White " ^
    "} else { " ^
    "  Write-Host ' >>> ' -NoNewline -ForegroundColor White; Write-Host 'RESULT: SAFE - WITHIN 11kW CONTINUOUS' -NoNewline -ForegroundColor Green; Write-Host ' <<<' -ForegroundColor White " ^
    "}; " ^
    "Write-Host '-------------------------------------------------------------------' -ForegroundColor Gray; "

echo.
set /p AGAIN="New Calculation? (y/n): "
if /i "%AGAIN%"=="y" goto START
exit