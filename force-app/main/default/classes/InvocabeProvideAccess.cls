public with sharing class InvocableProvideAccess {

    @Invocable(label='Provide Access' description='Provides access to records to the specified users.' category='Record Access')
    public static void provideAccess(List<Map<String,Object>> inputs) {

    }

    public class ProvideAccess{

        @InvocableVariable(label='Name of Object' required='true' description='Name of the object for which access needs to be provided.')
        public String nameOfObject;
        @InvocableVariable(label='Name of Object' required='true' description='Name of the object for which access needs to be provided.')
        public String rowCause;

    }

    public class UserAndRecordIds{
        Id userId;
        Set<Id> recordIds;
    }
}