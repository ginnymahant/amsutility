/* Description: This class provides an invocable action for flows to provide users access to records of multiple objects. This invocable action works for bulk record access as well
 e.g. If user/s need to be provided access to >10K records.
 * Author: G Mahant (Davanti)
 * Created Date: 12 Aug 24  
 * Test : InvocableProvideAccessTest
 */
@SuppressWarnings
public with sharing class InvocableProvideAccess {

    @InvocableMethod(label='Provide Access' description='Provides access to records to the specified users.' category='Programatic Record Access Management')
    public static List<AMC_ProvideAccessResult> provideAccess(List<AMC_ProvideAccessRequest> inputList) {

        List<AMC_ProvideAccessResult> errors = new List<AMC_ProvideAccessResult>(); 
        ApexManagedSharingUtility apexSharingUtility = ApexManagedSharingUtility.getInstance() ;

        for (AMC_ProvideAccessRequest req : inputList) {
            Boolean success ;
            if( req.nameOfObject.equalsIgnoreCase('Account') ) {
                success = apexSharingUtility.buildAccountShareRecords(req.accessLevel,req.caseAccessLevel, req.opportunityAccessLevel , req.contactAccessLevel , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
                if ( !success) {
                    AMC_ProvideAccessResult errObj = new AMC_ProvideAccessResult();
                    errObj.error = 'To provide account record access to users, parameters provided was invalid. Provide correct access levels that apply for case, contact etc and try again.';
                    errors.add(errObj);
                }
            } else {
                success = apexSharingUtility.buildShareRecords(req.nameOfObject , req.rowCause, req.accessLevel , UserAndRecordIds.convertToMap(req.userAndRecordIdsList));
                if ( !success) {
                    AMC_ProvideAccessResult errObj = new AMC_ProvideAccessResult();
                    errObj.error = 'To provide account record access to users, parameters provided was invalid. Provide correct access levels that apply for case, contact etc and try again.';
                    errors.add(errObj);
                } 
            }
        }
        if(errors.size() > 0 ) {
            return errors;
        }
        String jsonString =  JSON.serialize(apexSharingUtility.shareRecords('Providing access to records for users via Provide Access-Apex Managed Sharing utility failed.',TRUE));
        return (List<AMC_ProvideAccessResult>) JSON.deserialize(jsonString, List<AMC_ProvideAccessResult>.class);   
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
        @InvocableVariable(label='Contact Access level' required='false' description='Provide if Name of Object is Account, access must be greater than the default access of users')
        public String contactAccessLevel;
    }

    public class AMC_ProvideAccessResult{
        @InvocableVariable(label='Error' description='Details of errors encountered')
        public String error;
    }    


}