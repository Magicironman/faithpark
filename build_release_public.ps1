param(
  [Parameter(Mandatory = $true)]
  [string]$BackendUrl
)

Set-Location $PSScriptRoot

& flutter build apk --release "--dart-define=TRAFFIC_API_BASE_URL=$BackendUrl"
