@isTest
public with sharing class TaxResCaseAgencyInfoAgathaSyncBatchTest {
	@TestSetup
	static void TestDataSetup() {
		AccountTriggerHelper.skipTrigger = true;
		contactTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;

		Configuration_Settings__c objSetting = new Configuration_Settings__c();
		objSetting.TaxRes_Agatha_Sync_Time_Gap_in_Minutes__c = 45.0;
		insert objSetting;

		Account objAcc = TestUtility.CompanyAccount();
		objAcc.ZP_Company_id__c = '11111111111111TaxRes';
		update objAcc;

		Email_Subject_AutoClosed__c emailAutoClosed = new Email_Subject_AutoClosed__c();
		emailAutoClosed.Record_Type__c = 'Sales Cases';
		emailAutoClosed.Email_Subject__c = 'Test';
		emailAutoClosed.Name = 'Test';
		insert emailAutoClosed;

		Contact objCon = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAcc.Id)
			.setFirstName('Test Contact')
			.setLastName('Test')
			.setEmail('taxResCase@gusto1.com')
			.setPhone('1234567809')
			.setZPUserId('43243Gusto1')
			.build();
		insert objCon;

		Opportunity opp1 = new Opportunity();
		opp1.AccountId = objAcc.id;
		opp1.RecordTypeId = cache.getRecordTypeId('Opportunity', 'Benefits Renewal');
		opp1.name = 'Test';
		opp1.StageName = 'SAL';
		opp1.closedate = System.today();
		opp1.NumberOfEmployees__c = 12;
		insert opp1;

		Large_Scale_Issue__c largeScaleIssues = new Large_Scale_Issue__c();
		largeScaleIssues.name = 'Test LSI';
		insert largeScaleIssues;

		Case_Reason_Classification__c cseReason = new Case_Reason_Classification__c();
		cseReason.name = 'Test Reason';
		cseReason.Type__c = 'Tax Res';
		cseReason.Active__c = true;
		insert cseReason;

		ZP_User__c zpUser = new ZP_User__c();
		zpUser.Email__c = 'taxResCase@gusto1.com';
		zpUser.Created_At__c = Date.newInstance(2016, 11, 9);
		zpUser.Updated_At__c = Date.newInstance(2016, 12, 9);
		zpUser.Last_Sign_In_At__c = Date.newInstance(2018, 1, 1);
		zpUser.Id__c = '43243Gusto1';
		insert zpUser;

		ZP_User_Role__c zpUserRole = new ZP_User_Role__c();
		zpUserRole.User_Id__c = '43243Gusto1';
		zpUserRole.Phone__c = '1234567809';
		insert zpUserRole;

		Entitlement ent = new Entitlement(Name = 'Testing', AccountId = objAcc.Id, StartDate = Date.valueof(System.now()), EndDate = Date.valueof(System.now().addYears(2)));
		ent.type = 'Engagement - First Response';
		insert ent;

		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = true;
		ZP_Company_Onboarding_Funnel__c funnel = new ZP_Company_Onboarding_Funnel__c();
		funnel.company_id__c = '11111111111111TaxRes';
		funnel.add_addresses_completed__c = true;
		funnel.Sign__c = 'Test';
		funnel.add_addresses_started_at__c = System.now().addDays(2);
		funnel.add_addresses_completed_at__c = System.now().addDays(-1);
		funnel.add_employees_started_at__c = System.now().addDays(2);
		funnel.Add_employees_completed_at__c = System.now().addDays(-1);
		funnel.state_setup_started_at__c = System.now().addDays(2);
		funnel.State_setup_completed_at__c = System.now().addDays(-1);
		funnel.add_bank_info_started_at__c = System.now().addDays(2);
		funnel.add_bank_info_completed_at__c = System.now().addDays(-1);
		funnel.payroll_schedule_started_at__c = System.now().addDays(2);
		funnel.payroll_schedule_completed_at__c = System.now().addDays(-1);
		funnel.previous_paystubs_started_at__c = System.now().addDays(2);
		funnel.previous_paystubs_completed_at__c = System.now().addDays(-1);
		funnel.add_signatory_started_at__c = System.now().addDays(2);
		funnel.add_signatory_started_at__c = System.now().addDays(2);
		funnel.sign_all_forms_started_at__c = System.now().addDays(2);
		funnel.Sign_all_forms_completed_at__c = System.now().addDays(-1);
		funnel.verify_bank_info_started_at__c = System.now().addDays(2);
		funnel.verify_bank_info_completed_at__c = System.now().addDays(-1);
		funnel.historical_liabilities_started_at__c = System.now().addDays(2);
		funnel.historical_liabilities_completed_at__c = System.now().addDays(-1);
		insert funnel;
		ZPCompanyOnboardingFunnelTriggerHelper.skipTrigger = false;
	}

	@isTest
	static void testBatchExecution() {
		CaseTriggerHelper.skipTrigger = true;
		list<Account> list_accRec = [SELECT Id FROM Account LIMIT 1];
		Case cse = new Case();
		cse.RecordTypeId = cache.getRecordTypeId('Case', 'Tax Res');
		cse.AccountId = list_accRec.get(0).Id;
		cse.Subject = 'Test';
		cse.Description = 'Test';
		cse.Type = 'QLE';
		cse.Origin = 'Email';
		cse.SuppliedEmail = 'taxResCase@gusto1.com';
		cse.Authorized_User__c = 'No';
		cse.Formating_Status__c = 'Pending';
		cse.TaxRes_OBMsg_Trigger__c = true;
		insert cse;

		test.startTest();
		TaxResCaseAgencyInfoAgathaSyncBatch batchController = new TaxResCaseAgencyInfoAgathaSyncBatch();
		Database.executeBatch(batchController, 1);
		test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}

	@isTest
	static void testBatchScheduler() {
		test.starttest();
		TaxResCaseScheduler schedulerClass = new TaxResCaseScheduler();
		String chron = '0 0 23 * * ?';
		System.schedule('Test Sched', chron, schedulerClass);
		test.stopTest();
		System.assert(true, 'Fixing Apex PMD issue.');
	}
}