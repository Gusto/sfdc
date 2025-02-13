/**
 * @name         TaxResNoticeIndexDetailsCtrlTest
 * @author       Pravesh Rana
 * @date         May 30 2022
 * @description  Test class for TaxResNoticeIndexDetailsController class.
 **/
@isTest
public with sharing class TaxResNoticeIndexDetailsCtrlTest {
	static final Id TAX_NOTICE_INDEX_RECTYPE_MANUAL = Cache.getRecordTypeId('Tax_Notice_Index__c', 'Manual Indexing');
	static final String CASE_STATUS_READYFORDATACAPTURE = 'Ready for Data Capture';
	static final String AUTOMATION_STATUS_COMPLETED = 'Completed';
	static final String CASE_STATUS_CLOSED = 'Closed';
	static final String VALID_FORM_NUMBERS = 'UC216C; B1496A; UC603; WR8244; DE2088; UITR7; UC54A; UC832A; UC632; RT20; DOL626; TAX011; UI5B; 34913; 65536; KCNS404; UI29; LWCT105AF; METAX13; DLLRDUI61; UIA17771; 7554869; EXER8B; MODES527; UI273; UI128A; NUCS4291; IA97; NCUI104; JTA43L; JFS66208; OES48; 238; US657; TX1016; SUITS601; DOLUID45A; LB0482; C22; FORM45; C119; VECFC29; EMS174; WVUCMR7; UCT100BE; WYOD36;';

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Setup method to create test data
	 **/
	@TestSetup
	static void handleTestData() {
		AccountTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;
		List<Agency_Information__c> list_AgencyInformations = TestDataFactory.CreateAgencyInformation();

		Account objAccount = TestDataFactory.CompanyAccount();
		objAccount.Tier__c = null;
		objAccount.AM_Tier__c = null;
		update objAccount;

		Contact objContact = TestDataFactory.createTestContact(objAccount.Id);

		List<Case> list_cases = new List<Case>();

		User objAdminUser = new TestDataFactory.UserBuilder()
			.setAlias('partam')
			.setEmail('partneram@testorg.com')
			.setEmailEncoding('UTF-8')
			.setFirstName('Test')
			.setLastName('User')
			.setLanguageLocaleKey('en_US')
			.setLocaleSidKey('en_US')
			.setProfileId(UserInfo.getProfileId())
			.setTimeZoneSidKey('America/Los_Angeles')
			.setUserName('partneram@testorg.com')
			.setExemptfromValidationRules(true)
			.build();
		insert objAdminUser;

		Case objCasePILateDepTest = new TestDataFactory.CaseBuilder()
			.setSubject('P&I Late Deposit/Amendment Test')
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.build();
		list_cases.add(objCasePILateDepTest);

		Case objCaseMergeTest = new TestDataFactory.CaseBuilder()
			.setSubject('Test Merge')
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.build();
		list_cases.add(objCaseMergeTest);

		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.build();
		list_cases.add(objCase4);

		Case objCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Data Capture Case')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.build();
		list_cases.add(objCase);

		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[1].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setNoticeType('Credit listed or refund check')
			.build();
		list_cases.add(objCase2);

		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Res')
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test Auto Closed Case')
			.setDescription('Tax Res')
			.setType('Tax Res')
			.setEmailStatus(CaseUtils.EMAILSTATUS_OPEN)
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setMassEmailStep('SUI Rate Auto-Solve fired')
			.build();
		objCase1.Notice_Period__c = 'Q2 2023';
		objCase1.Tax_Notice_Form_Number__c = '365';
		objCase1.Tax_Notice_Date__c = System.Today();
		objCase1.Tax_Notice_Type__c = '940';
		objCase1.Penalty_Amount__c = 45;
		objCase1.Tax_Notice_Amount_Total__c = 56;
		objCase1.Assigned_Client_Tax_ID__c = '546ASD';
		list_cases.add(objCase1);

		Case objCaseParent = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test Parent')
			.setDescription(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setAgencyInformation(list_AgencyInformations[1].Id)
			.setStatus(CaseUtils.CASE_STATUS_READY_FOR_RESEARCH)
			.setNoticePeriod('Q1 2022')
			.setTaxNoticeDate(System.today().addDays(-25))
			.setTaxNoticeAmountTotal(50)
			.setTaxNoticeType('940')
			.build();
		list_cases.add(objCaseParent);
		
		Case objCasePreAnswered = new TestDataFactory.CaseBuilder()
			.setRecordTypeId(CaseUtils.TYPE_TAX_RES)
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setSubject('Test Previously Answered')
			.setDescription(CaseUtils.TYPE_TAX_RES)
			.setType(CaseUtils.TYPE_TAX_RES)
			.setAgencyInformation(list_AgencyInformations[1].Id)
			.setStatus(CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS)
			.setTaxNoticeDate(System.today().addDays(-5))
			.setTaxNoticeAmountTotal(55)
			.setNoticePeriod('Q1 2022')
			.setTaxNoticeType('940')
			.build();
		objCasePreAnswered.Multi_YR_QTR_Indicator__c = 'N';
		list_cases.add(objCasePreAnswered);

		insert list_cases;

		String strCloseCaseTemplate = 'Thanks for reaching out to our Tax Resolution team! We have reviewed your company’s notice and found that this was previously submitted in [CASE_NUMBER], which was previously completed and closed on [DATE_TIME_SOLVED].';
		String strInProgressCaseTemplate = 'Thanks for reaching out to our Tax Resolution team! We have reviewed your company’s notice and found that this was previously submitted in [CASE_NUMBER].';
		List<Auto_Solve_Package__c> list_AutoSolvePackages = new List<Auto_Solve_Package__c>();
		Auto_Solve_Package__c objSolveCloseCase = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('Duplicate Notices Closed Case')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate(strCloseCaseTemplate)
			.setCustomerJourney('Client Unresponsive')
			.setRootCause('Client')
			.setSubRootCause('Duplicate Notice')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('Duplicate Notice Auto-Solve fired')
			.setSUIRateFormNumbers(VALID_FORM_NUMBERS)
			.setAutomationStatus('Completed')
			.setAutomationMessage('')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objSolveCloseCase);

		Auto_Solve_Package__c objSolveInProgCase = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('Duplicate Notices InProgress Case')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate(strInProgressCaseTemplate)
			.setCustomerJourney('Support')
			.setRootCause('Client')
			.setSubRootCause('Duplicate Notice')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('Duplicate Notice Auto-Solve fired')
			.setSUIRateFormNumbers(VALID_FORM_NUMBERS)
			.setAutomationStatus('Completed')
			.setAutomationMessage('')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objSolveInProgCase);

		Auto_Solve_Package__c objSolve = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('No Notice Attached')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate('Email Body')
			.setCustomerJourney('Client Unresponsive')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('No Notice Attached Auto-Solve fired')
			.setSUIRateFormNumbers(VALID_FORM_NUMBERS)
			.setAutomationStatus('Completed')
			.setAutomationMessage('no notice attached auto-solve fired')
			.setActive(true)
			.build();

		list_AutoSolvePackages.add(objSolve);

		Auto_Solve_Package__c objSolvePreAnsProgress = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('Previously Answered InProgress Case')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate('This is a subsequent tax notice sent to you by [AGENCY]. This issue is being actively researched and worked on in [CASE_NUMBER], so our team will be responding in [CASE_NUMBER].')
			.setCustomerJourney('Client Unresponsive')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('Previously Answered Auto-Solve Fired')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objSolvePreAnsProgress);

		Auto_Solve_Package__c objSolvePreAnsClosed = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('Previously Answered Closed Case')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate('The agency is notifying your company of important tax information for [YR_QTR] [AGENCY] Taxes. I was able to confirm that a previous specialist has already resolved this matter on [DATE_TIME_SOLVED] under [CASE_NUMBER].')
			.setCustomerJourney('Client Unresponsive')
			.setRootCause('Client')
			.setSubRootCause('Did Not Follow Prior Advice')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('Previously Answered Auto-Solve Fired Closed/Solved')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objSolvePreAnsClosed);

		Auto_Solve_Package__c objBelowTolerance = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('Below Tolerance Case')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate('Thank you for reaching out to Gusto regarding this Internal Revenue Service (IRS) notice for [COMPANY_NAME].')
			.setCustomerJourney('Support')
			.setRootCause('TaxRes')
			.setSubRootCause('Liability Comms')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('Below Tolerance Auto-Solve fired')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objBelowTolerance);

		Auto_Solve_Package__c objPILateDeposit = new TestDataFactory.AutoSolvePackageBuilder()
			.setName('P&I Late Deposit/Amendment Notice')
			.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
			.setEmailTemplate('Thank you for reaching out to Gusto regarding this Internal Revenue Service (IRS) notice for [COMPANY_NAME].')
			.setCustomerJourney('Payroll Processing')
			.setRootCause('Client')
			.setSubRootCause('Backdated/Same Day Payroll')
			.setFieldSetUsed('No_Notice_Case_Updates')
			.setMassEmailStep('P&I Late Deposit/Amendment Auto-Solve Fired')
			.setActive(true)
			.build();
		list_AutoSolvePackages.add(objPILateDeposit);

		insert list_AutoSolvePackages;

		Id idTNDCRecType = Schema.SObjectType.Tax_Notice_Index__c.getRecordTypeInfosByName().get('Manual Indexing').getRecordTypeId();

		List<Tax_Notice_Index__c> list_TaxNoticeIndexes = new List<Tax_Notice_Index__c>();

		Tax_Notice_Index__c objNoticeIndex = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(objCase1.Id)
			.setTaxNoticeFormNumber('365')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(45)
			.setTaxNoticeAmountTotal(56)
			.setAgencyAssigned('546ASD')
			.setSuiRateEffectiveDate(System.Today())
			.setYearQuarter('Q2 2023')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex);

		Tax_Notice_Index__c objNoticeIndex1 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(objCase.Id)
			.setTaxNoticeFormNumber('365')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[0].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(45)
			.setTaxNoticeAmountTotal(56)
			.setAgencyAssigned('546ASD')
			.setSuiRateEffectiveDate(System.Today())
			.setYearQuarter('Q2 2023')
			.build();

		list_TaxNoticeIndexes.add(objNoticeIndex1);

		Tax_Notice_Index__c objNoticeIndex2 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(objCaseParent.Id)
			.setTaxNoticeFormNumber('365')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[1].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(459)
			.setTaxNoticeAmountTotal(54)
			.setAgencyAssigned('546ASD')
			.setYearQuarter('Q1 2022')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex2);

		Tax_Notice_Index__c objNoticeIndex3 = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(idTNDCRecType)
			.setCaseId(objCasePreAnswered.Id)
			.setTaxNoticeFormNumber('365A')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('940')
			.setAgencyInformation(list_AgencyInformations[1].Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(450)
			.setTaxNoticeAmountTotal(55)
			.setAgencyAssigned('546ASD')
			.setYearQuarter('Q1 2022')
			.setMultiYr('N')
			.build();
		list_TaxNoticeIndexes.add(objNoticeIndex3);

		insert list_TaxNoticeIndexes;
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Postive case
	 **/
	@isTest
	static void getCaseDetailsTestPositiveMethod() {
		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];

		Case objCase = TaxResNoticeIndexDetailsController.getCaseDetails(list_Cases[0].Id);
		//should get the case bcoz case id is correct.
		System.assert(objCase != null, 'case is null');
		System.assert(objCase.Id != null, 'case Id is null');

		objCase = TaxResNoticeIndexDetailsController.getCaseDetails(null);
		//if parameter is null
		System.assert(objCase == null, 'return value is not null');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case field-set's fields api names : Postive case
	 **/
	@isTest
	static void getRequiredFieldsTestPositiveMethod() {
		Test.startTest();
		String strRequiredFieldNames = TaxResNoticeIndexDetailsController.getRequiredFields();
		System.assert(String.isNotBlank(strRequiredFieldNames), 'return a blank string');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive Account : Postive case
	 **/
	@isTest
	static void getAccountDetailsTestPositiveMethod() {
		Test.startTest();
		List<Account> list_Accounts = [SELECT Id FROM Account LIMIT 1];
		Account objAccount = TaxResNoticeIndexDetailsController.getAccountDetails(list_Accounts.get(0).Id);
		System.assert(objAccount != null, 'Account is null');
		System.assert(objAccount.Id != null, 'Account Id is null');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Retrive case : Postive case
	 **/
	@isTest
	static void completeNoticeIndexRecordTestPositiveMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Test.startTest();
			CaseTriggerHelper.skipTrigger = true;
			List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];
			Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(Case__c = list_Cases[0].Id, RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL);
			insert objNotice;

			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			system.assertEquals(list_CaseRecords.size(), 1, 'Failed');

			list_Cases = [SELECT Id, Status FROM Case WHERE Id = :list_CaseRecords[0].Id];
			System.assert(list_Cases != null, 'case with matching case Id is not present');
			System.assert(list_Cases[0].Status != CASE_STATUS_READYFORDATACAPTURE, 'case status is not ready for capture');

			list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(null);
			system.assertEquals(list_CaseRecords, null, 'Failed');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : Duplicate Notice close Case
	 **/
	@isTest
	static void duplicateNoticeFPClosedCaseTestMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Case objIndexerCase = [SELECT Id, Status, Automation_Status__c, Tax_Res_Auto_Response_Sent__c, Mass_Email_Step__c FROM Case WHERE Subject = 'Data Capture Case' LIMIT 1];
			Case objExistingCase = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Subject = 'Test Auto Closed Case' LIMIT 1];
			//Duplicate TNDC Auto closed Case exist
			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objIndexerCase.Id });
			Test.stopTest();
			Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c FROM Case WHERE Id = :objIndexerCase.Id];
			System.assertEquals('Duplicate Notice F/P Check', objCaseDetail.Mass_Email_Step__c, 'mass email step is not Duplicate Notice F/P Check');
		}
	}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : Duplicate Notice close Case
	 **/
	@isTest
	static void duplicateNoticeClosedCaseTestMethod2() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Case objIndexerCase = [SELECT Id, Status, Automation_Status__c, Tax_Res_Auto_Response_Sent__c, Mass_Email_Step__c FROM Case WHERE Subject = 'Data Capture Case' LIMIT 1];
			Case objExistingCase = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Subject = 'Test Auto Closed Case' LIMIT 1];
			objExistingCase.Mass_Email_Step__c = '';
			update objExistingCase;

			objIndexerCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
			objIndexerCase.Mass_Email_Step__c = '';
			objIndexerCase.Automation_Status__c = '';
			objIndexerCase.Tax_Res_Auto_Response_Sent__c = false;
			update objIndexerCase;

			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objIndexerCase.Id });
			Test.stopTest();

			String strSolvedDate = Datetime.now().format('MMMMM dd, yyyy');	
			Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :objIndexerCase.Id];
			System.assertEquals('Duplicate Notice Auto-Solve fired', objCaseDetail.Mass_Email_Step__c, 'Mass Email step is not Duplicate Notice Auto-Solve fired');
			System.assert(objCaseDetail.Auto_Response_Email_Content__c.contains(strSolvedDate), 'Solved Date/Time is not found in the email template');
		}
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Duplicate Notice close Case For Tax Notice Numeration = FINAL
	 **/
	@isTest
	static void duplicateNoticeClosedCaseTestMethod3() {
			Case objIndexerCase = [SELECT Id, Status, Automation_Status__c, Tax_Res_Auto_Response_Sent__c, Mass_Email_Step__c FROM Case WHERE Subject = 'Data Capture Case' LIMIT 1];
			Case objExistingCase = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Subject = 'Test Auto Closed Case' LIMIT 1];
			objExistingCase.Mass_Email_Step__c = '';
			update objExistingCase;

			objIndexerCase.Status = CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS;
			objIndexerCase.Mass_Email_Step__c = '';
			objIndexerCase.Automation_Status__c = '';
			objIndexerCase.Tax_Res_Auto_Response_Sent__c = false;
			update objIndexerCase;

			Tax_Notice_Index__c objTaxNotice = [SELECT Id FROM Tax_Notice_Index__c WHERE Case__c = :objIndexerCase.Id];
			objTaxNotice.Tax_Notice_Numeration__c = CaseUtils.TAX_NOTICE_NUMERATION_FINAL;
			update objTaxNotice;

			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objIndexerCase.Id });
			Test.stopTest();

			Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :objIndexerCase.Id];
			System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCaseDetail.Status, 'Status is not Data Capture Complete');
		}

	/**
	 * @Author      : Pawan Kumar
	 * @Description : Duplicate Notice In Progress
	 **/
	@isTest
	static void duplicateInProgressCaseTestMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Case objIndexerCase = [SELECT Id, Status, Automation_Status__c, Tax_Res_Auto_Response_Sent__c, Mass_Email_Step__c FROM Case WHERE Subject = 'Data Capture Case' LIMIT 1];
			Case objExistingCase = [SELECT Id, Status, Mass_Email_Step__c, Automation_Status__c FROM Case WHERE Subject = 'Test Auto Closed Case' LIMIT 1];
			Test.startTest();

			objExistingCase.Status = CaseUtils.CASE_STATUS_READY_FOR_RESEARCH;
			objExistingCase.Mass_Email_Step__c = '';
			update objExistingCase;

			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objIndexerCase.Id });
			Case objCaseDetail1 = [SELECT Id, Status, Mass_Email_Step__c, Automation_Status__c, Tax_Res_Auto_Response_Sent__c FROM Case WHERE Id = :objIndexerCase.Id];
			System.assertEquals('Duplicate Notice Auto-Solve fired', objCaseDetail1.Mass_Email_Step__c, 'mass email step is not Duplicate Notice Auto-Solve fired');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : No Notice Attached
	 **/
	@isTest
	static void noNoticeAttachedTestMethod() {
		Auto_Solve_Package__c objSolve = [SELECT Id FROM Auto_Solve_Package__c WHERE Name = 'No Notice Attached' LIMIT 1];

		Test.startTest();
		List<Case> list_Cases = [SELECT Id FROM Case WHERE ContactId != NULL LIMIT 1];
		Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(Case__c = list_Cases[0].Id, No_Notice_Attached__c = true, RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL, Manually_Indexed__c = true);
		insert objNotice;

		List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
		system.assertEquals(list_CaseRecords.size(), 1, 'Failed');

		list_Cases = [SELECT Id, Status, Auto_Response_Email_Content__c, Automation_Message__c, Automation_Status__c FROM Case WHERE Id = :list_CaseRecords[0].Id];
		System.assert(list_Cases != null, 'Case with matching Id should exist');
		System.assert(list_Cases[0].Auto_Response_Email_Content__c != null, 'Auto_Response_Email_Content field value can not be null');
		System.assert(list_Cases[0].Automation_Status__c == AUTOMATION_STATUS_COMPLETED, 'Automation_Status field values is not Completed');

		list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(null);
		System.assertEquals(list_CaseRecords, null, 'Failed');
		Test.stopTest();
	}

	/**
	 * @Author      : Pravesh Rana
	 * @Description : Sui Rate auto close
	 **/
	@isTest
	static void suiRateTestMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Date dtSUIDate = date.newInstance(2023, 1, 1);

			Auto_Solve_Package__c objSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('SUI Rate Auto Solve')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Email Body')
				.setCustomerJourney('Accounts Update')
				.setRootCause('Informational')
				.setSubRootCause('Rate Notice')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('SUI Rate Auto-Solve fired')
				.setSUIRateFormNumbers(VALID_FORM_NUMBERS)
				.setAutomationStatus('Completed')
				.setAutomationMessage('SUI Rate auto-solve fired')
				.setActive(true)
				.build();
			insert objSolve;

			List<Agency_Information__c> list_AgenciesInfo = [SELECT Id FROM Agency_Information__c];

			Test.startTest();

			List<Case> list_Cases = [SELECT Id FROM Case WHERE ContactId != NULL LIMIT 1];
			Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(
				Case__c = list_Cases[0].Id,
				Tax_Notice_Form_Number__c = 'UC216C',
				SUI_Rate_Effective_Date__c = dtSUIDate,
				Yr_Qtr__c = 'Q4 2023',
				Agency_Information__c = list_AgenciesInfo[0].Id,
				Multi_Yr_Qtr_Indicator__c = 'N',
				RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL,
				No_Notice_Attached__c = false,
				Manually_Indexed__c = true
			);
			insert objNotice;

			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			system.assertEquals(list_CaseRecords.size(), 1, 'Failed');
			// Updating fields that Workato recipe would update -
			list_Cases[0].Status = 'Closed';
			list_Cases[0].Customer_Journey__c = 'Account Update';
			list_Cases[0].Is_ZP_Updated_with_SUI_rates__c = true;
			list_Cases[0].Root_Cause__c = 'Informational';
			list_Cases[0].Sub_Root_Cause__c = 'Rate Notice';
			list_Cases[0].Auto_Solve_Error_Message__c = 'SUCCESS';
			update list_Cases;
			list_Cases = [SELECT Id, Status, Auto_Response_Email_Content__c, Automation_Message__c, Automation_Status__c FROM Case WHERE Id = :list_CaseRecords[0].Id];
			System.assert(list_Cases != null, 'Case with matching Id should exist');
			System.assert(list_Cases[0].Auto_Response_Email_Content__c != null, 'Auto_Response_Email_Content field value can not be null');
			System.assert(list_Cases[0].Automation_Status__c == AUTOMATION_STATUS_COMPLETED, 'Automation_Status field values is not Completed');
			System.assert(list_Cases[0].Status == CASE_STATUS_CLOSED, 'Case status should be closed');

			list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(null);
			System.assertEquals(list_CaseRecords, null, 'Failed');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Sui Rate auto close for Tax Notice Numeration = FINAL
	 **/
	@isTest
	static void suiRateTestMethod1() {
			Date dtSUIDate = date.newInstance(2023, 1, 1);

			Auto_Solve_Package__c objSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('SUI Rate Auto Solve')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Email Body')
				.setCustomerJourney('Accounts Update')
				.setRootCause('Informational')
				.setSubRootCause('Rate Notice')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('SUI Rate Auto-Solve fired')
				.setSUIRateFormNumbers(VALID_FORM_NUMBERS)
				.setAutomationStatus('Completed')
				.setAutomationMessage('SUI Rate auto-solve fired')
				.setActive(true)
				.build();
			insert objSolve;

			List<Agency_Information__c> list_AgenciesInfo = [SELECT Id FROM Agency_Information__c];

			List<Case> list_Cases = [SELECT Id FROM Case WHERE ContactId != NULL LIMIT 1];
			Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[0].Id)
			.setTaxNoticeFormNumber('UC216C')
			.setSuiRateEffectiveDate(dtSUIDate)
			.setYearQuarter('Q4 2023')
			.setAgencyInformation(list_AgenciesInfo[0].Id)
			.setMultiYr('N')
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setTaxNumeration('FINAL')
			.build();
			insert objNotice;

			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			Test.stopTest();

			Case objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c, Automation_Status__c, Tax_Res_Auto_Response_Sent__c FROM Case WHERE Id = :list_Cases[0].Id];
			System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCaseDetail.Status, 'Status is not Data Capture Complete');
		}

	/***
	 * @Author      : Pravesh Rana
	 * @Description : No Notice Attached
	 **/
	@isTest
	static void dataRetrivelTestMethod() {
		String VALID_FORM_NUMBERS = 'ABCD1';
		Agency_Information__c objAgency = new Agency_Information__c();
		objAgency.Name = 'Agency1';
		objAgency.SUI_Rate_Form_Numbers__c = VALID_FORM_NUMBERS;
		insert objAgency;

		Tax_Rate__c objRate = new Tax_Rate__c();
		objRate.Agency_Information__c = objAgency.Id;
		objRate.ZP_Tax_Rate_Name__c = 'tax_code1';
		objRate.Name = 'tax_code1';
		insert objRate;

		List<Case> list_Cases = [SELECT Id FROM Case WHERE ContactId != NULL LIMIT 1];
		Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(
			Case__c = list_Cases[0].Id,
			Tax_Notice_Form_Number__c = 'UC216C',
			Yr_Qtr__c = 'Q4 2020',
			SUI_Rate_Effective_Date__c = System.today(),
			RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL
		);
		insert objNotice;

		Tax_Rate_Values__c objValue = new Tax_Rate_Values__c(Rate_Decimal__c = .03, Tax_Rate_Type__c = objRate.Id, Tax_Notice_Index__c = objNotice.Id);
		insert objValue;

		Test.startTest();
		List<String> list_TaxRateValues = new List<String>{ objRate.Id + '=>.03' };
		TaxResNoticeIndexDetailsController.syncTaxRateValuesForTNDC(objNotice.Id, list_TaxRateValues);
		TaxResNoticeIndexDetailsController.getTaxRatesValuesTNDC(objNotice.Id, objAgency.Id);
		List<Tax_Rate__c> list_Rates = TaxResNoticeIndexDetailsController.getTaxRatesForAgency(objAgency.Id, objNotice.Id);
		String strFormNumbers = TaxResNoticeIndexDetailsController.getSuiRateFormNumbers(objAgency.Id);

		System.assert(list_Rates.size() > 0);
		System.assert(strFormNumbers == VALID_FORM_NUMBERS);
		Test.stopTest();
	}

	/**
	 * @Author      : Sanjay Paryani
	 * @Description : Validate alphanumeric values in tax notice form number
	 **/
	@isTest
	static void alphaNumericFormNumberValidationTest() {
		Test.startTest();
		try {
			List<Case> list_Cases = [SELECT Id FROM Case LIMIT 1];
			Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c();
			objNotice.Case__c = list_Cases[0].Id;
			objNotice.Tax_Notice_Form_Number__c = 'AP&%$';
			objNotice.RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL;
			insert objNotice;
		} catch (Exception ex) {
			System.assertEquals('Tax Form Number can have only alphanumeric values', ex.getMessage());
		}

		Test.stopTest();
	}

	/**
	 * @Author      : AKS
	 * @Description : Retrive case : Postive case
	 **/
	@isTest
	static void completeNoticeIndexRecordBeforeGustoServiceMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Test.startTest();
			AccountTriggerHelper.skipTrigger = true;
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;

			List<Date> list_Dates1 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('Q2 2022', true);
			List<Date> list_Dates3 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('2022 Monthly', true);

			//Create Auto Solve for before gusto service
			Auto_Solve_Package__c objAutoSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('Before Gusto Service')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Test Email template')
				.setCustomerJourney('Prior to Gusto')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('Prior to Gusto Auto-Solve fired')
				.setActive(true)
				.build();
			insert objAutoSolve;

			Account objAccount = [SELECT Id, Joined_Date_Panda__c FROM Account LIMIT 1];
			objAccount.Joined_Date_Panda__c = date.today().addYears(1);
			update objAccount;

			List<Case> list_Cases = [SELECT Id, Notice_Period__c FROM Case WHERE AccountId = :objAccount.Id];
			list_Cases[0].Notice_Period__c = 'Q1 2022';
			update list_Cases;

			Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(Case__c = list_Cases[0].Id, Yr_Qtr__c = 'Q1 2022', Client_Name__c = objAccount.Id, RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL);
			insert objNotice;

			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			System.assertEquals(list_CaseRecords.size(), 1, 'Failed');

			list_Cases = [SELECT Id, Status, Automation_Status__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :list_CaseRecords[0].Id];
			System.assert(list_Cases != null, 'Case with matching Id should exist');
			System.assert(list_Cases[0].Status == CASE_STATUS_CLOSED, 'Case status should be closed');
			System.assert(list_Cases[0].Automation_Status__c == 'Completed', 'Automation_Status field values is not Completed');
			System.assert(list_Cases[0].Auto_Response_Email_Content__c == 'Test Email template', 'Auto_Response_Email_Content field value is not equals to Test Email template');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : Before Gusto Autosolve for Tax Numeration = FINAL
	 **/
	@isTest
	static void testBeforeGusto2() {
			AccountTriggerHelper.skipTrigger = true;
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;

			List<Date> list_Dates1 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('Q2 2022', true);
			List<Date> list_Dates3 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('2022 Monthly', true);

			//Create Auto Solve for before gusto service
			Auto_Solve_Package__c objAutoSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('Before Gusto Service')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Test Email template')
				.setCustomerJourney('Prior to Gusto')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('Prior to Gusto Auto-Solve fired')
				.setActive(true)
				.build();
			insert objAutoSolve;

			Account objAccount = [SELECT Id, Joined_Date_Panda__c FROM Account LIMIT 1];
			objAccount.Joined_Date_Panda__c = date.today().addYears(1);
			update objAccount;

			List<Case> list_Cases = [SELECT Id, Notice_Period__c FROM Case WHERE AccountId = :objAccount.Id];
			list_Cases[0].Notice_Period__c = 'Q1 2022';
			update list_Cases;

			Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[0].Id)
			.setYearQuarter('Q1 2022')
			.setClientName(objAccount.Id)
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setTaxNumeration('FINAL')
			.build();
			insert objNotice;

			Test.startTest();
			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			System.assertEquals(list_CaseRecords.size(), 1, 'Failed');

			list_Cases = [SELECT Id, Status, Automation_Status__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :list_CaseRecords[0].Id];
			System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, list_Cases[0].Status, 'Status is not updated to Data Capture Complete');
			Test.stopTest();
	}

	/**
	 * @Author      : AKS
	 * @Description : After Gusto : Postive case
	 **/
	@isTest
	static void completeNoticeIndexRecordAfterGustoServiceMethod() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		System.runAs(objUser) {
			Test.startTest();
			AccountTriggerHelper.skipTrigger = true;
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;
			ZPCompanySuspensionTriggerHelper.skipTrigger = true;

			List<Date> list_Dates1 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('Q3 2022', true);

			ZP_Company_Suspension__c objSuspension = new TestDataFactory.ZPCompanySuspensionBuilder()
				.setId('22233344553')
				.setCompanyId('1234567890')
				.setReason('Leaving for other vendor')
				.setUnSuspendedAt(Date.newInstance(3000, 1, 1))
				.setProcessingState('Queued')
				.setLastActiveDate(Date.newInstance(2022, 6, 15))
				.build();
			insert objSuspension;

			//Create Auto Solve for after  gusto service
			Auto_Solve_Package__c objAutoSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('After Gusto Service')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Test Email template')
				.setCustomerJourney('Period After Gusto')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('After Gusto Auto-Solve fired')
				.setActive(true)
				.build();
			insert objAutoSolve;

			Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
			objAccount.ZP_Company_ID__c = '1234567890';
			objAccount.Joined_Date_Panda__c = null;
			update objAccount;

			List<Case> list_Cases = [SELECT Id, Notice_Period__c FROM Case WHERE AccountId = :objAccount.Id];
			list_Cases[0].Notice_Period__c = 'Q3 2022';
			update list_Cases;

			Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(
				Case__c = list_Cases[0].Id,
				Yr_Qtr__c = 'Q3 2022',
				Client_Name__c = objAccount.Id,
				Multi_Yr_Qtr_Indicator__c = 'N',
				RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL
			);
			insert objNotice;

			List<Case> list_CaseRecords = TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });
			System.assertEquals(list_CaseRecords.size(), 1, 'Failed');

			list_Cases = [SELECT Id, Status, Automation_Status__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :list_CaseRecords[0].Id];
			System.assert(list_Cases != null, 'Case with matching Id should exist');
			System.assert(list_Cases[0].Status == CASE_STATUS_CLOSED, 'Case status should be closed');
			System.assert(list_Cases[0].Automation_Status__c == 'Completed', 'Automation_Status field values is not Completed');
			System.assert(list_Cases[0].Auto_Response_Email_Content__c == 'Test Email template', 'Auto_Response_Email_Content field value is not equals to Test Email template');
			Test.stopTest();
		}
	}

	/**
	 * @Author      : Shyam Nasare
	 * @Description : After Gusto Autosolve for Tax Numeration = FINAL
	 **/
	@isTest
	static void testAfterGusto2() {
			AccountTriggerHelper.skipTrigger = true;
			ContactTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;
			ZPCompanySuspensionTriggerHelper.skipTrigger = true;

			List<Date> list_Dates1 = TaxResNoticeIndexDetailsController.getQuarterMonthLastDate('Q3 2022', true);

			ZP_Company_Suspension__c objSuspension = new TestDataFactory.ZPCompanySuspensionBuilder()
				.setId('22233344553')
				.setCompanyId('1234567890')
				.setReason('Leaving for other vendor')
				.setUnSuspendedAt(Date.newInstance(3000, 1, 1))
				.setProcessingState('Queued')
				.setLastActiveDate(Date.newInstance(2022, 6, 15))
				.build();
			insert objSuspension;

			//Create Auto Solve for after  gusto service
			Auto_Solve_Package__c objAutoSolve = new TestDataFactory.AutoSolvePackageBuilder()
				.setName('After Gusto Service')
				.setRecordTypeId(Cache.getRecordTypeId('Auto_Solve_Package__c', 'Auto-Solve Relative'))
				.setEmailTemplate('Test Email template')
				.setCustomerJourney('Period After Gusto')
				.setRootCause('Client')
				.setSubRootCause('Unactionable')
				.setFieldSetUsed('No_Notice_Case_Updates')
				.setMassEmailStep('After Gusto Auto-Solve fired')
				.setActive(true)
				.build();
			insert objAutoSolve;

			Account objAccount = [SELECT Id, ZP_Company_ID__c FROM Account LIMIT 1];
			objAccount.ZP_Company_ID__c = '1234567890';
			objAccount.Joined_Date_Panda__c = null;
			update objAccount;

			List<Case> list_Cases = [SELECT Id, Notice_Period__c FROM Case WHERE AccountId = :objAccount.Id];
			list_Cases[0].Notice_Period__c = 'Q3 2022';
			update list_Cases;

			Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setCaseId(list_Cases[0].Id)
			.setYearQuarter('Q3 2022')
			.setClientName(objAccount.Id)
			.setMultiYr('N')
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setTaxNumeration('FINAL')
			.build();
			insert objNotice;

			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ list_Cases[0].Id });

			list_Cases = [SELECT Id, Status, Automation_Status__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :list_Cases[0].Id];
			System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, list_Cases[0].Status, 'Status is not updated to Data Capture Complete');
			Test.stopTest();
		}

	/**
	 * @author       Elavrasan N
	 * @description  Previously Answered In Progress (Feature 1)
	**/
	@isTest
	static void testPreviouslyAnsweredInProgress() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		System.runAs(objUser) {
			Case objCase = [ SELECT Id FROM Case WHERE Multi_YR_QTR_Indicator__c = 'N' AND Subject = 'Test Previously Answered'];
			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objCase.Id });
			Test.stopTest();
			
			Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c, ParentId, Related_Case__c FROM Case WHERE Id = :objCase.Id];
			System.assertEquals(TaxResNoticeIndexDetailsController.PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED, objCaseDetail.Mass_Email_Step__c, 'mass email step is not Previously Answered Auto Solve');
			System.assertEquals(true, objCaseDetail.Related_Case__c != null, 'Parent is not assigned to the Case.');
		}
	}

	/**
	 * @author       Shyam Nasare
	 * @description  Previously Answered In Progress for Tax Numeration = FINAL
	**/
	@isTest
	static void testPreviouslyAnsweredInProgress2() {
		Case objCase = [SELECT Id FROM Case WHERE Multi_YR_QTR_Indicator__c = 'N' AND Subject = 'Test Previously Answered'];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;
		Tax_Notice_Index__c objTaxNotice = [SELECT Id, Tax_Notice_Numeration__c FROM Tax_Notice_Index__c WHERE Case__c = :objCase.Id];
		objTaxNotice.Tax_Notice_Numeration__c = CaseUtils.TAX_NOTICE_NUMERATION_FINAL;
		update objTaxNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objCase.Id });
		Test.stopTest();
			
		Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c, ParentId, Related_Case__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCaseDetail.Status, 'Status is not updated to Data Capture Complete');
	}

	/**
	 * @author       Rushi R
	 * @description  Previously Answered Closed Case
	**/
	@isTest
	static void testPreviouslyAnsweredClosed() {
		User objUser = [SELECT Id, name FROM User WHERE Email = 'partneram@testorg.com'];
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		System.runAs(objUser) {
			Case objCase = [SELECT Id FROM Case WHERE Multi_YR_QTR_Indicator__c = 'N' AND Subject = 'Test Previously Answered' LIMIT 1];
			Case objParentCase = [
				SELECT Id, Status, Customer_Journey__c, Root_Cause__c, Sub_Root_Cause__c, Action_Taken__c, Customer_Actions_Required__c
				FROM Case
				WHERE Subject = 'Test Parent'
				LIMIT 1
			];
			objParentCase.Status = 'Solved';
			objParentCase.Customer_Journey__c = 'Accounts Update';
			objParentCase.Root_Cause__c = 'Client';
			objParentCase.Sub_Root_Cause__c = 'Incorrect Account ID';
			objParentCase.Action_Taken__c = 'No actions taken';
			objParentCase.Customer_Actions_Required__c = 'Update tax setup in gusto';  
			update objParentCase;
            
			Test.startTest();
			TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objCase.Id });
			Test.stopTest();
			
			Case objCaseDetail = [SELECT Id, Status, Automation_Status__c, Mass_Email_Step__c, ParentId, Related_Case__c FROM Case WHERE Id = :objCase.Id];
			System.assertEquals(TaxResNoticeIndexDetailsController.PREVIOUSLY_ANSWERED_AUTO_SOLVE_FIRED_CLOSED, objCaseDetail.Mass_Email_Step__c, 'mass email step is not Previously Answered Auto Solve');
			System.assertEquals(true, objCaseDetail.Related_Case__c != null, 'Parent is not assigned to the Case.');
		}
	}

	/**
	 * @author       Shyam Nasare
	 * @description  No Notice Attached Case Routing for Case Reason - SUI Rate
	**/
	@isTest
	static void testNoNoticeAttachedReRouting() {
		Case_Reason_Classification__c reasonClassification = new Case_Reason_Classification__c(Name='SUI Rate', Type__c='Tax Res');
		insert reasonClassification;

		Agency_Information__c agency_IRS = TestDataFactory.createOneAgencyInforation('Internal Revenue Service');

		List<Case> list_Cases = [SELECT Id, Routing_Case_Reason_Classification__c FROM Case WHERE ContactId != NULL AND Status = :CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS LIMIT 1];
		list_Cases[0].Routing_Case_Reason_Classification__c = reasonClassification.Id;
		list_Cases[0].Agency_Information__c = agency_IRS.Id;
		update list_Cases;

		Tax_Notice_Index__c objNotice = new Tax_Notice_Index__c(
			Case__c = list_Cases[0].Id,
			Tax_Notice_Form_Number__c = '1234',
			RecordTypeId = TAX_NOTICE_INDEX_RECTYPE_MANUAL,
			No_Notice_Attached__c = true
		);
		insert objNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{list_Cases[0].Id});
		Test.stopTest();

		Case objCaseDetail = [SELECT Id, Status FROM Case WHERE Id = :list_Cases[0].Id];
		System.assertEquals(CaseUtils.CASE_STATUS_READY_FOR_DATA_CAPTURE, objCaseDetail.Status, 'Case Status is not Ready for Data Capture');
	}

	/**
	 * @author       Shyam Nasare
	 * @description  Below Tolerance Autosolve Case
	**/
	@IsTest
	static void testBelowToleranceAutosolve() {
		Agency_Information__c agency_IRS = TestDataFactory.createOneAgencyInforation('Internal Revenue Service');
		List<Case> list_Cases = [SELECT Id, Agency_Information__c FROM Case WHERE ContactId != NULL AND Status = :CaseUtils.CASE_STATUS_DATA_CAPTURE_IN_PROGRESS LIMIT 1];
		list_Cases[0].Agency_Information__c = agency_IRS.Id;
		update list_Cases;

		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setCaseId(list_Cases[0].Id)
			.setTaxNoticeFormNumber('12344')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('941')
			.setAgencyInformation(agency_IRS.Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(0)
			.setTaxNoticeAmountTotal(45)
			.setAgencyAssigned('546ASD')
			.setYearQuarter('Q1 2022')
			.setMultiYr('N')
			.setTaxNumeration('1st')
			.build();
		insert objNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{list_Cases[0].Id});
		Test.stopTest();

		Case objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Id = :list_Cases[0].Id];
		System.assertEquals(objCaseDetail.Mass_Email_Step__c, 'Below Tolerance Auto-Solve fired', 'Automation Triggered is not Below Tolerance Auto-Solve fired');
	}

	/**
	 * @author       Shyam Nasare
	 * @description  Form Number (DE6601/DE2176) Merge Automation
	**/
	@isTest
	static void testFormNumberMergingAutomation() {
		Agency_Information__c objAgency_CAEDD = TestDataFactory.createOneAgencyInforation('CA-EDD');
		List<Case> list_Cases = [SELECT Id, Agency_Information__c, Subject FROM Case WHERE ContactId != NULL AND Subject IN ('Test Parent', 'Test Merge')];
		list_Cases[0].Agency_Information__c = objAgency_CAEDD.Id;
		list_Cases[1].Agency_Information__c = objAgency_CAEDD.Id;
		update list_Cases;

		Id idParentCase = list_Cases[0].Subject == 'Test Parent' ? list_Cases[0].Id : list_Cases[1].Id;
		Id idChildCase = list_Cases[0].Subject == 'Test Merge' ? list_Cases[0].Id : list_Cases[1].Id;

		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		Tax_Notice_Index__c objNoticeParent = [SELECT Id, Tax_Notice_Form_Number__c, Agency_Information__c FROM Tax_Notice_Index__c WHERE Case__c = :idParentCase LIMIT 1];
		objNoticeParent.Tax_Notice_Form_Number__c = 'DE6601';
		objNoticeParent.Agency_Information__c = objAgency_CAEDD.Id;
		objNoticeParent.SUI_Rate_Effective_Date__c = null;
		update objNoticeParent;

		Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setCaseId(idChildCase)
			.setTaxNoticeFormNumber('DE6601')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('944')
			.setAgencyInformation(objAgency_CAEDD.Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(1)
			.setTaxNoticeAmountTotal(12)
			.setAgencyAssigned('546ASD')
			.setYearQuarter('Q1 2022')
			.setMultiYr('N')
			.setTaxNumeration('2nd')
			.build();
		insert objNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{idChildCase});
		Test.stopTest();

		Case objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Id = :idChildCase];
		System.assertEquals(CaseUtils.STATUS_CLOSED, objCaseDetail.Status, 'Case Status is not Closed');
		System.assertEquals(objCaseDetail.Mass_Email_Step__c, 'DE6601/DE2176 Merge', 'Automation Triggered is not DE6601/DE2176 Merge');		
	}

	/**
	 * @author       Shyam Nasare
	 * @description  P&I Late Deposit/Amendment Autosolve Approved
	 **/
	@isTest
	static void testPILateDepositAutosolveApprove() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		Agency_Information__c objAgency_IRS = TestDataFactory.createOneAgencyInforation('Internal Revenue Service');
		Case objCase = [SELECT Id, Agency_Information__c, Subject FROM Case WHERE ContactId != NULL AND Subject = 'P&I Late Deposit/Amendment Test' LIMIT 1];
		objCase.Agency_Information__c = objAgency_IRS.Id;
		update objCase;

		Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setCaseId(objCase.Id)
			.setTaxNoticeFormNumber('CP161')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('944')
			.setAgencyInformation(objAgency_IRS.Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(0)
			.setTaxNoticeAmountTotal(60)
			.setAgencyAssigned('546A32SD')
			.setYearQuarter('Q1 2024')
			.setMultiYr('N')
			.setTaxNumeration('2nd')
			.setPenaltyAmount(11)
			.build();
		insert objNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objCase.Id });

		Case objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(TaxResNoticeIndexDetailsController.PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED, objCaseDetail.Mass_Email_Step__c, 'Automation Triggered is not P&I Late Deposit Partial Autosolve');
		System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCaseDetail.Status, 'Case Status is not Data Capture Complete');

		objCaseDetail.Status = CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS;
		update objCaseDetail;

		TaxResChecklistController.updateCaseForPILateDepositAutosolve('confirmAutosolve', objCaseDetail.Id);
		Test.stopTest();

		objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c, Auto_Response_Email_Content__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(TaxResNoticeIndexDetailsController.PI_LATE_DEPOSIT_AUTOSOLVE_FIRED, objCaseDetail.Mass_Email_Step__c, 'Automation Triggered is not P&I Late Deposit Autosolve');
	}

	/**
	 * @author       Shyam Nasare
	 * @description  P&I Late Deposit/Amendment Autosolve Declined
	 **/
	@isTest
	static void testPILateDepositAutosolveDecline() {
		Account objAccount = [SELECT Id FROM Account LIMIT 1];
		objAccount.Joined_Date_Panda__c = null;
		update objAccount;

		Agency_Information__c objAgency_IRS = TestDataFactory.createOneAgencyInforation('Internal Revenue Service');
		Case objCase = [SELECT Id, Agency_Information__c, Subject FROM Case WHERE ContactId != NULL AND Subject = 'P&I Late Deposit/Amendment Test' LIMIT 1];
		objCase.Agency_Information__c = objAgency_IRS.Id;
		update objCase;

		Tax_Notice_Index__c objNotice = new TestDataFactory.TaxNoticeIndexBuilder()
			.setRecordTypeId(TAX_NOTICE_INDEX_RECTYPE_MANUAL)
			.setCaseId(objCase.Id)
			.setTaxNoticeFormNumber('CP161')
			.setTaxNoticeDate(System.Today())
			.setTaxNoticeType('944')
			.setAgencyInformation(objAgency_IRS.Id)
			.setClientName(objAccount.Id)
			.setSegment('Company')
			.setTaxAmount(0)
			.setTaxNoticeAmountTotal(60)
			.setAgencyAssigned('546A32SD')
			.setYearQuarter('Q1 2024')
			.setMultiYr('N')
			.setTaxNumeration('2nd')
			.setPenaltyAmount(11)
			.build();
		insert objNotice;

		Test.startTest();
		TaxResNoticeIndexDetailsController.completeNoticeIndexRecord(new List<Id>{ objCase.Id });

		Case objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(TaxResNoticeIndexDetailsController.PI_LATE_DEPOSIT_PARTIAL_AUTOSOLVE_FIRED, objCaseDetail.Mass_Email_Step__c, 'Automation Triggered is not P&I Late Deposit Partial Autosolve');
		System.assertEquals(CaseUtils.CASE_STATUS_DATA_CAPTURE_COMPLETE, objCaseDetail.Status, 'Case Status is not Data Capture Complete');

		objCaseDetail.Status = CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS;
		update objCaseDetail;

		TaxResChecklistController.updateCaseForPILateDepositAutosolve('declineAutosolve', objCaseDetail.Id);

		objCaseDetail = [SELECT Id, Status, Mass_Email_Step__c FROM Case WHERE Id = :objCase.Id];
		System.assertEquals(CaseUtils.CASE_STATUS_RESEARCH_IN_PROGRESS, objCaseDetail.Status, 'Case Status is not Reasearch in progress');
		System.assert(objCaseDetail.Mass_Email_Step__c == null, 'Automation triggered is not updated');
		Test.stopTest();
	}

	/**
	 * @author       Shyam Nasare
	 * @description  Agency Information Tax Notice Type check
	 **/
	@isTest
	static void testGetAgencyTaxNoticeType() {
		List<Agency_Information__c> list_AgenciesInfo = [SELECT Id FROM Agency_Information__c WHERE Tax_Notice_Type__c <> NULL];
	
		Test.startTest();
		List<String> list_TaxNoticeTypes = TaxResNoticeIndexDetailsController.getTaxNoticeTypes(list_AgenciesInfo[0].Id);
		Test.stopTest();
	
		System.assert(list_TaxNoticeTypes != null, 'Tax Notice Type not present on Agency Info');
	}
}