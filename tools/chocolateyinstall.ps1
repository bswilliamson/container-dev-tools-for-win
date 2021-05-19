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

Function Set-DockerSetting {
  Param($key, $value)
  Write-Output "Modifying docker settings: $key=$value"
  $dockerSettingsPath = "$Env:HomeDrive\Users\$user\AppData\Roaming\Docker\settings.json"
  $dockerSettingsJSON = Get-Content $dockerSettingsPath | ConvertFrom-JSON
  $dockerSettingsJSON.$key = $value
  [IO.File]::WriteAllLines($dockerSettingsPath, ($dockerSettingsJSON | ConvertTo-JSON))
}

Function Stop-Docker {
  Write-Output "Stopping docker"
  foreach ($svc in (Get-Service | Where-Object {$_.name -ilike "*docker*" -and $_.Status -ieq "Running"})) {
    Write-Output "Stopping docker service"
    $svc | Stop-Service -ErrorAction Continue -Confirm:$false -Force
    Write-Output "waiting"
    $svc.WaitForStatus('Stopped','00:00:20')
  }
  Write-Output "stop again"
  Get-Process | Where-Object {$_.Name -ilike "*docker*"} | Stop-Process -ErrorAction Continue -Confirm:$false -Force
}

Function Start-Docker {
  foreach ($svc in (Get-Service | Where-Object {$_.name -ilike "*docker*" -and $_.Status -ieq "Stopped"})) {
    $svc | Start-Service 
    $svc.WaitForStatus('Running','00:00:20')
  }

  Start-Process "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
}

#
# Main logic
#

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
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

Set-DockerSetting 'integratedWslDistros' 'Ubuntu'

if ($httpProxy.AbsoluteUri -ne 'http://example.com') {
  Stop-Docker
  Write-Output "Detected HTTP proxy: $httpProxy"
  Set-DockerSetting 'proxyHttpMode' $true
  Set-DockerSetting 'overrideProxyHttp' "${httpProxy.host}`:${httpProxy.port}"
  Set-DockerSetting 'overrideProxyExclude' 'localhost,127.0.0.1'
}

if ($httpsProxy.AbsoluteUri -ne 'https://example.com') {
  Stop-Docker
  Write-Output "Detected HTTPS proxy: $httpsProxy"
  Set-DockerSetting 'proxyHttpMode' $true
  Set-DockerSetting 'overrideProxyHttps' "${httpsProxy.host}`:${httpsProxy.port}"
  Set-DockerSetting 'overrideProxyExclude' 'localhost,127.0.0.1'
}

Start-Docker
