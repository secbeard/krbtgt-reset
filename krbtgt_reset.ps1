# Pascal Bourbonnais 2024

#region gen password

# generate and confirm password function from: https://github.com/microsoftarchive/New-KrbtgtKeys.ps1/blob/master/New-KrbtgtKeys.ps1

Function confirmPasswordIsComplex($pwd) {
    Process {
        $criteriaMet = 0
		
        # Upper Case Characters (A through Z, with diacritic marks, Greek and Cyrillic characters)
        If ($pwd -cmatch '[A-Z]') {$criteriaMet++}
		
        # Lower Case Characters (a through z, sharp-s, with diacritic marks, Greek and Cyrillic characters)
        If ($pwd -cmatch '[a-z]') {$criteriaMet++}
		
        # Numeric Characters (0 through 9)
        If ($pwd -match '\d') {$criteriaMet++}
		
        # Special Chracters (Non-alphanumeric characters, currency symbols such as the Euro or British Pound are not counted as special characters for this policy setting)
        If ($pwd -match '[\^~!@#$%^&*_+=`|\\(){}\[\]:;"''<>,.?/]') {$criteriaMet++}
		
        # Check If It Matches Default Windows Complexity Requirements
        If ($criteriaMet -lt 3) {Return $false}
        If ($pwd.Length -lt 8) {Return $false}
        Return $true
    }
}

Function generateNewComplexPassword([int]$passwordNrChars) {
    Process {
        $iterations = 0
        Do {
            If ($iterations -ge 20) {
                Logging "  --> Complex password generation failed after '$iterations' iterations..." "ERROR"
                Logging "" "ERROR"
                EXIT
            }
            $iterations++
            $pwdBytes = @()
            $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
                Do {
                [byte[]]$byte = [byte]1
                $rng.GetBytes($byte)
                    If ($byte[0] -lt 33 -or $byte[0] -gt 126) {
                    CONTINUE
                    }
                $pwdBytes += $byte[0]
                }
            While ($pwdBytes.Count -lt $passwordNrChars)
            $pwd = ([char[]]$pwdBytes) -join ''
        } 
        Until (confirmPasswordIsComplex $pwd)
        Return $pwd
    }
}

#endregion gen password

$krbTGTMinTime = (Get-Date).AddHours(-12)
$allDC = Get-ADDomainController -Filter *
$pdc = $allDC.Where({$_.OperationMasterRoles -contains "PDCEmulator"}) | Select-Object -First 1
[int]$pwdLength = 64
New-EventLog -Source "pdcTasks" -LogName Application -ErrorAction Ignore

# I am the PDC
if ($env:COMPUTERNAME -eq $pdc.name) {
   
    $krbtgt = get-aduser krbtgt -Server $pdc -Properties passwordLastSet
    [bool]$proceed = $true

    # confirm password last set is older than: $krbTGTMinTime
    if ($krbtgt.PasswordLastSet -lt $krbTGTMinTime) {    

        $allRWDC = [System.Collections.ArrayList]@($allDC.Where({ ($_.OperationMasterRoles -notcontains "PDCEmulator") -and ($_.IsReadOnly -eq $false)}))

        foreach ($dc in $allRWDC) {
            #$replicationPartners = Get-ADReplicationPartnerMetadata -Target $dc -Scope Domain | Select-Object Server, LastReplicationSuccess

            # Get replication failures
            $repError = @(Get-ADReplicationFailure -Target $dc -Scope Domain | Select-Object Server, FirstFailureTime, FailureCount, FailureType)

            if ($repError.Count -gt 0) { 
                $proceed = $false
                Write-EventLog -LogName Application -Source "pdcTasks" -EventId 3 -EntryType Error -Message "Replication failure detected with $($dc.HostName)"
            }

            # check if krbtgt passwordLastSet is equivalent
            $partnerKrbtgt = get-aduser krbtgt -Server $dc -Properties passwordLastSet
            if ($partnerKrbtgt.PasswordLastSet -ne $krbtgt.PasswordLastSet) {
                $proceed = $false
                Write-EventLog -LogName Application -Source "pdcTasks" -EventId 5 -EntryType Error -Message "Mismatch KRBTGT password last set between PDC and $($dc.HostName)"
            }

        } # foreach ($dc in Get-ADDomainController -Filter *) {

        if ($proceed) {

            $newPwd = ConvertTo-SecureString -AsPlainText  -Force $(generateNewComplexPassword -passwordNrChars $pwdLength)
            
            # confirm the generated password length
            if ($newPwd.Length -eq $pwdLength) {

                Set-ADAccountPassword $krbtgt -Server $pdc -Reset -NewPassword $newPwd                           

                # confirm password last set is now newer than: $krbTGTMinTime
                $krbtgt = get-aduser krbtgt -Server $pdc -Properties passwordLastSet

                if ($krbtgt.PasswordLastSet -gt $krbTGTMinTime) {                    
                    Write-EventLog -LogName Application -Source "pdcTasks" -EventId 10 -EntryType Information -Message "KRBTGT password has been changed"
                } else {
                    Write-EventLog -LogName Application -Source "pdcTasks" -EventId 11 -EntryType Error -Message "KRBTGT password changed failed"
                }
            } # if ($newPwd.Length -eq $pwdLength) {
            
        } #  if ($proceed) {

    } else { # if ($krbtgt.PasswordLastSet -lt $krbTGTMinTime) {
        Write-EventLog -LogName Application -Source "pdcTasks" -EventId 7 -EntryType Warning -Message "KRBTGT password last set is newer than $krbTGTMinTime"
    } # if ($krbtgt.PasswordLastSet -lt $krbTGTMinTime) {

} else { # # if ($env:COMPUTERNAME -eq $pdc.name)
    Write-EventLog -LogName Application -Source "pdcTasks" -EventId 1 -EntryType Warning -Message "I am not the PDC, the PDC is: $($pdc.HostName)"
} # if ($env:COMPUTERNAME -eq $pdc.name)
