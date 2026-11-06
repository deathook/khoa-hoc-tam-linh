Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile('F:\App\KHTL\am-duong-ngu-hanh-1.png')

$dest = New-Object System.Drawing.Bitmap 512, 512
$g = [System.Drawing.Graphics]::FromImage($dest)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.Clear([System.Drawing.Color]::Black)

# Fill background with ambient star space from src edges
$bgBrush = New-Object System.Drawing.TextureBrush($src)
$bgBrush.WrapMode = [System.Drawing.Drawing2D.WrapMode]::Clamp
$g.FillRectangle($bgBrush, 0, 0, 512, 512)
$bgBrush.Dispose()

# Dim background space to pure cosmic deep tone
$darkOverlay = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
$g.FillRectangle($darkOverlay, 0, 0, 512, 512)
$darkOverlay.Dispose()

# Draw Yin Yang sphere centered
# Source sphere bounding box: X=145, Y=35, Width=500, Height=495
$srcSphereRect = New-Object System.Drawing.Rectangle 140, 35, 510, 495

# Dest sphere rect: centered at (256, 256) with size 430 x 430
$destSphereRect = New-Object System.Drawing.Rectangle 41, 41, 430, 430

$g.DrawImage($src, $destSphereRect, $srcSphereRect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

$testPath = "C:\Users\Admin\.gemini\antigravity\brain\bfced54a-2e0a-46c7-a1e5-914bf1450c7e\test_icon_safe.png"
$dest.Save($testPath, [System.Drawing.Imaging.ImageFormat]::Png)
$dest.Dispose()
$src.Dispose()
Write-Output "Saved safe test icon to $testPath"
