Demo-DeployAD
===================

## Overview ##

In this demonstration you will walk through the process of deploying a domain controller in Windows Azure. To deploy an Active Directory domain controller you must first configure a Windows Azure Virtual Network for IP persistence (non VNET deployments DHCP leases are short where a VNET deployment is perpetual). In many real world scenarios the VNET deployment would likely be connected with a site to site VPN tunnel. For this example you will only deploy a cloud only AD environment. 

<a name="technologies" />
### Key Technologies ###

- Windows Azure Virtual Machines 
- Windows Azure Virtual Networks
- Windows Azure PowerShell Cmdlets