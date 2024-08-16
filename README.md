# krbtgt-reset
GPO configuration to reset the krbtgt password in a safe way and mitigate golden ticket impact

  Does not required a user account as the task will be executed with SYSTEM privilege on a domain controller.
  It is scheduled by GPO and applied to the domain controllers OU
  

The script file should be stored in a location that is only writeable by domain admins.
Since the SYSVOL exists for that purpose and it is replicated, we will use this.
All operation requires domain admins privilege.

Copy the file to the NETLOGON fol

Create a new GPO under the Domain controllers OU.

![image](https://github.com/user-attachments/assets/c27eb474-94c2-4d0a-b8c1-361103d090d6)

Disable the User configuration as only computer related settings are implemented.

![image](https://github.com/user-attachments/assets/2000779f-bd37-4eba-a0f1-603a642232dd)

Create a scheduled task in the Preference section of Computer.

![image](https://github.com/user-attachments/assets/93fef0b4-3ab8-44c7-b25c-de27f00e577d)

Set the task to run as SYSTEM and run with hih privileges whether user logged or not.

![image](https://github.com/user-attachments/assets/0c72d0bc-907a-42cd-a7a4-3b292dc2d78c)

Create a trigger that will fits your needs, daily might be aggressive but I would recommend it if a breach is suspected.

![image](https://github.com/user-attachments/assets/dc5230af-becc-428a-95fd-79891301a190)

For the actions section select start a program.


![image](https://github.com/user-attachments/assets/78db32fe-0b87-4c77-bf3a-542e89d8d082)


The logs are visible in the Application logs

The DC is not the PDC

![image](https://github.com/user-attachments/assets/6cd91462-ed65-4cda-9132-99cfd028596c)



Version 1:
c8475640c6cd6db6f97e27e651cd42e8ea3ca8a0078584bafdd83e7c4b801a40  krbtgt_reset.ps1
62271109dcd91ecdf7e84b8b0c73aa028f36272d352b42b96fb82faa81cbdf48  ScheduledTasks.xml

The password generation functions have been reused from:
https://github.com/microsoftarchive/New-KrbtgtKeys.ps1/blob/master/New-KrbtgtKeys.ps1
