<a name="title" />
# Deploying Active Directory #

---
<a name="Overview" />
## Overview ##

In this demonstration you will walk through the process of deploying a domain controller in Windows Azure. To deploy an Active Directory domain controller you must first configure a Windows Azure Virtual Network for IP persistence (non VNET deployments DHCP leases are short where a VNET deployment is perpetual). In many real world scenarios the VNET deployment would likely be connected with a site to site VPN tunnel. For this example you will only deploy a cloud only AD environment. 

<a name="technologies" />
### Key Technologies ###

- Windows Azure subscription - you can sign up for free trial [here][1]
- Windows Azure Virtual Machines 
- Windows Azure Virtual Networks
- [Windows Azure PowerShell Cmdlets][2]

[1]: http://bit.ly/WindowsAzureFreeTrial
[2]: http://go.microsoft.com/?linkid=9811175&clcid=0x409



<a name="setup" />
### Setup and Configuration ###

In order to execute this demo you need to set up your environment.

1. Download, Install and Configure the Windows Azure PowerShell cmdlets. Instructions on how to configuration the cmdlets with your subscription can be found here: http://msdn.microsoft.com/en-us/library/windowsazure/jj554332.aspx

1. Download and install the latest node.js library from: htt://node.js. 

1. Install the node.js command line tools for Windows Azure by running the following command at a command prompt:

	````PowerShell
	npm install azure -g
	````

1. Modify the Config.Azure.XML for your Windows Azure Subscription. The following values are needed:

	- Target Storage Account Name, Container and Key where the demo VHDs will be copied to. 
		- The Storage Account Should Be in West US to allow the VHDs to copy in a timely manner.
	- Subscription Name - value can be retrieved from PowerShell by running **Get-AzureSubscription | select SubscriptionName**.
   - Unique name for the Cloud Service container that will be used when creating the domain controller in the PowerShell Demo.
   - Unique name for the Cloud Service container that will be used when creating domain joined member servers using the PowerShell demo (must be different than the DC cloud service).

1. Run the **Setup-1.Azure.cmd** script to copy the prepared VHDs to your storage account (the storage account must be in West US).

1.  Run the **Setup-2.Azure.cmd** script to create the OS disk entry for the VM you will use to create AD.

> **Note:** In the script examples do not leave the [ ] brackets when replacing the tokens with your own values.


<a name="Demo" />
## Demo ##

1. Configure the demo virtual network that the demonstration virtual machines will be deployed to. 

1. Create an affinity group for your virtual network in the region where your cloud services will be hosted.
			![create-affinity-group](Images/create-affinity-group.png?raw=true)

1. Create a simple virtual network and specify the previously created affinity group along with a single subnet network configuration.

	![simple-vnet](Images/simple-vnet.png?raw=true)

1. Set the address space to 10.1.0.0/16 and add a subnet called AppSubnet with a range of 10.1.1.0/24.

	![simple-vnet-2](Images/simple-vnet-2.png?raw=true)

1. Accept the defaults for the rest of the configuration.

	![simple-vnet-3](Images/simple-vnet-3.png?raw=true)

<a name="segment1" />

1. Run powershell_ise and and run the following script. The script will provision a virtual machine from the disk that was copied over earlier. The disk already has the Active Directory role provisioned and a forest created. 

	````PowerShell
	# Create VMs	
	$addcvm = New-AzureVMConfig -Name 'ad-dc' -InstanceSize Small -DiskName 'ad-dcosdisk' |
          	Set-AzureOSDisk 'ReadOnly' |
          	Set-AzureSubnet 'AppSubnet' | 
  	  	Add-AzureEndpoint -Name RDP -LocalPort 3389 -Protocol tcp 
	
	New-AzureVM -ServiceName $xml.configuration.cloudServiceName1 -VMs $addcvm -AffinityGroup 'MyVNETAG' -VNETName 'SimpleVNET'
	
	````
	
	> **Speaking Point:** The script above specifies the subnet and virtual network for the virtual machine to boot up in. Since this VM will also be a domain controller you are setting the OS disk cache settings to be read only to reduce the risk of data corruption.

1. Once the virtual machine is booted RDP in using administrator@fabrikam.com as the login and pass@word1 as the password.

1. From a command line run ipconfig /all

1. Note the DHCP lease expiration to demonstrate that it is for all intents and purposes a static IP address. Also, save the IP address because you will now use it to configure a member server.

1. Paste in the following script to create a member server joined VM. Update the $dcip variable to use the IP address of the domain controller before running.

````PowerShell
$dcip = '[IP ADDRESS OF DOMAIN CONTROLLER]'

$subnet = 'AppSubnet'

$ou = 'OU=AzureVMs,DC=fabrikam,DC=com'

$dom = 'fabrikam'
$domjoin = 'fabrikam.com'
$domuser = 'administrator'
$image = 'MSFT__Windows-Server-2012-Datacenter-201208.01-en.us-30GB.vhd'


$domVM = New-AzureVMConfig -Name 'ad-ms1' -InstanceSize Small -ImageName $image |      
	
		Add-AzureProvisioningConfig -WindowsDomain -JoinDomain $domjoin -Domain $dom -DomainPassword $pass -Password $pass -DomainUserName $domuser -MachineObjectOU $ou |
                Set-AzureSubnet -SubnetNames $subnet



$dns = New-AzureDns -Name 'ad-dc' -IPAddress $dcip
     
New-AzureVM -ServiceName $xml.configuration.cloudServiceName2 -AffinityGroup 'MyVNETAG' -VNetName 'SimpleVNET' -DnsSettings $dns -VMs $domVM -DNSSettings $dns

````

> **Speaking Point:** The PowerShell script above creates a new Windows Server that is domain joined at boot time. The computer account will be created in the AzureVMs Organizational Unit. By specifying the IP address of the domain controller in the DNS Settings the member server will automatically be configured to communicate to AD. 

