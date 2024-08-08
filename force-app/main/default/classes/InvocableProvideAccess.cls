public with sharing class InvocableProvideAccess {

    @InvocableMethod(label='Provide Access' description='Provides access to records to the specified users.' category='Programatic Record Access Management')
    public static List<String> provideAccess(List<AMC_ProvideAccessRequest> inputList) {

        List<String> errors = new List<String>(); 
        ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance() ;

        for (AMC_ProvideAccessRequest req : inputList) {
            Boolean success ;
            if( req.nameOfObject.equalsIgnoreCase('Account') ) {
                success = apexSharingUtility.buildAccountShareRecords(req.accessLevel,req.caseAccessLevel, req.opportunityAccessLevel , req.contactAccessLevel , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
                if ( !success) {
                    errors.add('To provide account record access to users, parameters provided was invalid. Provide correct access levels that apply for case, contact etc and try again.');
                }
            } else {
                success = apexSharingUtility.buildShareRecords(req.nameOfObject , req.rowCause, req.accessLevel , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
                if ( !success) {
                    errors.add('To provide ' + req.nameOfObject + ' record access to users, parameters provided was invalid.Ensure parametrer are not blank and object is configured in ApexManagedSharingSetting custom metadata.');
                } 
            }
        }
        if(errors.size() > 0 ) {
            return errors;
        }
        apexSharingUtility.shareRecords('Providing access to records for users via Provide Access-Apex Managed Sharing utility failed.',TRUE);
        return null;

    }

    public class AMC_ProvideAccessRequest{

        @InvocableVariable(label='Name of Object' required='true' description='Name of the object for which access needs to be provided.')
        public String nameOfObject;
        @InvocableVariable(label='Rowcause for access' required='true' description='Std Objects-Manual, Custom Objects-Apex Managed Sharing Reason')
        public String rowCause;
        @InvocableVariable(label='List of User Id and Record Ids' required='true' description='List of Users and Records for which access needs to be provided.')
        public List<UserAndRecordIds> userAndRecordIdsList;
        @InvocableVariable(label='Access level' required='true' description='Access must be greater than the default access of users')
        public String accessLevel;
        @InvocableVariable(label='Opportunity Access level' required='false' description='Provide if Name of Object is Account, access must be greater than the default access of users')
        public String opportunityAccessLevel;
        @InvocableVariable(label='Case Access level' required='false' description='Provide if Name of Object is Account, access must be greater than the default access of users')
        public String caseAccessLevel;
        @InvocableVariable(label='Case Access level' required='false' description='Provide if Name of Object is Account, access must be greater than the default access of users')
        public String contactAccessLevel;
    }


}