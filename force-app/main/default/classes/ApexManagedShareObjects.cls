public with sharing class ApexManagedShareObjects {

    //private static instance of the class
    private static ApexManagedShareObjects instance = null;
    //This map cpntain Key: name of sObject in lowerCase , value - GenericShgareObject record which containis details of share object for the object names in key
    private Map <String , GenericShareObject > mapOfObjectNameAndItsShareObjectDetails = new  Map <String , GenericShareObject > ();

    //private constructor to avoid creating an instance anywhere outside of this class
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
        System.debug('The mapOfObjectNameAndItsShareObjectDetails is -' + mapOfObjectNameAndItsShareObjectDetails);                       
    }

    public  GenericShareObject getTheShareObjectDetailsForObjectName (String sObjectName ){
        return mapOfObjectNameAndItsShareObjectDetails.get(sObjectName.toLowerCase());

    }    
         
    public static ApexManagedShareObjects  getInstance(){
        if(instance == null){
            instance = new ApexManagedShareObjects();
        }
        return instance;
    }

    private String returnNameOfShareObject (String sObjectName ) {
        if ( sObjectName.endsWith('__c'))
            return sObjectName.removeEnd('__c') + '__Share';
        else 
            return sObjectName +'Share';    
    }

    private String returnNameOfIdField (String sObjectName ) {
        if ( sObjectName.endsWith('__c'))
            return 'ParentId';
        else 
            return sObjectName + 'Id';    
    }

    private String returnNameOfAccessLevelField (String sObjectName ) {
        if ( sObjectName.endsWith('__c'))
            return 'AccessLevel';
        else 
            return sObjectName + 'AccessLevel';    
    }

    public class GenericShareObject {

        public String shareObjectName ;
        public String idFieldName ;
        public String accessLevelFieldName ;
        public SObjectType shareObjectType ;
    }

}