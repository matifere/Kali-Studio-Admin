Add-Type -AssemblyName System.Drawing

$srcPath = Join-Path $PSScriptRoot "..\assets\images\logo_naranja.png"
$outPath = Join-Path $PSScriptRoot "..\windows\runner\resources\app_icon.ico"

if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found at $srcPath"
    exit 1
}

$sizes = @(16, 32, 48, 64, 128, 256)
$pngBytesList = @()

$srcImage = [System.Drawing.Image]::FromFile($srcPath)

foreach ($sz in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($sz, $sz)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImage, 0, 0, $sz, $sz)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $pngBytesList += ,($ms.ToArray())
    $ms.Dispose()
}

$srcImage.Dispose()

# Build ICO binary
$count = $sizes.Count
$headerSize = 6 + (16 * $count)

$fs = New-Object System.IO.FileStream($outPath, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($fs)

# Write ICONDIR Header
$bw.Write([UInt16]0) # Reserved
$bw.Write([UInt16]1) # Type 1 = Icon
$bw.Write([UInt16]$count)

$currentOffset = $headerSize

for ($i = 0; $i -lt $count; $i++) {
    $sz = $sizes[$i]
    $pngData = $pngBytesList[$i]
    $widthByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
    $heightByte = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }

    $bw.Write($widthByte)
    $bw.Write($heightByte)
    $bw.Write([byte]0) # Color count
    $bw.Write([byte]0) # Reserved
    $bw.Write([UInt16]1) # Planes
    $bw.Write([UInt16]32) # Bit count
    $bw.Write([UInt32]$pngData.Length)
    $bw.Write([UInt32]$currentOffset)

    $currentOffset += $pngData.Length
}

for ($i = 0; $i -lt $count; $i++) {
    $bw.Write($pngBytesList[$i])
}

$bw.Flush()
$bw.Close()
$fs.Close()

Write-Output "Successfully generated $outPath with sizes: $($sizes -join ', ')"
