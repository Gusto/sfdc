/*
 * @name         ZPCompanySuspensionTriggerHelperTest
 * @author       Praveen Sethu
 * @date         12-29-2022
 * @description  Testing if overall status is updating on Account and Opportunty
 */
@isTest
public class ZPCompanySuspensionTriggerHelperTest {
	/*
	 * @author:         Praveen Sethu
	 * @description:   	Test if company suspension insert is updating overall status on account
	 * @param:          NA
	 * @return:         NA
	 */
	@isTest
	static void testCompanySuspensionInsert() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Test.startTest();

		ZP_Company_Suspension__c objSuspension = new TestDataFactory.ZPCompanySuspensionBuilder()
			.setId('4565756897890')
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setReason('Leaving for other vendor')
			.build();
		insert objSuspension;

		Test.stopTest();

		Account objAccAssert = [SELECT Id, ZP_Company_Overall_Status__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(ZPCompanySuspensionTriggerHelper.ACCOUNT_OVERALL_STATUS_SUSPENDED, objAccAssert.ZP_Company_Overall_Status__c);

		// assert if user facing suspension record is created
		System.assertNotEquals(0, [SELECT COUNT() FROM Company_Suspension__c WHERE Account__c = :objCompAccount.Id]);
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Test if company suspension insert is updating the right overall status on account
	 * @param:          NA
	 * @return:         NA
	 */
	@isTest
	static void testCompanySuspensionUpdate() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Test.startTest();

		ZP_Company_Suspension__c objSuspension = new TestDataFactory.ZPCompanySuspensionBuilder()
			.setId('4565756897890')
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setReason('Leaving for other vendor')
			.build();
		insert objSuspension;

		objSuspension.Unsuspended_At__c = Date.today();
		update objSuspension;

		Test.stopTest();

		Account objAccAssert = [SELECT Id, ZP_Company_Overall_Status__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(ZPCompanySuspensionTriggerHelper.ACCOUNT_OVERALL_STATUS_ACTIVE, objAccAssert.ZP_Company_Overall_Status__c);

		// assert if user facing suspension record is created
		System.assertNotEquals(0, [SELECT COUNT() FROM Company_Suspension__c WHERE Account__c = :objCompAccount.Id]);
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Testing scenario with multiple company suspensions per account
	 * @param:          NA
	 * @return:         NA
	 */
	@isTest
	static void testMultipleCompanySuspensionScenario() {
		Account objCompAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account OHI').setZPCompanyId('1111111111').build();
		insert objCompAccount;

		Test.startTest();

		ZP_Company_Suspension__c objSuspension1 = new TestDataFactory.ZPCompanySuspensionBuilder()
			.setId('4565756897890')
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setReason('Leaving for other vendor')
			.build();
		objSuspension1.Created_At__c = System.now().addDays(1);
		insert objSuspension1;

		ZP_Company_Suspension__c objSuspension2 = new TestDataFactory.ZPCompanySuspensionBuilder()
			.setId('3234543655437')
			.setCompanyId(objCompAccount.ZP_Company_ID__c)
			.setReason('Leaving for other vendor')
			.setUnSuspendedAt(Date.today().addDays(-1))
			.build();
		objSuspension1.Created_At__c = System.now().addDays(2);
		insert objSuspension2;

		Test.stopTest();

		Account objAccAssert = [SELECT Id, ZP_Company_Overall_Status__c FROM Account WHERE Id = :objCompAccount.Id];
		System.assertEquals(ZPCompanySuspensionTriggerHelper.ACCOUNT_OVERALL_STATUS_ACTIVE, objAccAssert.ZP_Company_Overall_Status__c);

		Company_Suspension__c objAssert = [SELECT Id, Unsuspended_At__c, Reason__c FROM Company_Suspension__c WHERE Id__c = :objSuspension2.Id__c];
		System.assertEquals(objAssert.Unsuspended_At__c, objSuspension2.Unsuspended_At__c);
		System.assertEquals(objAssert.Reason__c, objSuspension2.Reason__c);

		// assert if user facing suspension record is created
		System.assertNotEquals(0, [SELECT COUNT() FROM Company_Suspension__c WHERE Account__c = :objCompAccount.Id]);
	}
}