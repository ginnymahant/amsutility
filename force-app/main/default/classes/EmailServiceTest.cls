@isTest
public class EmailServiceTest {
    private static final String EMAIL_ADDRESS = 'fluffyunicornX1@flytest123.com';

    @testSetup
    static void setup() {

        ApexEmailNotification apexNotification = new ApexEmailNotification ( Email = EMAIL_ADDRESS);
        update apexNotification; 
        
    }

    @isTest
    static void testSendPlainTextEmail() {
        Messaging.SendEmailResult[] sendResults = null;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            sendResults = EmailService.sendEmailToApexEmailNotificationAddress('Test Email Subject', 'This is a test email.');
            Test.stopTest();
        }

        for (Messaging.SendEmailResult result : sendResults) {
            System.assert(result.isSuccess(), 'Email should have been sent');
        }
    }

    @isTest
    static void testSendEmailToApexEmailNotificationAddress() {
        Messaging.SendEmailResult[] sendResults = null;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            sendResults = EmailService.sendEmailToApexEmailNotificationAddress('Test Email Subject', 'This is a test email.');
            Test.stopTest();
        }

        for (Messaging.SendEmailResult result : sendResults) {
            System.assert(result.isSuccess(), 'Email should have been sent');
        }
    }
}