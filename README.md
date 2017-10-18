# parse-ConnectorSpaceOutput.ps1
  
  When troubleshooting issues using the synchronization engine for FIM/MIM and Azure AD connect you may need to export the connector spaces. These exported files are in an XML format, and can be hard to filter or find usable information. By converting to a CSV, an admin can easily filter these files using Excel or equivalent.
  For more info: https://technet.microsoft.com/en-us/library/jj590346(v=ws.10).aspx  
  At the moment the script is intended for use with XML outputted from an Azure AD Connect installation. Additional features could be added to support more exports, as well as relate connector space GUIDs to users.
  
  Use the script like below:
  .\parse-ConnectorSpaceOutput.ps1 -xmltoimport <path to csexport XML> -showOutput:$true
  
  You could run against all exported Connector space XMLs like this:
  Get-ChildItem *.xml | foreach{.\parse-ConnectorSpaceOutput.ps1 -xmltoimport $_.FullName}
