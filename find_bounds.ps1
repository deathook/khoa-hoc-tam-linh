Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Bitmap]::FromFile('F:\App\KHTL\am-duong-ngu-hanh-1.png')
$width = $img.Width
$height = $img.Height

# Scan non-black pixels (brightness > 0.08)
$minX = $width
$maxX = 0
$minY = $height
$maxY = 0

for ($y = 0; $y -lt $height; $y += 2) {
    for ($x = 0; $x -lt $width; $x += 2) {
        $pixel = $img.GetPixel($x, $y)
        $brightness = $pixel.GetBrightness()
        if ($brightness -gt 0.12) {
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}

Write-Output "Bounding box: X=[$minX, $maxX], Y=[$minY, $maxY]"
Write-Output "Width: $($maxX - $minX), Height: $($maxY - $minY)"
Write-Output "Center: X=$([int](($minX + $maxX)/2)), Y=$([int](($minY + $maxY)/2))"
$img.Dispose()
