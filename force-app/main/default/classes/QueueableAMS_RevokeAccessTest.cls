@isTest
public with sharing class QueueableAMS_RevokeAccessTest {

    @TestSetup
    static void makeData() {

        //Insert data for Apex Managed sharing control custom setting, without this error is thrown if access is shared or revoked using ApexManagedSharingUtility
        ApexManagedSharingControlSetting__c sharingControl = new ApexManagedSharingControlSetting__c ( Send_Failure_Emails__c = false , Stop_Queueable_Jobs_For_Record_Sharing__c = false);
        insert sharingControl;

        Account acc ; 
        Opportunity opp ;
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive = TRUE LIMIT 1];

        System.runAs(adminUser){
            String randomNumber  = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 20);
            acc = new Account( name = randomNumber);
            insert acc;
            opp = new Opportunity(Name  = 'TestAMSOpp1', StageName = 'New', CloseDate = System.today() , AccountId = acc.Id);
            insert opp;
        }
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        User userRec = new User(Alias = h.SubString(0,8) , Email = h.SubString(0,8)  + '@testdomain.com', isActive = true,
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id, 
                                TimeZoneSidKey='America/New_York', UserName = h.SubString(0,8) + '@testdomain.com');      
        insert userRec;
        
        AccountShare shareRec = new AccountShare();
        List<SObject> sharingRecords = new List<SObject>();
        shareRec.put('AccountId', acc.Id);
        shareRec.put('RowCause', 'Manual');
        shareRec.put('AccountAccessLevel','Edit');
        shareRec.put('OpportunityAccessLevel','Edit');
        shareRec.put('CaseAccessLevel','Edit');
        //shareRec.put('ContactAccessLevel','Edit');
        shareRec.put('UserOrGroupId', userRec.Id);
        insert shareRec;
    }
    @isTest
    static void testMethodExecute() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        
        Set<Id> acctIds = new Set<Id>{accRec.Id};
        Map<Id, Set<Id>> mapOfRecordsIdByUsrId = new Map<Id, Set<Id>> ();
        mapOfRecordsIdByUsrId.put(stdUser.Id , acctIds );

        Map <String , Map <Id, Set<Id>>> mapForRevokingAccessofUsers = new Map <String , Map <Id, Set<Id>>> ();
        mapForRevokingAccessofUsers.put('Account', mapOfRecordsIdByUsrId);
        QueueableAMS_RevokeAccess job = new QueueableAMS_RevokeAccess(mapForRevokingAccessofUsers , 'Failure during test execution');

        Test.startTest();
            System.enqueueJob(job) ;
        Test.stopTest();
        AccountShare stdUSerAccessRec ;
        try {
                stdUSerAccessRec = [SELECT Id FROM AccountShare WHERE AccountId = :accRec.Id AND UserOrGroupId = :stdUser.Id LIMIT 1];
        } catch (System.QueryException exp) {
            Assert.areEqual( null , stdUSerAccessRec , 'Access of User revoked as expected.');
        }
    }

    @isTest
    static void testMethodtrimMapAsPerChunkSize() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        List<Account> recs = new List<Account>();
        Set<Id> acctIds = new Set<Id>();
        Map<Id, Set<Id>> mapOfRecordsIdByUsrId = new Map<Id, Set<Id>> ();

        for ( Integer i = 0 ; i < QueueableAMS_RevokeAccess.MAX_NUMBER_OF_SHARE_RECORDS_TO_REVOKE_ACCESS - 10 ; i++ ){
            recs.add (new Account( name = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 20)));
        }
        User adminUser = [SELECT Id, UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive = TRUE LIMIT 1];
        System.runAs(adminUser){
            insert recs;
        }
        for ( Account acc : recs) {
            acctIds.add(acc.Id);
        }
        
        mapOfRecordsIdByUsrId.put(stdUser.Id , acctIds );
        Map <String , Map <Id, Set<Id>>> mapForRevokingAccessofUsers = new Map <String , Map <Id, Set<Id>>> ();
        mapForRevokingAccessofUsers.put('Account', mapOfRecordsIdByUsrId);
        QueueableAMS_RevokeAccess que = new QueueableAMS_RevokeAccess(mapForRevokingAccessofUsers , 'Failure during test execution');
        que.nameOfObject = 'Account';
        Test.startTest();
            que.trimMapAsPerChunkSize( 'Account' , mapOfRecordsIdByUsrId);
        Test.stopTest();
        Assert.areEqual( 0 , que.mapOfAllUserAccessDetailsPerObject.get('Account').size(), 'List trimmed correctly as per chunk size');
    }  
    @isTest
    static void testSanitizeRecordsToRemoveDirtyShares() {
       
        Map <String , Map <Id, Set<Id>>> mapForRevokingAccess = new Map <String , Map <Id, Set<Id>>> ();
        mapForRevokingAccess.put('Account' , null );
        mapForRevokingAccess.put('XYZRandomObject' , new Map <Id, Set<Id>>() );
                
        QueueableAMS_RevokeAccess job = new QueueableAMS_RevokeAccess( mapForRevokingAccess , 'Failure during test execution');
        job.nameOfObject = 'Account';
        job.santizeRecords();
        Assert.areEqual( false , job.mapOfAllUserAccessDetailsPerObject.containsKey('Account'), 'Account entry removed from map as there are no Account shares to revoke.');
        job.nameOfObject = 'XYZRandomObject';
        job.santizeRecords();
        Assert.areEqual( false , job.mapOfAllUserAccessDetailsPerObject.containsKey('XYZRandomObject'), 'Dirty entry removed from map.');
    }

}


