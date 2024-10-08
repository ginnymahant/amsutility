/* Description: This class provides functionality to send emails
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 * Test : EmailServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class EmailService {

    public static List<Messaging.SendEmailResult> sendPlainTextEmail(String to, String subject, String body) {
        try {
            String[] toAddresses = to.split(',');
    
            if(toAddresses.size() > 0 && String.isNotBlank(toAddresses[0])) {
                List<Messaging.SendEmailResult> result = sendEmail(toAddresses, subject, body);
                return result;
            } else {
                throw new EmailServiceException('To email addresses not specified.');
            }
        } catch (Exception ex) {
            throw new EmailServiceException('Encountered error while sending Email. Exception-'+ ex.getMessage());
        }
    }

    private static List<Messaging.SendEmailResult> sendEmail(String[] toAddresses, String subject, String body) {

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setToAddresses( toAddresses);
        email.setPlainTextBody(body);
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email },false);
        return results;
        
    }    
    
    /* TODO - Provide implementations of following methods 
    public static List<EmailMessage> getEmailsByIds(Set<Id> emailMessageIds){
        return null;
    }   

    private List<Messaging.SendEmailResult> sendEmailAndCreateCopy(EmailTemplate emailTemplate, String emailTo, List<Messaging.EmailFileAttachment> attachments, Id accountId){
        return null;        
    }

    private Messaging.SingleEmailMessage generateEmail(String emailTo, EmailTemplate emailTemplate, List<Messaging.EmailFileAttachment> attachments) {
        return null;       
       
    }

    /**
     * Input Params:
     * Map of whatIds by targetObjectIds
     * targetObjectIds: A list of IDs of the contacts, leads, or users to which the email will be sent. The IDs you specify set the context and ensure that merge fields in the template contain the correct data.
     * whatIds: secondary object for merge fields, ie: Case Id.
     * emailTemplateName: Developer name for the email template
     */
    /*TODO - Provide implementations of following methods
    public static List<Messaging.SendEmailResult> sendSingleEmailTemplate(Map<Id,Id> whatIdsBytargetObjectIds, String emailTemplateName) {

        return null;  
    }
    */

    public class EmailServiceException extends Exception {}
}