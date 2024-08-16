# krbtgt-reset
GPO configuration to reset the krbtgt password in a safe way and mitigate golden ticket impact

  Does not required a user account as the task will be executed with SYSTEM privilege on a domain controller.
  It is scheduled by GPO and applied to the domain controllers OU
  

The script file should be stored in a location that is only writeable by domain admins.
Since the SYSVOL exists for that purpose and it is replicated, we will use this.
All operation requires domain admins privilege.

Copy the file to the NETLOGON fol


![image](https://github.com/user-attachments/assets/4522295d-b28a-440d-ad1e-381074466394)


Version 1:
c8475640c6cd6db6f97e27e651cd42e8ea3ca8a0078584bafdd83e7c4b801a40  krbtgt_reset.ps1
62271109dcd91ecdf7e84b8b0c73aa028f36272d352b42b96fb82faa81cbdf48  ScheduledTasks.xml

The password generation functions have been reused from:
https://github.com/microsoftarchive/New-KrbtgtKeys.ps1/blob/master/New-KrbtgtKeys.ps1
