$APIAUTH = "up:demo:2gL8KkZ1QBIqxflX"
$UPBankingAPI = @{uri = 'https://api.up.com.au/api/v1/util/ping';
                   Method = 'Get'; #(or POST, or whatever)
                   Headers = @{
                                Authorization = "Bearer " + "$($APIAUTH)";
                            } #end headers hash table
           }
Function Get-UPBank-Accounts {
    [cmdletbinding()]
    Param (
            [Int]$PageSize
        )
    
    If ($PageSize) {
        $UPBankingAPI.uri = "https://api.up.com.au/api/v1/accounts?page[size]=$PageSize"
    } Else {
        $UPBankingAPI.uri = "https://api.up.com.au/api/v1/accounts"
    }
    $UpAccounts = Invoke-RestMethod @UPBankingAPI
    $UpAccountSummary = @()
    Do {
        
        ForEach ($Page in $UpAccounts.Data) {
            $AccountDetails = New-Object psobject
            $AccountDetails | Add-Member -MemberType NoteProperty -Name "Account_id" -Value $Page.id
            $AccountDetails | Add-Member -MemberType NoteProperty -Name "Account_Name" -Value $Page.attributes.displayName
            $AccountDetails | Add-Member -MemberType NoteProperty -Name "Account_Type" -Value $Page.attributes.accountType
            $AccountDetails | Add-Member -MemberType NoteProperty -Name "Account_Currency" -Value $Page.attributes.balance.currencycode
            $AccountDetails | Add-Member -MemberType NoteProperty -Name "Account_Balance" -Value $Page.attributes.balance.value

            $UpAccountSummary += $AccountDetails

            If ($UPAccounts.links.next) {
                $UPBankingAPI.uri = $UPAccounts.links.next
                $UpAccounts = Invoke-RestMethod @UPBankingAPI
            }
        }
    } Until ($UpAccounts.links.next -eq $null)
    
    $UPBankAccounts = $UpAccountSummary

    Return $UpAccountSummary
}
Function Get-UPBank-Categories {
[cmdletbinding()]
    Param ()

    $UPBankingAPI.uri = "https://api.up.com.au/api/v1/categories"
    $UPBankingCategories = Invoke-RestMethod @UPBankingAPI
    $UpCategories = @()

    ForEach ($Category in $UPBankingCategories.data) {
        $CategoryDetails = New-Object psobject
        $CategoryDetails | Add-Member -MemberType NoteProperty -Name "id" -Value $Category.id
        $CategoryDetails | Add-Member -MemberType NoteProperty -Name "Name" -Value $Category.attributes.name
        $UpCategories += $CategoryDetails
    }
    
    Return $UpCategories

}
Function Get-UPBank-Transactions {
    [cmdletbinding()]
    Param (
            [switch]$all
        )
        DynamicParam  {
                    $ParameterName = 'AccountName'
                    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
                    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
                    $ParameterAttribute.Mandatory = $true
                    $ParameterAttribute.Position = 1
                    $AttributeCollection.Add($ParameterAttribute)
                    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
                    $ParameterValidateSet = (Get-UPBank-Accounts).Account_Name
                    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ParameterValidateSet)
                    $AttributeCollection.Add($ValidateSetAttribute) 
                    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
                    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter) 
                    return $RuntimeParameterDictionary
        }
     Begin {
        $UpAccountName = $PsBoundParameters[$ParameterName]
     }

     Process {
        $UPBankAccounts = Get-UPBank-Accounts
        $TransactionURIID = ($UPBankAccounts | Where-Object {$_.Account_Name -eq $UpAccountName}).Account_id
        $UPBankingAPI.uri = "https://api.up.com.au/api/v1/accounts/$TransactionURIID/transactions"
        $UpTransactions = Invoke-RestMethod @UPBankingAPI
        
        $Transactions = @()

        Do {
            ForEach ($Page in $UpTransactions.Data) {
               $TransactionDetails = New-Object psobject
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_ID" -Value $Page.id
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Status" -Value $Page.attributes.status
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Description" -Value $Page.attributes.description
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Message" -Value $Page.attributes.message
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Currency" -Value $Page.attributes.amount.currencyCode
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Value" -Value $Page.attributes.amount.value
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Created" -Value $Page.attributes.createdAt
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Settled" -Value $Page.attributes.settledAt
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Category" -Value $Page.relationships.category.data
               $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Tags" -Value $Page.relationships.tags.data

               If (!($Page.relationships.category.data)) {
                    $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Type" -Value "Transfer"
               } Else {
                    $TransactionDetails | Add-Member -MemberType NoteProperty -Name "Transaction_Type" -Value "Transaction"
               }

               $Transactions += $TransactionDetails

               If ($UpTransactions.Links.next) {
                    $UPBankingAPI.uri = $UpTransactions.links.next
                    $UpTransactions = Invoke-RestMethod @UPBankingAPI
               }
            }
        } Until ($UpTransactions.links.next -eq $null)

        Return $Transactions
    }
}
