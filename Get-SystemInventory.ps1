## -------------------------------------------------------------------------------------------------------------
## 
##
##      Description: Inventory of server
##
## DISCLAIMER
## The sample scripts are not supported under any HP standard support program or service.
## The sample scripts are provided AS IS without warranty of any kind. 
## HP further disclaims all implied warranties including, without limitation, any implied 
## warranties of merchantability or of fitness for a particular purpose. 
##
##    
## Scenario
##     	Use iLO to collect information about servers
##      Use HP Rest API on iLO
##
## Reference
##
##      http://h22208.www2.hp.com/eginfolib/servers/docs/HPRestfultool/iLo4/data_model_reference.html
##      http://www8.hp.com/us/en/products/servers/proliant/restful-interface-tool.html
##		
##
## Input parameters:
##       Option 1: Specify list of iLO Ip address and credenials in a CSV file
##                  Format is :  iLO, user, password
##                 iLOServerCSV                       = path to the CSV file containing Server ILO/user/password
##
##       Option 2: Specify one IP address and credential. Will be used per server
##
##       Option 3: TBD - Range of iLO 
##
## History: 
##         Oct-2015: v1.0 - Initial release
##
##
## Prerequisites
##        iLO v2.30 or greater
##
## Platform tested
##        Blade Gen 8 servers
##        Blade Gen9 servers
##
## Contact: Dung.HoangKhac@hp.com
##
## -------------------------------------------------------------------------------------------------------------
<#
  .SYNOPSIS
    Perform an inventory of server hw components  
  
  .DESCRIPTION
    Perform an inventory of server hw components using the iLO REST API.
    The iLO REST API is available for iLO version 4.
    Works on G8 and Gen 9 servers. 
        
  .EXAMPLE
    Get-SystemInventory.ps1  -iLOServerCSV c:\iLO.CSV
    Get-SystemInventory.ps1  -iLOIP 10.254.1.171 -iLOAdminName administrator -iLOPassword <password>

  .PARAMETER iLOServerCSV
    Name of the CSV file containing iLO address, ILO admin name, iLO password
    The format is: iLO,user,password

  .PARAMETER iLOIP
    IP V4 address of the ILO board

  .PARAMETER iLOAdminName
    Name of an iLO admin account

  .PARAMETER iLOPassword
    Password of the iLO admin account

  .Notes
    NAME:  Get-SystemInventory.ps1
    LASTEDIT: 10/13/2015
    KEYWORDS: iLO REST
   
  .Link
    http://h22208.www2.hp.com/eginfolib/servers/docs/HPRestfultool/iLo4/data_model_reference.html
    http://www8.hp.com/us/en/products/servers/proliant/restful-interface-tool.html
    http://www.powershellgallery.com/packages/HPRESTCmdlets/
 
 #Requires PS -Version 4.0

 #>

[CmdletBinding(DefaultParametersetName="CSV")] 

Param (

[Parameter(ParameterSetName="CSV")]
        [string]$iLOServerCSV ="c:\hpiloCmdlets\Test-iLO.csv",

[Parameter(ParameterSetName="OneIP")]
        [string]$iLOIP        = "",

#[Parameter(ParameterSetName="Range")]
# To Be Reviewed
#        [string]$iLOIPstart   = "",
#        [string]$iLOIPend     = "",

[Parameter(ParameterSetName="OneIP",Mandatory=$true)]
#[Parameter(ParameterSetName="Range",Mandatory=$true)]
[ValidateNotNullOrEmpty()]
        [string]$iLOAdminName = "",

[Parameter(ParameterSetName="OneIP",Mandatory=$true)]
#[Parameter(ParameterSetName="Range",Mandatory=$true)]
[ValidateNotNullOrEmpty()]
        [string]$iLOPassword  = ""

        )
$iLOREST       = 'HPRESTCmdLets' 
#$iLORESTModule = 'C:\Program Files\WindowsPowerShell\Modules\HPRESTCmdlets\1.0.0.1\HPRESTCmdlets.psm1'

