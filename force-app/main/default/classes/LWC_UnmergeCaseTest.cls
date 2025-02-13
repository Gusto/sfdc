@isTest
public class LWC_UnmergeCaseTest {
    @testSetup
    static void setupData() {
        CaseTriggerHelper.skipTrigger = true;
        // Create a new Payroll Care Read Only Case.
        Case objCase = TestDataFactory.createCaseRecord('Payroll Care', true);
        CaseTriggerHelper.skipTrigger = false;
    }
    
    static testMethod void testGetCaseRecordType(){
        Case objCase = [SELECT Id, Status FROM Case WHERE RecordType.Name = 'Payroll Care' LIMIT 1];
        // Update Status to Closed to get a Read Only Case
        objCase.Status = 'Closed';
        update objCase;

        Test.startTest();
        LWC_UnmergeCase.WrapperResponse objWrapperSuccessResponse = LWC_UnmergeCase.getCaseRecordType(objCase.Id);
        Case objCaseToUnMerge = [SELECT Id, RecordType.Name FROM Case Where Id = :objCase.Id];
        LWC_UnmergeCase.WrapperResponse objWrapperUnMergeResponse = LWC_UnmergeCase.unmergeCaseRecord(objCaseToUnMerge);
        Test.stopTest();
        
        System.assertEquals(true, objWrapperSuccessResponse.isSuccess, 'Case record type was not changed to Read Only');
        System.assertEquals(true, objWrapperUnMergeResponse.isSuccess, 'Case was not unmerged');
    }
}