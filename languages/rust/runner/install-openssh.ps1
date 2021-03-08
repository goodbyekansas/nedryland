Write-Output "Installing OpenSSH Server..."
Get-WindowsCapability -Online | ? Name -like "OpenSSH.Server*" | Add-WindowsCapability -Online
Write-Output "Adding ssh keys..."
New-Item -Path "C:\ProgramData" -Name "ssh" -ItemType "directory" -Force
Set-Content -Value "@pubSshKey@" -Path C:\ProgramData\ssh\administrators_authorized_keys
$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

Write-Output "Starting ssh server..."
Start-Service sshd
Write-Output "All done!"

