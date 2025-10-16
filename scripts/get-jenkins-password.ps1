# Get Jenkins Initial Admin Password
# Instance: i-0856ca82ed4eeb0f9

Write-Host "=========================================="
Write-Host "Retrieving Jenkins Admin Password"
Write-Host "=========================================="
Write-Host ""

$InstanceId = "i-0856ca82ed4eeb0f9"
$Region = "ap-south-1"

Write-Host "Sending command to retrieve password..."
Write-Host ""

try {
    # Send command to get password
    $CommandId = (aws ssm send-command `
        --instance-ids $InstanceId `
        --document-name "AWS-RunShellScript" `
        --parameters "commands=['sudo cat /var/lib/jenkins/secrets/initialAdminPassword']" `
        --region $Region `
        --output json | ConvertFrom-Json).Command.CommandId
    
    if ($CommandId) {
        Write-Host "Command sent! Command ID: $CommandId"
        Write-Host "Waiting for result..."
        Write-Host ""
        
        Start-Sleep -Seconds 5
        
        # Get command result
        $Result = aws ssm get-command-invocation `
            --command-id $CommandId `
            --instance-id $InstanceId `
            --region $Region `
            --output json | ConvertFrom-Json
        
        if ($Result.StandardOutputContent) {
            Write-Host "=========================================="
            Write-Host "JENKINS INITIAL ADMIN PASSWORD:"
            Write-Host "=========================================="
            Write-Host ""
            Write-Host $Result.StandardOutputContent.Trim()
            Write-Host ""
            Write-Host "=========================================="
            Write-Host ""
            Write-Host "Copy this password and paste it into Jenkins!"
            Write-Host "Jenkins URL: http://13.201.118.13:8080"
        } else {
            Write-Host "Could not retrieve password via SSM."
            Write-Host ""
            Write-Host "Alternative method:"
            Write-Host "1. Go to EC2 Console"
            Write-Host "2. Select instance: i-0856ca82ed4eeb0f9"
            Write-Host "3. Click 'Connect' -> 'Session Manager'"
            Write-Host "4. Run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
        }
    }
} catch {
    Write-Host "SSM is not available on this instance."
    Write-Host ""
    Write-Host "To get the password:"
    Write-Host ""
    Write-Host "Method 1 - AWS Console (Recommended):"
    Write-Host "1. Go to: https://ap-south-1.console.aws.amazon.com/ec2/home?region=ap-south-1#Instances:"
    Write-Host "2. Select instance: i-0856ca82ed4eeb0f9"
    Write-Host "3. Click 'Connect' -> 'Session Manager' -> 'Connect'"
    Write-Host "4. In the terminal, run:"
    Write-Host "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    Write-Host ""
    Write-Host "Method 2 - User Data Script:"
    Write-Host "The password should also be saved at:"
    Write-Host "/home/ec2-user/jenkins-password.txt"
    Write-Host ""
    Write-Host "Jenkins URL: http://13.201.118.13:8080"
}
