<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
exit /b
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- DWM Dark Mode PInvoke ---
$code = @'
[DllImport("dwmapi.dll")]
public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
'@
$dwmapi = Add-Type -MemberDefinition $code -Name "Win32Dwm" -Namespace "Win32" -PassThru

# --- Theme Colors ---
$bg      = [System.Drawing.Color]::FromArgb(18, 18, 18)
$topBar  = [System.Drawing.Color]::FromArgb(32, 32, 32)
$inputBg = [System.Drawing.Color]::FromArgb(45, 45, 48)
$readBg  = [System.Drawing.Color]::FromArgb(25, 25, 25)
$fg      = [System.Drawing.Color]::FromArgb(220, 220, 220)
$accent  = [System.Drawing.Color]::FromArgb(38, 79, 120)  # Dark Blue
$orange  = [System.Drawing.Color]::FromArgb(140, 60, 0)   # Dark Orange

$form = New-Object Windows.Forms.Form
$form.Text = 'Turning Speed/Feed Master'
$form.Size = '380,460'
$form.BackColor = $bg
$form.ForeColor = $fg
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'

# --- Apply Dark Title Bar ---
$form.Add_HandleCreated({
    $attr = 20 
    $val  = 1  
    [Win32.Win32Dwm]::DwmSetWindowAttribute($this.Handle, $attr, [ref]$val, 4)
})

$Global:IsReverse = $false 

# --- Logic ---
$sync = {
    try {
        $d = [double]$tDia.Text
        if ($d -le 0) { return }

        if (-not $Global:IsReverse) {
            # MODE: Find RPM & IPM (Input SFM & IPR)
            $sfm = [double]$tSfm.Text; $ipr = [double]$tIpr.Text
            $rpm = ($sfm * 3.822) / $d
            $ipm = $rpm * $ipr
            $tRpm.Text = [math]::Round($rpm, 0); $tIpm.Text = [math]::Round($ipm, 3)
        } else {
            # MODE: Find SFM & IPR (Input RPM & IPM)
            $rpm = [double]$tRpm.Text; $ipm = [double]$tIpm.Text
            $sfm = ($rpm * $d) / 3.822
            $ipr = $ipm / $rpm
            $tSfm.Text = [math]::Round($sfm, 1); $tIpr.Text = [math]::Round($ipr, 5)
        }
    } catch {}
}

$toggleMode = {
    $Global:IsReverse = -not $Global:IsReverse
    if ($Global:IsReverse) {
        $btnToggle.Text = "MODE: RPM/IPM -> SFM/IPR"; $btnToggle.BackColor = $orange
        $tSfm.ReadOnly = $true; $tSfm.BackColor = $readBg; $tIpr.ReadOnly = $true; $tIpr.BackColor = $readBg
        $tRpm.ReadOnly = $false; $tRpm.BackColor = $inputBg; $tIpm.ReadOnly = $false; $tIpm.BackColor = $inputBg
    } else {
        $btnToggle.Text = "MODE: SFM/IPR -> RPM/IPM"; $btnToggle.BackColor = $accent
        $tSfm.ReadOnly = $false; $tSfm.BackColor = $inputBg; $tIpr.ReadOnly = $false; $tIpr.BackColor = $inputBg
        $tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
    }
    &$sync
}

# --- UI Build ---
$topPanel = New-Object Windows.Forms.Panel
$topPanel.Size = '380,60'; $topPanel.BackColor = $topBar; $topPanel.Dock = 'Top'
$form.Controls.Add($topPanel)

$btnToggle = New-Object Windows.Forms.Button
$btnToggle.Text = "MODE: SFM/IPR -> RPM/IPM"; $btnToggle.Size = '300,35'; $btnToggle.Location = '30,12'
$btnToggle.FlatStyle = 'Flat'; $btnToggle.BackColor = $accent; $btnToggle.ForeColor = 'White'; $btnToggle.FlatAppearance.BorderSize = 0
$btnToggle.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$btnToggle.Add_Click($toggleMode); $topPanel.Controls.Add($btnToggle)

function mkL($t, $y) {
    $l = New-Object Windows.Forms.Label; $l.Text = $t; $l.Location = "40,$y"; $l.AutoSize = $true
    $form.Controls.Add($l)
}
function mkT($y, $v) {
    $t = New-Object Windows.Forms.TextBox; $t.Text = $v; $t.Location = "190,$y"; $t.Size = "130,25"
    $t.BackColor = $inputBg; $t.ForeColor = 'White'; $t.BorderStyle = 'FixedSingle'
    $t.Font = New-Object Drawing.Font('Consolas', 10, [Drawing.FontStyle]::Bold)
    $t.Add_TextChanged($sync); $form.Controls.Add($t); return $t
}

# Fields
mkL "Work Diameter (in)" 100; $tDia = mkT 100 "2.000"
$sep1 = New-Object Windows.Forms.Label; $sep1.Size='300,1'; $sep1.BackColor=$topBar; $sep1.Location='30,150'; $form.Controls.Add($sep1)

mkL "Surface Speed (SFM)" 180; $tSfm = mkT 180 "400"
mkL "Spindle Speed (RPM)" 220; $tRpm = mkT 220 ""

$sep2 = New-Object Windows.Forms.Label; $sep2.Size='300,1'; $sep2.BackColor=$topBar; $sep2.Location='30,270'; $form.Controls.Add($sep2)

mkL "Feed Rate (IPR)" 300;     $tIpr = mkT 300 "0.012"
mkL "Feed Rate (IPM)" 340;     $tIpm = mkT 340 ""

# Initialize Result States
$tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
$form.Add_Load({ &$sync })
[void]$form.ShowDialog()