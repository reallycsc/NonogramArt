$projectRoot = "h:\Work\MyProject\ChineseMemory"

$sourceImgDir = "$projectRoot\assets\images\illustrations\yuangu"
$targetImgDir = "$projectRoot\assets\images\illustrations\chinese_history"

$sourcePuzzleDir = "$projectRoot\data\puzzles\yuangu"
$targetPuzzleDir = "$projectRoot\data\puzzles\chinese_history"

$sourceStories = "$projectRoot\data\stories\yuangu.json"
$targetPictures = "$projectRoot\data\pictures\chinese_history.json"

Write-Host "=== 迁移图片文件 ==="
Get-ChildItem -Path $sourceImgDir -Filter *.png | ForEach-Object {
    $targetPath = Join-Path $targetImgDir $_.Name
    Copy-Item -Path $_.FullName -Destination $targetPath -Force
    Write-Host "Copied: $($_.Name)"
}

Write-Host "`n=== 迁移数织关卡文件 ==="
Get-ChildItem -Path $sourcePuzzleDir -Filter *.json | ForEach-Object {
    $targetPath = Join-Path $targetPuzzleDir $_.Name
    Copy-Item -Path $_.FullName -Destination $targetPath -Force
    Write-Host "Copied: $($_.Name)"
}

Write-Host "`n=== 更新图片数据文件 ==="
$content = Get-Content -Path $sourceStories -Raw -Encoding UTF8
$content = $content -replace 'yuangu', 'chinese_history'
Set-Content -Path $targetPictures -Value $content -Encoding UTF8
Write-Host "Updated: $targetPictures"

Write-Host "`n=== 迁移完成! ==="