<# :
@echo off
title MAKINO A51-61NX HORIZONTAL MACHINING DRILLING HP REf

:: --- Print Reference in the FIRST window ---
cls
powershell -NoProfile -Command ^
    "Write-Host '===========================================================================' -ForegroundColor Gray; " ^
    "Write-Host '         MAKINO A51-61NX HORIZONTAL MACHINING DRILLING HP CALCULATOR' -ForegroundColor Red; " ^
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
echo [REFERENCE WINDOW ACTIVE]
echo Keep this open for Pu values.

:: --- Start the GUI in a SECOND window ---
start "Makino Logic Engine" powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
pause
exit /b
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$code = @'
[DllImport("dwmapi.dll")]
public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
'@
$dwmapi = Add-Type -MemberDefinition $code -Name "Win32Dwm" -Namespace "Win32" -PassThru

# --- Theme ---
$bg      = [System.Drawing.Color]::FromArgb(18, 18, 18)
$topBar  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$inputBg = [System.Drawing.Color]::FromArgb(45, 45, 48)
$readBg  = [System.Drawing.Color]::FromArgb(25, 25, 25)
$fg      = [System.Drawing.Color]::FromArgb(220, 220, 220)
$accent  = [System.Drawing.Color]::FromArgb(180, 40, 40) 
$green   = [System.Drawing.Color]::FromArgb(40, 180, 40)
$yellow  = [System.Drawing.Color]::FromArgb(200, 180, 0)

$form = New-Object Windows.Forms.Form
$form.Text = 'Makino A51-61NX Calc'
$form.Size = New-Object Drawing.Size(420, 680)
$form.BackColor = $bg
$form.ForeColor = $fg
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.TopMost = $true

$form.Add_HandleCreated({
    [Win32.Win32Dwm]::DwmSetWindowAttribute($this.Handle, 20, [ref]1, 4)
})

$Global:IsReverse = $false 

# --- Calculation Logic ---
$sync = {
    try {
        $d = [double]$tDia.Text; $pu = [double]$tPu.Text
        if ($d -le 0 -or $pu -le 0) { return }

        if (-not $Global:IsReverse) {
            $sfm = [double]$tSfm.Text; $ipr = [double]$tIpr.Text
            $rpm = ($sfm * 3.822) / $d; $ipm = $rpm * $ipr
            $tRpm.Text = [math]::Round($rpm, 0); $tIpm.Text = [math]::Round($ipm, 2)
        } else {
            $rpm = [double]$tRpm.Text; $ipm = [double]$tIpm.Text
            $sfm = ($rpm * $d) / 3.822; $ipr = $ipm / $rpm
            $tSfm.Text = [math]::Round($sfm, 1); $tIpr.Text = [math]::Round($ipr, 5)
        }

        # Makino Specific Math
        $mrr = ([math]::Pi * [math]::Pow($d, 2) / 4) * [double]$tIpm.Text
        $hps_theo = $mrr * $pu
        $kw_theo  = $hps_theo * 0.7457
        
        # Realistic Efficiency (85%)
        $kw_real  = ($kw_theo / 0.85)
        $trq      = if ([double]$tRpm.Text -gt 0) { ($hps_theo * 63025) / [double]$tRpm.Text } else { 0 }

        $tMrr.Text = [math]::Round($mrr, 3).ToString() + " in3/min"
        $tTrq.Text = [math]::Round($trq, 1).ToString() + " in-lbs"
        $tKwTheo.Text = [math]::Round($kw_theo, 2).ToString() + " kW"
        $tKwReal.Text = [math]::Round($kw_real, 2).ToString() + " kW"

        # Makino A51-61NX Status Update (22kW Peak / 18.5kW Cont)
        if ($kw_real -ge 22.0) {
            $lStatus.Text = "OVERLOAD - EXCEEDS PEAK 22kW"; $lStatus.ForeColor = $accent
        } elseif ($kw_real -ge 18.5) {
            $lStatus.Text = "WARNING - 18.5kW - 22kW 15 MIN ZONE (PEAK)"; $lStatus.ForeColor = $yellow
        } else {
            $lStatus.Text = "SAFE - 18.5kW CONTINUOUS"; $lStatus.ForeColor = $green
        }

        # Torque Rating Warning (approx 240Nm / 2124 in-lbs)
        if ($trq -gt 2124) { $tTrq.ForeColor = $accent } else { $tTrq.ForeColor = $fg }

    } catch {}
}

