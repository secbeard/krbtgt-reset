# krbtgt-reset
GPO configuration to reset the krbtgt password in a safe way and mitigate golden ticket impact

  Does not required a user account as the task will be executed with SYSTEM privilege on a domain controller.
  It is scheduled by GPO and applied to the domain controllers OU
  

The script file should be stored in a location that is only writeable by domain admins.
Since the SYSVOL exists for that purpose and it is replicated, we will use this.
All operation requires domain admins privilege.

Copy the file to the NETLOGON fol


The password generation functions have been reused from:
https://github.com/microsoftarchive/New-KrbtgtKeys.ps1/blob/master/New-KrbtgtKeys.ps1
