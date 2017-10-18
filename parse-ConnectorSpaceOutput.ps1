Param(
    [Parameter(Mandatory=$true, HelpMessage="Must be a file generated using csexport 'Name of Connector' export.xml)")]
    [string]$xmltoimport="%temp%\exportedStage1a.xml",
    [Parameter(Mandatory=$false, HelpMessage="Maximum number of users per output file")][int]$batchsize=1000,
    [Parameter(Mandatory=$false, HelpMessage="Show console output")][bool]$showOutput=$false
)

#LINQ isn't loaded automatically, so force it
[Reflection.Assembly]::Load("System.Xml.Linq, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089") | Out-Null

[int]$count=1
[int]$outputfilecount=1
[array]$objOutputUsers=@()

#XML must be generated using "csexport "Name of Connector" export.xml /f:x"
write-host "Importing XML" -ForegroundColor Yellow

#XmlReader.Create won't properly resolve the file location,
#so expand and then resolve it
$resolvedXMLtoimport=Resolve-Path -Path ([Environment]::ExpandEnvironmentVariables($xmltoimport))

#use an XmlReader to deal with even large files
$result=$reader = [System.Xml.XmlReader]::Create($resolvedXMLtoimport) 
$result=$reader.ReadToDescendant('cs-object')
$csobjhash = @{}
if($result -ne $false){
    do 
    {
    
        #old code
        #create the object placeholder
        #adding them up here means we can enforce consistency
        $objOutputUser=New-Object psobject
        Add-Member -inputobject $objOutputUser -MemberType NoteProperty -Name DN -Value ""    
        Add-Member -InputObject $objOutputUser -MemberType NoteProperty -Name ObjectType -Value ""
        Add-Member -InputObject $objOutputUser -MemberType NoteProperty -Name ConnectorSpaceGuid -Value ""
        Add-Member -InputObject $objOutputUser -MemberType NoteProperty -Name DateOccurred -Value ""
        Add-Member -InputObject $objOutputUser -MemberType NoteProperty -Name RetryCount -Value ""
        Add-Member -InputObject $objOutputUser -MemberType NoteProperty -Name ErrorType -Value ""
        Add-Member -inputobject $objOutputUser -MemberType NoteProperty -Name ProvisioningStep -Value ""
        Add-Member -inputobject $objOutputUser -MemberType NoteProperty -Name ErrorDetail -Value ""
        #/oldcode
    

        if ($showOutput) {Write-Host Found an exported object... -ForegroundColor Green}
        $user = [System.Xml.Linq.XElement]::ReadFrom($reader)


        $localname = $user.Nodes().Name.LocalName

        #dn
        $outDN= $user.Attribute('cs-dn').Value
        if ($showOutput) {Write-Host DN: $outDN}
        $objOutputUser.DN = $outDN

        #object id
        $outID=$user.Attribute('id').Value
        if ($showOutput) {Write-Host ID: $outID}
        $objOutputUser.ConnectorSpaceGuid = $outID

        #object type
        $outType=$user.Attribute('object-type').Value
        if ($showOutput) {Write-Host Type: $outType}
        $objOutputUser.ObjectType = $outType

        switch($localname){
            "export-errordetail"
            {
                if ($showOutput) {Write-Host LocalName: export-errordetail}
                $rootelements = @("export-status","cd-error")

            }
            "import-errordetail"
            {
                if ($showOutput) {Write-Host LocalName: import-errordetail}
                $rootelements = @("import-status","extension-error-info")
            }        
        }
    

        #reset variables
        $elementcount = 0
        $step = $null

        #retreive-Root Node subelements   
        $baseExpression = '$user.Element($localname)' 
        $rootnode = Invoke-Expression $baseExpression

        #pull attributes out of our root node
        if ($showOutput) {Write-Host Element: $($rootnode.Name) $elementcount}             

        [string]$dateoccured = $rootnode.Attribute("date-occurred").Value
        $dateoccured = ("'" + $dateoccured + "'")
        [int]$retrycount = $rootnode.Attribute("retry-count").Value
        $errorType = $rootnode.Attribute("error-type").Value
    
        $objOutputUser.DateOccurred = $dateoccured.ToString()
        if ($showOutput) {Write-Host Date: $dateoccured}
        $objOutputUser.RetryCount = $retrycount
        if ($showOutput) {Write-Host Retry: $retrycount}
        $objOutputUser.ErrorType = $errorType
        if ($showOutput) {Write-Host ErrorType: $errorType}

        #we must walk through all XML sub-elements specified in above switch statement
        foreach($subelement in $rootelements){
            $rootnode = $rootnode.Element($subelement)
            if ($showOutput) {Write-Host ElementName: $subelement $elementcount}

                                                                                                                                                                                                                                                                                            if(($rootnode).HasElements -eq $true -and $rootnode -ne $null){
            if($elementcount -eq 0){
                 if($localname -like "import*"){
                    $step = $rootnode.Element("algorithm-step").Value
                    if ($showOutput) {Write-Host Algorithm-Step: $step}           
                    }
                }         

            if($elementcount -eq 1){
                [array]$nodes = @($rootnode.Nodes().Name.Localname)

                if($nodes.Count -ne 0){
                    foreach($node in $nodes){
                
                        if ($showOutput) {Write-Host NodeinElement: $node}

                        $attribute = $rootnode.Element($node).Value

                        switch($node){
                            "extension-name"
                            {
                                if($step -ne $null){
                                    [string]$out = $step + ":" + $attribute
                                    }
                                else{
                                    [string]$out = $attribute
                                    }
                                $objOutputUser.ProvisioningStep = $out
                                if ($showOutput) {Write-Host ErrorType: $out}

                            }
                            "call-stack"
                            {
                                $objOutputUser.ErrorDetail = $attribute -replace ("`r|`n","")
                                if ($showOutput) {Write-Host ErrorDetail: $attribute}
                            }
                            "error-name"
                            {
                                $objOutputUser.ProvisioningStep = $attribute
                                if ($showOutput) {Write-Host ErrorType: $attribute}
                            }
                            "error-literal"
                            {

                                $tempdetails = $attribute
                                if ($showOutput) {Write-Host TempDetail: $tempdetails}

                            }
                            "extra-error-details"
                            {
                                $tempdetails = [string]($tempdetails + "`t" + $attribute) -replace ("`r|`n","")
                                $objOutputUser.ErrorDetail = $tempdetails
                                if ($showOutput) {Write-Host ErrorDetail: $tempdetails}
                            }
                            "error-code"
                            {
                                $objOutputUser.ProvisioningStep = $attribute
                                if ($showOutput) {Write-Host ErrorType: $attribute}
                            }
                            "server-error-detail"
                            {
                                [string]$tempdetails = $tempdetails + "`t" + $attribute
                                $objOutputUser.ErrorDetail = $tempdetails -replace ("`r|`n","")
                                if ($showOutput) {Write-Host ErrorDetail: $tempdetails}
                            }
                        }
                    }
                }
                Else{
                    Write-Host "No Sub-Nodes in Elemenet $subelement" -ForegroundColor Yellow
                }
            }
            }

            $elementcount ++

        }

        $objOutputUsers += $objOutputUser

        Write-Progress -activity "Processing ${xmltoimport} in batches of ${batchsize}" -status "Batch ${outputfilecount}: " -percentComplete (($objOutputUsers.Count / $batchsize) * 100)

        #every so often, dump the processed users in case we blow up somewhere
        if ($count % $batchsize -eq 0)
        {
            Write-Host Hit the maximum users processed without completion... -ForegroundColor Yellow

            #export the collection of users as as CSV
            Write-Host Writing processedusers${outputfilecount}.csv -ForegroundColor Yellow
            $objOutputUsers | Export-Csv -path processedusers${outputfilecount}.csv -NoTypeInformation

            #increment the output file counter
            $outputfilecount+=1

            #reset the collection and the user counter
            $objOutputUsers = $null
            $count=0
        }

        $count+=1

        #need to bail out of the loop if no more users to process
        if ($reader.NodeType -eq [System.Xml.XmlNodeType]::EndElement)
        {
            break
        }
    [string]$tempdetails = ""

    } while ($reader.Read)

    #need to write out any users that didn't get picked up in a batch of 1000
    #export the collection of users as as CSV

    $name = (Get-childitem $xmltoimport).Name.TrimEnd(".xml")
    Write-Host "Writing $name-process.csv" -ForegroundColor Yellow
    $objOutputUsers | Export-Csv -path $name-processed.csv -NoTypeInformation
}
else{
    Write-Host "Empty File: $xmltoimport" -ForegroundColor Red
}