# Test Gemini API to find which models work

$apiKey = "AIzaSyAoQbuWmbaTm9Cw0mDpP5f_nFwTqi_z7ag"

Write-Host "Testing Gemini API Models..." -ForegroundColor Cyan
Write-Host ""

# Test 1: List available models
Write-Host "1. Listing available models..." -ForegroundColor Yellow
$listUrl = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey"
try {
    $response = Invoke-RestMethod -Uri $listUrl -Method Get
    Write-Host "Available models:" -ForegroundColor Green
    foreach ($model in $response.models) {
        if ($model.name -match "gemini" -and $model.supportedGenerationMethods -contains "generateContent") {
            Write-Host "  - $($model.name)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Error listing models: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Testing specific models..." -ForegroundColor Yellow

# Models to test
$modelsToTest = @(
    "gemini-1.5-flash",
    "gemini-1.5-flash-latest", 
    "gemini-1.5-flash-001",
    "gemini-1.5-flash-002",
    "gemini-pro",
    "gemini-pro-vision"
)

foreach ($model in $modelsToTest) {
    Write-Host "Testing: $model" -ForegroundColor Cyan
    
    $url = "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=$apiKey"
    
    $body = @{
        contents = @(
            @{
                parts = @(
                    @{
                        text = "Say 'API works' if you can read this."
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
        Write-Host "  SUCCESS: $model works!" -ForegroundColor Green
        Write-Host "  Response: $($response.candidates[0].content.parts[0].text)" -ForegroundColor Gray
        Write-Host ""
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "  FAILED: $model (HTTP $statusCode)" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host "Testing complete!" -ForegroundColor Cyan
