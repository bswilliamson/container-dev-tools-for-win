$ErrorActionPreference = 'Stop'

#
# Function definitions
#

Function Add-VSCodeExtension {
  Param($name, $user)
  Write-Verbose "installing: $name"
  $userHome = "$env:SystemDrive\Users\$user"
  $userExtDir = "$userHome\.vscode\extensions"
  $userDataDir = "$userHome\AppData\Roaming\Code"
  Write-Debug "vscode ext: http_proxy=$env:http_proxy"
  Write-Debug "vscode ext: https_proxy=$env:https_proxy"
  Write-Debug "vscode ext: name=$name"
  Write-Debug "vscode ext: extDir=$userExtDir"
  Write-Debug "vscode ext: dataDir=$userDataDir"
  try {
    code --install-extension $name --extensions-dir $userExtDir --user-data-dir $userDataDir --force
  } catch {
    # todo: handle buffer warning error, fail for anything else
    Write-Debug $_
  }
}

#
# Main logic
#

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$params = Get-PackageParameters
$user = $params['User']
$httpProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('http://example.com')
$httpsProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('https://example.com')

if ($user -eq $null) {
  throw 'Parameter "User" must be set'
}

Write-Output 'configuring: vscode'
# vscode seems to ignore the system proxy when invoked from here so we'll set it manually
$env:http_proxy = $httpProxy
$env:https_proxy =  $httpsProxy

Add-VSCodeExtension -User $user -Name 'ms-vscode-remote.remote-wsl'
Add-VSCodeExtension -User $user -Name 'ms-vscode-renote.remote-containers'
Add-VSCodeExtension -User $user -Name 'ms-azuretools.vscode-docker'

Write-Output 'configuring: docker'
Add-LocalGroupMember -Group "docker-users" -Member $user -ea 0

cp "$toolsDir\docker-proxy.ps1" "$($env:ChocolateyInstall)\bin\"