$toggleMode = {
    $Global:IsReverse = -not $Global:IsReverse
    $btnToggle.Text = if($Global:IsReverse){"MODE: SFM/IPR"}else{"MODE: RPM/IPM"}
    $tSfm.ReadOnly = $Global:IsReverse; $tSfm.BackColor = if($Global:IsReverse){$readBg}else{$inputBg}
    $tIpr.ReadOnly = $Global:IsReverse; $tIpr.BackColor = if($Global:IsReverse){$readBg}else{$inputBg}
    $tRpm.ReadOnly = -not $Global:IsReverse; $tRpm.BackColor = if($Global:IsReverse){$inputBg}else{$readBg}
    $tIpm.ReadOnly = -not $Global:IsReverse; $tIpm.BackColor = if($Global:IsReverse){$inputBg}else{$readBg}
    &$sync
}

# --- UI Build Helpers ---
function mkL($t, $y, $x=40) {
    $l = New-Object Windows.Forms.Label; $l.Text = $t; $l.Location = New-Object Drawing.Point($x, $y); $l.AutoSize = $true
    $form.Controls.Add($l); return $l
}
function mkT($y, $v) {
    $t = New-Object Windows.Forms.TextBox; $t.Text = $v; $t.Location = New-Object Drawing.Point(230, $y); $t.Size = New-Object Drawing.Size(130, 25)
    $t.BackColor = $inputBg; $t.ForeColor = 'White'; $t.BorderStyle = 'FixedSingle'
    $t.Font = New-Object Drawing.Font('Consolas', 10, [Drawing.FontStyle]::Bold)
    $t.Add_TextChanged($sync); $form.Controls.Add($t); return $t
}

# --- Layout ---
$topPanel = New-Object Windows.Forms.Panel
$topPanel.Size = New-Object Drawing.Size(420, 60); $topPanel.BackColor = $topBar; $topPanel.Dock = 'Top'
$form.Controls.Add($topPanel)

$btnToggle = New-Object Windows.Forms.Button
$btnToggle.Text = "MODE: Find RPM/IPM"; $btnToggle.Size = New-Object Drawing.Size(320, 35); $btnToggle.Location = New-Object Drawing.Point(40, 12)
$btnToggle.FlatStyle = 'Flat'; $btnToggle.BackColor = $accent; $btnToggle.ForeColor = 'White'; $btnToggle.FlatAppearance.BorderSize = 0
$btnToggle.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$btnToggle.Add_Click($toggleMode); $topPanel.Controls.Add($btnToggle)

mkL "Drill Diameter (in)" 80;  $tDia = mkT 80 "1.000"
mkL "Unit Power (Pu)" 115;     $tPu  = mkT 115 "0.65"
$sep1 = New-Object Windows.Forms.Label; $sep1.Size=New-Object Drawing.Size(340, 1); $sep1.BackColor=$topBar; $sep1.Location=New-Object Drawing.Point(30, 155); $form.Controls.Add($sep1)

mkL "Surface Speed (SFM)" 175; $tSfm = mkT 175 "300"
mkL "Spindle Speed (RPM)" 210; $tRpm = mkT 210 ""
mkL "Feed Rate (IPR)" 245;     $tIpr = mkT 245 "0.008"
mkL "Feed Rate (IPM)" 280;     $tIpm = mkT 280 ""

$sep2 = New-Object Windows.Forms.Label; $sep2.Size=New-Object Drawing.Size(340, 1); $sep2.BackColor=$topBar; $sep2.Location=New-Object Drawing.Point(30, 325); $form.Controls.Add($sep2)

mkL "Spindle Torque:" 350;     $tTrq = mkL "---" 350; $tTrq.Left=230
mkL "MRR (in3/min):" 380;      $tMrr = mkL "---" 380; $tMrr.Left=230
mkL "Theoretical (kW):" 410;   $tKwTheo = mkL "---" 410; $tKwTheo.Left=230; $tKwTheo.ForeColor=[System.Drawing.Color]::Gray
mkL "Realistic (85%):" 440;    $tKwReal = mkL "---" 440; $tKwReal.Left=230; $tKwReal.Font=New-Object Drawing.Font('Consolas', 12, [Drawing.FontStyle]::Bold)

$lStatus = mkL "READY" 490; $lStatus.Width=340; $lStatus.TextAlign='MiddleCenter'; $lStatus.Font=New-Object Drawing.Font('Segoe UI', 11, [Drawing.FontStyle]::Bold)

$foot = mkL "Makino A51-61NX Drilling Suite" 580; $foot.ForeColor = [System.Drawing.Color]::Gray; $foot.Font = New-Object Drawing.Font('Segoe UI', 8)

$tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
$form.Add_Load({ &$sync })
[void]$form.ShowDialog()