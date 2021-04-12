$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$params = Get-PackageParameters
$user = $params['User']
$httpProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('http://example.com')
$httpsProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('https://example.com')
$dockerSettingsPath = "$Env:HomeDrive\Users\$user\AppData\Roaming\Docker\settings.json"

if ($user -eq $null) {
  throw 'Parameter "User" must be set'
}

Function Set-DockerSetting {
  Param($key, $value)
  Write-Output "Modifying docker settings: $key=$value"
  $dockerSettingsJSON = Get-Content $dockerSettingsPath | ConvertFrom-JSON
  $dockerSettingsJSON.$key = $value
  [IO.File]::WriteAllLines($dockerSettingsPath, ($dockerSettingsJSON | ConvertTo-JSON))
}

Function Add-VSCodeExtension {
  Param($name)
  # vscode seems to ignore the system proxy when invoked from here so we'll set it manually
  $env:http_proxy = $http_proxy
  $env:https_proxy =  $https_proxy
  try {
    code --install-extension $name
  } catch {
    # todo: handle buffer warning error
  }
}

if ($httpProxy.AbsoluteUri -ne 'http://example.com') {
  Write-Output "Detected HTTP proxy: $httpProxy"
  Set-DockerSetting 'proxyHttpMode' $true
  Set-DockerSetting 'overrideProxyHttp' $httpProxy.AbsoluteUri
  [IO.File]::WriteAllLines($dockerSettingsPath, ($dockerSettingsJSON | ConvertTo-JSON))
}

if ($httpsProxy.AbsoluteUri -ne 'https://example.com') {
  Write-Output "Detected HTTPS proxy: $httpsProxy"
  $dockerSettingsJSON = Get-Content $dockerSettingsPath | ConvertFrom-JSON
  $dockerSettingsJSON.proxyHttpMode = $true
  $dockerSettingsJSON.overrideProxyHttps = $httpsProxy.AbsoluteUri
  [IO.File]::WriteAllLines($dockerSettingsPath, ($dockerSettingsJSON | ConvertTo-JSON))
}

Add-VSCodeExtension 'ms-vscode-remote.remote-wsl'
Add-VSCodeExtension 'ms-vscode-renote.remote-containers'
