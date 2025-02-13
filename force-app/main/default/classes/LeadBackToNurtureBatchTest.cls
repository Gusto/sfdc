/**
 * @name         : LeadBackToNurtureBatchTest
 * @author       : Praveen Sethu
 * @date         : 08-30-2021
 * @description  : Tests if Lead status is updated to Back to Nurture
 * @test classes : NA
 **/
@isTest
public with sharing class LeadBackToNurtureBatchTest {
	/**
	 * @Author      : Praveen Sethu & Veeresh Kumar
	 * @Description : Tests if Lead status is updated to Back to Nurture
	 * @Parm        : NA
	 * @Return      : NA
	 **/

	@isTest
	static void testBackToNurtureUpdate() {
		Date dtLeadDormantDate = Date.today().addDays(-(LeadUtil.NO_OF_LEAD_DORMANT_DAYS + 3));

		// Skip Lead Trigger for faster Lead inserts and updates
		LeadTriggerHelper.skipTrigger = true;

		// Insert two company leads
		List<Lead> list_LeadsToInsert = new List<Lead>();
		Lead objLead1 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('lead1@lead1.com')
			.setPhone('123456789')
			.setCompany('Back to Nurture Company 1')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setLeadSource('LinkedIn')
			.build();

		list_LeadsToInsert.add(objLead1);

		Lead objLead2 = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('lead2@lead2.com')
			.setPhone('123456789')
			.setCompany('Back to Nurture Company 2')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setLeadSource('LinkedIn')
			.build();

		list_LeadsToInsert.add(objLead2);

		insert list_LeadsToInsert;

		Lead objLeadInsertAssert1 = [SELECT Id, Last_Rep_Activity_Date__c, Status FROM Lead WHERE Id = :objLead1.Id];
		System.assertEquals(null, objLeadInsertAssert1.Last_Rep_Activity_Date__c);
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadInsertAssert1.Status);

		Lead objLeadInsertAssert2 = [SELECT Id, Last_Rep_Activity_Date__c, Status FROM Lead WHERE Id = :objLead2.Id];
		System.assertEquals(null, objLeadInsertAssert2.Last_Rep_Activity_Date__c);
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadInsertAssert2.Status);

		// Set Last Rep Activity Date to past no Of Lead Dormant Days
		objLead1.Last_Rep_Activity_Date__c = dtLeadDormantDate;

		// Set MQL Date to past No Of Lead Dormant Days
		objLead2.MQL_Date__c = dtLeadDormantDate;

		update list_LeadsToInsert;

		Lead objLeadUpdateAssert1 = [SELECT Id, Last_Rep_Activity_Date__c, Status FROM Lead WHERE Id = :objLead1.Id];
		System.assertEquals(dtLeadDormantDate, objLeadUpdateAssert1.Last_Rep_Activity_Date__c);

		Lead objLeadUpdateAssert2 = [SELECT Id, Last_Rep_Activity_Date__c, MQL_Date__c, Status FROM Lead WHERE Id = :objLead2.Id];
		System.assertEquals(null, objLeadUpdateAssert2.Last_Rep_Activity_Date__c);
		System.assertEquals(dtLeadDormantDate, objLeadUpdateAssert2.MQL_Date__c);
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadUpdateAssert2.Status);

		Test.startTest();

		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		LeadBackToNurtureScheduler objScheduler = new LeadBackToNurtureScheduler();
		objScheduler = new LeadBackToNurtureScheduler(null);
		String strJobId = System.schedule('Test Lead Back To Nurture Scheduler', strCronExpr, objScheduler);

		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		// Assert if Status of both the leads switched to 'Back to Nurture'
		for (Lead objLead : [SELECT Id, Status FROM Lead WHERE Id IN :list_LeadsToInsert]) {
			System.assertEquals(LeadUtil.LEAD_STATUS_BACK_TO_NURT, objLead.Status);
		}

		// Finally check if there are any exceptions logged
		checkForExceptions();
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Create a deliberate exception log.
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testException() {
		Date dtLeadDormantDate = Date.today().addDays(-(LeadUtil.NO_OF_LEAD_DORMANT_DAYS + 3));

		// Skip Lead Trigger for faster Lead inserts and updates
		LeadTriggerHelper.skipTrigger = true;

		// Insert Company lead:
		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('lead1@lead1.com')
			.setPhone('123456789')
			.setCompany('Back to Nurture Company')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.setLeadSource('LinkedIn')
			.build();

		insert objLead;

		Lead objLeadInsertAssert = [SELECT Id, Last_Rep_Activity_Date__c, MQL_Date__c, Status FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(null, objLeadInsertAssert.Last_Rep_Activity_Date__c);
		System.assertEquals(LeadUtil.LEAD_STATUS_MQL, objLeadInsertAssert.Status);

		objLead.MQL_Date__c = dtLeadDormantDate;
		update objLead;

		Lead objLeadUpdateAssert = [SELECT Id, MQL_Date__c FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(dtLeadDormantDate, objLeadUpdateAssert.MQL_Date__c);

		Test.startTest();
		// Turn exception flag on to cover exceptions
		LeadBackToNurtureBatch.blnException = true;

		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		LeadBackToNurtureScheduler objScheduler = new LeadBackToNurtureScheduler();
		String strJobId = System.schedule('Test Lead Back To Nurture Scheduler', strCronExpr, objScheduler);

		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'LeadBackToNurtureBatch'];
		System.assertNotEquals(0, list_Exceptions.size());
	}

	/**
	 * @Author      : Praveen Sethu & Veeresh Kumar
	 * @Description : Test if no exceptions are logged
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	public static void checkForExceptions() {
		// Assert no exceptions are logged from Task Trigger
		List<Exception_Log__c> list_Exceptions = [SELECT Id FROM Exception_Log__c WHERE Class_Name__c = 'LeadBackToNurtureBatch'];
		System.assertEquals(0, list_Exceptions.size());
	}
}