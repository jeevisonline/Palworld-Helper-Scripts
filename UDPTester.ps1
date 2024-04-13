<#
.SYNOPSIS
   UDP Port Testing tool entirely made in powershell.  Has only been seen to work with Palworld.

.DESCRIPTION
   This tool will allow you to send any data to a UDP port, and it will let you know if it received any data back.
   There are not many ways to test if a UDP port is open, so this is one of the ways that can work.

.PARAMETER IpAddress <string>
   Enter the IP address that you are testing the connection to.

.PARAMETER -Port <int>
   Optional
   Enter the port number you want to test.

.PARAMETER Message "String"
    Optional
    The data you want to send.  This can be anything, as long as it is enclosed in quotes.
    
.PARAMETER -Count <int>
   Optional
   Enter the amount of times you want to send a test.

.EXAMPLE
   UDPPortTest.ps1 -IpAddress 127.0.0.1
   UDPPortTest.ps1 -IpAddress 127.0.0.1 -Port 8222 -Message "Hello!" -Count 3

.OUTPUTS
   The script will output the response received if there is a response.  If not, it will display a message, and exit 1.

.NOTES
   v1.0 Jeevis created
   v1.1 Updated to support counts, as well as set 8211 to the default port.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,
    [int]$Port = 8211,
    [string]$Message = "Hello, UDP!",
    [int]$Count = 1
)

function Format-Hexadecimal {
    param(
        [byte[]]$Bytes,
        [int]$MaxBytesLength
    )
    # Join all bytes with a space for better readability
    return ($Bytes | ForEach-Object { "{0:X2}" -f $_ }) -join ' '
}

$TotalResponseTime = 0
$MaxResponseLength = 0
$MaxTimeLength = 0
$Responses = @()

Write-Host "Attempting to send $Count messages to $IPAddress on port $Port"
Write-Host "-------------------------------------------------------------"

for ($i = 0; $i -lt $Count; $i++) {
    try {
        $UdpClient = New-Object System.Net.Sockets.UdpClient
        $EncodedMessage = [System.Text.Encoding]::ASCII.GetBytes($Message)
        $null = $UdpClient.Send($EncodedMessage, $EncodedMessage.Length, $IPAddress, $Port)

        $ReceiveEndpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Any, 0)
        $UdpClient.Client.ReceiveTimeout = 5000

        $StartTime = Get-Date

        try {
            $ReceivedData = $UdpClient.Receive([ref]$ReceiveEndpoint)
            $ResponseTime = ((Get-Date) - $StartTime).TotalMilliseconds
            $TotalResponseTime += $ResponseTime

            if ($ReceivedData.Length -gt $MaxResponseLength) {
                $MaxResponseLength = $ReceivedData.Length
            }

            $ResponseTimeString = "{0:F4}ms" -f $ResponseTime
            if ($ResponseTimeString.Length -gt $MaxTimeLength) {
                $MaxTimeLength = $ResponseTimeString.Length
            }

            $Responses += @{TimeString = $ResponseTimeString; Data = $ReceivedData}
        } catch [System.Net.Sockets.SocketException] {
            Write-Host "No response received within the timeout period."
        } finally {
            $UdpClient.Close()
        }
    } catch {
        Write-Host "An error occurred: $_"
    }
}

if ($Responses.Count -gt 0) {
    foreach ($Response in $Responses) {
        $PaddedTime = $Response.TimeString.PadRight($MaxTimeLength)
        $HexResponse = Format-Hexadecimal -Bytes $Response.Data -MaxBytesLength $MaxResponseLength
        Write-Host ("Received response in " + $PaddedTime + ": " + $HexResponse)
    }

    if ($Count -gt 1) {
        $AverageResponseTime = $TotalResponseTime / $Count
        Write-Host "-------------------------------------------------------------"
        Write-Host "Average response time: $($AverageResponseTime)ms"
    }
} else {
    Write-Host "No responses were received."
}
