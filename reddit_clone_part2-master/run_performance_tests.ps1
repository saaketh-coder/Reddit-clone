# Reddit Clone Performance Testing Script
# This script runs 10 different test configurations to measure performance

Write-Host "=== Reddit Clone Performance Testing Suite ===" -ForegroundColor Cyan
Write-Host "Running 10 tests with increasing load...`n" -ForegroundColor Yellow

# Define test configurations: [users, subreddits, posts, comments]
$tests = @(
    @{Name="Tiny"; Args="5 2 10 15"},
    @{Name="Small"; Args="25 5 50 75"},
    @{Name="Default"; Args="100 10 200 300"},
    @{Name="Medium"; Args="150 12 400 600"},
    @{Name="Medium-Large"; Args="250 15 600 900"},
    @{Name="Large"; Args="500 20 1000 1500"},
    @{Name="Very Large"; Args="750 25 1500 2250"},
    @{Name="Extra Large"; Args="1000 30 2000 3000"},
    @{Name="Massive"; Args="1500 40 3000 4500"},
    @{Name="Extreme"; Args="2000 50 5000 7500"}
)

# Create results directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsDir = "performance_results_$timestamp"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

Write-Host "Results directory: $resultsDir`n" -ForegroundColor Green

# Run each test
$testNumber = 1
$totalTests = $tests.Count

foreach ($test in $tests) {
    Write-Host "[$testNumber/$totalTests] $($test.Name) - $($test.Args)" -ForegroundColor Cyan
    
    $startTime = Get-Date
    
    # Run the test and capture output
    $outputFile = "$resultsDir/test_$testNumber.txt"
    $args = $test.Args -split " "
    
    # Execute gleam run with arguments
    $output = gleam run -- $args 2>&1 | Out-String
    $output | Out-File -FilePath $outputFile
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Extract and display key metrics only
    $output | Select-String -Pattern "Total Users:|Total Posts:|Total Comments:|Total Votes:|Total Direct Messages:|Operations/second:" | ForEach-Object {
        Write-Host "  $($_.Line.Trim())" -ForegroundColor White
    }
    Write-Host "  Duration: $([math]::Round($duration, 2))s`n" -ForegroundColor Green
    
    # Append to combined results file
    Add-Content -Path "$resultsDir/all_results.txt" -Value "`n========== Test $testNumber - $($test.Name) ==========`n"
    Add-Content -Path "$resultsDir/all_results.txt" -Value "Config: $($test.Args)`n"
    $output | Add-Content -Path "$resultsDir/all_results.txt"
    
    $testNumber++
    
    # Wait between tests
    if ($testNumber -le $totalTests) {
        Start-Sleep -Seconds 2
    }
}

Write-Host "=== All Tests Completed! ===" -ForegroundColor Green
Write-Host "Results saved in: $resultsDir`n" -ForegroundColor Cyan

# Create summary report
$summaryFile = "$resultsDir/SUMMARY.md"
$summaryContent = @"
# Reddit Clone Performance Test Summary
**Run Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Test Configurations

| Test | Users | Subreddits | Posts | Comments | Duration | Status |
|------|-------|------------|-------|----------|----------|--------|
"@

$testNumber = 1
foreach ($test in $tests) {
    $testFile = "$resultsDir/test_$testNumber.txt"
    $content = Get-Content $testFile -Raw
    
    $users = ($test.Args -split " ")[0]
    $subreddits = ($test.Args -split " ")[1]
    $posts = ($test.Args -split " ")[2]
    $comments = ($test.Args -split " ")[3]
    
    # Try to extract duration from file
    $durationMatch = $content | Select-String -Pattern "Duration: (\d+) seconds"
    $duration = if ($durationMatch) { $durationMatch.Matches.Groups[1].Value + "s" } else { "N/A" }
    
    $status = if ($content -match "=== Simulation Results ===") { "Pass" } else { "Fail" }
    
    $summaryContent += "`n| $($test.Name) | $users | $subreddits | $posts | $comments | $duration | $status |"
    $testNumber++
}

$summaryContent += @"


## Key Metrics Observed

Review individual test files for detailed metrics including:
- Operations per second
- Total votes processed
- Direct messages sent
- Karma calculations
- Notification delivery

## Files Generated

- **all_results.txt** - Combined output from all tests
- **test_1.txt to test_10.txt** - Individual test outputs
- **SUMMARY.md** - This summary report

"@

$summaryContent | Out-File -FilePath $summaryFile

Write-Host "`nSummary report created: SUMMARY.md" -ForegroundColor Green
Write-Host "`nTo view results:" -ForegroundColor Yellow
Write-Host "  - Individual test: cat $resultsDir/test_1.txt" -ForegroundColor White
Write-Host "  - All results: cat $resultsDir/all_results.txt" -ForegroundColor White
Write-Host "  - Summary: cat $resultsDir/SUMMARY.md" -ForegroundColor White
