Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile('F:\App\KHTL\am-duong-ngu-hanh-1.png')
Write-Output "Dimensions: $($img.Width) x $($img.Height)"
$img.Dispose()
