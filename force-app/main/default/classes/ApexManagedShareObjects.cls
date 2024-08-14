/* Description: This Singleton pattern based class provides Share object details to the AMS utility.
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 * Test : ApexManagedShareObjectTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ApexManagedShareObjects {

    private static ApexManagedShareObjects instance = null;
    //This map contains Key: name of sObject in lowerCase , value - GenericShareObject record which contains details of share object for the object name in key
    private Map <String , GenericShareObject > mapOfObjectNameAndItsShareObjectDetails = new  Map <String , GenericShareObject > ();

    //private constructor to avoid creating an instance anywhere outside of this class (Singleton Pattern)
    private ApexManagedShareObjects() {
        List<ApexManagedSharingSetting__mdt> shareObjectSettings = [ SELECT Id , MasterLabel , ObjectName__c
                                FROM ApexManagedSharingSetting__mdt 
                                LIMIT 49999];               
        
        Map<String, Schema.SObjectType> mapOfObjectNameAndItsShareObjectDetailsNAmeAndType =  Schema.getGlobalDescribe();
        for ( ApexManagedSharingSetting__mdt setting : shareObjectSettings )  {

            if ( mapOfObjectNameAndItsShareObjectDetailsNAmeAndType.containsKey(returnNameOfShareObject( setting.ObjectName__c).tolowerCase())) {
                GenericShareObject genSObjRec = new GenericShareObject();
                genSObjRec.shareObjectName = returnNameOfShareObject( setting.ObjectName__c ).tolowercase();
                genSObjRec.accessLevelFieldName = returnNameOfAccessLevelField ( setting.ObjectName__c );
                genSObjRec.idFieldName = returnNameOfIdField( setting.ObjectName__c ) ;
                genSObjRec.shareObjectType = (Schema.SObjectType)mapOfObjectNameAndItsShareObjectDetailsNAmeAndType.get(genSObjRec.shareObjectName);//use .newSObject() to get the instance
                mapOfObjectNameAndItsShareObjectDetails.put( (setting.ObjectName__c).tolowercase() , genSObjRec);
            }
        }                    
    }
    /**
     * @description This method returns details of Share object for a specific object in sObjectName
     * @param String sObjectName The name of the sObject
     * @return GenericShareObject instance with name of Share object,  name of Id field in Share object , an instance of the share object and the field name which holds the access level
    */
    public  GenericShareObject getTheShareObjectDetailsForObjectName (String sObjectName ){
        return mapOfObjectNameAndItsShareObjectDetails.get(sObjectName.toLowerCase());

    }    
    /**
     * @description This method creates and returns an instance of parent class for Singleton pattern
     * @param 
     * @return ApexManagedShareObjects instance 
    */
    public static ApexManagedShareObjects  getInstance(){
        if(instance == null){
            instance = new ApexManagedShareObjects();
        }
        return instance;
    }
    /**
     * @description Return the name of share object for sObjectName
     * @param String sObjectName
     * @return String  
    */
    private String returnNameOfShareObject (String sObjectName ) {
        if ( sObjectName.endsWith('__c')){
            return sObjectName.removeEnd('__c') + '__Share';
        }else {
            return sObjectName +'Share';  
        } 
    }
    /**
     * @description Return the name of Id field in share object for sObjectName
     * @param String sObjectName
     * @return String  
    */
    private String returnNameOfIdField (String sObjectName ) {
        if ( sObjectName.endsWith('__c')){
            return 'ParentId';
        } else {
            return sObjectName + 'Id';  }   
    }
    /**
     * @description Return the name of accesslevel field in share object for sObjectName
     * @param String sObjectName
     * @return String  
    */
    private String returnNameOfAccessLevelField (String sObjectName ) {
        if ( sObjectName.endsWith('__c')){
            return 'AccessLevel';
        }else { 
            return sObjectName + 'AccessLevel';
        }        
    }

    public class GenericShareObject {

        public String shareObjectName ;
        public String idFieldName ;
        public String accessLevelFieldName ;
        public SObjectType shareObjectType ;
    }

}