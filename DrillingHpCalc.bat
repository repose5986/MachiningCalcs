<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
exit /b
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- FIXED DARK MODE DECOR ---
$code = @'
using System;
using System.Runtime.InteropServices;

public class Win32Dwm {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    
    public static void SetDarkMode(IntPtr hwnd) {
        int attribute = 20; // DWMWA_USE_IMMERSIVE_DARK_MODE
        int useDarkMode = 1;
        DwmSetWindowAttribute(hwnd, attribute, ref useDarkMode, sizeof(int));
    }
}
'@
Add-Type -TypeDefinition $code

# ===========================================================================
#  MACHINE LIBRARY
# ===========================================================================
$machineLib = [ordered]@{
    "Makino A51-61NX"   = @(18.5, 22.0, 2124)
    "Nakamura WY-100II Main" = @(7.45, 11.18, 690)
    "Nakamura WY-100II Milling" = @(2.2, 7.1, 141)
}
# Material Database (Name = Pu Value)
$matList = [ordered]@{
    "Custom / Manual Entry"   = 0.65
    "Aluminum (6061-T6)"      = 0.25
    "Aluminum (7075)"         = 0.35
    "Brass (Free Cutting)"    = 0.22
    "Bronze (Hard)"           = 0.48
    "Copper (Pure)"           = 0.45
    "Gray Iron (Soft)"        = 0.32
    "Gray Iron (Hard)"        = 0.48
    "Nodular / Ductile Iron"  = 0.60
    "Steel 12L14 (Free Mach)" = 0.50
    "Steel 1018/1020"         = 0.60
    "Steel 1045/1144"         = 0.75
    "Alloy 4140 (Annealed)"   = 0.75
    "Alloy 4140 (32 HRC)"     = 1.10
    "Alloy 4140 (42 HRC)"     = 1.40
    "Stainless 303"           = 0.90
    "Stainless 304/316"       = 1.10
    "Stainless 17-4 PH"       = 1.20
    "Titanium (6Al-4V)"       = 1.25
    "Inconel 718"             = 1.95
    "Hastelloy"               = 2.05
}

# --- THEME ---
$bg      = [System.Drawing.Color]::FromArgb(18, 18, 18)
$topBar  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$inputBg = [System.Drawing.Color]::FromArgb(45, 45, 48)
$readBg  = [System.Drawing.Color]::FromArgb(25, 25, 25)
$fg      = [System.Drawing.Color]::FromArgb(220, 220, 220)
$accent  = [System.Drawing.Color]::FromArgb(180, 40, 40) 
$green   = [System.Drawing.Color]::FromArgb(40, 180, 40)
$yellow  = [System.Drawing.Color]::FromArgb(200, 180, 0)
$blue = [System.Drawing.Color]::FromArgb(0, 120, 215)

$form = New-Object Windows.Forms.Form
$form.Text = 'HP Calculator (Mill/Drill)'
$form.Size = New-Object Drawing.Size(440, 850) # Increased height for new fields
$form.BackColor = $bg
$form.ForeColor = $fg
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.TopMost = $true
$form.Add_HandleCreated({ [Win32Dwm]::SetDarkMode($this.Handle) })

$Global:IsReverse = $false 