$RESTRoot      = "/rest/v1"
$RESTAccount   = "/rest/v1/AccountService"
$RESTChassis   = "/rest/v1/Chassis"
$RESTEvent     = "/rest/v1/EventService"
$RESTManagers  = "/rest/v1/Managers"
$RESTSession   = "/rest/v1/SessionService"
$RESTSystems   = "/rest/v1/Systems"



$BL           = 'Blade'
$ThisSession  = [PSCustomobject]""

## -------------------------------------------------------------------------------------------------------------
##
##                     Function New-InventoryFiles
##
## -------------------------------------------------------------------------------------------------------------
Function New-InventoryFiles 
{

Param ([string]$Enclosure,[string]$headerprefix)

    # ---------------------------
    #  Generate Output files

    $TimeStamp = get-date -format MMMyyyy 

    $script:Fwfile  = "$Enclosure-FW-$TimeStamp.CSV"
    $script:CPUfile = "$Enclosure-CPU-$TimeStamp.CSV"
    $script:PDFile  = "$Enclosure-PhysicalDisk-$TimeStamp.CSV"
    $script:LDFile  = "$Enclosure-LogicalDisk-$TimeStamp.CSV"

    $script:MemFile = "$Enclosure-Memory-$TimeStamp.CSV"
    $script:NicFile = "$Enclosure-NIC-$TimeStamp.CSV"
    $script:iLOFile = "$Enclosure-ILO-$TimeStamp.CSV"

    if (-not (test-path $Script:FwFile))
    {
        $FirmwareCSV = New-Item $script:FwFile  -type file -force
        Set-content -Path $script:FwFile -Value "$HeaderPrefix,Fw Name,Fw Version"
    }

    # ---Generate header for NIC CSV file
    if (-not (test-path $Script:NicFile))
    {
        $NicCSV = New-Item $script:NicFile  -type file -force
        Set-content -Path $script:NicFile -Value "$HeaderPrefix,AdapterName,MAC Address,IP Address,Connected to,State"
    }

    # ---Generate header for 'Physical Disk'  CSV file
        if (-not (test-path $Script:PDFile))
    {
       $PDCSV = New-Item $script:PDFile  -type file -force
       Set-content -Path $script:PDFile -Value "$HeaderPrefix,Controller Model,Controller FW,Controller S/N,Disk Number,Disk Size,Disk S/N,Disk Type,Disk Model"
    }

    # ---Generate header for 'Logical Disk'  CSV file
    if (-not (test-path $Script:LDFile))
    {
       $LDCSV = New-Item $script:LDFile  -type file -force
       Set-content -Path $script:LDFile -Value "$HeaderPrefix,Controller Model,Controller FW,Controller S/N,RAID Type,Logical Drive Size"
    }

    # ---Generate header for 'Physical Disk'  CSV file
        if (-not (test-path $Script:MemFile))
    {
        # ---Generate header for Memory CSV file
        $MemCSV = New-Item $script:MemFile  -type file -force
        Set-content -Path $script:MemFile -Value "$HeaderPrefix,Location,State,Memory Type,Size(GB),Freq,P/N"
    }

    # ---Generate header for CPU CSV file
    if (-not (test-path $Script:CPUFile))
    {
        $CpuCSV = New-Item $script:CPUFile  -type file -force
        Set-content -Path $script:CpuFile -Value "$headerprefix,Count,Model,Memory(GB),Status" 
    }

    # ---Generate header for ILO CSV file
    if (-not (test-path $Script:iLOFile))
    {
        $iLOCSV = New-Item $script:iLOFile  -type file -force
        Set-content -Path $script:iLOFile -Value "$headerprefix,Host Name,Subnet,Gateway,Name Servers,Mac Address,Firmware, Model" 
    }


                    


} # End Function New-Inventory


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerFWInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerFWInfo
{
    Param([string]$Prefix)

    $Systems = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $FwRef = "$sys/firmwareInventory"
        $FWInventory =  Get-HPRESTDataRaw -session $script:ThisSession -href $FwRef
        foreach ($item in $FWInventory.Current)
        {
   
            foreach ( $prop in ($item.psobject.Properties.Value))
            {
                if ($Prop.Name )
                {
                                # "$headerprefix,Fw Name,Fw Version"
                    $sFWArray += "$Prefix,$($prop.Name),$($Prop.VersionString)`n"  
                }
            }
        }
    }
    return $sFWArray

} # End Collect-ServerFWInfo


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerNICInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerNICInfo
{
    Param([string]$Prefix)

    $Systems = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $AdapterRef = "$sys/networkadapters"
        $Networks   =  Get-HPRESTDataRaw -session $script:ThisSession -href $AdapterRef
        foreach ($Nic in $Networks)
        { 
            foreach ($NicRef in $Nic.Links.member.href)
            {
                $NicInventory = Get-HPRESTDataRaw -session $script:ThisSession -href $Nicref
                foreach ($item in $NicInventory)
                {
                    $AdapterName = $item.Name
                    foreach ( $port in $($item.PhysicalPorts) )
                    {
                        $MAC   = $port.MacAddress
                        $VCNet = $port.Name
                        $state = $port.Status.state
                        $IP    = $port.IPV4Addresses
                

                                    # "$HeaderPrefix,AdapterName,MAC Address,IP Address,Connected to,State"
                        $sNicArray += "$Prefix,$AdapterName,$MAC,$IP,$VCNet,$state`n"  

                    }
                }
            }
        }

    }
    return $sNicArray

} # End Collect-ServerNICInfo


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerDiskInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerDiskInfo
{
    Param([string]$Prefix)

    $Systems = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $ControllerRef            = "$sys/Smartstorage/ArrayControllers"
        $ArrayControllers         =  Get-HPRESTDataRaw -session $script:ThisSession -href $ControllerRef
        foreach ($C in $ArrayControllers.links.member.href)
        { 
            $ThisController = Get-HPRESTDataRaw -session $script:ThisSession -href $C

            $FwVersion      = $ThisController.FirmwareVersion.Current.VersionString
            $Model          = $ThisController.Model
            $SN             = $Thiscontroller.SerialNumber
            
            $MemCache = "0"
            if ($Script:EnclosureName -eq $BL)
            {
                $MemCache       = $Thiscontroller.CacheMemorySizeMiB
            }

            # Get Logical Drives info
            $LDrivesref     = $Thiscontroller.Links.LogicalDrives.href

            $LDInventory = Get-HPRESTDataRaw -session $script:ThisSession -href $LDrivesref
            foreach ($LDref in $LDInventory.links.member.href)
            {
                $LD         = Get-HPRESTDataRaw -session $script:ThisSession -href $LDref
                $LDCapacity = $LD.CapacityMiB
                $LDSize     = $LD.StripeSizeBytes
                $LDRaidType = $LD.Raid

                            # $HeaderPrefix,Controller Model,Controller FW,Controller S/N,RAID Type,Logical Drive Size"
                $sLDArray += "$Prefix,$Model,$FWVersion,$SN,$LDRaidType,$LDCapacity`n"  

                
            }
            

            # Get Physical Drives info
            $PDCount         = 0
            $PDrivesRef      = $Thiscontroller.Links.PhysicalDrives.href

            $PDInventory = Get-HPRESTDataRaw -session $script:ThisSession -href $PDrivesref
            foreach ($PDRef in $PDinventory.Links.member.href)
            {
                $PD          = Get-HPRESTDataRaw -session $script:ThisSession -href $PDref
                $PDCount++
                $PDModel     = $PD.Model
                $PDSN        = $PD.SerialNumber
                $PDMediaType = $PD.MediaType
                $PDCapacity  = $PD.CapacityMiB
                

            #         $HeaderPrefix,Controller Model,Controller FW,Controller S/N,Disk Number,Disk Size,Disk S/N, Disk Type, Disk Model"
                $sPDArray += "$Prefix,$Model,$FWVersion,$SN,$PDCount,$PDCapacity,$PDSN,$PDMediatype,$PDModel`n"  
                
            }


        }

    }
    return $sLDArray,$sPDArray

} # End Collect-ServerDiskInfo



## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerMemoryInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerMemoryInfo
{
    Param([string]$Prefix)

    $Systems = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $MemoryRef                = "$sys/Memory"
        $MemBank                  =  Get-HPRESTDataRaw -session $script:ThisSession -href $MemoryRef
        foreach ($m in $MemBank.links.member.href)
        { 
            $ThisDim        = Get-HPRESTDataRaw -session $script:ThisSession -href $m
            $SocketLocator  = $ThisDim.SocketLocator
            $MemSize        = $ThisDim.SizeMB / 1KB
            $DimType        = $ThisDim.DimmType
            $PartNum        = $ThisDim.PartNumber
            $Freq           = $ThisDim.MaximumFrequencyMHz
            $status         = $ThisDim.DIMMStatus

                              #"$HeaderPrefix,Location,State,Memory Type,Size(GB),Freq,P/N
            $sMemArray      += "$Prefix,$SocketLocator,$status,$DimType,$MemSize,$Freq,$PartNum`n"
        }

    }
    return $sMemArray

} # End Collect-ServerMemoryInfo

## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServerCPUInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServerCPUInfo
{
    Param([string]$Prefix)

    $Systems = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTSystems
    foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
    {
        $C         = Get-HPRestDataRaw -Session $script:ThisSession -href $sys
        $CPU       = $C.Processors
        $CPUCount  = $CPU.Count
        $CPUModel  = $CPU.ProcessorFamily
        $CPUStatus = $CPU.Status.HealthRollUp
        $Mem       = $C.Memory.TotalSystemMemoryGB

                    # "$headerprefix,Count,Model,Memory(GB),Status" 
        $sCPUArray += "$prefix,$CPUCount,$CPUModel,$Mem,$CPUStatus`n" 

    }
    return $sCPUArray

} # End Collect-ServerCPUInfo


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Collect-ServeriLOInfo
##
## -------------------------------------------------------------------------------------------------------------
Function Collect-ServeriLOInfo
{
    Param([string]$Prefix)

    $Managers = Get-HPRESTDataRaw -session $script:ThisSession -href $RESTManagers
    foreach ($mgrRef in $Managers.links.member.href) # /rest/v1/managers/1 or /rest/v1/managers/2
    {
        $mgr       = Get-HPRestDataRaw -Session $script:ThisSession -href $mgrRef

        $iLOFW     = $mgr.FirmwareVersion
        $iLOModel  = $mgr.Model
        
        foreach ($enetRef in $mgr.links.EthernetNICs.href)
        {
            $enet  = Get-HPRestDataRaw -Session $script:ThisSession -href $enetRef
            foreach ($interfaceRef in $enet.links.member.href)
            {
                $inter      = get-HPRestDataRaw -Session $script:ThisSession -href $interfaceRef
                $iLOFQDN    = $inter.FQDN
                $iLOMAC     = $inter.MacAddress
                $iLONS      = "" 

                if ($Script:EnclosureName -eq $BL)
                {
                    if (-not [system.string]::IsNullOrEmpty($inter.NameServers))
                    {
                        $iLONS      = [system.string]::Join("|", $inter.NameServers)
                    }
                }
                $IPV4       = $inter.IPV4Addresses
                foreach ($i in $IPV4)
                {
                    $iLOIP      = $i.Address
                    $iLODHCP    = $i.AddressOrigin
                    $iLOGW      = $i.Gateway
                    $iLOSubnet  = $i.SubnetMask

                                # "$headerprefix,Host Name,Subnet,Gateway,Name Servers,MAC Address,Firmware, Model"
                    $sILOArray += "$Prefix,$iLOFQDN,$iLOSubnet,$iLOGW,$iLONS,$ILOMAC,$iLOFW,$iLOModel`n"
                    
                }

            }


        }


    }
    return $siLOArray

} # End Collect-ServeriLOInfo


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Process_1Server
##
## -------------------------------------------------------------------------------------------------------------
Function Process_1Server
{
    Param (
        [string]$iLOIP,
        [string]$iLOAdminName,
        [string]$iLOPassword  
    )

    #TBD
    # Validate input

    # Make the connection
    $script:ThisSession = Connect-HPRest -Address $iLOIP -Username $iLOAdminName -Password $iLOPassword –DisableCertificateAuthentication 

    #TBD Chekc if session exists

    # Get Server information
    $RefChassis = "$RESTChassis/1" 
    $ThisChassis = Get-HPRestDataRaw -Session $script:ThisSession -href $RefChassis
    
    #TBD Check if exists
    
    $sType  = $ThisChassis.ChassisType   # Blade or DL?
    $sModel = $ThisChassis.model
    $sSKU   = $ThisChassis.SKU
    
    
    if ($sType -eq $BL)
    {
        $Manufacturer  = $ThisChassis.Manufacturer
        $ThisOEM       = $ThisChassis.oem.$Manufacturer

        $sBayNumber           = $ThisOEM.BayNumber
        $script:EnclosureName = $ThisOEM.Location.GeographicLocation.RackName
        $Prefix               = "$Server,$sBayNumber,$iLOIP" 
        $HeaderPrefix         = "Server,BayNumber,iLOIP" 
    }
    else # Not BL
    {
        $script:EnclosureName = "DL"
        $sBayNumber           = ""
        $Prefix               = "$Server,$iLOIP" 
        $HeaderPrefix         = "Server,iLOIP"
    }

        
    # generate inventory files 
    New-InventoryFiles -Enclosure $script:enclosurename -headerprefix $HeaderPrefix

    write-host -ForegroundColor white "`n Collecting FW/Network/Storage/CPU/Memory/iLO information from iLO $iLOIP...." 

    # Collect FW info on servers 
    $sFWArray = Collect-ServerFWInfo -Prefix $Prefix
    add-content -path $script:FwFile   -Value $sFwArray

    # Collect Network info
    $sNicArray = Collect-ServerNICInfo -Prefix $Prefix
    add-content -path $script:NicFile   -Value $sNicArray

    # Collect Storage info
    $sLDArray, $sPDArray = Collect-ServerDiskInfo -Prefix $Prefix
    add-content -path $script:LDFile   -Value $sLDArray    # Logical Disk
    add-content -path $script:PDFile   -Value $sPDArray    # Physical Disk

    # Collect Memory info
    $sMemArray = Collect-ServerMemoryInfo -Prefix $Prefix
    add-content -path $script:MemFile   -Value $sMemArray

    # Collect Processor info
    $sCPUArray = Collect-ServerCPUInfo -Prefix $Prefix
    add-content -path $script:CPUFile   -Value $sCPUArray

    # Collect iLO info
    $siLOArray = Collect-ServeriLOInfo -Prefix $Prefix
    add-content -path $script:iLOFile   -Value $siLOArray

} # End function - Process_1Server


