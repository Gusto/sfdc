@isTest
public class FailedRecordsAccountAssignmentShdlrTest {
    
    @isTest
    static void methodForTest(){
        test.startTest();
            FailedRecordsAccountAssignmentScheduler sh1 = new FailedRecordsAccountAssignmentScheduler();
            String sch = '0 0 23 * * ?'; 
            system.schedule('Test Territory Check', sch, sh1);
        test.stopTest();
    }
}