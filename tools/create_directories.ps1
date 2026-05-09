$projectRoot = "h:\Work\MyProject\ChineseMemory"

$directories = @(
    "$projectRoot\data\pictures",
    "$projectRoot\data\puzzles\chinese_history",
    "$projectRoot\data\puzzles\world_history",
    "$projectRoot\data\puzzles\asian_civilization",
    "$projectRoot\data\puzzles\european_civilization",
    "$projectRoot\data\puzzles\africa_america_civilization",
    "$projectRoot\data\puzzles\war_military",
    "$projectRoot\data\puzzles\political_system",
    "$projectRoot\data\puzzles\economic_trade",
    "$projectRoot\data\puzzles\world_heritage",
    "$projectRoot\data\puzzles\chinese_heritage",
    "$projectRoot\data\puzzles\archaeology",
    "$projectRoot\data\puzzles\historical_mysteries",
    "$projectRoot\assets\images\illustrations\chinese_history",
    "$projectRoot\assets\images\illustrations\world_history",
    "$projectRoot\assets\images\illustrations\asian_civilization",
    "$projectRoot\assets\images\illustrations\european_civilization",
    "$projectRoot\assets\images\illustrations\africa_america_civilization",
    "$projectRoot\assets\images\illustrations\war_military",
    "$projectRoot\assets\images\illustrations\political_system",
    "$projectRoot\assets\images\illustrations\economic_trade",
    "$projectRoot\assets\images\illustrations\world_heritage",
    "$projectRoot\assets\images\illustrations\chinese_heritage",
    "$projectRoot\assets\images\illustrations\archaeology",
    "$projectRoot\assets\images\illustrations\historical_mysteries",
    "$projectRoot\assets\images\icons",
    "$projectRoot\assets\images\ui",
    "$projectRoot\assets\images\backgrounds"
)

foreach ($dir in $directories) {
    if (-not (Test-Path -Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "Created directory: $dir"
    } else {
        Write-Host "Directory already exists: $dir"
    }
}

Write-Host "`nAll directories created successfully!"