# --- CALCULATION ENGINE ---
$sync = {
    try {
        $d = [double]$tDia.Text; $pu = [double]$tPu.Text
        if ($d -le 0 -or $pu -le 0) { return }

        # RPM/IPM Logic
        if (-not $Global:IsReverse) {
            $sfm = [double]$tSfm.Text; $ipr = [double]$tIpr.Text
            $rpm = ($sfm * 3.822) / $d; $ipm = $rpm * $ipr
            $tRpm.Text = [math]::Round($rpm, 0); $tIpm.Text = [math]::Round($ipm, 2)
        } else {
            $rpm = [double]$tRpm.Text; $ipm = [double]$tIpm.Text
            if ($rpm -le 0) { return }
            $sfm = ($rpm * $d) / 3.822; $ipr = $ipm / $rpm
            $tSfm.Text = [math]::Round($sfm, 1); $tIpr.Text = [math]::Round($ipr, 5)
        }

        # MRR Calculation based on Operation Type
        if ($comboOp.SelectedItem -eq "Drilling") {
            $mrr = ([math]::Pi * [math]::Pow($d, 2) / 4) * [double]$tIpm.Text
        } else {
            # Milling MRR = Width of Cut * Depth of Cut * IPM
            $mrr = [double]$tWoc.Text * [double]$tDoc.Text * [double]$tIpm.Text
        }

        $hps_theo = $mrr * $pu
        $kw_theo  = $hps_theo * 0.7457
        $kw_real  = ($kw_theo / 0.85)
        $trq      = if ([double]$tRpm.Text -gt 0) { ($hps_theo * 63025) / [double]$tRpm.Text } else { 0 }

        $tMrr.Text = [math]::Round($mrr, 3).ToString() + " in3/min"
        $tTrq.Text = [math]::Round($trq, 1).ToString() + " in-lbs"
        $tKwTheo.Text = [math]::Round($kw_theo, 2).ToString() + " kW"
        $tKwReal.Text = [math]::Round($kw_real, 2).ToString() + " kW"

        $currentMach = $machineLib[$comboMachine.SelectedItem]
        $contLimit = $currentMach[0]; $peakLimit = $currentMach[1]; $trqLimit = $currentMach[2]

        if ($kw_real -ge $peakLimit) {
            $lStatus.Text = "OVERLOAD - EXCEEDS $($peakLimit)kW"; $lStatus.ForeColor = $accent
        } elseif ($kw_real -ge $contLimit) {
            $lStatus.Text = "$($contLimit)kW 15-30 MIN PEAK LOAD ZONE"; $lStatus.ForeColor = $yellow
        } else {
            $lStatus.Text = "SAFE - CONTINUOUS ZONE"; $lStatus.ForeColor = $green
        }
        if ($trq -gt $trqLimit) { $tTrq.ForeColor = $accent } else { $tTrq.ForeColor = $fg }
    } catch {}
}

# --- UI HELPERS ---
function mkL($t, $y, $x=40) {
    $l = New-Object Windows.Forms.Label; $l.Text = $t
    $l.Location = New-Object Drawing.Point($x, $y); $l.AutoSize = $true
    $form.Controls.Add($l); return $l
}
function mkT($y, $v) {
    $t = New-Object Windows.Forms.TextBox; $t.Text = $v
    $t.Location = New-Object Drawing.Point(240, $y); $t.Size = New-Object Drawing.Size(130, 25)
    $t.BackColor = $inputBg; $t.ForeColor = 'White'; $t.BorderStyle = 'FixedSingle'; $t.Font = New-Object Drawing.Font('Consolas', 10, [Drawing.FontStyle]::Bold)
    $t.Add_TextChanged($sync); $form.Controls.Add($t); return $t
}

# --- HEADER SECTION ---
$topPanel = New-Object Windows.Forms.Panel; $topPanel.Size = "440, 165"; $topPanel.BackColor = $topBar; $topPanel.Dock = 'Top'
$form.Controls.Add($topPanel)

mkL "MACHINE" 8 40 | % { $_.Parent = $topPanel; $_.ForeColor = [Drawing.Color]::Gray }
$comboMachine = New-Object Windows.Forms.ComboBox; $comboMachine.Items.AddRange($machineLib.Keys); $comboMachine.SelectedIndex = 0
$comboMachine.Location = "40,25"; $comboMachine.Size = "340,30"; $comboMachine.DropDownStyle = "DropDownList"; $comboMachine.BackColor = $inputBg; $comboMachine.ForeColor = "White"; $comboMachine.FlatStyle = "Flat"
$comboMachine.Add_SelectedIndexChanged($sync); $topPanel.Controls.Add($comboMachine)

mkL "MATERIAL REFERENCE (Pu)" 62 40 | % { $_.Parent = $topPanel; $_.ForeColor = [Drawing.Color]::Gray }
$comboMat = New-Object Windows.Forms.ComboBox; $comboMat.Items.AddRange($matList.Keys); $comboMat.SelectedIndex = 0
$comboMat.Location = "40,79"; $comboMat.Size = "340,30"; $comboMat.DropDownStyle = "DropDownList"; $comboMat.BackColor = $inputBg; $comboMat.ForeColor = "White"; $comboMat.FlatStyle = "Flat"
$comboMat.Add_SelectedIndexChanged({ if($comboMat.SelectedIndex -ne 0){ $tPu.Text = $matList[$comboMat.SelectedItem] }; &$sync })
$topPanel.Controls.Add($comboMat)

