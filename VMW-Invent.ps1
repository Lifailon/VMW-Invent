#region functons-main
function var-main {
$global:srv = $srvs.Text
$global:user = $user_name.Text
$global:pass = $password.Text
}

function auth-main {
Connect-VIServer $srv -User $user -Password $pass
}
#endregion

#region forms-main
Add-Type -assembly System.Windows.Forms
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ="VMW-Invent"
$main_form.Width = 1440
$main_form.Height = 900
$main_form.Font = "Arial,16"
$main_form.AutoSize = $false
$main_form.FormBorderStyle = "FixedSingle"
$main_form.StartPosition = "CenterScreen"
$main_form.ShowIcon = $False
#endregion

#region menu
$dll_import = @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
namespace System
{
public class IconExtractor
{
public static Icon Extract(string file, int number, bool largeIcon)
{
IntPtr large;
IntPtr small;
ExtractIconEx(file, number, out large, out small, 1);
try
{
return Icon.FromHandle(largeIcon ? large : small);
}
catch
{
return null;
}
}
[DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
}
}
"@

Add-Type -TypeDefinition $dll_import -ReferencedAssemblies System.Drawing

$watermark_srvs = "Server name"
$watermark_login = "Login name"
$watermark_password = "Password"

$srvs_Enter = {
if ($srvs.Text -like $watermark_srvs) {
$srvs.Text = ""
$srvs.ForeColor = [System.Drawing.SystemColors]::WindowText
}}

$srvs_Leave = {
if ($srvs.Text -like "") {
$srvs.Text = $watermark_srvs
$srvs.ForeColor = [System.Drawing.Color]::LightGray
}}

$srvs = New-Object System.Windows.Forms.TextBox
$srvs.Location = New-Object System.Drawing.Point(5,6)
$srvs.Size = New-Object System.Drawing.Size(200,25)
$srvs.ForeColor = [System.Drawing.Color]::LightGray 
$srvs.add_Enter($srvs_Enter)
$srvs.add_Leave($srvs_Leave)
$srvs.Text = $watermark_srvs
$main_form.Controls.Add($srvs)

$user_Enter = {
if ($user_name.Text -like $watermark_login) {
$user_name.Text = ""
$user_name.ForeColor = [System.Drawing.SystemColors]::WindowText
}}

$user_Leave = {
if ($user_name.Text -like "") {
$user_name.Text = $watermark_login
$user_name.ForeColor = [System.Drawing.Color]::LightGray
}}

$user_name = New-Object System.Windows.Forms.TextBox
$user_name.Location = New-Object System.Drawing.Point(210,6)
$user_name.Size = New-Object System.Drawing.Size(200,25)
$user_name.ForeColor = [System.Drawing.Color]::LightGray 
$user_name.add_Enter($user_Enter)
$user_name.add_Leave($user_Leave)
$user_name.Text = $watermark_login
$main_form.Controls.Add($user_name)

$password_Enter = {
if ($password.Text -like $watermark_password) {
$password.PasswordChar = "*"
$password.Text = ""
$password.ForeColor = [System.Drawing.SystemColors]::WindowText
}}

$password_Leave = {
if ($password.Text -like "") {
$password.PasswordChar = $null
$password.Text = $watermark_password
$password.ForeColor = [System.Drawing.Color]::LightGray
}}

$password = New-Object System.Windows.Forms.TextBox
$password.Multiline = $true
$password.WordWrap = $true
$password.Location = New-Object System.Drawing.Point(415,6)
$password.Size = New-Object System.Drawing.Size(200,32)
$password.ForeColor = [System.Drawing.Color]::LightGray 
$password.add_Enter($password_Enter)
$password.add_Leave($password_Leave)
$password.Text = $watermark_password
$main_form.Controls.Add($password)

$mainToolStrip = New-Object System.Windows.Forms.ToolStrip
$mainToolStrip.Location = New-Object System.Drawing.Point(615,0)
$mainToolStrip.ImageScalingSize = New-Object System.Drawing.Size(36,42)
$mainToolStrip.Size = New-Object System.Drawing.Size(850,42)
$mainToolStrip.AutoSize = $false
$mainToolStrip.Anchor = "Top"
$main_form.Controls.Add($mainToolStrip)
#endregion

#region uncomment-auto-cred
#$srvs.Text = "vcsa.domain.local"
#$user_name.Text = "administrator@vsphere.local"
#$password.Text = "password"
#$srvs.ForeColor = [System.Drawing.SystemColors]::WindowText
#$user_name.ForeColor = [System.Drawing.SystemColors]::WindowText
#$password.ForeColor = [System.Drawing.SystemColors]::WindowText
#$password.PasswordChar = "*"
#endregion

#region dgv
$dgv = New-Object System.Windows.Forms.DataGridView
$dgv.Location = New-Object System.Drawing.Point(5,45)
$dgv.Size = New-Object System.Drawing.Size(1415,790)
$dgv.Font = "Arial,10"
$dgv.AutoSizeColumnsMode = "Fill"
$dgv.AutoSize = $false
$dgv.MultiSelect = $true
$dgv.ReadOnly = $true
$main_form.Controls.Add($dgv)
#endregion

#region buttons
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$ContextMenu.MenuItems.Add(
"Copy",{
$dgv_selected = @($dgv.SelectedCells.Value)
Set-Clipboard $dgv_selected
})
$main_form.ContextMenu = $ContextMenu

$connect = New-Object System.Windows.Forms.ToolStripButton
$connect.ToolTipText = "Connect to host and print VMs"
$connect.Image = [System.IconExtractor]::Extract("setupapi.dll", 27, $true)
$mainToolStrip.Items.Add($connect)

$connect.add_Click({
$connect.Enabled = $false
var-main
auth-main
$vms = get-vm | sort Name
$dgv.Rows.Clear()
$dgv.DataSource = $null
$dgv.ColumnCount = 13
$dgv.Columns[0].Name  = "Status"
$dgv.Columns[1].Name  = "Name"
$dgv.Columns[2].Name  = "Host"
$dgv.Columns[3].Name  = "vCPU"
$dgv.Columns[4].Name  = "RAM"
$dgv.Columns[5].Name  = "All Space"
$dgv.Columns[6].Name  = "Used Space"
$dgv.Columns[7].Name  = "Disk-1"
$dgv.Columns[8].Name  = "Disk-2"
$dgv.Columns[9].Name  = "Disk-3"
$dgv.Columns[10].Name = "Disk-4"
$dgv.Columns[11].Name = "Notes"
$dgv.Columns[12].Name = "Create Date"
#$dgv.Columns[13].Name = "CPU Hot Add"
#$dgv.Columns[14].Name = "RAM Hot Add"
$out = foreach ($vm in $vms) {
$HD = $vm | Get-HardDisk | select -ExpandProperty CapacityGB
[int]$d1 = $HD[0]
[string]$d1 += " GB"
[int]$d2 = $HD[1]
[string]$d2 += " GB"
[int]$d3 = $HD[2]
[string]$d3 += " GB"
[int]$d4 = $HD[3]
[string]$d4 += " GB"
[int]$UsedSpaceGB = $vm.UsedSpaceGB
[string]$UsedSpaceGB += " GB"
[int]$ProvisionedSpaceGB = $vm.ProvisionedSpaceGB
[string]$ProvisionedSpaceGB += " GB"
[int]$MemoryGB = $vm.MemoryGB
[string]$MemoryGB += " GB"
$dgv.Rows.Add(
$vm.PowerState,$vm.Name,$vm.VMHost,$vm.NumCpu,$MemoryGB,$ProvisionedSpaceGB,$UsedSpaceGB,$d1,$d2,$d3,$d4,$vm.Notes,$vm.CreateDate)
#$vm.CpuHotAddEnabled,$vm.MemoryHotAddEnabled
}
$dgv.Rows | ForEach-Object {
if ($_.Cells["Status"].Value -eq "PoweredOn") {
$_.Cells[0] | %{$_.Style.BackColor = "lightgreen"}
} elseif ($_.Cells["Status"].Value -eq "PoweredOff") {
$_.Cells[0] | %{$_.Style.BackColor = "pink"}
}}
$vm_count = $vms.count
$on_count = ($vms.PowerState -match "on").count
$off_count = ($vms.PowerState -match "off").count
$Status.Text = "VMs count $vm_count (Power on: $on_count | Power off: $off_count)"
$connect.Enabled = $true
})

$ESXi = New-Object System.Windows.Forms.ToolStripButton
$ESXi.ToolTipText = "Hosts"
$ESXi.Image = [System.IconExtractor]::Extract("Networkexplorer.dll", 1, $true)
$mainToolStrip.Items.Add($ESXi)

$ESXi.add_Click({
$ESXi.Enabled = $false
$hosts = Get-VMHost
$dgv.Rows.Clear()
$dgv.DataSource = $null
$dgv.ColumnCount = 12
$dgv.Columns[0].Name  = "Status"
$dgv.Columns[1].Name  = "Name"
$dgv.Columns[2].Name  = "Man"
$dgv.Columns[3].Name  = "Model"
$dgv.Columns[4].Name  = "CPU"
$dgv.Columns[5].Name  = "EVC Mode"
$dgv.Columns[6].Name  = "vCPU"
$dgv.Columns[7].Name  = "CPU Total"
$dgv.Columns[8].Name  = "CPU Usage"
$dgv.Columns[9].Name  = "RAM Total"
$dgv.Columns[10].Name = "RAM Usage"
$dgv.Columns[11].Name = "IP"
$out = foreach ($h in $hosts) {
[int]$MemoryTotalGB = $h.MemoryTotalGB
[int]$MemoryUsageGB = $h.MemoryUsageGB
$1p = $MemoryTotalGB / 100
[int]$free_p = $MemoryUsageGB / $1p
[string]$MemoryTotalGB += " GB"
[string]$MemoryUsageGB += " GB ($free_p %)"
[int]$cpu_total = $h.CpuTotalMhz
[int]$cpu_usage = $h.CpuUsageMhz
$cpu_total_1p = $cpu_total / 100
[int]$cpu_usage_p = $cpu_usage / $cpu_total_1p
[string]$cpu_total_string = "$cpu_total MHz"
[string]$cpu_usage_proc = "$cpu_usage MHz ($cpu_usage_p %)"
$ip = $h | Get-VMHostNetworkAdapter | sort -Descending ip | select -ExpandProperty ip
$ip = $ip -join "; "
$dgv.Rows.Add(
$h.PowerState,$h.Name,$h.Manufacturer,$h.Model,$h.ProcessorType,$h.MaxEVCMode,$h.NumCpu,$cpu_total_string,$cpu_usage_proc,$MemoryTotalGB,$MemoryUsageGB,$ip
)}
$dgv.Rows | ForEach-Object {
if ($_.Cells["Status"].Value -match "on") {
$_.Cells[0] | %{$_.Style.BackColor = "lightgreen"}
} elseif ($_.Cells["Status"].Value -match "off") {
$_.Cells[0] | %{$_.Style.BackColor = "pink"}
}}
$hosts_count = $hosts.count
$Status.Text = "Hosts count: $hosts_count"
$ESXi.Enabled = $true
})

$datastore = New-Object System.Windows.Forms.ToolStripButton
$datastore.ToolTipText = "Datastore"
#$datastore.Image = [System.IconExtractor]::Extract("setupapi.dll", 32, $true) #14,50
$datastore.Image = [System.IconExtractor]::Extract("networkexplorer.dll", 18, $true)
$mainToolStrip.Items.Add($datastore)

$datastore.add_Click({
$datastore.Enabled = $false
$dss = Get-Datastore
$dgv.Rows.Clear()
$dgv.DataSource = $null
$dgv.ColumnCount = 6
$dgv.Columns[0].Name = "Status"
$dgv.Columns[1].Name = "Name"
$dgv.Columns[2].Name = "Datacenter"
$dgv.Columns[3].Name = "All Space"
$dgv.Columns[4].Name = "Free Space"
$dgv.Columns[5].Name = "Type FS"
$out = foreach ($ds in $dss) {
[int]$CapacityGB = $ds.CapacityGB
[int]$FreeSpaceGB = $ds.FreeSpaceGB
$1p = $CapacityGB / 100
[int]$free_p = $FreeSpaceGB / $1p
[string]$CapacityGB += " GB"
[string]$FreeSpaceGB += " ($free_p %)"
$dgv.Rows.Add(
$ds.State,$ds.Name,$ds.Datacenter,$CapacityGB,$FreeSpaceGB,$ds.Type
)}
$dgv.Rows | ForEach-Object {
if ($_.Cells["Status"].Value -eq "Available") {
$_.Cells[0] | %{$_.Style.BackColor = "lightgreen"}
} elseif ($_.Cells["Status"].Value -eq "Unavailable") {
$_.Cells[0] | %{$_.Style.BackColor = "pink"}
}}
$ds_count = $dss.count
$Status.Text = "Datastore count: $ds_count"
$datastore.Enabled = $true
})

$network_adapter = New-Object System.Windows.Forms.ToolStripButton
$network_adapter.ToolTipText = "Network Adapter VM"
$network_adapter.Image = [System.IconExtractor]::Extract("setupapi.dll", 53, $true)
$mainToolStrip.Items.Add($network_adapter)

$network_adapter.add_Click({
$network_adapter.Enabled = $false
$gna = Get-VM | Get-NetworkAdapter | sort Parent
$dgv.Rows.Clear()
$dgv.DataSource = $null
$dgv.ColumnCount = 6
$dgv.Columns[0].Name = "VM"
$dgv.Columns[1].Name = "Name Adapter"
$dgv.Columns[2].Name = "ID"
$dgv.Columns[4].Name = "Type"
$dgv.Columns[3].Name = "MAC-Address"
$dgv.Columns[5].Name = "Settings"
$out = foreach ($na in $gna) {
$dgv.Rows.Add(
$na.Parent,$na.Name,$na.Id,$na.MacAddress,$na.Type,$na.ConnectionState
)}
$dgv.Rows | ForEach-Object {
if ($_.Cells["Settings"].Value -like "Connected*") {
$_.Cells[5] | %{$_.Style.BackColor = "lightgreen"}
} elseif ($_.Cells["Settings"].Value -like "*NotConnected*") {
$_.Cells[5] | %{$_.Style.BackColor = "pink"}
}}
$na_count = $gna.count
$Status.Text = "Network adapter count: $na_count"
$network_adapter.Enabled = $true
})

$Start = New-Object System.Windows.Forms.ToolStripButton
$Start.ToolTipText = "Start VM"
$Start.Image = [System.IconExtractor]::Extract("ddores.dll", 42, $true)
$mainToolStrip.Items.Add($Start)

$Start.add_Click({
$Start.Enabled = $false
$dgv_selected = @($dgv.SelectedCells.Value)
foreach ($vm_select in $dgv_selected) {
Start-VM -vm $vm_select -Confirm:$False
}
$select_status = $dgv_selected -join ","
$Status.Text = "Start VM: $select_status"
$Start.Enabled = $true
})

$Reboot = New-Object System.Windows.Forms.ToolStripButton
$Reboot.ToolTipText = "Reboot Guest VM"
$Reboot.Image = [System.IconExtractor]::Extract("shell32.dll", 238, $true)
$mainToolStrip.Items.Add($Reboot)

$Reboot.add_Click({
$Reboot.Enabled = $false
$dgv_selected = @($dgv.SelectedCells.Value)
foreach ($vm_select in $dgv_selected) {
Restart-VMGuest -vm $vm_select -Confirm:$False
}
$select_status = $dgv_selected -join ","
$Status.Text = "Reboot VM: $select_status"
$Reboot.Enabled = $true
})

$Shutdown_guest = New-Object System.Windows.Forms.ToolStripButton
$Shutdown_guest.ToolTipText = "Shutdown Guest VM"
$Shutdown_guest.Image = [System.IconExtractor]::Extract("shell32.dll", 27, $true)
$mainToolStrip.Items.Add($Shutdown_guest)

$Shutdown_guest.add_Click({
$Shutdown_guest.Enabled = $false
$dgv_selected = @($dgv.SelectedCells.Value)
foreach ($vm_select in $dgv_selected) {
Shutdown-VMGuest -vm $vm_select -Confirm:$False
}
$select_status = $dgv_selected -join ","
$Status.Text = "Shutdown Guest VM: $select_status"
$Shutdown_guest.Enabled = $true
})

$Shutdown_kill = New-Object System.Windows.Forms.ToolStripButton
$Shutdown_kill.ToolTipText = "Stop and kill process VM"
$Shutdown_kill.Image = [System.IconExtractor]::Extract("imageres.dll", 207, $true)
$mainToolStrip.Items.Add($Shutdown_kill)

$Shutdown_kill.add_Click({
$Shutdown_kill.Enabled = $false
$dgv_selected = @($dgv.SelectedCells.Value)
foreach ($vm_select in $dgv_selected) {
Stop-VM -Kill -vm $vm_select -Confirm:$False
}
$select_status = $dgv_selected -join ","
$Status.Text = "Stop and kill process VM: $select_status"
$Shutdown_kill.Enabled = $true
})
#endregion

#region status
$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$Status = New-Object System.Windows.Forms.ToolStripStatusLabel
$main_form.Controls.Add($statusStrip)
$StatusStrip.Items.Add($Status)
$Status.Text = "Version 1.1"

$main_form.ShowDialog()
#endregion