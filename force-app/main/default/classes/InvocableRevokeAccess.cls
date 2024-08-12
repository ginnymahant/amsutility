/* Description: This class provides an invocable action for flows to revoke access of users to records of multiple objects. This invocable action works for bulk record access as well
 e.g. If user/s access to >10K records needs to be revoked.
 * Author: G Mahant (Davanti)
 * Created Date: 12 Aug 24  
 * Test : InvocableProvideAccessTest
 */
@SuppressWarning
public with sharing class InvocableRevokeAccess {

    @InvocableMethod(label='Revoke Access' description='Revoke access to records for specified users.' category='Programatic Record Access Management')
    public static List<AMC_RevokeAccessResult> revokeAccess(List<AMC_RevokeAccessRequest> inputList) {
        
        List<AMC_RevokeAccessResult> errors = new List<AMC_RevokeAccessResult>(); 
        ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance() ;

        for (AMC_RevokeAccessRequest req : inputList) {
            Boolean success = apexSharingUtility.addToListOfRecordsForRevokingAccess(req.nameOfObject , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
            if ( !success) {
                AMC_RevokeAccessResult errObj = new AMC_RevokeAccessResult();
                errObj.error = 'To provide ' + req.nameOfObject + ' record access to users, parameters provided was invalid.Ensure inputs are not blank and object is configured in ApexManagedSharingSetting custom metadata.';
                errors.add(errObj);
            } 
        }
        if(errors.size() > 0 ) {
            return errors;
        }
        String jsonString =  JSON.serialize(apexSharingUtility.revokeAllAccess('Revoking access to records for users via Provide Access-Apex Managed Sharing utility failed.',TRUE));
        return (List<AMC_RevokeAccessResult>) JSON.deserialize(jsonString, List<AMC_RevokeAccessResult>.class); 
    }

    public class AMC_RevokeAccessRequest{
        @InvocableVariable(label='Name of Object' required='true' description='Name of the object for which access needs to be provided.')
        public String nameOfObject ;
        @InvocableVariable(label='List of User Id and Record Ids' required='true' description='List of Users and Records for whom access needs to be revoked.')
        public List<UserAndRecordIds> userAndRecordIdsList;
    }

    public class AMC_RevokeAccessResult{
        @InvocableVariable(label='Error' description='Details of errors encountered')
        public String error;
    }  

}