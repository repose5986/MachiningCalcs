<# :
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%~f0' -Raw)"
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
$accent  = [System.Drawing.Color]::FromArgb(38, 79, 120)
$warn    = [System.Drawing.Color]::FromArgb(180, 40, 40)

$form = New-Object Windows.Forms.Form
$form.Text = 'Arc Feed Compensator'
$form.Size = '400,520'
$form.BackColor = $bg
$form.ForeColor = $fg
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'

$form.Add_HandleCreated({
    [Win32.Win32Dwm]::DwmSetWindowAttribute($this.Handle, 20, [ref]1, 4)
})

$Global:Mode = "Inside"

# --- Logic ---
$sync = {
    try {
        $r_arc = [double]$tArcR.Text
        $r_tool = ([double]$tDia.Text / 2)
        $f_lin = [double]$tLinF.Text

        if ($r_arc -gt 0 -and $r_tool -gt 0) {
            if ($Global:Mode -eq "Inside") {
                $adj = $f_lin * (($r_arc - $r_tool) / $r_arc)
                $lBadge.Text = "REDUCED"
                $lBadge.ForeColor = $warn
                $tAdjF.ForeColor = $warn
            } else {
                $adj = $f_lin * (($r_arc + $r_tool) / $r_arc)
                $lBadge.Text = "INCREASED"
                $lBadge.ForeColor = [System.Drawing.Color]::DeepSkyBlue
                $tAdjF.ForeColor = [System.Drawing.Color]::DeepSkyBlue
            }
            $tAdjF.Text = [math]::Round($adj, 2)
            $pct = ($adj / $f_lin) * 100
            $lPct.Text = [math]::Round($pct, 1).ToString() + "% of Linear Feed"
        }
    } catch { $tAdjF.Text = "---" }
}

$toggleMode = {
    if ($Global:Mode -eq "Inside") {
        $Global:Mode = "Outside"; $btnToggle.Text = "ARC: OUTSIDE (CONVEX)"; $btnToggle.BackColor = $accent
    } else {
        $Global:Mode = "Inside"; $btnToggle.Text = "ARC: INSIDE (CONCAVE)"; $btnToggle.BackColor = $warn
    }
    &$sync
}

# --- UI ---
$topPanel = New-Object Windows.Forms.Panel
$topPanel.Size = '400,60'; $topPanel.BackColor = $topBar; $topPanel.Dock = 'Top'
$form.Controls.Add($topPanel)

$btnToggle = New-Object Windows.Forms.Button
$btnToggle.Text = "ARC: INSIDE (CONCAVE)"; $btnToggle.Size = '320,35'; $btnToggle.Location = '30,12'
$btnToggle.FlatStyle = 'Flat'; $btnToggle.BackColor = $warn; $btnToggle.ForeColor = 'White'; $btnToggle.FlatAppearance.BorderSize = 0
$btnToggle.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
$btnToggle.Add_Click($toggleMode); $topPanel.Controls.Add($btnToggle)

function mkL($t, $x, $y) {
    $l = New-Object Windows.Forms.Label; $l.Text = $t; $l.Location = "$x,$y"; $l.AutoSize = $true
    $form.Controls.Add($l); return $l
}
function mkT($y, $v) {
    $t = New-Object Windows.Forms.TextBox; $t.Text = $v; $t.Location = "220,$y"; $t.Size = "120,25"
    $t.BackColor = $inputBg; $t.ForeColor = 'White'; $t.BorderStyle = 'FixedSingle'
    $t.Font = New-Object Drawing.Font('Consolas', 10, [Drawing.FontStyle]::Bold)
    $t.Add_TextChanged($sync); $form.Controls.Add($t); return $t
}

mkL "Tool Diameter (in)" 40 100; $tDia = mkT 100 "0.500"
mkL "Linear Feed (IPM)" 40 140; $tLinF = mkT 140 "50.0"
mkL "Arc Radius (in)" 40 180;   $tArcR = mkT 180 "0.750"

$sep = New-Object Windows.Forms.Label; $sep.Size='320,1'; $sep.BackColor=$topBar; $sep.Location='30,240'; $form.Controls.Add($sep)

# Fixed Results Section
mkL "Adjusted Feed Rate:" 40 280
$lBadge = mkL "REDUCED" 185 282
$lBadge.Font = New-Object Drawing.Font('Segoe UI', 7, [Drawing.FontStyle]::Bold)

$tAdjF = New-Object Windows.Forms.TextBox
$tAdjF.Location = "40,310"; $tAdjF.Size = "200,40"
$tAdjF.BackColor = $bg; $tAdjF.ForeColor = $warn; $tAdjF.ReadOnly = $true; $tAdjF.BorderStyle = 'None'
$tAdjF.Font = New-Object Drawing.Font('Consolas', 24, [Drawing.FontStyle]::Bold)
$form.Controls.Add($tAdjF)
$tAdjF.BringToFront()

$lPct = mkL "---% of Linear Feed" 40 360
$lPct.ForeColor = [System.Drawing.Color]::Gray

$form.Add_Load({ &$sync })
[void]$form.ShowDialog()