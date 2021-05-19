$ErrorActionPreference = 'Stop'

#
# Function definitions
#

Function Add-VSCodeExtension {
  Param($name)
  try {
    code --install-extension $name
  } catch {
    # todo: handle buffer warning error
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
$env:http_proxy = $http_proxy
$env:https_proxy =  $https_proxy
Add-VSCodeExtension 'ms-vscode-remote.remote-wsl'
Add-VSCodeExtension 'ms-vscode-renote.remote-containers'
Add-VSCodeExtension 'ms-azuretools.vscode-docker'

Write-Output 'configuring: docker'
Add-LocalGroupMember -Group "docker-users" -Member $user -ea 0

cp "$toolsDir\docker-proxy.ps1" "$($env:ChocolateyInstall)\bin\"