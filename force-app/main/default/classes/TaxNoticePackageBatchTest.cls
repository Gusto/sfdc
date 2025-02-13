/**
 * @author      Todd Dowdy
 * @description Confirm Auto Solve Package and Case values are updated
 * Date: 08/12/2022
 **/
@isTest
public with sharing class TaxNoticePackageBatchTest {
	public static final String AUTOSOLVEPACKAGE_BATCH_RECORDTYPE_NAME = 'Auto-Solve Batch';
	public static final Id idAutoSolveBatchRT = Cache.getRecordTypeId('Auto_Solve_Package__c', AUTOSOLVEPACKAGE_BATCH_RECORDTYPE_NAME);
	public static final Id idTNDCRecType = CaseUtils.TAX_NOTICE_INDEX_RECTYPE_MANUAL;

	@testSetup
	static void setUp() {
		CaseTriggerHelper.skipTrigger = true;
		// Create Agency_Information__c record
		List<Agency_Information__c> list_AgencyInformtaions = new List<Agency_Information__c>();
		Agency_Information__c objAgencyInformation = new TestDataFactory.AgencyInformationBuilder().setName('Test Agency Information').setActive(true).build();
		list_AgencyInformtaions.add(objAgencyInformation);

		Agency_Information__c objAgencyInformation2 = new TestDataFactory.AgencyInformationBuilder().setName('Test Agency Information 2').setActive(true).build();
		list_AgencyInformtaions.add(objAgencyInformation2);

		insert list_AgencyInformtaions;

		Agency_Information__c strAgencyInformation = [SELECT Id FROM Agency_Information__c WHERE Name = 'Test Agency Information' LIMIT 1];

		// Create Auto_Solve_Package__c Record
		List<Auto_Solve_Package__c> list_AutoSolvePkg = new List<Auto_Solve_Package__c>();
		list_AutoSolvePkg.add(
			// Package with one Agency
			new TestDataFactory.AutoSolvePackageBuilder()
				.setName('Test Auto Package 1')
				.setRecordTypeId(idAutoSolveBatchRT)
				.setAutoSolvePackageStatus('Active')
				.setStatus('Ready for Research')
				.setTaxNoticeType('SUI')
				.setTaxNoticeFormNumber('IA126')
				.setCustomerJourney('Support')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setEmailTemplate('Hello World')
				.setTaxNoticeNumeration('1st')
				.setTaxNoticeAmountTotal(0)
				.setTaxNoticeDate(System.today())
				.setAgencyInformationId(strAgencyInformation.Id)
				.setClientIds('1231412134')
				.build()
		);

		list_AutoSolvePkg.add(
			// Package with multiple Agencies
			new TestDataFactory.AutoSolvePackageBuilder()
				.setName('Test Auto Package 2')
				.setRecordTypeId(idAutoSolveBatchRT)
				.setAutoSolvePackageStatus('Active')
				.setStatus('Ready for Research')
				.setTaxNoticeType('SUI')
				.setTaxNoticeFormNumber('IA126')
				.setCustomerJourney('Support')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setEmailTemplate('Hello World')
				.setTaxNoticeNumeration('1st')
				.setTaxNoticeAmountTotal(0)
				.setTaxNoticeDate(System.today())
				.setAgencyInformationId(strAgencyInformation.Id)
				.setClientIds('1231412134')
				.build()
		);

		list_AutoSolvePkg.add(
			// Package with multiple Agencies
			new TestDataFactory.AutoSolvePackageBuilder()
				.setName('Test Auto Package 3')
				.setRecordTypeId(idAutoSolveBatchRT)
				.setAutoSolvePackageStatus('Active')
				.setStatus('Ready for Research')
				.setTaxNoticeType('SUI')
				.setTaxNoticeFormNumber('IA126')
				.setCustomerJourney('Support')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setEmailTemplate('Hello World')
				.setTaxNoticeNumeration('1st')
				.setTaxNoticeDate(System.today())
				.setAgencyInformationId(objAgencyInformation2.Id)
				.setGustoIsAddresseeOfRecord(true)
				.setClientIds('1231412134')
				.build()
		);
		insert list_AutoSolvePkg;

		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;

		// Create Company Accounts
		Account objAccount = new TestDataFactory.AccountBuilder()
			.setRecordTypeId('Company')
			.setName('TEST ACCOUNT')
			.setJoinedDate(System.today())
			.setZPCompanyId('1231412134')
			.build();
		insert objAccount;

		// Create Company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId('Company')
			.setAccountId(objAccount.Id)
			.setFirstName('TEST CONTACT')
			.setLastName('CONTACT')
			.setPhone('1234567890')
			.setEmail('test.contact@gusto.com')
			.setZPUserId(String.valueOf(CaseTriggerHelperTest.generateRandomId()))
			.build();
		insert objContact;

		AccountTriggerHelper.skipTrigger = false;
		ContactTriggerHelper.skipTrigger = false;
		// Create Case - meets criteria
		List<Case> list_Case = new List<Case>();
		list_Case.add(
			new TestDataFactory.CaseBuilder()
				.setSubject('Auto Solve Test Case 1')
				.setStatus('Ready for Research')
				.setRecordTypeId('Tax Res')
				.setOrigin('Email')
				.setDirection('Inbound')
				.setTaxNoticeType('SUI')
				.setTaxNoticeNumeration('1st')
				.setTaxNoticeDate(System.today())
				.setTaxNoticeFormNumber('IA126')
				.setTaxNoticeAmountTotal(0)
				.setAgencyInformation(strAgencyInformation.Id)
				.setAccountId(objAccount.Id)
				.setContactId(objContact.Id)
				.build()
		);

		list_Case.add(
			new TestDataFactory.CaseBuilder()
				.setSubject('Auto Solve Test Case 2')
				.setStatus('Ready for Research')
				.setRecordTypeId('Tax Res')
				.setOrigin('Email')
				.setDirection('Inbound')
				.setTaxNoticeType('SUI')
				.setTaxNoticeFormNumber('IA126')
				.setTaxNoticeNumeration('1st')
				.setTaxNoticeDate(System.today())
				.setTaxNoticeAmountTotal(0)
				.setAgencyInformation(objAgencyInformation2.Id)
				.setPhysicalMail(true)
				.setAccountId(objAccount.Id)
				.setContactId(objContact.Id)
				.build()
		);

		insert list_Case;

		// Create Manual TNDC - meets criteria
		List<Tax_Notice_Index__c> list_TNDCs = new List<Tax_Notice_Index__c>();
		list_TNDCs.add(
			new TestDataFactory.TaxNoticeIndexBuilder()
				.setRecordTypeId(idTNDCRecType)
				.setCaseId(list_Case[0].Id)
				.setTaxNoticeFormNumber('IA126')
				.setTaxNoticeDate(System.Today())
				.setTaxNoticeType('SUI')
				.setAgencyInformation(strAgencyInformation.Id)
				.setClientName(objAccount.Id)
				.setSegment('Company')
				.setTaxAmount(45)
				.setTaxNoticeAmountTotal(0)
				.setAgencyAssigned('546ASD')
				.setSuiRateEffectiveDate(System.Today())
				.setYearQuarter('Q2 2023')
				.setTaxNumeration('1st')
				.build()
		);

		list_TNDCs.add(
			new TestDataFactory.TaxNoticeIndexBuilder()
				.setRecordTypeId(idTNDCRecType)
				.setCaseId(list_Case[1].Id)
				.setTaxNoticeFormNumber('IA126')
				.setTaxNoticeDate(System.Today())
				.setTaxNoticeType('SUI')
				.setAgencyInformation(objAgencyInformation2.Id)
				.setClientName(objAccount.Id)
				.setSegment('Company')
				.setTaxAmount(45)
				.setTaxNoticeAmountTotal(0)
				.setAgencyAssigned('546ASD')
				.setSuiRateEffectiveDate(System.Today())
				.setYearQuarter('Q2 2023')
				.setTaxNumeration('1st')
				.build()
		);

		insert list_TNDCs;
	}

	/**
	 * @author      Todd Dowdy
	 * @description Confirm Auto Solve Package and Case values are updated
	 **/
	@isTest
	static void testTaxNoticePackageBatchBatch() {
		Test.startTest();
		TaxNoticePackageBatchJob job = new TaxNoticePackageBatchJob();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		Case[] list_Case = [
			SELECT
				Id,
				Customer_Journey__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Auto_Response_Email_Content__c,
				Tax_Notice_Amount_Total__c,
				Tax_Notice_Date__c,
				Tax_Notice_Numeration__c,
				Automation_Status__c,
				Automation_Message__c
			FROM Case
			WHERE Subject = 'Auto Solve Test Case 1'
		];

		for (Case objCase : list_Case) {
			System.assertEquals('Hello World', objCase.Auto_Response_Email_Content__c, 'Case Auto Response Template Updated to match Package Record');
			System.assertEquals('Support', objCase.Customer_Journey__c, 'Case Customer Journey Updated to Support');
			System.assertEquals('Client', objCase.Root_Cause__c, 'Case Root Cause Updated to Client');
			System.assertEquals('Unactionable', objCase.Sub_Root_Cause__c, 'Case Sub Root Cause Updated to Unactionable');
			System.assertEquals('1st', objCase.Tax_Notice_Numeration__c, 'Case Tax_Notice_Numeration__c is empty');
			System.assertEquals(0, objCase.Tax_Notice_Amount_Total__c, 'Case Tax Notice Amount - Total is not 0');
			System.assertEquals(System.today(), objCase.Tax_Notice_Date__c, 'Case Tax Notice Date is not match');
			System.assertEquals('Started', objCase.Automation_Status__c, 'Case Automation_Status__c updated to Started');
			System.assertEquals('Auto-Solve Batch', objCase.Automation_Message__c, 'Case Automation_Message__c updated to Auto-Solve Batch');
		}

		Auto_Solve_Package__c[] list_AutoSolvePkg = [
			SELECT Id, Tax_Notice_Type__c, Tax_Notice_Form_Number__c, Tax_Notice_Numeration__c, Status__c
			FROM Auto_Solve_Package__c
			WHERE AutoSolvePackageStatus__c = 'Active' AND RecordTypeId = :idAutoSolveBatchRT
		];

		for (Auto_Solve_Package__c objPkg : list_AutoSolvePkg) {
			System.assertEquals('SUI', objPkg.Tax_Notice_Type__c, 'Auto Solve Package Notice type is empty');
			System.assertEquals('IA126', objPkg.Tax_Notice_Form_Number__c, 'Auto Solve Package Form Number is empty');
			System.assertEquals('1st', objPkg.Tax_Notice_Numeration__c, 'Auto Solve Package Numeration is empty');
			System.assertEquals('Ready for Research', objPkg.Status__c, 'Auto Solve Package Status is empty');
		}
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the process case related with the Auto Solve Package - Positive.
	 * 				  (Here we try to process a case with Physical Mail == true for the packages with Gusto Adhrresee == true)
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testCaseProcessPositive() {
		Test.startTest();
		TaxNoticePackageBatch objTaxNoticePackageBatch = new TaxNoticePackageBatch();
		Database.executebatch(objTaxNoticePackageBatch);
		Test.stopTest();

		Case objCase = [
			SELECT
				Id,
				Customer_Journey__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Auto_Response_Email_Content__c,
				Tax_Notice_Amount_Total__c,
				Tax_Notice_Date__c,
				Tax_Notice_Numeration__c,
				Automation_Status__c,
				Automation_Message__c
			FROM Case
			WHERE Subject = 'Auto Solve Test Case 2'
			LIMIT 1
		];

		System.assertEquals('Hello World', objCase.Auto_Response_Email_Content__c, 'Case Auto Response Template Updated to match Package Record');
		System.assertEquals('Support', objCase.Customer_Journey__c, 'Case Customer Journey Updated to Support');
		System.assertEquals('Client', objCase.Root_Cause__c, 'Case Root Cause Updated to Client');
		System.assertEquals('Unactionable', objCase.Sub_Root_Cause__c, 'Case Sub Root Cause Updated to Unactionable');
		System.assertEquals('1st', objCase.Tax_Notice_Numeration__c, 'Case Tax_Notice_Numeration__c is empty');
		System.assertEquals(0, objCase.Tax_Notice_Amount_Total__c, 'Case Tax Notice Amount - Total is not 0');
		System.assertEquals(System.today(), objCase.Tax_Notice_Date__c, 'Case Tax Notice Date is not match');
		System.assertEquals('Started', objCase.Automation_Status__c, 'Case Automation_Status__c updated to Started');
		System.assertEquals('Auto-Solve Batch', objCase.Automation_Message__c, 'Case Automation_Message__c updated to Auto-Solve Batch');
	}

	/**
	 * @author        Pawan Kumar
	 * @description   This method is used to test the process case related with the Auto Solve Package - Negative.
	 * 				  (Here we try to process a case with Physical Mail == true for the packages with Gusto Adhrresee == false)
	 * @param         NA
	 * @return 		  NA
	 */
	@isTest
	static void testCaseProcessNegative() {
		Test.startTest();
		List<Auto_Solve_Package__c> list_AutoSolvePackages = [SELECT Id, Gusto_Is_Addressee_Of_Record__c FROM Auto_Solve_Package__c WHERE Gusto_Is_Addressee_Of_Record__c = TRUE];
		for (Auto_Solve_Package__c objAutoSolve : list_AutoSolvePackages) {
			objAutoSolve.Gusto_Is_Addressee_Of_Record__c = false;
			objAutoSolve.Notice_Period__c = 'Q2 2021';
		}
		update list_AutoSolvePackages;
		TaxNoticePackageBatch objTaxNoticePackageBatch = new TaxNoticePackageBatch();
		Database.executebatch(objTaxNoticePackageBatch);
		Test.stopTest();

		Case objCase = [
			SELECT
				Id,
				Customer_Journey__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Auto_Response_Email_Content__c,
				Tax_Notice_Amount_Total__c,
				Tax_Notice_Date__c,
				Tax_Notice_Numeration__c,
				Automation_Status__c,
				Automation_Message__c
			FROM Case
			WHERE Subject = 'Auto Solve Test Case 2'
			LIMIT 1
		];

		System.assertNotEquals('Hello World', objCase.Auto_Response_Email_Content__c, 'Case Auto Response Template Updated to match Package Record');
		System.assertNotEquals('Support', objCase.Customer_Journey__c, 'Case Customer Journey Updated to Support');
		System.assertNotEquals('Client', objCase.Root_Cause__c, 'Case Root Cause Updated to Client');
		System.assertNotEquals('Unactionable', objCase.Sub_Root_Cause__c, 'Case Sub Root Cause Updated to Unactionable');
		System.assertNotEquals('Started', objCase.Automation_Status__c, 'Case Automation_Status__c updated to Started');
		System.assertNotEquals('Auto-Solve Batch', objCase.Automation_Message__c, 'Case Automation_Message__c updated to Auto-Solve Batch');
	}
}