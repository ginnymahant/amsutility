@IsTest
public with sharing class QueueableAMS_ProvideAccessTest {

    private static String uniqueId ;

    @TestSetup
    static void makeData() {

        //Insert data for Apex Managed sharing control custom setting, without this error is thrown if access is shared or revoked using ApexManagedSharingUtilityV2
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
        uniqueId = h.SubString(0,8);
        User userRec = new User(Alias = uniqueId, Email= uniqueId + '@testdomain.com', isActive = true,
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = p.Id, 
                                TimeZoneSidKey='America/New_York', UserName= uniqueId + '@testdomain.com');      
        insert userRec;
    }

    @isTest
    static void testAccountSharingForAUser() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        AccountShare shareRec = new AccountShare();
        List<SObject> sharingRecords = new List<SObject>();
        shareRec.put('AccountId', accRec.Id);
        shareRec.put('RowCause', 'Manual');
        shareRec.put('AccountAccessLevel','Edit');
        shareRec.put('OpportunityAccessLevel','Edit');
        shareRec.put('CaseAccessLevel','Edit');
        //shareRec.put('ContactAccessLevel','Edit');
        shareRec.put('UserOrGroupId', stdUser.Id);
        sharingRecords.add(shareRec);

        Map<String, List<Sobject>> mapOfAllSharingRecordsToInsert = new Map<String, List<Sobject>>();
        mapOfAllSharingRecordsToInsert.put('Account' , (List<AccountShare>)(sharingRecords));     
                
        Test.startTest();
            QueueableAMS_ProvideAccess jobToShareRecords = new QueueableAMS_ProvideAccess( mapOfAllSharingRecordsToInsert );
            System.enqueueJob(jobToShareRecords); 
        Test.stopTest();        
        List<AccountShare> acctShareList = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :stdUser.Id];
        Assert.areEqual( 1, acctShareList.size(), '1 Account Share records for 1 user found as expected.');
    }
    @isTest
    static void testMethodtrimMapAsPerChunkSize() {

        Map<String, List<SObject>> mapOfAllSharingRecords = new Map<String, List<SObject>>();
        List<SObject> recs = new List<SObject>();
        for ( Integer i = 0 ; i < QueueableAMS_ProvideAccess.COUNT_OF_RECS_TO_INSERT + 10 ; i++ ){
            recs.add (new Account( name = EncodingUtil.convertToHex(Crypto.generateAesKey(128)).substring(0, 20)));
        }
        mapOfAllSharingRecords.put('Account', recs);
        QueueableAMS_ProvideAccess que = new QueueableAMS_ProvideAccess(mapOfAllSharingRecords);
        que.nameOfObject = 'Account';
        Test.startTest();
            que.trimMapAsPerChunkSize( recs);
        Test.stopTest();
        Assert.areEqual(10, que.mapOfAllSharingRecordsToInsert.get('Account').size(), 'List trimmed correctly as per chunk size');
    }    

    @isTest
    static void testSanitizeRecordsToRemoveDirtyShares() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        AccountShare shareRec = new AccountShare();
        List<SObject> sharingRecords = new List<SObject>();
        shareRec.put('AccountId', accRec.Id);
        shareRec.put('RowCause', 'Manual');
        shareRec.put('AccountAccessLevel','Edit');
        shareRec.put('OpportunityAccessLevel','Edit');
        shareRec.put('CaseAccessLevel','Edit');
        //shareRec.put('ContactAccessLevel','Edit');
        shareRec.put('UserOrGroupId', stdUser.Id);
        sharingRecords.add(shareRec);

        Map<String, List<Sobject>> mapOfAllSharingRecordsToInsert = new Map<String, List<Sobject>>();
        mapOfAllSharingRecordsToInsert.put('Account' , null );
        mapOfAllSharingRecordsToInsert.put('XYZRandomObject' , (List<AccountShare>)(sharingRecords));
                
        QueueableAMS_ProvideAccess jobToShareRecords = new QueueableAMS_ProvideAccess( mapOfAllSharingRecordsToInsert );
        jobToShareRecords.nameOfObject = 'Account';
        jobToShareRecords.santizeRecords();
        Assert.areEqual( false , mapOfAllSharingRecordsToInsert.containsKey('Account'), 'Account entry removed from map as there are no Account records to share.');
        jobToShareRecords.nameOfObject = 'XYZRandomObject';
        jobToShareRecords.santizeRecords();
        Assert.areEqual( false , mapOfAllSharingRecordsToInsert.containsKey('XYZRandomObject'), 'Dirty entry removed from map.');
    }
        
}