mkL "OPERATION TYPE" 116 40 | % { $_.Parent = $topPanel; $_.ForeColor = [Drawing.Color]::Gray }
$comboOp = New-Object Windows.Forms.ComboBox; $comboOp.Items.AddRange(@("Drilling", "Milling")); $comboOp.SelectedIndex = 0
$comboOp.Location = "40,133"; $comboOp.Size = "340,30"; $comboOp.DropDownStyle = "DropDownList"; $comboOp.BackColor = $inputBg; $comboOp.ForeColor = "White"; $comboOp.FlatStyle = "Flat"
$comboOp.Add_SelectedIndexChanged({
    $isMill = ($comboOp.SelectedItem -eq "Milling")
    $tWoc.ReadOnly = -not $isMill; $tWoc.BackColor = if($isMill){$inputBg}else{$readBg}
    $tDoc.ReadOnly = -not $isMill; $tDoc.BackColor = if($isMill){$inputBg}else{$readBg}
    &$sync
})
$topPanel.Controls.Add($comboOp)

$btnToggle = New-Object Windows.Forms.Button; $btnToggle.Text = "MODE: RPM/IPM"; $btnToggle.Size = "340,30"; $btnToggle.Location = "40,185"
$btnToggle.FlatStyle = 'Flat'; $btnToggle.BackColor = $blue; $btnToggle.ForeColor = 'White'; $btnToggle.Font = New-Object Drawing.Font('Segoe UI', 8, [Drawing.FontStyle]::Bold)
$btnToggle.Add_Click({ $Global:IsReverse = -not $Global:IsReverse; $btnToggle.Text = if($Global:IsReverse){"MODE: SFM/IPR"}else{"MODE: RPM/IPM"} 
    $tSfm.ReadOnly = $Global:IsReverse; $tSfm.BackColor = if($Global:IsReverse){$readBg}else{$inputBg}
    $tIpr.ReadOnly = $Global:IsReverse; $tIpr.BackColor = if($Global:IsReverse){$readBg}else{$inputBg}
    $tRpm.ReadOnly = -not $Global:IsReverse; $tRpm.BackColor = if($Global:IsReverse){$inputBg}else{$readBg}
    $tIpm.ReadOnly = -not $Global:IsReverse; $tIpm.BackColor = if($Global:IsReverse){$inputBg}else{$readBg}; &$sync })
$form.Controls.Add($btnToggle)

# --- INPUT FIELDS ---
mkL "Tool Diameter (in)" 230;  $tDia = mkT 230 "1.000"
mkL "Unit Power (Pu)" 265;    $tPu  = mkT 265 "0.65"
mkL "Width of Cut (WOC)" 300; $tWoc = mkT 300 "0.500"; $tWoc.ReadOnly = $true; $tWoc.BackColor = $readBg
mkL "Depth of Cut (DOC)" 335; $tDoc = mkT 335 "0.500"; $tDoc.ReadOnly = $true; $tDoc.BackColor = $readBg
mkL "Surface Speed (SFM)" 385; $tSfm = mkT 385 "300"
mkL "Spindle Speed (RPM)" 420; $tRpm = mkT 420 ""
mkL "Feed Rate (IPR/IPT)" 455; $tIpr = mkT 455 "0.008"
mkL "Feed Rate (IPM)" 490;     $tIpm = mkT 490 ""

$sep = New-Object Windows.Forms.Label; $sep.Size="340,1"; $sep.BackColor=$topBar; $sep.Location="40,540"; $form.Controls.Add($sep)

# --- OUTPUTS ---
mkL "Spindle Torque:" 560;     $tTrq = mkL "---" 560; $tTrq.Left=240
mkL "MRR (in3/min):" 590;      $tMrr = mkL "---" 590; $tMrr.Left=240
mkL "Theoretical (kW):" 620;   $tKwTheo = mkL "---" 620; $tKwTheo.Left=240; $tKwTheo.ForeColor=[Drawing.Color]::Gray
mkL "Realistic (85%):" 650;    $tKwReal = mkL "---" 650; $tKwReal.Left=240; $tKwReal.Font=New-Object Drawing.Font('Consolas', 12, [Drawing.FontStyle]::Bold)

$lStatus = mkL "READY" 710; $lStatus.Width=340; $lStatus.TextAlign='MiddleCenter'; $lStatus.Font=New-Object Drawing.Font('Segoe UI', 12, [Drawing.FontStyle]::Bold)

$tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
$form.Add_Load({ &$sync })
[void]$form.ShowDialog()