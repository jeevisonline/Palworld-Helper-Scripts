<#
.SYNOPSIS
   UDP Port Testing tool entirely made in powershell.  Has only been seen to work with Palworld.

.DESCRIPTION
   This tool will allow you to send any data to a UDP port, and it will let you know if it received any data back.
   There are not many ways to test if a UDP port is open, so this is one of the ways that can work.

.PARAMETER IpAddress <string>
   Enter the IP address that you are testing the connection to.

.PARAMETER -Port <int>
   Enter the port number you want to test.

.PARAMETER Message "String"
    Optional
    The data you want to send.  This can be anything, as long as it is enclosed in quotes.

.EXAMPLE
   UDPTester.ps1 -IpAddress 127.0.0.1 -Port 8211

.OUTPUTS
   The script will output the response received if there is a response.  If not, it will display a message, and exit 1.

.NOTES
   v1.0 Jeevis created
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$IPAddress,
    [Parameter(Mandatory=$true)]
    [int]$Port,
    [string]$Message = "Hello!"
)

try {
    # Create UDP client
    $UdpClient = New-Object System.Net.Sockets.UdpClient

    # Send data to the specified IP address and port
    $EncodedMessage = [System.Text.Encoding]::ASCII.GetBytes($Message)
    $null = $UdpClient.Send($EncodedMessage, $EncodedMessage.Length, $IPAddress, $Port)

    Write-Host "Message sent to $IPAddress on port $Port"

    # Set the receive endpoint to the IP address and port
    $ReceiveEndpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Any, 0)

    # Set the UDP client receive timeout (e.g., 5000ms = 5 seconds)
    $UdpClient.Client.ReceiveTimeout = 5000

    # Listen for response
    try {
        $ReceivedData = $UdpClient.Receive([ref]$ReceiveEndpoint)
        $Response = [System.Text.Encoding]::ASCII.GetString($ReceivedData)
        Write-Host "Received response: $Response"
        exit 0  # Exit with status 0 if response is received
    } catch [System.Net.Sockets.SocketException] {
        Write-Host "No response received within the timeout period."
        exit 1  # Exit with status 1 if no response is received
    } finally {
        $UdpClient.Close()
    }
} catch {
    Write-Host "An error occurred: $_"
    exit 1  # Exit with status 1 if an error occurs
}
