*This script collects information of DL and BL Servers using HPiLORESTCmdlets

Prerequisites:
- Windows POwerShell 5.0
- HPiLORESTCmdlets ( see instructions below)


Process
 - Open a Windows PowerShell in administrator mode from your desktop
 - Install HPiLORESTCmdlets by executing the command: Install-Module HPRESTCmdlets 
	Note: It needs access to the Internet
 - Create an iloserver.csv that conatins: iLO Ipaddress, Username , password ( see sample)


Run the script
 .\Get-SystemInventory.ps1 -iloServerCSV iloServer.csv


Result:
 - List of CSV files ( see samples in ZIP)