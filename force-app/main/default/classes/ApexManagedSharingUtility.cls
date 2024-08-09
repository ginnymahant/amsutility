/* Description: This is the main class for AMS Utility. For AMS Utility refer-https://generatekiwisaver.atlassian.net/wiki/spaces/SF/pages/1397358617/Apex+Managed+Sharing+Utility
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 * Test : ApexManagedSharingUtilTest
 */
 
public without sharing class ApexManagedSharingUtility {

    //Declare members
    private static ApexManagedSharingUtility instance = null;
    private ApexManagedSharingControlSetting__c APEX_MANAGED_SHARING_CONTROL_SETTING ;
    private Map <String , List<SObject>> mapOfAllSharingRecordsToInsert = new Map <String , List<SObject>>();
    private Map <String , Map <Id, Set<Id>>> mapOfAllUserAccessDetailsPerObject = new Map <String , Map <Id, Set<Id>>> ();
    private String OWD_ACCOUNT;
    private String OWD_CASE;
    private String OWD_OPPORTUNITY;
    private String OWD_CONTACT;

    //Declare Constants, values of these should not be changed ideally. Some of the constants values may be changed on test environments for testing purpose.
    private static final Integer MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE = 9999 ; //This value should be same as the value of QueueableAMS_ProvideAccess.COUNT_OF_RECS_TO_INSERT. 
    public static final Integer MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS = 15; //This value should always be same as MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS
    public static final Integer MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS = 15; // This value must not exceed 15
    public static final Integer MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS = 150; // This value must not exceed 150
    public static final Integer MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS = 20; //This value must not exceed 20
    public static final Integer MAX_LENGHT_OF_SHAREOBJ_SOQL_FORREVOKING_ACCESS = 100000 ; //This value must not exceed 100000. The Governor imit for length of SOQL statement is 100000
    
    private ApexManagedSharingUtility() {

        //Read Custom Setting for controlling sending of failure email during sharing/revoking of access
        APEX_MANAGED_SHARING_CONTROL_SETTING  = [ SELECT Send_Failure_Emails__c , Email_Ids__c FROM ApexManagedSharingControlSetting__c LIMIT 1] ;

        Organization org = [ SELECT Id, DefaultAccountAccess, DefaultContactAccess, DefaultCaseAccess, DefaultOpportunityAccess FROM Organization ];
        OWD_ACCOUNT = org.DefaultAccountAccess;
        OWD_CASE = org.DefaultCaseAccess;
        OWD_CONTACT = org.DefaultContactAccess;
        OWD_OPPORTUNITY = org.DefaultOpportunityAccess;


    }
    /**
     * @description This method generates and returns an instance of this class as per Singleton Pattern
     * @param nameOfObject The name of the object for which records needs to be shared
    */ 
    public static ApexManagedSharingUtility getInstance() {

        if(instance == null){
            instance = new ApexManagedSharingUtility();
        }
        return instance;
    }

    /**
     * @description This method creates share records
     * @param apiNameOfObject The name of the object for which records needs to be shared
     * @param rowCause The reason for sharing the record - its either apex defined or 'Manual'
     * @param accessLevel The level of access while sharing records
     * @param mapOfUserIdAndRecordIds A map containind User Ids of users that need access to records in respective Set<Id> 
     * NOTE: 
     */

    public boolean buildShareRecords( String apiNameOfObject , String rowCause , String accessLevel , Map<Id, Set<Id>> mapOfUserIdAndRecordIds) {

        //Perform Null checks
        if(String.isBlank(apiNameOfObject) || String.isBlank(rowCause) || String.isBlank(accessLevel) || mapOfUserIdAndRecordIds == null || mapOfUserIdAndRecordIds.size() == 0  || apiNameOfObject.tolowerCase() == 'account')
            return false;

            apiNameOfObject = apiNameOfObject.tolowerCase();
        //Ensure that the object in apiNameOfObject is valid  i.e. it has been configured for sharing  
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(apiNameOfObject);
        if ( shareObjectDetail == null)
            return false;

        //Build share records
        List<SObject> sharingRecords = new List<SObject>();
        for (Id userId : mapOfUserIdAndRecordIds.keySet()) {
            Set<Id> recIds = mapOfUserIdAndRecordIds.get(userId);
            for( Id recId : recIds) {
                SObject shareObjectRec = shareObjectDetail.shareObjectType.newSObject();
                shareObjectRec.put(shareObjectDetail.idFieldName, recId);
                shareObjectRec.put(shareObjectDetail.accessLevelFieldName, accessLevel);
                shareObjectRec.put('RowCause', apiNameOfObject.endsWith('__c') ? rowCause : 'Manual' );
                shareObjectRec.put('UserOrGroupId', userId);
                sharingRecords.add(shareObjectRec); 
            }     
        }
        if( sharingRecords.size() == 0 )
            return false;

        List<SObject> shareRecs = new List<SObject>();
        if ( mapOfAllSharingRecordsToInsert.get(apiNameOfObject) == null )
            shareRecs = sharingRecords;
        else
        {
            shareRecs = mapOfAllSharingRecordsToInsert.get(apiNameOfObject);
            shareRecs.addAll(sharingRecords);
        } 
         
        mapOfAllSharingRecordsToInsert.put( apiNameOfObject , shareRecs);
        return true;
    }  
    
    /**
     * @description This method creates share records for AccountShare
     * @param accountAccessLevel The level of access that users must have to Account records when Accounts are being shared with them
     * @param caseAccessLevel The level of access that users must have to child Case records associated to the Acccount being shared with them
     * @param opportunityAccessLevel The level of access that users must have to child Opportunity records associated to the Acccount being shared with them
     * @param mapOfUserIdAndRecordIds A map containind User Ids of users that need access to records in respective Set<Id> 
     * NOTE: 
     */

    public boolean buildAccountShareRecords( String accountAccessLevel , String caseAccessLevel , String  opportunityAccessLevel , String  contactAccessLevel , Map<Id, Set<Id>> mapOfUserIdAndRecordIds) {

        if( String.isBlank(accountAccessLevel) || mapOfUserIdAndRecordIds == null || mapOfUserIdAndRecordIds.size() == 0 )
            return false;
        if ( !OWD_CONTACT.equalsIgnoreCase('ControlledByParent') && String.isBlank(contactAccessLevel) )  
            return false;     
        
        //Ensure that the object in nameOfObject is valid before creating shares 
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName('account');
        if ( shareObjectDetail == null)
            return false;

        List<SObject> sharingRecords = new List<SObject>();
        for (Id userId : mapOfUserIdAndRecordIds.keySet()) {
            Set<Id> recIds = mapOfUserIdAndRecordIds.get(userId);
            for( Id recId : recIds) {
                SObject shareRec = shareObjectDetail.shareObjectType.newSObject();
                shareRec.put('AccountId', recId);
                shareRec.put('AccountAccessLevel', accountAccessLevel);
                if (String.isNotBlank(caseAccessLevel)) {
                    shareRec.put('CaseAccessLevel', caseAccessLevel);
                }
                if (String.isNotBlank(opportunityAccessLevel)) {
                    shareRec.put('OpportunityAccessLevel', opportunityAccessLevel);
                }
                if (!OWD_CONTACT.equalsIgnoreCase('ControlledByParent')) {
                    shareRec.put('ContactAccessLevel', contactAccessLevel);
                }
                shareRec.put('RowCause', 'Manual');
                shareRec.put('UserOrGroupId', userId);
                sharingRecords.add(shareRec); 
            }          
        }
        if( sharingRecords.size() == 0 )
            return false;

        List<SObject> shareRecs ;
        if ( mapOfAllSharingRecordsToInsert.get('account') == null )
            shareRecs = sharingRecords;
        else 
        {
            shareRecs = mapOfAllSharingRecordsToInsert.get('account');
            shareRecs.addAll(sharingRecords);
        }
            
        mapOfAllSharingRecordsToInsert.put( 'account' , shareRecs);   
        System.debug('The map of all account sharing records is - '+ mapOfAllSharingRecordsToInsert); 
        return true;
    }  

    /**
     * @description This method shares records of all objects
     * @param messageInCaseOfFailure Message to be printed in failure emails
     * @param smartshare If this is TRUE - then the method switches to chained queueables(async) to create all share records if the no. of share records is more than MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE or 
     * the no. of objects whose records need to be shared is more than MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS;  if the no. of share records is less than MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE AND 
     * the no. of objects whose records need to be shared is less than MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS share records are created in synchonous mode(part of the same transaction). 
     * If this is FALSE then sharing of all record happens in sync mode always
     * 
     */

    public List<String> shareRecords(String messageInCaseOfFailure , Boolean smartshare) {
        if ( mapOfAllSharingRecordsToInsert == null || mapOfAllSharingRecordsToInsert.size() == 0 )
            return null;

        List<String> errors = new List<String>();
        if ( smartshare ) {
            Integer totalShareRecords = 0;
            for ( String key : mapOfAllSharingRecordsToInsert.keySet() ) {
                if ( mapOfAllSharingRecordsToInsert.get(key) != null )
                totalShareRecords = totalShareRecords + mapOfAllSharingRecordsToInsert.get(key).size() ;
            }
            if ( mapOfAllSharingRecordsToInsert.keySet().size() > MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS || totalShareRecords > MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE ) {
                QueueableAMS_ProvideAccess jobToShareRecords = new QueueableAMS_ProvideAccess(mapOfAllSharingRecordsToInsert);
                System.enqueueJob(jobToShareRecords);
            }
            else {
                for ( String nameOfObject : mapOfAllSharingRecordsToInsert.keySet() ) {
                    String error = shareRecordsOfObject( nameOfObject , messageInCaseOfFailure );
                    if(String.isNotBlank(error)) {
                        errors.add(error);
                    }
                }
            }            
        }
        else {
                if ( mapOfAllSharingRecordsToInsert.keySet().size() > MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS ) {
                    throw new ApexManagedSharingUtilityException('The count of objects of records to share exceeds the permissimible limit of '+MAX_COUNT_OF_SHARE_OBJECTS_TO_PROVIDE_ACCESS+'. Please use the method shareRecordsInBulk instead.');
                }
                if( mapOfAllSharingRecordsToInsert.values().size() > MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE ) {
                    throw new ApexManagedSharingUtilityException('The number of records to share exceeds the permissimible limit of 10k (Governor limit of No. of records in DML per transaction). Please use the method shareRecordsInBulk instead.');
                }   
                for ( String nameOfObject : mapOfAllSharingRecordsToInsert.keySet() ) {
                    String error = shareRecordsOfObject( nameOfObject , messageInCaseOfFailure );
                    if(String.isNotBlank(error)) {
                        errors.add(error);
                    }
                }  
        }
        mapOfAllSharingRecordsToInsert.clear();
        return errors;
    }

    /**
     * @description This method shares records of an object, provided the number of share records to create doesn't exceed MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE, in which case an exception is thrown. This method always creates the share 
     * records synchonously
     * @param nameOfObject Name of the object whose share object records need to be created. 
     * @param messageInCaseOfFailureToShareRecords Message to be printed in failure emails
     * 
     */

    public String shareRecordsOfObject( String nameOfObject , String messageInCaseOfFailureToShareRecords ) {
        nameOfObject = nameOfObject.toLowerCase();
        List<SObject> shareRecords = mapOfAllSharingRecordsToInsert.get(nameOfObject) ;
        if( shareRecords == null || shareRecords.size() == 0 )
            return null;
        if ( shareRecords.size() > MAX_COUNT_OF_SHARE_RECORDS_TO_CREATE ) {
            throw new ApexManagedSharingUtilityException('The number of records to share exceeds the permissimible limit of 10k (Governor limit of No. of records in DML per transaction). Please use the method shareRecords with smartShare TRUE instead.');
        }   
        return provideAccess (shareRecords , 'Providing user access to records of '+nameOfObject+ '.'+messageInCaseOfFailureToShareRecords) ;   
    }

    /**
     * @description This method maintains a map - mapOfAllUserAccessDetailsPerObject which contains Key: <Name of Object> and Value : < Map with Key: < User Id > and Value : <Set of record Ids of object named in nameOfObject> >. 
     * mapOfAllUserAccessDetailsPerObject maintains lists of users and the records to which their access must be revoked per object
     * @param nameOfObject The name of the object for which access of user/s needs to be revoked>
     * @param mapOfUserIdAndRecordIds A map containing User Ids of users for whom access to records in respective Set<Id> must be revoked
     * NOTE: 
     */

    public Boolean addToListOfRecordsForRevokingAccess( String nameOfObject ,  Map<Id, Set<Id>> mapOfUserIdAndRecordIds ) {

        if(String.isBlank(nameOfObject) || mapOfUserIdAndRecordIds == null || mapOfUserIdAndRecordIds.size() == 0 )
            return false;

        nameOfObject = nameOfObject.tolowerCase();
        //Ensure that the object in nameOfObject has been configured for Aex Managed sharing and revoking, if not then return 
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(nameOfObject);
        if ( shareObjectDetail == null)
            return false;

        //Filter out entries in mapOfUserIdAndRecordIds wherein a key is NULL or its Set of values is NULL or the Set contains nothing
        Map<Id, Set<Id>> mapOfUserIdAndRecordIds_Filtered = new  Map<Id, Set<Id>>();
        for ( Id userId : mapOfUserIdAndRecordIds.keySet() ) {
            if ( userId != null && mapOfUserIdAndRecordIds.get( userId ) != null && mapOfUserIdAndRecordIds.get( userId ).size() > 0 )
                mapOfUserIdAndRecordIds_Filtered.put( userId , mapOfUserIdAndRecordIds.get( userId ) );
        }

        //Add mapOfUserIdAndRecordIds_Filtered to mapOfAllUserAccessDetailsPerObject  
        if ( mapOfAllUserAccessDetailsPerObject.get(nameOfObject) == null || mapOfAllUserAccessDetailsPerObject.get(nameOfObject).size() == 0 ) {
            mapOfAllUserAccessDetailsPerObject.put( nameOfObject , mapOfUserIdAndRecordIds_Filtered);
        }
        else
        {
            Map <Id, Set<Id>> existingMapOfAllUserAccessDetailsPerObject = mapOfAllUserAccessDetailsPerObject.get(nameOfObject);
            for (String userIdAsKey : mapOfUserIdAndRecordIds_Filtered.keySet()) {
                if ( mapOfUserIdAndRecordIds_Filtered.get( userIdAsKey ) == null || ( mapOfUserIdAndRecordIds_Filtered.get( userIdAsKey )).size() == 0)
                    continue;
                    
                if ( existingMapOfAllUserAccessDetailsPerObject.get( userIdAsKey ) != null && existingMapOfAllUserAccessDetailsPerObject.get( userIdAsKey ).size() > 0  ) {
                    Set<Id> existingRecIds = existingMapOfAllUserAccessDetailsPerObject.get( userIdAsKey ) ; 
                    existingRecIds.addAll(  mapOfUserIdAndRecordIds_Filtered.get( userIdAsKey ) );
                    existingMapOfAllUserAccessDetailsPerObject.put( userIdAsKey , existingRecIds );
                }
                else {
                        existingMapOfAllUserAccessDetailsPerObject.put( userIdAsKey , mapOfUserIdAndRecordIds_Filtered.get( userIdAsKey ));
                }
            }
            mapOfAllUserAccessDetailsPerObject.put(nameOfObject , existingMapOfAllUserAccessDetailsPerObject) ;
        }
        
        System.debug ('The mapOfAllUserAccessDetailsPerObject is - ' + mapOfAllUserAccessDetailsPerObject ) ; 
        return true; 
    }

    /**
     * @description This method revokes access of users to all records of all objects present in mapOfAllUserAccessDetailsPerObject
     * @param messageInCaseOfFailure  Message to be printed in failure emails
     * @param smartRevoke If this is TRUE - then the method switches to chained queueables(asynchronous mode) to revoke access of users if the no. of objects in mapOfAllUserAccessDetailsPerObject exceeds MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS ,
     * or if result of inspectRecordsBeforeRevokingAccessAndReturnQuery is a failure;  if the no. of objects in mapOfAllUserAccessDetailsPerObject is less than MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS AND 
     * result of inspectRecordsBeforeRevokingAccessAndReturnQuery is not a failure then revoking of access happens in synchonous mode(part of the same transaction). 
     * 
     */

    public List<String> revokeAllAccess( String messageInCaseOfFailure , Boolean smartRevoke) {

        if( mapOfAllUserAccessDetailsPerObject == null || mapOfAllUserAccessDetailsPerObject.size() == 0 )
            return null;
        List<String> errors = new List<String>();
        if ( smartRevoke ) {
            if ( mapOfAllUserAccessDetailsPerObject.keySet().size() > MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS ) {
                QueueableAMS_RevokeAccess jobToRevokeAccess = new QueueableAMS_RevokeAccess( mapOfAllUserAccessDetailsPerObject , messageInCaseOfFailure );
                System.enqueueJob(jobToRevokeAccess);
            }
            else {
                    Boolean asyncMode = FALSE ;
                    for ( String nameOfObject : mapOfAllUserAccessDetailsPerObject.keySet() ) {
                        InspectionResult result = inspectRecordsBeforeRevokingAccessAndReturnQuery( nameOfObject ) ;
                        //Inspect the users and records for which their access needs to be revoked, inspection determines if revoking needs to be done in Sync or Async Mode
                        if( result != null && result.inspectionFailed ) {
                            asyncMode = TRUE;
                            break ;
                        }
                    }
                    if ( asyncMode ) {
                        QueueableAMS_RevokeAccess jobToRevokeAccess = new QueueableAMS_RevokeAccess( mapOfAllUserAccessDetailsPerObject , messageInCaseOfFailure );
                        System.enqueueJob(jobToRevokeAccess);
                    } 
                    else {
                        for ( String nameOfObject : mapOfAllUserAccessDetailsPerObject.keySet() ) {
                            String error = revokeAccessForObject( nameOfObject , messageInCaseOfFailure );
                            if(String.isNotBlank(error)) {
                                errors.add(error);
                            }
                        }
                    }  
            }          
        }
        else {
                if ( mapOfAllUserAccessDetailsPerObject.keySet().size() > MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS ) {
                    throw new ApexManagedSharingUtilityException('The count of objects for revoking access exceeds the permissimible limit of '+ MAX_COUNT_OF_SHARE_OBJECTS_TO_REVOKE_ACCESS +'. Please use the method revokeAllAccess with smartRevoke TRUE instead.');
                }
                for ( String nameOfObject : mapOfAllUserAccessDetailsPerObject.keySet() ) {
                    InspectionResult result = inspectRecordsBeforeRevokingAccessAndReturnQuery( nameOfObject ) ;
                    if( result != null && result.inspectionFailed ) {
                        throw new ApexManagedSharingUtilityException( result.inspectionFailureMessage );
                    }
                } 
                for ( String nameOfObject : mapOfAllUserAccessDetailsPerObject.keySet() ) {
                    String error = revokeAccessForObject( nameOfObject , messageInCaseOfFailure );
                    if(String.isNotBlank(error)) {
                        errors.add(error);
                    }
                }
        }
        mapOfAllUserAccessDetailsPerObject.clear();     
        return errors;
    }

    /**
     * @description This method revokes access of users to all records from mapOfAllUserAccessDetailsPerObject for a specified object. To revole access this method queries share object records using a dynamic SOQL and then deletes them by invoking 
     * revokeAccess method. This method revokes access synchonously. It throws an exception incase result of inspectRecordsBeforeRevokingAccessAndReturnQuery method is a failure.
     * @param nameOfObject Name of the object for which access of all users to al records present in mapOfAllUserAccessDetailsPerObject needs to be revoked. 
     * @param messageInCaseOfFailureToRevokeAccess  Message to be printed in failure emails
     *  
     */
    
    public String revokeAccessForObject( String nameOfObject , String messageInCaseOfFailureToRevokeAccess ) {
        nameOfObject = nameOfObject.toLowerCase();

        //Retrieve the map that holds user access details for the given object
        Map< Id, Set<Id> > mapOfAllUserAccessDetailsForObject = mapOfAllUserAccessDetailsPerObject.get(nameOfObject) ;
        if( mapOfAllUserAccessDetailsForObject == null || mapOfAllUserAccessDetailsForObject.size() == 0 )
            return null;

        InspectionResult result = inspectRecordsBeforeRevokingAccessAndReturnQuery( nameOfObject );
        if ( result == null )
            return null;
        if( result != null && result.inspectionFailed ) {
            throw new ApexManagedSharingUtilityException( result.inspectionFailureMessage );
        }

        List<SObject> shareRecs = (List<SObject>) Database.query( result.theShareObjectQuery );
        List<SObject> revokeSharing = new List<SObject>();
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(nameOfObject);
        
        //From all sharing records choose the ones for USer and respective record
        for( SObject shareRecord : shareRecs)  {
            Set<Id> recIds = mapOfAllUserAccessDetailsForObject.get((Id)(shareRecord.get('UserOrGroupId'))); 
            if ( recIds == null || recIds.size() == 0 )
                continue;   
            if( recIds.contains( (Id) shareRecord.get(shareObjectDetail.idFieldName)  ) && checkForNonSystemRowCauses((String)shareRecord.get('RowCause')) )  {
                    revokeSharing.add(shareRecord);
            }       
        } 
        System.debug('AMS UTILITY REVOKING ACCESS FOR - '+revokeSharing);   
        return revokeAccess ( revokeSharing ,  'Revoking access of users to '+ nameOfObject + '.'+ messageInCaseOfFailureToRevokeAccess) ;   
    }

    /**
     * @description This method retrieves data from mapOfAllUserAccessDetailsPerObject for the objects specified in nameOfObject. This data is checked to see if the number of users for whom access needs to be revoked exceeds MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS
     * and the total number of records across all the users exceeds MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS. The method builds a dynamic SOQL to query share object of object specified in nameOfObject based on user Ids nd record Ids. The length of SOQL
     * is also checked and it must not exceed MAX_LENGHT_OF_SHAREOBJ_SOQL_FORREVOKING_ACCESS which is the governor limit of length of SOQL statements. TODO- Check that the length of WHERE CLAUSE must not exceed 4000 which is the Goernor limit. Currently values of  
     * constants MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS and MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS are such that WHERE clause length will always be less than 4000 but its good to keep an additional check
     * @param nameOfObject Name of the object for which checks need to be made
     *  
     */

    private InspectionResult inspectRecordsBeforeRevokingAccessAndReturnQuery( String nameOfObject ) {

        InspectionResult result = new InspectionResult();

        //Ensure that the object in nameOfObject is valid before proceeding to revoke access 
        ApexManagedShareObjects apexShareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject shareObjectDetail = apexShareObjects.getTheShareObjectDetailsForObjectName(nameOfObject);
        if ( shareObjectDetail == null)
            return null ;

        //Retrieve the map that holds user access details for the given object
        Map< Id, Set<Id> > mapOfAllUserAccessDetailsForObject = mapOfAllUserAccessDetailsPerObject.get(nameOfObject) ;

        //Get All UserIds from mapOfAllUserAccessDetailsForObject
        Set<Id> allUserIds = new Set<Id>();
        allUserIds.addAll( mapOfAllUserAccessDetailsForObject.keySet() ) ; 

        //Get a count of all records to revoke access for various users 
        Set<Id> recordIds = new Set<Id>() ; 
        for ( Id userId : mapOfAllUserAccessDetailsForObject.keySet() ) {
            Set<Id> recIds = mapOfAllUserAccessDetailsForObject.get ( userId );
            if ( recIds != null && recIds.size() > 0)
                recordIds.addAll( recIds ) ;
        }
        
        if( recordIds.size() == 0 || allUserIds.size() == 0)
            return null ;
        
        if ( recordIds.size() > MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS ) {
            result.inspectionFailed = TRUE;
            result.inspectionFailureMessage =  'The number of records to which access must be revoked for users exceeds the permissimible limit of ' + MAX_COUNT_OF_SHARE_RECORDS_TO_REVOKE_ACCESS + '.Please use the method revokeAllAccess with smartRevoke TRUE instead.';
            return result ;
        }
        if ( allUserIds.size() > MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS ) {
            result.inspectionFailed = TRUE;
            result.inspectionFailureMessage = 'The number of users for whom access must be revoked for users exceeds the permissimible limit of ' + MAX_COUNT_OF_USERS_TO_REVOKE_ACCESS + '.Please use the method revokeAllAccess with smartRevoke TRUE instead.';
            return result ;
        } 
        String shareObjectQuery = getQueryShareObjectByUserOrGrpIdsAndRecIds( shareObjectDetail.shareObjectName, shareObjectDetail.idFieldName , allUserIds,  recordIds  );
        if ( shareObjectQuery.length() > MAX_LENGHT_OF_SHAREOBJ_SOQL_FORREVOKING_ACCESS ) {
            result.inspectionFailed = TRUE;
            result.inspectionFailureMessage = 'Unable to query records from share Object as the query exceeds the permissimible limit of ' + MAX_LENGHT_OF_SHAREOBJ_SOQL_FORREVOKING_ACCESS + '.Please use the method revokeAllAccess with smartRevoke TRUE.';
            return result ;
        }
        result.inspectionFailed = FALSE;
        result.inspectionFailureMessage = '';
        result.theShareObjectQuery =  shareObjectQuery;
        return result ;
    }

    /**
     * @description This method checks if the param rowCause matches the rowcauses for Managed Sharing Refer- https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_understanding.htm, if so it returns FALSe else it return TRUE
     * @param rowCause Name of the object for which checks need to be made
     *  
     */

    private Boolean checkForNonSystemRowCauses( String rowCause ) {
        if( rowCause.equalsIgnoreCase( 'ImplicitChild' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'ImplicitParent' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'PortalImplicit' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'GuestParentImplicit' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'GuestRule' ) )
            return FALSE;                
        if( rowCause.equalsIgnoreCase( 'Owner' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'Rule' ) )
            return FALSE;    
        if( rowCause.equalsIgnoreCase( 'Team' ) )
            return FALSE;
        if( rowCause.equalsIgnoreCase( 'TerritoryRule' ) )
            return FALSE;
                
        return TRUE;    
    }

    /**
     * @description This method inserts share object records passed in accessRecords
     * @param accessRecords list of share object records
     *  @param messageInCaseOfFailure  Message to be printed in failure emails
     */

    public String provideAccess (List<SObject> accessRecords  , String messageIncaseOfFailure ) {

        String subject = 'Record Access Management Utility-Error Notification '+ System.today().format();
        String body = 'Hi,\n\n';
        Boolean errorFound = FALSE;

        if ( accessRecords == null || accessRecords.size() > 10000 ) // Max no. of DML records in a transaction is 10000
            return null;

        if(accessRecords != null && accessRecords.size() > 0 )  { 
            body +=       '    This email is to notify you of the errors encountered while sharing access to records for some users. '+ messageIncaseOfFailure +' \n\n'; 
            Database.SaveResult[] result = Database.insert(accessRecords,false);

            for (Database.SaveResult res : result) {
                if (res.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted record for ID: ' + res.getId());
                }
                else { System.debug('Error inserting record for: ' + res);
                        if(!errorFound)
                        errorFound = TRUE;
                        // Operation failed, so get all errors                
                        for(Database.Error err : res.getErrors()) {
                            body += ' Error - '+ err.getStatusCode() + ': ' + err.getMessage() + ' \n';          
                            body += 'Fields that affected this error - '+ err.getFields() + ' \n\n'; 
                        }
                }
            }
            try {
                if(errorFound && APEX_MANAGED_SHARING_CONTROL_SETTING.Send_Failure_Emails__c ) {
                    EmailService.sendPlainTextEmail(APEX_MANAGED_SHARING_CONTROL_SETTING.Email_Ids__c, subject, body);
                }
            } catch(Exception ex) {
                System.debug('Unexpected failure occurred while sending email: '+ ex.getMessage());
            }                   
        }
        return errorFound ? body : null; 
    }

    /**
     * @description This method deletes share object records passed in accessRecords
     * @param accessRecords list of share object records
     *  @param messageInCaseOfFailure  Message to be printed in failure emails
     */

    public String revokeAccess( List<SObject> accessRecords , String messageIncaseOfFailure ) {   

        String subject = 'Record Access Management Utility-Error Notification '+ System.today().format();
        String body = 'Hi,\n\n';
        Boolean errorFound = FALSE;

        if ( accessRecords == null ||  accessRecords.size() > 10000 ) // Max no. of DML records in a transaction is 10000
            return null;

        if(accessRecords != null && accessRecords.size() > 0 )  {  
            body +=       '    This email is to notify you of the errors encountered while revoking access to records for some users. '+ messageIncaseOfFailure +' \n\n';
            Database.DeleteResult[] result = Database.delete(accessRecords,false);

            for (Database.DeleteResult res : result) {
                if (res.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted record with ID: ' + res.getId());
                }
                else { 
                        if(!errorFound)
                            errorFound = TRUE;  
                    // Operation failed, so get all errors                
                        for(Database.Error err : res.getErrors()) {
                            body += 'ID : '+ res.getId()+ ' Error - '+ err.getStatusCode() + ': ' + err.getMessage() + ' \n';           
                            body += 'Fields that affected this error - '+ err.getFields() + ' \n\n'; 
                        }         
                }
            }
            try {
                    if( errorFound  && APEX_MANAGED_SHARING_CONTROL_SETTING.Send_Failure_Emails__c ) {
                        EmailService.sendPlainTextEmail(APEX_MANAGED_SHARING_CONTROL_SETTING.Email_Ids__c, subject, body);
                    }
            } catch(Exception ex) {
                System.debug('Unexpected failure occurred while sending email: '+ ex.getMessage());
            } 
        }
        return errorFound ? body : null;
    }

    /**
     * @description This method prepares a dynamic SOQL statement which queries a share object based on user Ids and ids of records(ParentId/AccountId/OpportunityId field)
     * @param sObjectName Name of the share object 
     * @param idFieldName  Name of Id field present in Share object (ParentId/AccountId/OpportunityId field)
     * @param userIds List of UserId
     * @param recordIds List of record Ids
     *  
     */

    private String getQueryShareObjectByUserOrGrpIdsAndRecIds(String sObjectName, String idFieldName , Set<Id> userIds , Set<Id> recordIds) {

        List<String> lstOfUserIds = new List<String> ();
        List<String> lstOfRecIds = new List<String> ();
        for( Id val : userIds ) {
            lstOfUserIds.add(val);
        }
        for( Id val : recordIds) {
            lstOfRecIds.add(val);
        }

        String listOfValuesForQuery = '(';
        String listOfValuesForRecIds = '(';
        for (Integer i=0; i < lstOfUserIds.size(); i++) {
            listOfValuesForQuery = listOfValuesForQuery + '\'' + lstOfUserIds[i] + '\'';
             if(i <=  lstOfUserIds.size()-2 )   
                listOfValuesForQuery = listOfValuesForQuery + ',';
        }
        listOfValuesForQuery = listOfValuesForQuery + ')';
        
        for (Integer i=0; i < lstOfRecIds.size(); i++) {
            listOfValuesForRecIds = listOfValuesForRecIds + '\'' + lstOfRecIds[i] + '\'';
            if(i <=  lstOfRecIds.size()-2 )   
                listOfValuesForRecIds = listOfValuesForRecIds + ',';
        }
        listOfValuesForRecIds = listOfValuesForRecIds + ')';

        String query = String.format(
                'SELECT Id,UserOrGroupId,RowCause,{0} FROM {1} WHERE {2} IN {3} AND {4} IN {5} LIMIT 49999',
                new List<String> {
                        idFieldName,
                        sObjectName,
                        'UserOrGroupId',
                        listOfValuesForQuery ,
                        idFieldName,
                        listOfValuesForRecIds
                }
        );
        System.debug(query);
        return query;
    }

    public class InspectionResult {
        public Boolean inspectionFailed ;
        public String theShareObjectQuery = '' ;
        public String inspectionFailureMessage = '' ;
    }

    public class ApexManagedSharingUtilityException extends Exception {
    }
      
}