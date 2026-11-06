Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile('F:\App\KHTL\am-duong-ngu-hanh-1.png')

$dest = New-Object System.Drawing.Bitmap 512, 512
$g = [System.Drawing.Graphics]::FromImage($dest)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# Crop a perfect 532x532 square centered on the sphere
$cropX = 128
$cropY = 0
$cropSize = 532

$srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropSize, $cropSize
$destRect = New-Object System.Drawing.Rectangle 0, 0, 512, 512
$g.DrawImage($src, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

$testPath = "C:\Users\Admin\.gemini\antigravity\brain\bfced54a-2e0a-46c7-a1e5-914bf1450c7e\test_natural.png"
$dest.Save($testPath, [System.Drawing.Imaging.ImageFormat]::Png)
$dest.Dispose()
$src.Dispose()
Write-Output "Saved natural test icon to $testPath"
