Function Set-DockerSetting {
  Param($key, $value)
  Write-Output "Modifying docker settings: $key=$value"
  $path = "$Env:AppData\Docker\settings.json"
  $dockerSettings = Get-Content $path | ConvertFrom-JSON
  if (-not($dockerSettings.PSobject.Properties.Name -contains $Key)) {
    $dockerSettings | Add-Member -Name $key -Value $Value -MemberType NoteProperty
  } else {
    $dockerSettings.$key = $value
  }
  [IO.File]::WriteAllLines($path, ($dockerSettings | ConvertTo-JSON))
}

$httpProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('http://example.com')
$httpsProxy = [System.Net.WebRequest]::DefaultWebProxy.GetProxy('https://example.com')

if ($httpProxy.AbsoluteUri -ne 'http://example.com') {
  Write-Output "Detected HTTP proxy: $httpProxy"
  Set-DockerSetting -Key 'proxyHttpMode' -Value $true
  $proxyHost = $httpProxy.host
  $proxyPort = $httpProxy.port
  Set-DockerSetting -Key 'overrideProxyHttp' -Value "$proxyHost`:$proxyPort"
  Set-DockerSetting -Key 'overrideProxyExclude' -Value 'localhost,127.0.0.1'
}

if ($httpsProxy.AbsoluteUri -ne 'https://example.com') {
  Write-Output "Detected HTTPS proxy: $httpsProxy"
  Set-DockerSetting -User $user -Key 'proxyHttpMode' -Value $true
  $proxyHost = $httpsProxy.host
  $proxyPort = $httpsProxy.port
  Set-DockerSetting -Key 'overrideProxyHttps' -Value "$proxyHost`:$proxyPort"
  Set-DockerSetting -Key 'overrideProxyExclude' -Value 'localhost,127.0.0.1'
}