/**
 * @author      Ankit Rajput
 * @description Confirm that failed automation cases are updated 
 * Date: 20/12/2024
 **/

@isTest
public class BatchProcessFailedAutoSolvePkgTest {
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
				.setActive(true)
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
				.setActive(true)
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
				.setActive(true)
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
        
        list_Case[0].Automation_Status__c = 'Failed';
        list_Case[0].Automation_Message__c = 'Auto-Solve Batch';
        list_Case[0].Mass_Email_Step__c = 'Test Auto Package 2';
        update list_Case[0];
        

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
		BatchProcessFailedAutoSolvePkgCases objBatchJob = new BatchProcessFailedAutoSolvePkgCases();
		Database.executeBatch(objBatchJob);
		
		Test.stopTest();

		Case[] list_Case = [
			SELECT
				Id,
            	Status,
				Customer_Journey__c,
				Root_Cause__c,
				Sub_Root_Cause__c,
				Auto_Response_Email_Content__c,
				Tax_Notice_Amount_Total__c,
				Tax_Notice_Date__c,
				Tax_Notice_Numeration__c,
				Automation_Status__c,
				Automation_Message__c,
            	Mass_Email_Step__c
			FROM Case
			WHERE Subject = 'Auto Solve Test Case 1'
		];
        System.assertEquals('Started', list_Case[0].Automation_Status__c, 'Case Automation_Status__c updated to Started');
	}
}