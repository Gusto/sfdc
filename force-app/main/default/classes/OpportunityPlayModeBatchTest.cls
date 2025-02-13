/**
 * @name         OpportunityPlayModeBatchTest
 * @author       Praveen Sethu
 * @date         03-07-2021
 * @description  Updating eligiblity status of ineligible opportunities for play mode
 **/

@isTest
public class OpportunityPlayModeBatchTest {
	/*** Tests if Ineligible opportunity becomes eligible, batch class must update eligibility ***/
	@isTest
	static void testOpptyPlayModeEligibility() {
		Account objCompanyAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Test Company Account', true);

		// Insert Ineligible Opportunity - This record will not be served in play mode
		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.COMPANY_OPPTY_RT_ID, objCompanyAccount.Id, Date.today().addDays(10), 'Test Company Opportunity', 'MQL', false);
		objOppty.Served_Play_Mode__c = OpportunityUtil.INELIGIBLE_SAL_GREETERS_PLAYMODE;
		insert objOppty;

		Contact objContact = TestUtils.createContact(objCompanyAccount.Id, 'First Name', 'Last Name', 'oppcontactrole@oppty.com', false);
		objContact.Current_Sequence_Status__c = 'Active';
		insert objContact;

		OpportunityContactRole objOpptyContactRole = new OpportunityContactRole(OpportunityId = objOppty.Id, ContactId = objContact.Id);
		insert objOpptyContactRole;

		Test.startTest();
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;

		OpportunityPlayModeBatchScheduler objScheduler = new OpportunityPlayModeBatchScheduler();
		String strJobId = System.schedule('Test Opportunity PlayMode Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		Opportunity objOpptyAssert = [SELECT Id, Served_Play_Mode__c FROM Opportunity WHERE Id = :objOppty.Id];
		System.assertEquals(true, String.isBlank(objOpptyAssert.Served_Play_Mode__c));
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if Exceptions are logged.
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testExceptions() {
		Account objCompanyAccount = TestUtils.createAccount(AccountUtil.COMPANY_ACCOUNT_RT_ID, 'Test Company Account', true);

		// Insert Ineligible Opportunity - This record will not be served in play mode
		Opportunity objOppty = TestUtils.createOpportunity(OpportunityUtil.COMPANY_OPPTY_RT_ID, objCompanyAccount.Id, Date.today().addDays(10), 'Test Company Opportunity', 'MQL', false);
		objOppty.Served_Play_Mode__c = OpportunityUtil.INELIGIBLE_SAL_GREETERS_PLAYMODE;
		insert objOppty;

		Test.startTest();

		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;

		OpportunityPlayModeBatch.blnTestException = true;

		OpportunityPlayModeBatchScheduler objScheduler = new OpportunityPlayModeBatchScheduler();
		String strJobId = System.schedule('Test Opportunity PlayMode Scheduler', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);

		Test.stopTest();

		OpportunityPlayModeBatch.blnTestException = false;

		Integer intLogCount = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c = 'OpportunityPlayModeBatch'];
		System.assertNotEquals(0, intLogCount);
	}
}