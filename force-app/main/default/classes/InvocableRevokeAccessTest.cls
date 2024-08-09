@isTest
public with sharing class InvocableRevokeAccessTest {

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
	static void revokeAccessTest() {
		User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
		List<InvocableProvideAccess.AMC_ProvideAccessRequest> requestList = new List<InvocableProvideAccess.AMC_ProvideAccessRequest>();
		InvocableProvideAccess.AMC_ProvideAccessRequest request = new InvocableProvideAccess.AMC_ProvideAccessRequest();
        List<InvocableRevokeAccess.AMC_RevokeAccessRequest> revokeRequestList = new List<InvocableRevokeAccess.AMC_RevokeAccessRequest>();
        InvocableRevokeAccess.AMC_RevokeAccessRequest revokeReq = new InvocableRevokeAccess.AMC_RevokeAccessRequest();
        List<UserAndRecordIds> userAndRecordIdsList = new List<UserAndRecordIds>();

		request.nameOfObject = 'Opportunity';
		request.rowCause = 'Manual';
        request.accessLevel = 'Edit';
		
		List<Opportunity> opportunities = [
			SELECT Id
			FROM Opportunity
			LIMIT 1
		];

        UserAndRecordIds userAndRecordIds = new UserAndRecordIds();
        userAndRecordIds.userId = stdUser.Id;
        userAndRecordIds.recordIds = new List<Id>{ opportunities[0].Id };
        userAndRecordIdsList.add(userAndRecordIds);
		request.userAndRecordIdsList = userAndRecordIdsList;
		requestList.add(request);

        List<InvocableProvideAccess.AMC_ProvideAccessResult> errors = InvocableProvideAccess.provideAccess(requestList);
        Assert.areEqual( true, errors == null || errors.size() == 0 , 'Providing access to Opportunity was successful');
        
        revokeReq.nameOfObject = 'Opportunity';
        revokeReq.userAndRecordIdsList = userAndRecordIdsList;
        revokeRequestList.add(revokeReq);
        List<InvocableRevokeAccess.AMC_RevokeAccessResult> revErrors = new List<InvocableRevokeAccess.AMC_RevokeAccessResult>();

        Test.startTest();
            revErrors = InvocableRevokeAccess.revokeAccess(revokeRequestList);
        Test.stopTest();

        Assert.areEqual( true, errors == null || errors.size() == 0 , 'Revoking access to Opportunity was successful');
	}

    @isTest
	static void negativeTestForRevokeAccess() {
		User stdUser = [SELECT Id FROM User WHERE Profile.name = 'Standard User' AND isActive = true LIMIT 1];
		List<InvocableProvideAccess.AMC_ProvideAccessRequest> requestList = new List<InvocableProvideAccess.AMC_ProvideAccessRequest>();
		InvocableProvideAccess.AMC_ProvideAccessRequest request = new InvocableProvideAccess.AMC_ProvideAccessRequest();
        List<InvocableRevokeAccess.AMC_RevokeAccessRequest> revokeRequestList = new List<InvocableRevokeAccess.AMC_RevokeAccessRequest>();
        InvocableRevokeAccess.AMC_RevokeAccessRequest revokeReq = new InvocableRevokeAccess.AMC_RevokeAccessRequest();
        List<UserAndRecordIds> userAndRecordIdsList = new List<UserAndRecordIds>();
        
        revokeReq.nameOfObject = 'Opportunity';
        revokeReq.userAndRecordIdsList = null;
        revokeRequestList.add(revokeReq);
        List<InvocableRevokeAccess.AMC_RevokeAccessResult> errors = null;
        Test.startTest();
            errors = InvocableRevokeAccess.revokeAccess(revokeRequestList);
        Test.stopTest();

        Assert.areEqual( true, errors != null , 'Revoking access to Opportunity was successful');
	}
}