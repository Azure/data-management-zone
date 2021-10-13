# Self-hosted Agents

The Enterprise-Scale reference architecture is secure by design and uses a multi-layered security approach to overcome common data exfiltration risks raised by customers. Features on a network, identity, data and service layer, enable customers to define granular access controls to only expose required data to a user. Even if some of these security mechanisms fail, data within the ESA platform stays secure.

```powershell
$vmSizes=Get-AzComputeResourceSku | where{$_.ResourceType -eq 'virtualMachines' -and $_.Locations.Contains('CentralUSEUAP')} 

foreach($vmSize in $vmSizes)
{
   foreach($capability in $vmSize.capabilities)
   {
       if($capability.Name -eq 'EphemeralOSDiskSupported' -and $capability.Value -eq 'true')
       {
           $vmSize
       }
   }
}
```