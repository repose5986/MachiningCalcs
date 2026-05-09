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
$bg      = [System.Drawing.Color]::FromArgb(18, 18, 18)    # Deep Black-Grey
$topBar  = [System.Drawing.Color]::FromArgb(32, 32, 32)    # Dark Header
$inputBg = [System.Drawing.Color]::FromArgb(45, 45, 48)    # Input Field
$readBg  = [System.Drawing.Color]::FromArgb(25, 25, 25)    # Read Only
$fg      = [System.Drawing.Color]::FromArgb(220, 220, 220) # Off-White Text
$accent  = [System.Drawing.Color]::FromArgb(38, 79, 120)   # Slate Blue (Muted Dark Mode Blue)
$orange  = [System.Drawing.Color]::FromArgb(140, 60, 0)    # Muted Dark Mode Orange

$form = New-Object Windows.Forms.Form
$form.Text = 'Milling Speed/Feed'
$form.Size = '380,500'
$form.BackColor = $bg
$form.ForeColor = $fg
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'

# --- Apply Dark Title Bar (Win10 1809+ / Win11) ---
$form.Add_HandleCreated({
    $attr = 20 # DWMWA_USE_IMMERSIVE_DARK_MODE
    $val  = 1  # Enable
    [Win32.Win32Dwm]::DwmSetWindowAttribute($this.Handle, $attr, [ref]$val, 4)
})

$Global:IsReverse = $false 

# --- Logic ---
$sync = {
    try {
        $d = [double]$tDia.Text; $f = [double]$tFlu.Text
        if ($d -le 0 -or $f -le 0) { return }
        if (-not $Global:IsReverse) {
            $sfm = [double]$tSfm.Text; $ipt = [double]$tIpt.Text
            $rpm = ($sfm * 3.822) / $d; $ipm = $rpm * $ipt * $f
            $tRpm.Text = [math]::Round($rpm, 0); $tIpm.Text = [math]::Round($ipm, 2)
        } else {
            $rpm = [double]$tRpm.Text; $ipm = [double]$tIpm.Text
            $sfm = ($rpm * $d) / 3.822; $ipt = $ipm / ($rpm * $f)
            $tSfm.Text = [math]::Round($sfm, 1); $tIpt.Text = [math]::Round($ipt, 5)
        }
    } catch {}
}

$toggleMode = {
    $Global:IsReverse = -not $Global:IsReverse
    if ($Global:IsReverse) {
        $btnToggle.Text = "MODE: RPM/IPM -> SFM/IPT"; $btnToggle.BackColor = $orange
        $tSfm.ReadOnly = $true; $tSfm.BackColor = $readBg; $tIpt.ReadOnly = $true; $tIpt.BackColor = $readBg
        $tRpm.ReadOnly = $false; $tRpm.BackColor = $inputBg; $tIpm.ReadOnly = $false; $tIpm.BackColor = $inputBg
    } else {
        $btnToggle.Text = "MODE: SFM/IPT -> RPM/IPM"; $btnToggle.BackColor = $accent
        $tSfm.ReadOnly = $false; $tSfm.BackColor = $inputBg; $tIpt.ReadOnly = $false; $tIpt.BackColor = $inputBg
        $tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
    }
    &$sync
}

# --- UI Build ---
$topPanel = New-Object Windows.Forms.Panel
$topPanel.Size = '380,60'; $topPanel.BackColor = $topBar; $topPanel.Dock = 'Top'
$form.Controls.Add($topPanel)

$btnToggle = New-Object Windows.Forms.Button
$btnToggle.Text = "MODE: SFM/IPT -> RPM/IPM"; $btnToggle.Size = '300,35'; $btnToggle.Location = '30,12'
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

mkL "Tool Diameter (in)" 100; $tDia = mkT 100 "0.500"
mkL "Number of Flutes" 140;  $tFlu = mkT 140 "4"
$sep1 = New-Object Windows.Forms.Label; $sep1.Size='300,1'; $sep1.BackColor=$topBar; $sep1.Location='30,190'; $form.Controls.Add($sep1)
mkL "Surface Speed (SFM)" 220; $tSfm = mkT 220 "300"
mkL "Spindle Speed (RPM)" 260; $tRpm = mkT 260 ""
$sep2 = New-Object Windows.Forms.Label; $sep2.Size='300,1'; $sep2.BackColor=$topBar; $sep2.Location='30,310'; $form.Controls.Add($sep2)
mkL "Feed / Tooth (IPT)" 340; $tIpt = mkT 340 "0.002"
mkL "Feed Rate (IPM)" 380;   $tIpm = mkT 380 ""

$tRpm.ReadOnly = $true; $tRpm.BackColor = $readBg; $tIpm.ReadOnly = $true; $tIpm.BackColor = $readBg
$form.Add_Load({ &$sync })
[void]$form.ShowDialog()