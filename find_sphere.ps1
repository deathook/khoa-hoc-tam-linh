Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Bitmap]::FromFile('F:\App\KHTL\am-duong-ngu-hanh-1.png')
$cx = 400
$cy = 266

# Scan vertically from center up and down
$topY = 0
for ($y = 0; $y -lt $cy; $y++) {
    $p = $img.GetPixel($cx, $y)
    if ($p.R -gt 70 -or $p.G -gt 70 -or $p.B -gt 70) {
        $topY = $y
        break
    }
}

$botY = 531
for ($y = 531; $y -gt $cy; $y--) {
    $p = $img.GetPixel($cx, $y)
    if ($p.R -gt 70 -or $p.G -gt 70 -or $p.B -gt 70) {
        $botY = $y
        break
    }
}

# Scan horizontally at cy
$leftX = 0
for ($x = 0; $x -lt $cx; $x++) {
    $p = $img.GetPixel($x, $cy)
    if ($p.R -gt 70 -or $p.G -gt 70 -or $p.B -gt 70) {
        $leftX = $x
        break
    }
}

$rightX = 799
for ($x = 799; $x -gt $cx; $x--) {
    $p = $img.GetPixel($x, $cy)
    if ($p.R -gt 70 -or $p.G -gt 70 -or $p.B -gt 70) {
        $rightX = $x
        break
    }
}

Write-Output "Sphere top: $topY, bottom: $botY (diameter: $($botY - $topY), center Y: $(($topY + $botY)/2))"
Write-Output "Sphere left: $leftX, right: $rightX (diameter: $($rightX - $leftX), center X: $(($leftX + $rightX)/2))"
$img.Dispose()
