 <#
.Description
Sets or removes DNS Zones for caching in the DNS Service.

.PARAMETER EmergencyShutOff
Used to remove the cache DNS Zones from the DNS service. This will send all traffic to the normal internet address and disable caching.
 
.PARAMETER CacheIp
Sets the IP Address for each caching DNS Zone to <IPAddress>. Set to the IP of your caching server. Must be a valid IP address.
#>

[CmdletBinding(DefaultParameterSetName = 'Cache')]
Param(
    [parameter(ParameterSetName="Emergency")][Switch]$EmergencyShutOff,
    [parameter(ParameterSetName="Cache",mandatory=$true)][IPAddress]$CacheIp
)

$microsoftZones = 'download.windowsupdate.com', 'tlu.dl.delivery.mp.microsoft.com',
    'officecdn.microsoft.com', 'officecdn.microsoft.com.edgesuite.net'
$googleZones = 'dl.google.com', 'gvt1.com'
$adobeZones = 'ardownload.adobe.com', 'ccmdl.adobe.com', 'agsupdate.adobe.com'

$zoneGroup = $microsoftZones + $googleZones + $adobeZones

function Set-CacheRecord {
    Param(
        [switch]$Wildcard,
        [switch]$Root,
        [string]$ZoneName
    )
    if ( $Wildcard ) {
        $record = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Node '*' -ErrorAction Ignore
        if ( $record -and $record.RecordData.IPv4Address -ne $CacheIp ) {
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -Name "*" -Confirm:$false
        }
        if ( !$record ) {
            Add-DnsServerResourceRecord -A -IPv4Address $CacheIp -Name "*" -ZoneName $ZoneName
        }
    }
    if ( $Root ) {
        $record = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A -Node '@' -ErrorAction Ignore
        if ( $record -and $record.RecordData.IPv4Address -ne $CacheIp ) {
            Remove-DnsServerResourceRecord -ZoneName $ZoneName -Name "@" -Confirm:$false
        }
        if ( !$record ) {
            Add-DnsServerResourceRecord -A -IPv4Address $CacheIp -Name "@" -ZoneName $ZoneName
        }
    }
}

# Emergency shut off section removes all cache zones from DNS
if ( $EmergencyShutOff ) {
    $zoneGroup.ForEach{Remove-DnsServerZone -Name $_ -Force -Confirm:$false}
}

else {
    foreach ( $z in $zoneGroup ) {
        try {
            $zone = Get-DnsServerZone -Name $z -ErrorAction Ignore
            if ( !$zone ) {
                Add-DnsServerPrimaryZone -Name $z -ReplicationScope Domain -DynamicUpdate None
            }
        }
        catch {
            $Error[0]
            break
        }

        switch -regex ( $z ) {
            '(download.windowsupdate.com|tlu.dl.delivery.mp.microsoft.com)' {
                try {
                    Set-CacheRecord -Wildcard -Root -ZoneName $z
                }
                catch {
                    $Error[0]
                    break
                }
            }
            'gvt1.com' {
                try {
                    Set-CacheRecord -Wildcard -ZoneName $z
                }
                catch {
                    $Error[0]
                    break        
                }
            }
            default {
                try {
                    Set-CacheRecord -Root -ZoneName $z
                }
                catch {
                    $Error[0]
                    break        
                }
            }
        }
    }
} 
