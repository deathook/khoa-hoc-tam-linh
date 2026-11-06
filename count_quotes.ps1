$json = Get-Content 'F:\App\KHTL\assets\data\quotes.json' -Raw | ConvertFrom-Json
Write-Output "Total quotes: $($json.Count)"
