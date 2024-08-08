public with sharing class InvocableRevokeAccess {
    @InvocableMethod(label='Revoke Access' description='Revoke access to records for specified users.' category='Programatic Record Access Management')
    public static List<String> revokeAccess(List<AMC_RevokeAccessRequest> inputList) {
        
        List<String> errors = new List<String>(); 
        ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance() ;

        for (AMC_RevokeAccessRequest req : inputList) {
            Boolean success = apexSharingUtility.addToListOfRecordsForRevokingAccess(req.nameOfObject , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
            if ( !success) {
                errors.add('To provide ' + req.nameOfObject + ' record access to users, parameters provided was invalid.Ensure parametrer are not blank and object is configured in ApexManagedSharingSetting custom metadata.');
            } 
        }
        if(errors.size() > 0 ) {
            return errors;
        }
        apexSharingUtility.revokeAllAccess('Revoking access to records for users via Provide Access-Apex Managed Sharing utility failed.',TRUE);
        return null;
    }

    public class AMC_RevokeAccessRequest{
        @InvocableVariable(label='Name of Object' required='true' description='Name of the object for which access needs to be provided.')
        public String nameOfObject ;
        @InvocableVariable(label='List of User Id and Record Ids' required='true' description='List of Users and Records for whom access needs to be revoked.')
        public List<UserAndRecordIds> userAndRecordIdsList;

    }

}