## -------------------------------------------------------------------------------------------------------------
##
##                     Function Process_1Server
##
## -------------------------------------------------------------------------------------------------------------

# ----------------------------
# Check input file

switch ($PSCmdlet.ParameterSetName)
{

    "OneIP" 
        {
            if ( -not( [string]::IsNullOrEmpty($iLOAdminName) -or [string]::IsNullOrEmpty($iLOPassword) ))
            {
                Process_1Server -iLOIP $iLOIP -iLOAdminName $iLOAdminName -iLOPassword $iLOPassword      
            }
            else
            {
                write-host " ILO Credential not specified - iLOAdminName and/or iLO Password" 
            }

        }

    "Range"
        {
            #TBD

        }

     "CSV"
        {
            if ( -not $iLOServerCSV)
            {
                write-host "No file specified in -iLOServerCSV ."                return
            }

            if ( -not (Test-path $iLOServerCSV) )
            {
                write-host "File $iLOServerCSV does not exist."                return            }            # ----------------------------            #   Process the input file            # Read the CSV Users file            $tempFile = [IO.Path]::GetTempFileName()            type $iLOServerCSV | where { ($_ -notlike ",,,,*") -and ( $_ -notlike "#*") -and ($_ -notlike ",,,#*") } > $tempfile   # Skip blank line                $ListofServers = import-csv $tempfile


            foreach ($s in $ListofServers)
            {
                $serverIP   = $s.iLO
                $user       = $s.User
                $password   = $s.Password
                Process_1Server -iLOIP $serverIP -iLOAdminName $user -iLOPassword $password
            }        

        }

}


