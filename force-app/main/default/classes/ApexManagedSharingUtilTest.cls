@isTest
public with sharing class ApexManagedSharingUtilTest {

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
    public static void testBuildAccountShareRecords() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Map<Id, Set<Id>> mapOfUserIdAndRecordIds = new Map<Id, Set<Id>> () ; 
        mapOfUserIdAndRecordIds.put(stdUser.Id , new Set<Id> {accRec.Id} );
        ApexManagedSharingUtilityV2 amsUtil = ApexManagedSharingUtilityV2.getInstance();

        Test.startTest();
            amsUtil.buildAccountShareRecords('Edit', 'Edit', 'Edit', mapOfUserIdAndRecordIds);
            amsUtil.shareRecords( 'Sharing failed during test', false );
        Test.stopTest();

        List<AccountShare> AccountShareList = [SELECT Id FROM AccountShare WHERE userOrGroupId = :stdUser.Id];
        Assert.areEqual( 1, AccountShareList.size(), 'One Account Share record for one User found as expected.');
    }

    @isTest
    public static void testBuildAccountShareRecordsWithSmartShare() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User'  AND isActive = true LIMIT 1];
        Account accRec = [SELECT Id FROM Account LIMIT 1];
        Map<Id, Set<Id>> mapOfUserIdAndRecordIds = new Map<Id, Set<Id>> () ; 
        mapOfUserIdAndRecordIds.put(stdUser.Id , new Set<Id> {accRec.Id} );
        ApexManagedSharingUtilityV2 amsUtil = ApexManagedSharingUtilityV2.getInstance();

        Test.startTest();
            amsUtil.buildAccountShareRecords('Edit', 'Edit', 'Edit', mapOfUserIdAndRecordIds);
            amsUtil.shareRecords( 'Sharing failed during test', true );
        Test.stopTest();

        List<AccountShare> AccountShareList = [SELECT Id FROM AccountShare WHERE userOrGroupId = :stdUser.Id];
        Assert.areEqual( 1, AccountShareList.size(), 'One Account Share record for one User found as expected.');
    }
    @isTest
    public static void testBuildShareRecords() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, Set<Id>> mapOfUserIdAndRecordIds = new Map<Id, Set<Id>> () ; 
        mapOfUserIdAndRecordIds.put(stdUser.Id , new Set<Id> { oppRec.Id } );
        ApexManagedSharingUtilityV2 amsUtil = ApexManagedSharingUtilityV2.getInstance();

        Test.startTest();
            amsUtil.buildShareRecords('Opportunity', 'Manual', 'Edit', mapOfUserIdAndRecordIds);
            amsUtil.shareRecords( 'Sharing failed during test', false );
        Test.stopTest();

        List<OpportunityShare> OppShareList = [SELECT Id FROM OpportunityShare WHERE userOrGroupId = :stdUser.Id];
        Assert.areEqual(1,OppShareList.size(), 'One Opportunity Share record for one User found as expected.');
    }
    @isTest
    public static void testBuildShareRecordsWithSmartShare() {

        User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
        Opportunity oppRec = [SELECT Id FROM Opportunity LIMIT 1];
        Map<Id, Set<Id>> mapOfUserIdAndRecordIds = new Map<Id, Set<Id>> () ; 
        mapOfUserIdAndRecordIds.put(stdUser.Id , new Set<Id> { oppRec.Id } );
        ApexManagedSharingUtilityV2 amsUtil = ApexManagedSharingUtilityV2.getInstance();

        Test.startTest();
            amsUtil.buildShareRecords('Opportunity', 'None', 'Edit', mapOfUserIdAndRecordIds);
            amsUtil.shareRecords( 'Sharing failed during test', true );
        Test.stopTest();

        List<OpportunityShare> AccountShareList = [SELECT Id FROM OpportunityShare WHERE userOrGroupId = :stdUser.Id];
        Assert.areEqual(1,AccountShareList.size(), 'One Opportunity Share record for one User found as expected.');
    }
}