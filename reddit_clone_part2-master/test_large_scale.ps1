# Large Scale Performance Test Script
# Tests with increased Erlang VM limits

Write-Host "=== Large Scale Reddit Clone Performance Tests ===" -ForegroundColor Cyan
Write-Host "Erlang VM configured with: +P 2000000 +Q 1000000" -ForegroundColor Yellow
Write-Host ""

$tests = @(
    @{Name="10K Users"; Args="10000 100 5000 7500"},
    @{Name="25K Users"; Args="25000 150 12500 18750"},
    @{Name="50K Users"; Args="50000 200 25000 37500"},
    @{Name="100K Users"; Args="100000 250 50000 75000"}
)

foreach ($test in $tests) {
    Write-Host "[$($test.Name)] Starting test..." -ForegroundColor Green
    Write-Host "  Config: $($test.Args)" -ForegroundColor Gray
    
    $startTime = Get-Date
    
    try {
        $output = gleam run -- $test.Args.Split() 2>&1 | Out-String
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        Write-Host "  Completed in $([math]::Round($duration, 2))s" -ForegroundColor Green
        
        # Extract key metrics
        if ($output -match "Total Users: (\d+)") { Write-Host "  Users: $($matches[1])" }
        if ($output -match "Total Posts: (\d+)") { Write-Host "  Posts: $($matches[1])" }
        if ($output -match "Total Comments: (\d+)") { Write-Host "  Comments: $($matches[1])" }
        if ($output -match "Operations/second: ([\d.]+)") { Write-Host "  Ops/sec: $($matches[1])" -ForegroundColor Cyan }
        Write-Host ""
        
    } catch {
        Write-Host "  FAILED: $_" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "=== Tests Complete ===" -ForegroundColor Cyan
