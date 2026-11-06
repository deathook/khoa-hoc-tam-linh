Add-Type -AssemblyName System.Drawing

$srcPath = "F:\App\KHTL\am-duong-ngu-hanh-1.png"
Write-Output "Using source image: $srcPath"
$src = [System.Drawing.Bitmap]::FromFile($srcPath)
Write-Output "Source size: $($src.Width)x$($src.Height)"

$cropX = 128
$cropY = 0
$cropSize = 532
$srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropSize, $cropSize

# Generate master 512x512 icon
$master512 = New-Object System.Drawing.Bitmap 512, 512
$g512 = [System.Drawing.Graphics]::FromImage($master512)
$g512.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g512.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g512.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g512.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, 512, 512), $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$g512.Dispose()

$master512.Save("F:\App\KHTL\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$master512.Save("F:\App\KHTL\iconcompress.png", [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "Saved master 512x512 icon to icon.png and iconcompress.png"

$resMap = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

$resDir = "F:\App\KHTL\android\app\src\main\res"

foreach ($name in $resMap.Keys) {
    $size = $resMap[$name]
    $folder = Join-Path $resDir $name
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    
    # 1. Square icon
    $destBitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($destBitmap)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.Clear([System.Drawing.Color]::Transparent)
    
    $destRect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $graphics.DrawImage($src, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()
    
    $outPath = Join-Path $folder "ic_launcher.png"
    $destBitmap.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $destBitmap.Dispose()

    # 2. Round icon (circular clip)
    $roundBitmap = New-Object System.Drawing.Bitmap $size, $size
    $roundG = [System.Drawing.Graphics]::FromImage($roundBitmap)
    $roundG.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $roundG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $roundG.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $roundG.Clear([System.Drawing.Color]::Transparent)
    
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddEllipse(0, 0, $size, $size)
    $roundG.SetClip($path)
    $roundG.DrawImage($src, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $path.Dispose()
    $roundG.Dispose()
    
    $roundPath = Join-Path $folder "ic_launcher_round.png"
    $roundBitmap.Save($roundPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $roundBitmap.Dispose()

    Write-Output "Generated $outPath and round ($size x $size)"
}

$master512.Dispose()
$src.Dispose()
Write-Output "All icons updated successfully with am-duong-ngu-hanh-1.png!"
