# upbanking
Some different methods to get Details from your UP Bank via their API through Different Windows Applications.

#upbanking-powershell
This is a powershell script used to pull information about your bank details.
Modify the first line that holds the API Authorisation Key to be the one you get from your account.

Commands
Get-UpBank-Accounts
  Returns a list of all UP Bank Accounts with the following information
    - Account_ID (Internal GUID used to identify your account information)
    - Account_Name (The Display Name you have given your account)
    - Account_Type (Transactional / Saver)
    - Account_Currency (Base Currency for the account)
    - Account_Balance (Current Balance of your Account)
    
Get-UPBank-Categories
  Returns an UP Predefined list of Categories provided by UP for assigning to your purchases
  
Get-UPBank-Transactions
  Requires Name of an Account (Should Auto Populate)
  
  Returns Transactions for that account with basic information returned
    - Transaction_ID 
    - Transaction_Status (If it hasn't settled yet - it will show as held here)
    - Transaction_Description
    - Transaction_Message (When sending money to someone else - this is what would show in the optional message field)
    - Transaction_currency (Currency Transaction Happened In)
    - Transaction_Created (Date of Transaction)
    - Transaction_Settled (Date transaction was settled in your account)
    - Transaction_Category (Any categories assigned to the transaction - Null if Transfer)
    - Transaction_Tags (Any Tags assigned to the transaction)
