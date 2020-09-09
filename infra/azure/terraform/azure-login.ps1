param(
    [Parameter(Mandatory = $true)] 
    [string] $userName, 
    [Parameter(Mandatory = $true)]
    [SecureString] $password)

az login -u $userName -p $password

