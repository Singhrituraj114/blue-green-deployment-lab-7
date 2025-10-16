# Check Jenkins Status Script
# New Jenkins IP: 13.201.118.13

$JenkinsIP = "13.201.118.13"
$JenkinsURL = "http://$JenkinsIP:8080"

Write-Host "=========================================="
Write-Host "Checking Jenkins Installation Status"
Write-Host "=========================================="
Write-Host ""
Write-Host "Jenkins is installing automatically..."
Write-Host "This takes about 5-7 minutes."
Write-Host ""

$maxAttempts = 20
$attempt = 0

while ($attempt -lt $maxAttempts) {
    $attempt++
    Write-Host "[$attempt/$maxAttempts] Checking if Jenkins is ready..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $JenkinsURL -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 403) {
            Write-Host " ✅ Jenkins is UP!"
            Write-Host ""
            Write-Host "=========================================="
            Write-Host "Jenkins is ready!"
            Write-Host "=========================================="
            Write-Host "URL: $JenkinsURL"
            Write-Host ""
            Write-Host "Retrieving initial admin password..."
            Write-Host ""
            
            # Try to get password via AWS Systems Manager (if available)
            $password = aws ssm send-command --instance-ids i-0856ca82ed4eeb0f9 --document-name "AWS-RunShellScript" --parameters 'commands=["cat /var/lib/jenkins/secrets/initialAdminPassword"]' --region ap-south-1 --output text --query 'Command.CommandId' 2>$null
            
            if ($password) {
                Write-Host "Password retrieval command sent. Check AWS Console or wait..."
            } else {
                Write-Host "To get the password, open Jenkins URL and it will show you how to retrieve it."
            }
            
            Write-Host ""
            Write-Host "Next steps:"
            Write-Host "1. Open: $JenkinsURL"
            Write-Host "2. Wait for the 'Unlock Jenkins' page"
            Write-Host "3. Follow the instructions on screen"
            Write-Host ""
            
            # Try to open browser
            Start-Process $JenkinsURL
            
            return
        }
    } catch {
        Write-Host " Not ready yet (${attempt}/${maxAttempts})"
    }
    
    Start-Sleep -Seconds 30
}

Write-Host ""
Write-Host "⏰ Still installing. Jenkins URL: $JenkinsURL"
Write-Host "   Keep checking manually or wait a bit longer."
