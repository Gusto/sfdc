/**
 * @name         : ReProcessZPAccountantSurveyBatchTest
 * @author       : Praveen Sethu
 * @date         : 05-19-2021
 * @description  : Test class for ReProcessZPAccountantSurveyBatch
 **/

@isTest
public with sharing class ReProcessZPAccountantSurveyBatchTest {
	@isTest
	public static void testReprocessAccountantSurveyBatch() {
		String strAccountantLeadId = '1001';
		// Insert failed record
		ZP_Accountant_Survey_Response__c objZPSurveyResponse = new ZP_Accountant_Survey_Response__c(Id__c = '123', Accountant_Lead_Id__c = strAccountantLeadId);
		insert objZPSurveyResponse;

		ZP_Accountant_Survey_Response__c objSurveyResAssert = [SELECT Id, Processing_State__c FROM ZP_Accountant_Survey_Response__c WHERE Id = :objZPSurveyResponse.Id];
		System.assertEquals('Error', objSurveyResAssert.Processing_State__c);

		// Create a Reseller Lead with Accountant Lead Id
		Lead objResellerLead = TestUtils.createNewLead(LeadUtil.RESELLER_LEAD_RT_ID, 'FName', 'LName', 'resellerlead@two.com', '123456789', 'Reseller 2', false);
		objResellerLead.ZP_Accountant_Lead_ID__c = strAccountantLeadId;
		insert objResellerLead;

		Test.startTest();
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;

		ReProcessZPAccountantSurveyScheduler objScheduler = new ReProcessZPAccountantSurveyScheduler();
		String jobId = System.schedule('Re Process Failed ZP Accountant Survey Response', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		objSurveyResAssert = [SELECT Id, Processing_State__c FROM ZP_Accountant_Survey_Response__c WHERE Id = :objZPSurveyResponse.Id];
		System.assertEquals('Processed', objSurveyResAssert.Processing_State__c);
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Test if Exceptions are logged.
	 * @Parm        : void
	 * @Return      : void
	 **/
	@isTest
	static void testExceptions() {
		String strAccountantLeadId = '1001';
		// Insert failed record
		ZP_Accountant_Survey_Response__c objZPSurveyResponse = new ZP_Accountant_Survey_Response__c(Id__c = '123', Accountant_Lead_Id__c = strAccountantLeadId);
		insert objZPSurveyResponse;

		ZP_Accountant_Survey_Response__c objSurveyResAssert = [SELECT Id, Processing_State__c FROM ZP_Accountant_Survey_Response__c WHERE Id = :objZPSurveyResponse.Id];
		System.assertEquals('Error', objSurveyResAssert.Processing_State__c);

		Test.startTest();
		Integer intNextYear = Date.today().year() + 1;
		String strCronExp = '0 0 0 15 3 ? ' + intNextYear;

		ReProcessZPAccountantSurveyBatch.blnTestException = true;

		ReProcessZPAccountantSurveyScheduler objScheduler = new ReProcessZPAccountantSurveyScheduler();
		String jobId = System.schedule('Re Process Failed ZP Accountant Survey Response', strCronExp, objScheduler);
		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		ReProcessZPAccountantSurveyBatch.blnTestException = false;

		Integer intLogCount = [SELECT COUNT() FROM Exception_Log__c WHERE Class_Name__c = 'ReProcessZPAccountantSurveyBatch'];
		System.assertNotEquals(0, intLogCount);
	}
}