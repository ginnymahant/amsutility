/* Description: This class is part of AMS Utility. Its used to create share object records in case of bulk sharing. 
 * This class is an auto-chained queueable which can be stopped by setting Stop_Queueable_Jobs_For_Record_Sharing__c field of ApexManagedSharingControlSetting Custom Setting in case something goes wrong.
 * For AMS Utility refer-https://generatekiwisaver.atlassian.net/wiki/spaces/SF/pages/1397358617/Apex+Managed+Sharing+Utility
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 * Test : QueueableAMS_ProvideAccessTest
 */
@SuppressWarnings
public inherited sharing class QueueableAMS_ProvideAccess implements Queueable{
    @TestVisible
    private Map<String, List<Sobject>> mapOfAllSharingRecordsToInsert;
    @TestVisible
    private String nameOfObject = '' ;
    public static final Integer COUNT_OF_RECS_TO_INSERT = 9999;  // THIS VALUE MUST NOT EXCEED 10000 ELSE DML GovernorLimit will be hit and exception thrown, and the whole job will error out 

    public QueueableAMS_ProvideAccess(Map<String, List<Sobject>> mapOfAllSharingRecords ) {
        mapOfAllSharingRecordsToInsert = mapOfAllSharingRecords;
    }
    

    public void execute(System.QueueableContext qc) {

        ApexManagedSharingControlSetting__c setting = [ SELECT Stop_Queueable_Jobs_For_Record_Sharing__c FROM ApexManagedSharingControlSetting__c LIMIT 1] ;
        Boolean stopQueueableJobs = setting.Stop_Queueable_Jobs_For_Record_Sharing__c ;

        if( stopQueueableJobs )
            { return; }
        System.debug('The mapOfAllSharingRecordsToInsert  IS BEFORE SANITIZING = '+ mapOfAllSharingRecordsToInsert);
        santizeRecords();
        System.debug('The mapOfAllSharingRecordsToInsert  IS AFTER SANITIZING = '+ mapOfAllSharingRecordsToInsert);
       
        if( mapOfAllSharingRecordsToInsert != null && mapOfAllSharingRecordsToInsert.size() > 0 ) {
            Map<String, List<Sobject>> mapOfAllSharingRecordsToInsertTemp = mapOfAllSharingRecordsToInsert;
            Boolean nextSharingJob = false;
            List<SObject> recordsForSharing ;

            Set<String> objectNames = mapOfAllSharingRecordsToInsertTemp.keySet() ;
            if (String.isBlank(nameOfObject)) {
                for ( String objName : objectNames ) {
                    nameOfObject = objName ;
                    break;
                }
            }

            //Get records of key: nameOfObject
            System.debug('BEFORE Sharing records of - '+nameOfObject);
            recordsForSharing = mapOfAllSharingRecordsToInsertTemp.get(nameOfObject);
            if(recordsForSharing != null && recordsForSharing.size() > 0 ) {
               
                List<SObject> shareRecords =  trimMapAsPerChunkSize ( recordsForSharing);
                ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance();
                apexSharingUtility.provideAccess(shareRecords , 'Sharing records of '+nameOfObject.toUpperCase());
            }
        }
        
        if(mapOfAllSharingRecordsToInsert != null && mapOfAllSharingRecordsToInsert.size() > 0 ) {
            System.debug('------BEFORE ENQUEING NEXT job --------------');
            QueueableAMS_ProvideAccess nextJobForApexRecordSharing = new  QueueableAMS_ProvideAccess(mapOfAllSharingRecordsToInsert);
            System.enqueueJob (nextJobForApexRecordSharing);
        }
    }

    /**
     * @description This method sanitizes entries in mapOfAllSharingRecordsToInsert and removes any null values or data for objects not configured for sharing
     * @param : None
     */
    @TestVisible
    private void santizeRecords() {
        Set<String> dirtyShare = new Set<String>();
        //Get instance of class which stores all share Object details for those objects that have been configured for Sharing in Custom Metadata
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
         
        for( String nameOfObject : mapOfAllSharingRecordsToInsert.keySet()) {
            ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(nameOfObject);
            if ( shareObjectDetail == null) { 
                dirtyShare.add(nameOfObject); 
            }
            if( shareObjectDetail != null && mapOfAllSharingRecordsToInsert.get( nameOfObject ) == null ) { 
                dirtyShare.add(nameOfObject); 
            }
        }
        //Remove records of object from mapOfAllSharingRecordsToInsert if the object has not been configured for sharing or the key in mapOfAllSharingRecordsToInsert is not having any data
        if(dirtyShare.size() > 0 ) {
            for (String shareStr : dirtyShare) {
                mapOfAllSharingRecordsToInsert.remove(shareStr);
            }
        }
    }

    /**
     * @description This method chunks entries in mapOfAllSharingRecordsToInsert into a chunk of size = COUNT_OF_RECS_TO_INSERT for each share object record 
     * @param : typeOfShareRecord Name of object configured for sharing
     * @param : recordsToShare all entries from mapOfAllSharingRecordsToInsert for specified share object -  
     */
    @TestVisible
    private List<SObject> trimMapAsPerChunkSize( List<SObject> recordsToShare) {
        
        if(recordsToShare == null || recordsToShare.size() == 0 ) 
            { return null; }

        Integer totalShareRecs = recordsToShare.size();
        List<SObject> shareRecsToInsert = new List<SObject>();

        if( totalShareRecs <= COUNT_OF_RECS_TO_INSERT ) {
            shareRecsToInsert = recordsToShare;
            mapOfAllSharingRecordsToInsert.remove(nameOfObject);
            return shareRecsToInsert ;
        }
        else if( totalShareRecs > COUNT_OF_RECS_TO_INSERT){
            List<SObject> recordsToShareTemp = new List<SObject>();
            recordsToShareTemp.addAll(recordsToShare);
            //pick set of COUNT_OF_RECS_TO_INSERT records starting from start in list 
            for ( Integer i = 0; i < totalShareRecs ; i++ )
            {
                if(shareRecsToInsert.size() == COUNT_OF_RECS_TO_INSERT ) 
                    { break; }
                
                shareRecsToInsert.add(recordsToShare[i]);
                Integer indexOfRecToRemove = recordsToShareTemp.indexOf(recordsToShare[i]);
                recordsToShareTemp.remove(indexOfRecToRemove);
            }
            recordsToShare.clear();
            recordsToShare.addAll(recordsToShareTemp);
                
            if( recordsToShare != null && recordsToShare.size() > 0) {
                mapOfAllSharingRecordsToInsert.put(nameOfObject , recordsToShare);
            } else { 
                mapOfAllSharingRecordsToInsert.remove(nameOfObject);    
            }
                return  shareRecsToInsert;
        }
        return null;                       
    }

}