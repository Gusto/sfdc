/**
 * @author      Todd Dowdy
 * @description Test Class validating Auto Solve/ Closed Batch correctly updates cases based on Record Type.
 * Date: 03/06/2023
 **/
@isTest
public class AutoUpdateCaseStatusBatchTest {
	@TestSetup
	static void testSetup() {
		List<Case> list_InsertTestCases = new List<Case>();
		List<Case> list_UpdateCases = new List<Case>();
		List<Case_Reason_Classification__c> list_InsertCaseReasonClassifications = new List<Case_Reason_Classification__c>();

		// Create new company account
		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test Company Account').build();
		insert objAccount;

		// Create Agnecy for Tax Res Case
		Agency_Information__c objAgency = TestDataFactory.createOneAgencyInforation('Test Agency');

		// Create new company Contact
		Contact objContact = new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAccount.Id)
			.setFirstName('Test First Name')
			.setLastName('Test Last Name')
			.setEmail('StatusAutoUpdateBatch@test.com')
			.build();
		insert objContact;

		// Create Payroll Care Confirm Case Reason for Auto Solve
		Case_Reason_Classification__c objCaseReasonClassification1 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Payroll Care Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setDoNotAutoSolve(false)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification1);

		// Create Benefits Care Confirm Case Reason for Auto Solve
		Case_Reason_Classification__c objCaseReasonClassification2 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Benefits Care Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Benefits Care')
			.setDoNotAutoSolve(false)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification2);

		// Create Modern Bank Confirm Case Reason for Auto Solve
		Case_Reason_Classification__c objCaseReasonClassification4 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Modern Bank Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Modern Bank')
			.setDoNotAutoSolve(false)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification4);

		// Create GEP CX Confirm Case Reason for Auto Solve
		Case_Reason_Classification__c objCaseReasonClassification5 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test GEP CX Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('GEP CX')
			.setDoNotAutoSolve(false)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification5);

		// Create PayrollOps Audit Confirm Case Reason for Auto Solve
		Case_Reason_Classification__c objCaseReasonClassification6 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test PayrollOps Audit Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('PayrollOps Audit')
			.setDoNotAutoSolve(false)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification6);

		// Create Do Not Auto Solve Payroll Care Confirm Case Reason
		Case_Reason_Classification__c objCaseReasonClassification7 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Do Not Auto Solve')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Payroll Care')
			.setDoNotAutoSolve(true)
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification7);

		// Create No Response from Customer Care Confirm Case Reason
		Case_Reason_Classification__c objCaseReasonClassification8 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName(CaseUtils.STR_AUTO_SOLVED_CASE_REASON)
			.setIsActive(true)
			.setType('Payroll Care')
			.setClass('Class 1')
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification8);

		Case_Reason_Classification__c objCaseReasonClassification9 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('No Response from Customer')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Benefits Care')
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification9);

		Case_Reason_Classification__c objCaseReasonClassification10 = new TestDataFactory.CaseReasonClassificationBuilder()
			.setName('Test Risk Assurance Reason')
			.setIsActive(true)
			.setClass('Class 1')
			.setType('Risk Assurance')
			.build();
		list_InsertCaseReasonClassifications.add(objCaseReasonClassification10);

		insert list_InsertCaseReasonClassifications;

		// Auto Close Payroll Care Case
		Case objCase1 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Closed')
			.setSubject('Auto Close Payroll Care')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close Payroll Care Case')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification1.Id)
			.setConfirmCaseReason(objCaseReasonClassification1.Name)
			.setAudience('Employee')
			.build();
		list_InsertTestCases.add(objCase1);

		// Auto Close Benefits Care Case
		Case objCase2 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setStatus('Solved')
			.setSubject('Auto Close Benefits Care')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close Benefits Care Case')
			.setAudience('Employer')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification2.Id)
			.setConfirmCaseReason(objCaseReasonClassification2.Name)
			.build();
		list_InsertTestCases.add(objCase2);

		// Auto Close Tax Res Case
		Case objCase3 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Tax Res')
			.setType('Tax Res')
			.setStatus('Solved')
			.setSubject('Auto Close Tax Res')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close Tax Res Case')
			.setAgencyInformation(objAgency.Id)
			.setCustomerJourney('Prior to Gusto')
			.setRootCause('Client')
			.setSubRootCause('Amendment Pending')
			.setNoticePeriod('2024')
			.setActionTaken('Skip Email Alert')
			.setCustomerActionsRequired('No customer actions required')
			.setLargeScaleIssue('No LSI')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCase3);

		// Auto Close Modern Bank Case
		Case objCase4 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setStatus('Solved')
			.setSubject('Auto Close Modern Bank')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close Modern Bank Case')
			.setComplaintType('No Complaint')
			.setProduct('Not Product Specific')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification4.Id)
			.setConfirmCaseReason(objCaseReasonClassification4.Name)
			.build();
		list_InsertTestCases.add(objCase4);

		// Auto Close PayrollOps Audit Case
		Case objCase5 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('PayrollOps Audit')
			.setType('PayrollOps Audit')
			.setStatus('Closed')
			.setSubject('Auto Close PayrollOps Audit')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close PayrollOps Audit Case')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification6.Id)
			.setConfirmCaseReason(objCaseReasonClassification6.Name)
			.build();
		list_InsertTestCases.add(objCase5);

		// Auto Close GEP CX Case
		Case objCase6 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('GEP CX')
			.setType('GEP CX')
			.setStatus('Solved')
			.setSubject('Auto Close GEP CX')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close GEP CX Case')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification5.Id)
			.setConfirmCaseReason(objCaseReasonClassification5.Name)
			.build();
		list_InsertTestCases.add(objCase6);

		// Auto Close Risk Assurance
		Case objCase14 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId(CaseUtils.TYPE_RISK_ASSURANCE)
			.setType(CaseUtils.TYPE_RISK_ASSURANCE)
			.setStatus(CaseUtils.STATUS_SOLVED)
			.setSubject('Auto Close Risk Assurance')
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Auto Close Risk Assurance Case')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification5.Id)
			.setConfirmCaseReason(objCaseReasonClassification5.Name)
			.build();
		list_InsertTestCases.add(objCase14);

		// Auto Solve Payroll Care Case
		Case objCase7 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Awaiting Response')
			.setSubject('Auto Solve Payroll Care')
			.setSuppliedEmail('AutoSolve@gusto.com')
			.setDescription('Auto Solve Payroll Care Case')
			.setAutoSolve(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCase7);

		// Auto Solve Benefits Care Case
		Case objCase8 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Benefits Care')
			.setType('Benefits Care')
			.setStatus('Awaiting Response')
			.setSubject('AutoUpdateCaseStatusBatchTest Benefits Care')
			.setSuppliedEmail('AutoSolve@gusto.com')
			.setDescription('Auto Solve Benefits Care Case')
			.setConfirmCaseReason(objCaseReasonClassification2.Name)
			.setAutoSolve(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCase8);

		// Auto Solve Modern Bank Case
		Case objCase9 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Modern Bank')
			.setType('Modern Bank')
			.setStatus('Awaiting Response')
			.setSubject('Auto Solve Modern Bank')
			.setSuppliedEmail('AutoSolve@gusto.com')
			.setDescription('Auto Solve Modern Bank Case')
			.setComplaintType('No Complaint')
			.setProduct('Not Product Specific')
			.setAutoSolve(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification4.Id)
			.setConfirmCaseReason(objCaseReasonClassification4.Name)
			.build();
		list_InsertTestCases.add(objCase9);

		// Auto Solve Risk Assurance Case
		Case objCase12 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Risk Assurance')
			.setType('Risk Assurance')
			.setStatus('Awaiting Response')
			.setSubject('Auto Solve Risk Assurance')
			.setSuppliedEmail('AutoSolve@gusto.com')
			.setDescription('Auto Solve Risk Assurance Case')
			.setAutoSolve(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification10.Id)
			.setConfirmCaseReason(objCaseReasonClassification10.Name)
			.build();
		list_InsertTestCases.add(objCase12);

		// Do Not Auto Close Payroll Care Case
		Case objCase10 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Solved')
			.setSubject('Payroll Care Do Not Auto Close')
			.setSuppliedEmail('DoNotAutoClose@test.com')
			.setDescription('Do Not Auto Close Payroll Care Case')
			.setAutoCloseDateTime(System.now().addMinutes(20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification1.Id)
			.setConfirmCaseReason(objCaseReasonClassification1.Name)
			.build();
		list_InsertTestCases.add(objCase10);

		// Do Not Auto Solve Payroll Care Case
		Case objCase11 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Payroll Care')
			.setType('Payroll Care')
			.setStatus('Awaiting Response')
			.setSubject('Payroll Care Do Not Auto Solve')
			.setSuppliedEmail('DoNotAutoSolve@test.com')
			.setDescription('Do Not Auto Solve Payroll Care Case')
			.setAutoSolve(System.now().addMinutes(-20))
			.setConfirmCaseReasonClassification(objCaseReasonClassification7.Id)
			.setConfirmCaseReason(objCaseReasonClassification7.Name)
			.setDoNotAutoSolve(true)
			.build();
		list_InsertTestCases.add(objCase11);

		// Auto Solve R&D Record Type
		Case objCase13 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('R&D Tax Credits')
			.setStatus('Solved')
			.setSubject('R&D Auto Close')
			.setSuppliedEmail('AutoCloseResolution@test.com')
			.setDescription('R&D Auto Solve')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCase13);

		Case objCase15 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setStatus('Awaiting Internal Support')
			.setSubject('Engagement1')
			.setSuppliedEmail('AutoCloseResolution@test.com')
			.setDescription('Engagement')
			.setFollowUpDateTime(System.now().addMinutes(-20))
			.setInternalSupportForm('Captain/SME')
			.build();
		list_InsertTestCases.add(objCase15);

		Case objCase16 = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Engagement')
			.setStatus('Awaiting Response')
			.setSubject('Engagement')
			.setSuppliedEmail('AutoCloseResolution@test.com')
			.setDescription('Engagement')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCase16);

		Case objCaseSalesCase = new TestDataFactory.CaseBuilder()
			.setAccountId(objAccount.Id)
			.setContactId(objContact.Id)
			.setRecordTypeId('Sales Cases')
			.setStatus(CaseUtils.STATUS_CLOSED)
			.setSubject('Sales Cases Auto Close')
			.setType(CaseUtils.TYPE_SALES_EMAIL)
			.setSuppliedEmail('AutoClose@test.com')
			.setDescription('Sales Cases Auto Close')
			.setAutoCloseDateTime(System.now().addMinutes(-20))
			.build();
		list_InsertTestCases.add(objCaseSalesCase);

		if (!list_InsertTestCases.isEmpty()) {
			CaseTriggerHelper.skipTrigger = true;
			insert list_InsertTestCases;
			CaseTriggerHelper.skipTrigger = false;
		}
	}
	/**
	 * @author          Todd Dowdy
	 * @description     Validate Auto Solve Cases were solved correctly
	 **/
	@isTest
	static void testAutoSolve() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		List<Case> list_AutoSolveCases = [
			SELECT
				Id,
				Subject,
				Status,
				Automation_Message__c,
				Automation_Status__c,
				Date_Time_Solved__c,
				SuppliedEmail,
				RecordTypeId,
				Confirm_Case_Reason__c,
				Confirm_Case_Reason_Classification__c,
				Audience__c
			FROM Case
			WHERE SuppliedEmail = 'AutoSolve@test.com'
		];
		for (Case objCase : list_AutoSolveCases) {
			if (objCase.RecordTypeId != CaseUtils.RECTYPE_RISK_ASSURANCE && objCase.RecordTypeId != CaseUtils.RECTYPE_PAYROLL_CARE) {
				System.assertEquals('Solved', objCase.Status, 'Case auto solve Status Was not updated to Solved ' + objCase.Subject);
				System.assertEquals('Auto Solve Email Alert', objCase.Automation_Message__c, 'Auto Solve Automation Message was updated in flow ' + objCase.Subject);
				if (objCase.RecordTypeId != CaseUtils.RECTYPE_BENEFITS_CARE) {
					System.assertNotEquals('Completed', objCase.Automation_Status__c, 'Auto Solve Automation Status was not updated in flow ' + objCase.Subject);
					System.assertNotEquals(null, objCase.Confirm_Case_Reason__c, 'Confirm Case Reason is required to Auto Solve' + objCase.Subject);
					System.assertNotEquals(CaseUtils.STR_AUTO_SOLVED_CASE_REASON, objCase.Confirm_Case_Reason__c, 'Case Confirm Reason Was not updated ' + objCase.Subject);
					if (objCase.RecordTypeId != CaseUtils.RECTYPE_MODERN_BANK) {
						System.assertEquals(true, objCase.Confirm_Case_Reason_Classification__c != null, 'Case Confirm Reason look up Was not updated ' + objCase.Subject);
					}
				}
				System.assertNotEquals(null, objCase.Date_Time_Solved__c, 'Case auto solve Date time Solved not populated ' + objCase.Subject);

				if (objCase.RecordTypeId == CaseUtils.RECTYPE_PAYROLL_CARE || objCase.RecordTypeId == CaseUtils.RECTYPE_BENEFITS_CARE) {
					System.assertEquals(CaseUtils.AUDIENCE_OTHER, objCase.Audience__c, 'Audience was not updated.');
				}
			} else {
				if (objCase.RecordTypeId != CaseUtils.RECTYPE_PAYROLL_CARE) {
					System.assertEquals('Solved', objCase.Status, 'Case auto solve Status Was not updated to Solved ' + objCase.Subject);
				}
			}
		}
	}

	/**
	 * @author          Todd Dowdy
	 * @description     Validate Auto Close Cases were closed correctly
	 **/
	@isTest
	static void testAutoClose() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		List<Case> list_AutoCloseCases = [
			SELECT Id, Subject, Status, RecordTypeId, recordtype.developername, Type, SuppliedEmail, Confirm_Case_Reason__c, Auto_Close_Date_Time__c
			FROM Case
			WHERE SuppliedEmail = 'AutoClose@test.com'
		];
		for (Case objCase : list_AutoCloseCases) {
			if (objCase.RecordTypeId != CaseUtils.RECTYPE_PAYROLL_CARE) {
				System.assertEquals('Closed', objCase.Status, 'Case auto close Status Was updated to Closed ' + objCase.Subject);
			}
			if (objCase.Type.contains('Payroll Care')) {
				System.assertNotEquals(CaseUtils.RECTYPE_PAYROLL_CARE_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was updated ' + objCase.Subject);
			} else if (objCase.Type.contains('Benefits Care')) {
				System.assertEquals(CaseUtils.RECTYPE_BENEFITS_CARE_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
			} else if (objCase.Type.contains('Modern Bank')) {
				System.assertEquals(CaseUtils.RECTYPE_MODERN_BANK_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
			} else if (objCase.Type.contains('PayrollOps Audit')) {
				//System.assertNotEquals(CaseUtils.RECTYPE_PAYROLLOPS_AUDIT_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
			} else if (objCase.Type.contains('Tax Res')) {
				System.assertEquals(CaseUtils.RECTYPE_TAXRES_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
				System.assertEquals(null, objCase.Confirm_Case_Reason__c, 'Tax Res Case does not need a Confirm Case reason');
			} else if (objCase.Type.contains(CaseUtils.TYPE_RISK_ASSURANCE)) {
				System.assertEquals(CaseUtils.RECTYPE_RISK_ASSURANCE_READ_ONLY, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
			} else if (objCase.Type.contains(CaseUtils.TYPE_SALES_EMAIL)) {
				System.assertEquals(CaseUtils.RECTYPE_SALES_CASES_CLOSED, objCase.RecordTypeId, 'Case auto close RecordType was not updated ' + objCase.Subject);
			}
		}
	}

	/**
	 * @author          Todd Dowdy
	 * @description     Validate Auto Solve action was skipped when Do_Not_Auto_Solve__c = true
	 **/
	@isTest
	static void testDoNotAutoSolve() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		Case objDoNotAutoSolveCases = [
			SELECT Id, Subject, Status, Automation_Message__c, Automation_Status__c, Date_Time_Solved__c, SuppliedEmail
			FROM Case
			WHERE SuppliedEmail = 'DoNotAutoSolve@test.com' AND Do_not_Auto_Solve__c = TRUE
			LIMIT 1
		];
		System.assertNotEquals('Solved', objDoNotAutoSolveCases.Status, 'Case Auto Solved even though Don\'t Auto Solve was true' + objDoNotAutoSolveCases.Subject);
	}

	/**
	 * @author          Todd Dowdy
	 * @description     Validate Auto Close action was skipped when Confirm Case Reason isn't populated
	 **/
	@isTest
	static void testDoNotAutoClose() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		Case objDoNotAutoSolveCases = [
			SELECT Id, Subject, Status, Automation_Message__c, Automation_Status__c, Date_Time_Solved__c, SuppliedEmail
			FROM Case
			WHERE SuppliedEmail = 'DoNotAutoClose@test.com'
			LIMIT 1
		];
		System.assertNotEquals('Closed', objDoNotAutoSolveCases.Status, 'Case Auto Closed even though there is no Confirm Case Reason ' + objDoNotAutoSolveCases.Subject);
	}

	/**
	 * @author Ajay Krishna P U
	 * @description Test Auto close resolution - integration test
	 */
	@isTest
	static void testPopulateAutoCloseResolution1() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		Case objAutoCloseCase = [SELECT Id, Subject, Status, Case_Resolution__c FROM Case WHERE SuppliedEmail = 'AutoCloseResolution@test.com' LIMIT 1];
		System.assert('Closed' == objAutoCloseCase.Status, 'Failed to Auto close R&D Record Type');
		System.assert(null != objAutoCloseCase.Case_Resolution__c, 'Failed to Auto populate Case resolution');
	}

	/**
	 * @author Ajay Krishna P U
	 * @description Test Auto close resolution - unit test
	 */
	@isTest
	static void testPopulateAutoCloseResolution2() {
		//Auto Close Without Resolution
		Case objCaseClosed = new Case(Status = CaseUtils.STATUS_CLOSED, RecordTypeId = CaseUtils.RECTYPE_R_D_TAX_CREDITS);

		Boolean blnIsUpdate = new AutoUpdateCaseStatusBatch().autoPopulateCloseResolution(objCaseClosed);
		System.assert(blnIsUpdate == true, 'Auto Update failed - without resolution for R&D type');
		System.assert(objCaseClosed.Case_Resolution__c != null, 'Invalid case resolution- without resolution for type R&D');

		//Auto Close With Resolution
		objCaseClosed = new Case(Case_Resolution__c = CaseUtils.RESOLUTION_ISSUE_RESOLVED, Status = CaseUtils.STATUS_CLOSED, RecordTypeId = CaseUtils.RECTYPE_R_D_TAX_CREDITS);

		blnIsUpdate = new AutoUpdateCaseStatusBatch().autoPopulateCloseResolution(objCaseClosed);
		System.assert(blnIsUpdate == false, 'Auto Update failed - with resolution for R&D type');
		System.assert(objCaseClosed.Case_Resolution__c == CaseUtils.RESOLUTION_ISSUE_RESOLVED, 'Invalid case resolution - with resolution for type R&D');
	}
	/**
	 * @author          Priya
	 * @description     Validate Awaiting Internal Support Cases were updated to In Progress correctly
	 **/
	@isTest
	static void testAutoInProgress() {
		Test.startTest();
		AutoUpdateCaseStatusBatch job = new AutoUpdateCaseStatusBatch();
		Integer intYear = Date.today().year() + 1;
		String strCronExpr = '0 0 0 15 3 ? ' + intYear;
		String strJobId = System.schedule('job name', strCronExpr, job);
		job.execute(null);
		Test.stopTest();

		// Case was in Awaiting Internal Support and will change to In Progress after Test.stopTest()
		Case obj_InPRogressCase = [
			SELECT Id, Subject, Status, RecordTypeId, recordtype.developername, follow_up_date_time__c
			FROM Case
			WHERE Subject = 'Engagement1' AND Internal_Support_Requested_From__c = 'Captain/SME'
			LIMIT 1
		];
		System.assertEquals('In Progress', obj_InPRogressCase.Status, 'Case Status Was Not updated to In Progress ' + obj_InPRogressCase.Subject);
	}
}