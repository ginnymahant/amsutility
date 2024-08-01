/* Description: Test class for ApexManagedShareObjects
 * Author: G Mahant (Davanti)
 * Created Date: 15 Mar 22  
 */
@isTest
public with sharing class ApexManagedShareObjectTest {
    @TestSetup
    static void setupData(){
        
    }

    public static void testInstanceGeneratorMethod(){
        ApexManagedShareObjects shareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject gso = shareObjects.getTheShareObjectDetailsForObjectName('Account');
        Assert.areEqual(gso.shareObjectName, 'AccountShare', 'Name of share object for Account matches as expected');
        Assert.areEqual(gso.idFieldName, 'Id', 'Name of Id field in AccountShare object matches as expected');
    }
}