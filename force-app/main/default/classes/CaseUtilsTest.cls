@isTest
private class CaseUtilsTest {
	@testSetup
	static void setUp() {
		Account objAccount = TestUtility.CompanyAccount();

		CaseTriggerHelper.skipTrigger = true;

		Test.startTest();
		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_ENGAGEMENT)
			.setAccountId(objAccount.Id)
			.setSubject('Test')
			.setDescription('Test')
			.setType(CaseUtils.TYPE_PAYROLL_CARE)
			.setOrigin(CaseUtils.ORIGIN_EMAIL)
			.build();
		insert objCase;

		Test.stopTest();
	}

	@isTest
	static void staticListTestMethod() {
		list<selectoption> caseTypeOptionList = CaseUtils.caseTypeOptionList();
		list<selectoption> caseStatusOptionList = CaseUtils.caseStatusOptionList();
		list<selectoption> caseStatusDetailOptionList = CaseUtils.caseStatusDetailOptionList();
		list<selectoption> list_PayrollAuditStatusDetailOptions = CaseUtils.casePayrollAuditStatusDetailOptionList();
		list<selectoption> list_EngagementTypeOptions = CaseUtils.caseEngagementTypeOptionList();
	}

	@istest
	static void testRouteCaseTaxRes() {
		case cse = new case();
		List<case> tempList = [SELECT id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (tempList.size() > 0)
			cse = tempList.get(0);
		test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Tax Res', cse);
		test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test routeCase() with payroll care
	 */
	@isTest
	static void testRouteCasesPRC() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (list_Temp.size() > 0) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Payroll Care', objCase);
		CaseUtils.routeCase('Benefits Care', objCase);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test routeCase() with benefits care
	 */
	@isTest
	static void testRouteCasesFSC() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (list_Temp.size() > 0) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Benefits Care', objCase);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test routeCase() with modern bank
	 */
	@isTest
	static void testRouteCasesModernBank() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (list_Temp.size() > 0) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Modern Bank', objCase);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test routeCase() with benefits compliance
	 */
	@isTest
	static void testRouteCasesBenCompliance() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (list_Temp.size() > 0) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Benefits Compliance', objCase);
		Test.stopTest();
	}

	/**
	 * @author Alex Xiong
	 * @description test routeCase() with payroll audit
	 */
	@isTest
	static void testRouteCasesPayrollAudit() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];
		if (list_Temp.size() > 0) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Payroll Audit', objCase);
		Test.stopTest();
	}

	@istest
	static void testRouteCases2() {
		case cse = new case();
		List<case> tempList = [SELECT id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case];
		if (tempList.size() > 0)
			cse = tempList.get(0);
		CaseTriggerHelper.skipTrigger = true;
		test.startTest();
		CaseUtils.routeCase('Tax Ops', cse);
		CaseUtils.routeCase('Payroll Compliance', cse);
		CaseUtils.routeCase('Risk Assurance', cse);
		test.stopTest();
	}

	@istest
	static void testRouteCases3() {
		case cse = new case();
		List<case> tempList = [SELECT id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case];
		if (tempList.size() > 0)
			cse = tempList.get(0);
		test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Benefits BoR', cse);
		CaseUtils.routeCase('Benefits Change Case', cse);
		test.stopTest();
	}

	@istest
	static void testRouteCases4() {
		case cse = new case();
		List<case> tempList = [SELECT id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c FROM Case];
		if (tempList.size() > 0)
			cse = tempList.get(0);
		test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		CaseUtils.routeCase('Benefits New Plan Case', cse);
		CaseUtils.routeCase('Benefits Renewal Case', cse);
		CaseUtils.routeCase('Member Fulfillment Emails', cse);
		test.stopTest();
	}

	@isTest
	static void testCaseRouting() {
		Case objCase = new Case();
		List<Case> list_Cases = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];

		if (!list_Cases.isEmpty()) {
			objCase = list_Cases[0];
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;

		Map<String, String> map_CaseTypeToRecordType = new Map<String, String>{
			CaseUtils.TYPE_SALES_CASES => 'Sales Cases',
			CaseUtils.TYPE_TAX_OPS => 'Tax Ops',
			CaseUtils.TYPE_PAYROLL_COMPLIANCE => 'Payroll Compliance',
			CaseUtils.TYPE_BENEFITS_CHANGE_CASE => 'Benefits Change Case',
			CaseUtils.TYPE_BENEFITS_NEW_PLAN_CASE => 'Benefits New Plan Case',
			CaseUtils.TYPE_BENEFITS_RENEWAL_CASE => 'Benefits Renewal Case',
			CaseUtils.TYPE_MEMEBER_FULFILLMENT_EMAILS => 'Member Fulfillment Emails'
		};

		for (String strCaseType : map_CaseTypeToRecordType.keySet()) {
			String strExpectedRecordType = map_CaseTypeToRecordType.get(strCaseType);

			CaseUtils.caseRouting(strCaseType, objCase);
			System.assert(objCase.RecordTypeId == Cache.getRecordTypeId('Case', strExpectedRecordType));
		}

		Test.stopTest();
	}

	@isTest
	static void testCaseRouting2() {
		Case objCase = new Case();
		List<Case> list_Cases = [SELECT Id, RecordTypeId, RecordType.Name, AccountId, Subject, Description, Type, Context__c, Reviewed_by_Dedicated_Support__c FROM Case];

		if (!list_Cases.isEmpty()) {
			objCase = list_Cases[0];
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;

		Map<String, String> map_CaseTypeToRecordType = new Map<String, String>{
			CaseUtils.TYPE_TAX_RES => 'Tax Res',
			CaseUtils.TYPE_PAYROLL_CARE => 'Payroll Care',
			CaseUtils.TYPE_MODERN_BANK => 'Modern Bank',
			CaseUtils.TYPE_BENEFITS_COMPLIANCE => 'Benefits Compliance',
			CaseUtils.TYPE_BENEFITS_CARE => 'Benefits Care',
			CaseUtils.TYPE_RISK_ASSURANCE => 'Risk Assurance',
			CaseUtils.TYPE_PAYROLLOPS_AUDIT => 'PayrollOps Audit'
		};

		for (String strCaseType : map_CaseTypeToRecordType.keySet()) {
			String strExpectedRecordType = map_CaseTypeToRecordType.get(strCaseType);

			CaseUtils.caseRouting(strCaseType, objCase);
			System.assert(objCase.RecordTypeId == Cache.getRecordTypeId('Case', strExpectedRecordType));
		}

		Test.stopTest();
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Check for TaxRes RingLead pilot agencies from custom metadatatype
	 * @Parm        : NA
	 * @Return      : NA
	 **/
	@isTest
	static void testGetRingLeadEligibleAgencies() {
		Set<String> set_PilotAgencies = new Set<String>();
		String strPilotAgency1 = 'New York Unemployment';
		String strPilotAgency2 = 'Nebraska U.C. Fund';

		Test.startTest();
		set_PilotAgencies = CaseUtils.getRingLeadEligibleAgencies();
		Test.stopTest();

		System.assertEquals(true, set_PilotAgencies.contains(strPilotAgency1));
		System.assertEquals(true, set_PilotAgencies.contains(strPilotAgency2));
	}
    /**
	 * @author Prajjwal Tawri
	 * @description test routeCase() with Engagement
	 */
	@isTest
	static void testRouteCasesEngagement() {
		Case objCase = new Case();
		List<Case> list_Temp = [SELECT Id, RecordTypeId, Type, OwnerId FROM Case];
		if (!list_Temp.isEmpty()) {
			objCase = list_Temp.get(0);
		}

		Test.startTest();
		CaseTriggerHelper.skipTrigger = true;
		EngagementCaseViewExtension.blnIsCaseRoute = true;
		CaseUtils.routeCase('Engagement', objCase);
		Test.stopTest();

		objCase = [SELECT Id, Support_Level__c, Type, RecordTypeId, OwnerId FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.TIER_1, objCase.Support_Level__c, 'Support Level should be Tier 1');
		System.assertEquals(CaseUtils.RECTYPE_ENGAGEMENT,objCase.RecordTypeId, 'Record Type is not Engagement');
		System.assertEquals(CaseUtils.PAYROLL_CASE_PILLAR, objCase.Type, 'Type is not Payroll');
		System.assertEquals(CaseUtils.ID_ENGAGEMENT_CASES_QUEUE, objCase.OwnerId, 'Case Owner should be Engagement Cases queue');
	}
}