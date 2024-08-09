/* Description: This class is part of AMS Utility. Its used to remove access of users to records of configured objects. This is used incase of large scale data access.
 * This class is an auto-chained queueable which can be stopped by setting Stop_Queueable_Jobs_For_Record_Sharing__c field of ApexManagedSharingControlSetting Custom Setting in case something goes wrong.
 * For AMS Utility refer-https://generatekiwisaver.atlassian.net/wiki/spaces/SF/pages/1397358617/Apex+Managed+Sharing+Utility
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 * Test : QueueableAMS_RevokeAccessTest
 */
 
public inherited sharing class QueueableAMS_RevokeAccess implements Queueable{
    @TestVisible
    private Map <String , Map <Id, Set<Id>>> mapOfAllUserAccessDetailsPerObject = new Map <String , Map <Id, Set<Id>>> ();
    private String messageInCaseOfFailure = '' ;
    @TestVisible
    private String nameOfObject = '' ;
    public static final Integer COUNT_OF_RECS_TO_INSERT = 9999;  // THIS VALUE MUST NOT EXCEED 10000 ELSE DML GovernorLimit will be hit and exception thrown, and the whole job will error out 
    @TestVisible
    private static final Integer MAX_NUMBER_OF_USERS_TO_REVOKE_ACCESS = ApexManagedSharingUtility.MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS ;
    @TestVisible
    private static final Integer MAX_NUMBER_OF_SHARE_RECORDS_TO_REVOKE_ACCESS = ApexManagedSharingUtility.MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS ;

    public QueueableAMS_RevokeAccess( Map <String , Map <Id, Set<Id>>> mapOfAllUserAccessDetailsForRevoking , String messageOfFailure) {
        mapOfAllUserAccessDetailsPerObject = mapOfAllUserAccessDetailsForRevoking ;
        messageInCaseOfFailure = messageOfFailure ;
    }

    public void execute(System.QueueableContext qc) {

        ApexManagedSharingControlSetting__c setting = [ SELECT Stop_Queueable_Jobs_For_Record_Sharing__c FROM ApexManagedSharingControlSetting__c LIMIT 1] ;
        Boolean stopQueueableJobs = setting.Stop_Queueable_Jobs_For_Record_Sharing__c ;

        if( stopQueueableJobs )
            return;
        System.debug('The mapOfAllUserAccessDetailsPerObject  IS BEFORE SANITIZING = '+ mapOfAllUserAccessDetailsPerObject);
        santizeRecords();
        System.debug('The mapOfAllUserAccessDetailsPerObject  IS AFTER SANITIZING = '+ mapOfAllUserAccessDetailsPerObject);
       
        if( mapOfAllUserAccessDetailsPerObject != null && mapOfAllUserAccessDetailsPerObject.size() > 0 ) {
            Map <String , Map <Id, Set<Id>>> mapOfAllUserAccessDetailsPerObject_Temp = mapOfAllUserAccessDetailsPerObject ;
            Map <Id, Set<Id>> mapOfUserIdsAndRecordsForObject ;

            Set<String> objectNames = mapOfAllUserAccessDetailsPerObject_Temp.keySet() ;
            if (String.isBlank(nameOfObject)) {
                for ( String objName : objectNames ) {
                    nameOfObject = objName ;
                    break;
                }
            }

            //Get records of key: nameOfObject
            System.debug('BEFORE Revoking access of users for records of - '+nameOfObject);
            mapOfUserIdsAndRecordsForObject = mapOfAllUserAccessDetailsPerObject_Temp.get(nameOfObject);

            if( mapOfUserIdsAndRecordsForObject != null && mapOfUserIdsAndRecordsForObject.size() > 0 ) {
                
                Map <Id, Set<Id>> mapOfUserIdsAndRecordsToRevokeAccess =  trimMapAsPerChunkSize ( nameOfObject , mapOfUserIdsAndRecordsForObject );
                ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance();
                apexSharingUtility.addToListOfRecordsForRevokingAccess( nameOfObject , mapOfUserIdsAndRecordsToRevokeAccess );
                apexSharingUtility.revokeAccessForObject( nameOfObject , messageInCaseOfFailure );
            }
        }
        
        if(mapOfAllUserAccessDetailsPerObject != null && mapOfAllUserAccessDetailsPerObject.size() > 0 && !Test.isRunningTest() ) {
            System.debug('------BEFORE ENQUEING NEXT job --------------');
            QueueableAMS_RevokeAccess nextJob = new  QueueableAMS_RevokeAccess( mapOfAllUserAccessDetailsPerObject , messageInCaseOfFailure );
            System.enqueueJob ( nextJob );
        }
    }

    /**
     * @description This method sanitizes entries in mapOfAllUserAccessDetailsPerObject and removes any null values or data for objects not configured for sharing
     * @param : None
     */
    @TestVisible
    private void santizeRecords() {
        Set<String> dirtyShare = new Set<String>();
        //Get instance of class which stores all share Object details for those objects that have been configured for Sharing in Custom Metadata
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
         
        for( String nameOfObject : mapOfAllUserAccessDetailsPerObject.keySet()) {
            ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(nameOfObject);
            if ( shareObjectDetail == null)
                dirtyShare.add(nameOfObject);
            if( shareObjectDetail != null && ( mapOfAllUserAccessDetailsPerObject.get( nameOfObject ) == null || mapOfAllUserAccessDetailsPerObject.get( nameOfObject ).size() == 0 ) )
                dirtyShare.add(nameOfObject);  
        }
        //Remove records of object from mapOfAllUserAccessDetailsPerObject if the object has not been configured for sharing or the key in mapOfAllUserAccessDetailsPerObject is not having any data
        if(dirtyShare.size() > 0 ) {
            for (String shareStr : dirtyShare) {
                mapOfAllUserAccessDetailsPerObject.remove(shareStr);
            }
        }
    }

    /**
     * @description This method chunks entries in mapOfAllSharingRecordsToInsert into a chuk=nk of size = COUNT_OF_RECS_TO_INSERT for each share object record 
     * @param : nameOfObject Name of object
     * @param : mapOfUserIdsAndRecordsForAnObject all entries from mapOfAllUserAccessDetailsPerObject for specified share object - nameOfObject //TODO: This param is redundant and can be gotten rid of
     */
    @TestVisible
    private  Map <Id, Set<Id>> trimMapAsPerChunkSize(String nameOfObject ,  Map <Id, Set<Id>> mapOfUserIdsAndRecordsForAnObject ) {
        
        if( mapOfUserIdsAndRecordsForAnObject == null || mapOfUserIdsAndRecordsForAnObject.size() == 0 ) 
            return null;

        Map <Id, Set<Id>> mapOfUserIdsAndRecordsToRevokeAccess = new  Map <Id, Set<Id>>(); 
        Integer countOfUserIds = 0 ;
        Integer countOfRecordIds = 0 ;

        for ( Id userId : mapOfUserIdsAndRecordsForAnObject.keySet() ) {
            if ( mapOfUserIdsAndRecordsForAnObject.get(userId) != null && mapOfUserIdsAndRecordsForAnObject.get(userId).size() > 0 ) {
                for ( Id recordId : mapOfUserIdsAndRecordsForAnObject.get(userId) ) {
                    if ( countOfUserIds < MAX_NUMBER_OF_USERS_TO_REVOKE_ACCESS && countOfRecordIds < MAX_NUMBER_OF_SHARE_RECORDS_TO_REVOKE_ACCESS) {
                        if ( mapOfUserIdsAndRecordsToRevokeAccess.get( userId) == null  ) {
                            mapOfUserIdsAndRecordsToRevokeAccess.put( userId , new Set<Id>()) ;
                            countOfUserIds++;
                        }
                            
                        Set<Id> existingIds =  mapOfUserIdsAndRecordsToRevokeAccess.get( userId) ;
                        existingIds.add( recordId ) ;
                        mapOfUserIdsAndRecordsToRevokeAccess.put( userId , existingIds);   
                        countOfRecordIds++;
                        mapOfAllUserAccessDetailsPerObject.get(nameOfObject).get(userId).remove( recordId );
                    } 
                }
            }
            if ( mapOfAllUserAccessDetailsPerObject.get(nameOfObject).get(userId) == null || mapOfAllUserAccessDetailsPerObject.get(nameOfObject).get(userId).size() == 0 )
                mapOfAllUserAccessDetailsPerObject.get(nameOfObject).remove( userId );
        }

        return mapOfUserIdsAndRecordsToRevokeAccess ;                
    }

}