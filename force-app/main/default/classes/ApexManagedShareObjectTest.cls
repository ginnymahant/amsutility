@isTest
public with sharing class ApexManagedShareObjectTest {
    @TestSetup
    static void setupData(){
        
    }

    public static void testImstanceGeneratorMethod(){
        ApexManagedShareObjects shareObjects = ApexManagedShareObjects.getInstance();
        ApexManagedShareObjects.GenericShareObject gso = shareObjects.getTheShareObjectDetailsForObjectName('Account');
        Assert.areEqual(gso.shareObjectName, 'AccountShare', 'Name of share object for Account matches as expected');
        Assert.areEqual(gso.idFieldName, 'Id', 'Name of Id field in AccountShare object matches as expected');
    }
}