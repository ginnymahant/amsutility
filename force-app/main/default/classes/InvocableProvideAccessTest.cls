@isTest
public with sharing class InvocableProvideAccessTest {
    
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
    }
    @isTest
	static void provideAccessTest() {
		User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
		List<InvocableProvideAccess.AMC_ProvideAccessRequest> requestList = new List<InvocableProvideAccess.AMC_ProvideAccessRequest>();
		InvocableProvideAccess.AMC_ProvideAccessRequest request = new InvocableProvideAccess.AMC_ProvideAccessRequest();
		request.nameOfObject = 'Opportunity';
		request.rowCause = 'Manual';
        request.accessLevel = 'Edit';
		List<UserAndRecordIds> userAndRecordIdsList = new List<UserAndRecordIds>();

		List<Opportunity> opportunities = [
			SELECT Id
			FROM Opportunity
			LIMIT 1
		];
		Id opportunityId = opportunities[0].Id;
        UserAndRecordIds userAndRecordIds = new UserAndRecordIds();
        userAndRecordIds.userId = stdUser.Id;
        userAndRecordIds.recordIds = new Set<Id>{ opportunityId };
        userAndRecordIdsList.add(userAndRecordIds);
		request.userAndRecordIdsList = userAndRecordIdsList;
		requestList.add(request);

         request = new InvocableProvideAccess.AMC_ProvideAccessRequest();
		request.nameOfObject = 'Account';
        request.accessLevel = 'Edit';
		userAndRecordIdsList = new List<UserAndRecordIds>();

        userAndRecordIds = new UserAndRecordIds();
        userAndRecordIds.userId = stdUser.Id;
        userAndRecordIds.recordIds = new Set<Id>{ };
        userAndRecordIdsList.add(userAndRecordIds);
		request.userAndRecordIdsList = userAndRecordIdsList;

        Test.startTest();
            List<String> errors = InvocableProvideAccess.provideAccess(requestList);
        Test.stopTest();
        Assert.areEqual( true, errors == null, 'Providing access to Opportunity was successful');

	}
    @isTest
	static void negativeTestForprovideAccess() {
		User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
		List<InvocableProvideAccess.AMC_ProvideAccessRequest> requestList = new List<InvocableProvideAccess.AMC_ProvideAccessRequest>();
		InvocableProvideAccess.AMC_ProvideAccessRequest request = new InvocableProvideAccess.AMC_ProvideAccessRequest();
		request.nameOfObject = 'Account';
		request.rowCause = 'Manual';
        request.accessLevel = 'Edit';
		List<UserAndRecordIds> userAndRecordIdsList = new List<UserAndRecordIds>();
        UserAndRecordIds userAndRecordIds = new UserAndRecordIds();
        userAndRecordIds.userId = stdUser.Id;
        userAndRecordIds.recordIds = new Set<Id>{ };
        userAndRecordIdsList.add(userAndRecordIds);
		request.userAndRecordIdsList = userAndRecordIdsList;
        requestList.add(request);

        Test.startTest();
            List<String> errors = InvocableProvideAccess.provideAccess(requestList);
        Test.stopTest();
        Assert.areNotEqual( null, errors , 'Providing access to Account with invalid request reported errors');

	}
}