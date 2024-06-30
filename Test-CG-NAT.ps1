# Function to get public IP address
function Get-PublicIPAddress {
    try {
        $ipAddress = Invoke-RestMethod -Uri "https://ipv4.icanhazip.com"
        return $ipAddress.Trim()
    }
    catch {
        Write-Host "Failed to retrieve public IP address."
        exit 1
    }
}

# Function to perform traceroute and count hops
function Perform-Traceroute {
    param (
        [string]$IPAddress
    )

    $tracerouteResults = tracert -h 5 $IPAddress
    $hops = ($tracerouteResults | Select-String -Pattern "^\s*\d+\s").Count

    return $hops
}

# Main script
$publicIPAddress = Get-PublicIPAddress
Write-Host "Your public IP address is: $publicIPAddress"

$hops = Perform-Traceroute -IPAddress $publicIPAddress
Write-Host "Traceroute to $publicIPAddress completed with $hops hops."

if ($hops -eq 1) {
    Write-Host "You most likely do not have CG-NAT."
} elseif ($hops -ge 5) {
    Write-Host "Your hops are 5 or greater. You most likely have CG-NAT."
} else {
    Write-Host "You have $hops hops.  You most likely have CG-NAT."
}
