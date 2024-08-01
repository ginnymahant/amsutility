Apex Managed Sharing utility has been developed so it can be used to -

  Provide access to different users to records of multiple object at a time

  Revoke access of different users to records of multiple objects at a time

  Share a single record or bulk records (>10K) – the utility figures out on it own if it needs to use async mode for bulk data access

  Specify reason(Rowcause) of choice - Manual or Apex Sharing Reason

Following feature of the utility make it easy to use in code -

  Utilize utility from code - Singleton Pattern so can be used across multiple classes without needing to pass references. 1 class – 2 methods for sharing and revoking each

  Utilize utility from flows - Can be invoked as an Apex Action by flows (WIP)

  Configureable Stop switch for bulk mode sharing and revoking of access incase something goes wrong

Source Code - 

  This utility consists of four apex classes, a custom metadata and a custom setting - 

Custom Metadata

  Objects for which Apex Managed Sharing is required must be configured in ApexManagedSharingSettings custom metadata.

Apex Classes

  ApexManagedShareObjects - This is a singleton pattern based class which contains details of share objects of all objects that have been configured for apex managed sharing.

  ApexManagedSharingUtilityV2 - This is also a singleton pattern based class which has methods for sharing access and revoking access of users to records of objects that have been configured in custom metadata. This class maintains a map mapOfAllSharingRecordsToInsert which contains a list of share object records to be created per object. The class also maintains a map mapOfAllUserAccessDetailsPerObject which contains  list of all users and records that they must get access to per object. ApexManagedSharingUtilityV2 detects if it needs to create share records and delete share records in asynchronous mode. To do so it uses QueueableAMS_ProvideAccess or QueueableAMS_RevokeAccess .  If the amount of share records to be created or queried is higher than per transaction limit then ApexManagedSharingUtilityV2  utility switches to asynchronous mode otherwise it runs synchronously.

  QueueableAMS_ProvideAccess - This queueable apex class is invoked  by shareRecords method of ApexManagedSharingUtilityV2. 

  QueueableAMS_RevokeAccess - This queueable apex class is invoked  by revokeAllAccess method of ApexManagedSharingUtilityV2. It queries the necessary share object records and deletes them.


Custom Setting

ApexManagedSharingControlSetting is a hierarchical custom setting which contains a field which controls if jobs of QueueableAMS_ProvideAccess  or QueueableAMS_RevokeAccess must be allowed to run. This custom setting contains another flag which controls if failure email must be sent to users in Apex Exception Notification incase there is an error while creating share object records or deleting share object records. A value defined at Org level is sufficient.


Using the Utility

1.Define objects in ApexManagedSharingSetting Metadata

2.Define Email and Bulk settings in ApexManagedSharingControl Custom Settings

3.Define Apex Sharing Reasons for custom objects

4.Invoke utility in Code

Example for providing access to users -

/*-----------------------------------------------------------------------CODE--------------------------------------------------------------------------------*/
//Define a map Key: user Id, Value : Set of Ids of records that the user needs access to
Map<Id, Set<Id>> mapOfUserIdsAndSetOfRecordIdsToShare1 = new Map<Is, Set<Id>>();

//Logic to populate the map Key: user Id, Value : Set of record ids of My_CustomObject1__c to provide access to

ApexManagedSharingUtilityV2 apexSharingUtility = ApexManagedSharingUtilityV2.getInstance() ;
apexSharingUtility.buildShareRecords( ‘My_CustomObject1__c', Schema.My_CustomObject1__Share.RowCause.MyReason1__c , 'Read', mapOfUserIdsAndSetOfRecordIdsToShare1 );
.
.
.
Map<Id, Set<Id>> mapOfUserIdsAndSetOfRecordIdsToShare2 = new Map<Is, Set<Id>>();
. //Logic to populate the map Key: user Id, Value : Set of record ids of My_CustomObject2__c to provide access

apexSharingUtility.buildShareRecords( ‘My_CustomObject2__c', Schema.My_CustomObject2__Share.RowCause.MyReason2__c , Edit', mapOfUserIdsAndSetOfRecordIdsToShare2 );
apexSharingUtility.shareRecords('Failure Message',TRUE);
/*-----------------------------------------------------------------------CODE--------------------------------------------------------------------------------*/

NOTE:  buildAccountShareRecords method of ApexManagedSharingUtilityV2 must be used incase users must be provided access to records of Account object only.

Example for revoking access of users

/*-----------------------------------------------------------------------CODE--------------------------------------------------------------------------------*/
//Define a map Key: user Id, Value : Set of Ids of records to which users must no longer have access
Map<Id, Set<Id>> mapOfUserIdsAndSetOfRecordIdsToRevokeAccess1 = new Map<Is, Set<Id>>();

//Logic to populate the map Key: user Id, Value : Set of record ids of My_CustomObject1__c to revoke access for

ApexManagedSharingUtilityV2 apexSharingUtility = ApexManagedSharingUtilityV2.getInstance() ;
apexSharingUtility.addToListOfRecordsForRevokingAccess( ‘My_CustomObject1__c' , mapOfUserIdsAndSetOfRecordIdsToRevokeAccess);
.
.
.
Map<Id, Set<Id>> mapOfUserIdsAndSetOfRecordIdsToRevokeAccess2 = new Map<Is, Set<Id>>();
. //Logic to populate the map Key: user Id, Value : Set of record ids of My_CustomObject2__c to revoke access for

apexSharingUtility.addToListOfRecordsForRevokingAccess( ‘My_CustomObject2__c', mapOfUserIdsAndSetOfRecordIdsToRevokeAccess2);
apexSharingUtility.revokeAllAccess('Failure Message',TRUE);
/*-----------------------------------------------------------------------CODE--------------------------------------------------------------------------------*/

TO DO - Features and Enhancements 
1. Create method to elevate access of users to records from Read To Edit. This will be similar to revokeAllAccess method, instead of deleting this method will update share records.
2. Create method to downgrade access of users to certain records from Edit To Read.This will be similar to revokeAllAccess method, instead of deleting this method will update share records.
3. Clear the map at the end in shareRecord.
4. Clear the map at the end in revokeAllAccess.
5. There should be a method to support bulk revoking of access followed by providing access in bulk. The method can invoke a new Queueable which will be auto-chained and its execute method will include logic inside execute methods of QueueableAMS_RevokeAccess and QueueableAMS_RevokeAccess.
6. An email notification to be sent at the end of Queueable jobs that provide access and revoke access.The email notification is configurable and can be sent to a list of users configured in a custom setting, this email notification can be switched off and on as well.
7. Enhance utility to manage (provide and revoke) access to records for Queues and Public Groups
