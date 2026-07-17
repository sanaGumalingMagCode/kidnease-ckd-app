# Quick test for new Gemini API key

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Gemini API Key Tester" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Read API key from .env file
$envPath = "kidnease_app\.env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath
    $apiKeyLine = $envContent | Where-Object { $_ -match "GEMINI_API_KEY=" }
    if ($apiKeyLine) {
        $apiKey = ($apiKeyLine -split "=")[1]
        Write-Host "Found API key in .env: $($apiKey.Substring(0, 10))..." -ForegroundColor Green
    } else {
        Write-Host "No GEMINI_API_KEY found in .env file!" -ForegroundColor Red
        exit
    }
} else {
    Write-Host ".env file not found!" -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Testing Gemini 2.0 Flash (newest model)..." -ForegroundColor Yellow

$url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey"

$body = @{
    contents = @(
        @{
            parts = @(
                @{
                    text = "Reply with 'API is working perfectly!' if you can read this message."
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json"
    $replyText = $response.candidates[0].content.parts[0].text
    
    Write-Host ""
    Write-Host "SUCCESS! Gemini API is working!" -ForegroundColor Green
    Write-Host "Response from AI:" -ForegroundColor Cyan
    Write-Host $replyText -ForegroundColor White
    Write-Host ""
    Write-Host "Your API key is valid and working correctly!" -ForegroundColor Green
    Write-Host "You can now run the app with: flutter run --release" -ForegroundColor Yellow
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host ""
    Write-Host "FAILED: HTTP $statusCode" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please get a new API key from:" -ForegroundColor Yellow
    Write-Host "https://aistudio.google.com/app/apikey" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
