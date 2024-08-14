/* Description: This classes tests functionality of EmailService
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 */
@isTest
public class EmailServiceTest {
    private static final String EMAIL_ADDRESS = 'fluffyunicornX1@flytest123.com';

    @testSetup
    static void setup() {

        ApexEmailNotification apexNotification = new ApexEmailNotification ( Email = EMAIL_ADDRESS);
        
    }

    @isTest
    static void negativeTestSendPlainTextEmail() {
        Messaging.SendEmailResult[] sendResults = null;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            try{
                    Test.startTest();
                    sendResults = EmailService.sendPlainTextEmail( '','Test Email Subject', 'This is a test email.');
                    Test.stopTest();
            } catch (EmailService.EmailServiceException exp) {
                Assert.areEqual(true, String.isNotBlank(exp.getMessage()) , 'Error detection for blank To address works as expected.');
            }
            Assert.areEqual(null, sendResults , 'Email not sent as To address was missing');
        }
    }

    @isTest
    static void testSendPlainTextEmail() {
        Messaging.SendEmailResult[] sendResults = null;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            sendResults = EmailService.sendPlainTextEmail(EMAIL_ADDRESS,'Test Email Subject', 'This is a test email.');
            Test.stopTest();
        }

        for (Messaging.SendEmailResult result : sendResults) {
            System.assert(result.isSuccess(), 'Email should have been sent');
        }
    }

}