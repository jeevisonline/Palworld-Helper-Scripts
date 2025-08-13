# =========================
# CG-NAT / VPN Quick Check
# =========================
# Logic:
# - We traceroute directly to your observed public (WAN) IPv4.
# - If that WAN IP is 1 hop away -> Likely no CG-NAT (and not full-tunnel VPN).
# - If it's more than 1 hop -> You may have CG-NAT or are using a VPN,
#   which can prevent effective IPv4 port forwarding.

# ---- Settings ----
$MaxHops = 5   # keep modest for speed; increase if needed

# ---- Functions ----

function Get-PublicIPAddress {
    try {
        $ipAddress = Invoke-RestMethod -Uri "https://ipv4.icanhazip.com"
        return $ipAddress.Trim()
    }
    catch {
        Write-Host "Failed to retrieve public IPv4 address."
        exit 1
    }
}

function Get-TracerouteHops {
    param(
        [Parameter(Mandatory)][string]$Destination,
        [int]$MaxHops = 10
    )

    # Windows tracert: -4 (IPv4), -d (no DNS), -w 100 (100ms timeout), -h (max hops)
    $raw = tracert -4 -d -w 100 -h $MaxHops $Destination

    $hopIPs = @()
    foreach ($line in $raw) {
        # Only consider lines that start with a hop number
        if ($line -match '^\s*\d+\s') {
            # Collect all IPv4s on the line; take the last one if any
            $matches = [regex]::Matches($line, '(?:\d{1,3}\.){3}\d{1,3}')
            if ($matches.Count -gt 0) {
                $ip = $matches[$matches.Count - 1].Value
                $hopIPs += $ip
                if ($ip -eq $Destination) { break }
            }
            # else: hop was "* * * Request timed out." -> skip
        }
    }
    return ,$hopIPs
}

function Assess-CGNATOrVPN {
    param(
        [Parameter(Mandatory)][int]$HopCount
    )

    if ($HopCount -le 0) {
        return @{
            Status = "Indeterminate"
            Detail = "No hop IPs observed (timeouts or filtering). Try increasing -w or -h."
        }
    }
    elseif ($HopCount -eq 1) {
        return @{
            Status = "Likely NO CG-NAT"
            Detail = "Your WAN IP is reachable in 1 hop (direct)."
        }
    }
    else {
        return @{
            Status = "May have CG-NAT or are using a VPN"
            Detail = "Your WAN IP required more than 1 hop."
        }
    }
}

# ---- Main ----

$wanIP = Get-PublicIPAddress
Write-Host "Detected WAN IPv4: $wanIP"

Write-Host "Running traceroute to $wanIP (IPv4, no DNS, 100ms timeout, max $MaxHops hops)..."
$hops = Get-TracerouteHops -Destination $wanIP -MaxHops $MaxHops

if ($hops.Count -gt 0) {
    Write-Host "Observed hops to $wanIP"
    $i = 1
    foreach ($h in $hops) {
        Write-Host ("  {0,2}: {1}" -f $i, $h)
        $i++
    }
} else {
    Write-Host "No hop IPs observed."
}

$result = Assess-CGNATOrVPN -HopCount $hops.Count
Write-Host ""
Write-Host "Assessment: $($result.Status)"
Write-Host "Details   : $($result.Detail)"
Write-Host ("Total hops: {0}" -f $hops.Count)
