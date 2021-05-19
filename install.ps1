param($User, $Debug, $Verbose)
$ErrorActionPreference = 'Stop'

choco pack

$installArgs = '-fy'
if ($Debug -eq $true) {
  $installArgs += 'd'
}
if ($Verbose -eq $true) {
   $installArgs += 'v'
}
choco install $installArgs container-dev-tools-for-win -s "'.;https://chocolatey.org/api/v2'" --Params "/User:$User"

rm *.nupkg
