@isTest
public class ZPRecoveryCaseBatchTest {
	@isTest
	static void testZPRecoveryCaseBatch() {
		ZP_Recovery_Case__c objZPRecoveryCase = new ZP_Recovery_Case__c(
			Company_Id__c = '7757616923607181',
			Event_Type__c = 'Testing',
			Created_At_Date__c = System.Today(),
			Event_Check_Date__c = System.Today(),
			Last_Processed__c = System.Today(),
			Recovery_Case_Id__c = '175750090'
		);
		insert objZPRecoveryCase;

		test.startTest();
        objZPRecoveryCase = [SELECT Id,Processing_State__c FROM ZP_Recovery_Case__c];
        System.assertEquals(objZPRecoveryCase.Processing_State__c, 'Queued', 'The Processing_State__c of ZP_Recovery_Case__c records should be Queued.');
		database.executeBatch(new ZPRecoveryCaseBatch(), 10);
		test.stopTest();
        objZPRecoveryCase = [SELECT Id,Processing_State__c FROM ZP_Recovery_Case__c];
        System.assertEquals(objZPRecoveryCase.Processing_State__c, 'Error', 'The Processing_State__c of ZP_Recovery_Case__c records should be Error.');
        
	}
}