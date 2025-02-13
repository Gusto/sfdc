/**
* @name         : EmailToCaseTest
* @author       : Sean DesMarteau
* @date         : 02-15-2021
* @description  : This test class tests and validates Email to Case. If any test in this class fails Email to Case is broken in the Environment. 
				  This test class should be run for every deployment into production to be confident Email to Case will function after the deployment
* @test classes : EmailToCaseTest
**/
@isTest(SeeAllData=true) // Required to be able to test Email to Case Logic
public class EmailToCaseTest {
	// STATIC VARIABLES
	public static Boolean blnTestRealLife = false;
	public static User objSystemUser = [SELECT Id, Name FROM User WHERE Name = 'System' LIMIT 1];
	public static Map<String, Id> map_QueueNameToId = getCaseQueues();
	public static Database.DMLOptions dmlOpts = new Database.DMLOptions();
	public static Map<String, Id> getCaseQueues() {
		map_QueueNameToId = new Map<String, Id>();

		for (Group objGroup : [SELECT Id, Name FROM Group WHERE Type = 'Queue']) {
			map_QueueNameToId.put(objGroup.Name, objGroup.Id);
		}

		return map_QueueNameToId;
	}

	// HELPER FUNCTIONS
	/*
	 * @author      : Sean DesMarteau
	 * @Description	: Mimics Email-To-Case Logic. The method will attempt to insert a Case and EmailMessage as the System User
	 * 				  which will closely mimic standard Email-To-Case functionality. This is called in each test method.
	 * @Parm		: strToAddress - To Address for the Email
					  strCaseRecordTypeName - Record Type for the Case
					  strCaseType - Case Type 
	 				  strCasePriority - Priority of the Case
					  strCaseOrigin - Case Orgin
					  strCaseOwner - Should be the System user unless specified
	 * @Return:     : N/A
	 */
	public static void emailToCaseTest(String strToAddress, String strCaseRecordTypeName, String strCaseType, String strCasePriority, String strCaseOrigin, String strCaseOwner) {
		System.runAs(objSystemUser) {
			// Setup Case Record
			Case objCase = initializeCase(strCaseRecordTypeName, strCaseType, strCasePriority, strCaseOrigin, strCaseOwner);

			// Run Default Assignment Rules and Insert Case
			Database.DMLOptions dmo = new Database.DMLOptions();
			dmo.assignmentRuleHeader.useDefaultRule = true;
			objCase.setOptions(dmo);

			insert objCase;

			// Validate Case was Created
			List<Case> list_Cases = [SELECT Id FROM Case WHERE Id = :objCase.Id];
			System.assertEquals(1, list_Cases.size());

			// Create EmailMessage Record
			EmailMessage objEmail = initializeEmail(strToAddress, objCase);
			insert objEmail;

			// Associate EmailMessage Record to Case Record
			Case objCaseUpdate = new Case();
			objCaseUpdate.Id = objCase.Id;
			objCaseUpdate.SourceId = objEmail.Id;
			update objCaseUpdate;
		}
	}

	/*
	 * @author      : Sean DesMarteau
	 * @description	: Initializes the EmailMessage Object with required information. Should be based off Email to Case Settings
	 * @parm		: strToAddress - To Address for the Email
					  objCase - Case Record containing Email-To-Case Information
	 * @return:     : EmailMessage Record
	 */
	public static EmailMessage initializeEmail(String strToAddress, Case objCase) {
		EmailMessage objEmail = new EmailMessage();

		objEmail.FromAddress = objCase.SuppliedEmail;
		objEmail.FromName = objCase.SuppliedName;
		objEmail.Subject = objCase.Subject;
		objEmail.TextBody = objCase.Description;
		objEmail.ToAddress = strToAddress;
		objEmail.ParentId = objCase.Id;
		objEmail.Incoming = true;

		return objEmail;
	}

	/*
	 * @author      : Sean DesMarteau
	 * @description	: Initializes the Case Object with required information. Should be based off Email to Case Settings
	 * @parm		: strCaseRecordTypeName - Record Type for the Case
					  strCaseType - Case Type 
	 				  strCasePriority - Priority of the Case
					  strCaseOrigin - Case Orgin
					  strCaseOwner - Should be the System user unless specified
	 * @return:     : Case Record
	 */
	public static Case initializeCase(String strCaseRecordTypeName, String strCaseType, String strCasePriority, String strCaseOrigin, String strCaseOwner) {
		Case objCase = new Case();

		objCase.RecordTypeId = Cache.getRecordTypeId('Case', strCaseRecordTypeName);
		objCase.Subject = strCaseRecordTypeName.toUppercase() + ' EMAIL-TO-CASE TEST';
		objCase.Description = strCaseRecordTypeName.toUppercase() + ' EMAIL-TO-CASE TEST';
		objCase.Status = 'New';
		objCase.Origin = strCaseOrigin;
		objCase.Type = strCaseType;
		objCase.Priority = strCasePriority;
		objCase.SuppliedEmail = 'testing@gusto.com';
		objCase.SuppliedName = 'Tester Test';
		objCase.OwnerId = map_QueueNameToId.containsKey(strCaseOwner) ? map_QueueNameToId.get(strCaseOwner) : objSystemUser.Id;

		return objCase;
	}

	// TEST METHODS

	/*
	 * @author      : Sean DesMarteau
	 * @description	: Tests Email-To-Case Logic in a real life situation. If this Test passes and others don't it means that the Try Catch on CaseTrigger is working.
	 * 				  The Try Catch makes it so Emails are not lost but case logic processing may be incomplete. A fix should be implemented if this is the case.
	 */
	// Email - support@gusto.com
	public static testMethod void supportGustoEmailRealLife() {
		blnTestRealLife = true;
		Test.startTest();
		emailToCaseTest('support@gusto.com', 'Payroll Care', 'Payroll Care', 'Medium', 'Payroll Care Email', null);
		Test.stopTest();
		blnTestRealLife = false;
	}

	/*
	 * @author      : Sean DesMarteau
	 * @description	: All Tests below test Email-To-Case Logic for each Email-To-Case Email.
	 * 				  If any test fails Email-To-Case is not working and any error should be addressed immediately.
	 */
	// Email - support@gusto.com
	public static testMethod void supportGustoEmail() {
		Test.startTest();
		emailToCaseTest('support@gusto.com', 'Payroll Care', 'Payroll Care', 'Medium', 'Payroll Care Email', null);
		Test.stopTest();
	}

	// Email - concierge@gusto.com
	public static testMethod void conciergeGustoEmail() {
		Test.startTest();
		emailToCaseTest('concierge@gusto.com', 'Payroll Care', 'Payroll Care', 'Medium', 'Payroll Care Email', null);
		Test.stopTest();
	}

	// Email - smallgroupbenefits@gusto.com
	public static testMethod void smallGroupBenefitsGustoEmail() {
		Test.startTest();
		emailToCaseTest('smallgroupbenefits@gusto.com', 'Sales Cases', 'Sales Email', 'Medium', 'Success Email', null);
		Test.stopTest();
	}

	// Email - success@gusto.com
	public static testMethod void successGustoEmail() {
		Test.startTest();
		emailToCaseTest('success@gusto.com', 'Sales Cases', 'Sales Email', 'Medium', 'Success Email', null);
		Test.stopTest();
	}

	// Email - success@zenpayroll.com
	public static testMethod void successZenPayrollEmail() {
		Test.startTest();
		emailToCaseTest('success@zenpayroll.com', 'Sales Cases', 'Sales Email', 'Medium', 'Success Email', null);
		Test.stopTest();
	}

	// Email - setup@gusto.com
	public static testMethod void gustoSetupEmail() {
		Test.startTest();
		emailToCaseTest('setup@gusto.com', 'Sales Cases', 'Sales Email', 'Medium', 'Success Email', 'Sales Case Queue');
		Test.stopTest();
	}

	// Benefits Care
	// Email - benefits@gusto.com
	public static testMethod void benefitsGustoEmail() {
		Test.startTest();
		emailToCaseTest('benefits@gusto.com', 'Benefits Care', 'Benefits Care', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - gustobenefitscard@benefits.gusto.com
	public static testMethod void gustoBenefitsCardBenefitsGustoEmail() {
		Test.startTest();
		emailToCaseTest('gustobenefitscard@benefits.gusto.com', 'Benefits Care', 'Benefits Care', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - cobra@gusto.com
	public static testMethod void cobraGustoEmail() {
		Test.startTest();
		emailToCaseTest('cobra@gusto.com', 'Benefits Care', 'Benefits Care', 'Medium', 'Cobra Email', 'Continuation (COBRA)');
		Test.stopTest();
	}

	// Email - qsehra@gusto.com
	public static testMethod void qsheraGustoEmail() {
		Test.startTest();
		emailToCaseTest('qsehra@gusto.com', 'Benefits Care', 'Benefits Care', 'Medium', 'QSEHRA Email', null);
		Test.stopTest();
	}

	// Benefits BoR
	// Email - bor-transfer@gusto.com
	public static testMethod void borTransferGustoEmail() {
		Test.startTest();
		emailToCaseTest('bor-transfer@gusto.com', 'Benefits BoR', 'Benefits BoR', 'Medium', 'Email', 'Benefits Transfer- Carrier');
		Test.stopTest();
	}

	// Email - bor-transfer+expressdynamics@gusto.com
	public static testMethod void borTransferExpressDynamicsGustoEmail() {
		Test.startTest();
		emailToCaseTest('bor-transfer+expressdynamics@gusto.com', 'Benefits BoR', 'Benefits BoR', 'Medium', 'Email', 'Benefits Transfer- Carrier');
		Test.stopTest();
	}

	// Email - bor-transfer+percival@gusto.com
	public static testMethod void borTransferPercivalGustoEmail() {
		Test.startTest();
		emailToCaseTest('bor-transfer+percival@gusto.com', 'Benefits BoR', 'Benefits BoR', 'Medium', 'Email', 'Benefits Transfer- Carrier');
		Test.stopTest();
	}

	// Email - bor-transfer+wonolo@gusto.com
	public static testMethod void borTransferWonoloGustoEmail() {
		Test.startTest();
		emailToCaseTest('bor-transfer+wonolo@gusto.com', 'Benefits BoR', 'Benefits BoR', 'Medium', 'Email', 'Benefits Transfer- Carrier');
		Test.stopTest();
	}

	// Email - benefits-onboarding@gusto.com
	public static testMethod void benefitsOnboardingGustoEmail() {
		Test.startTest();
		emailToCaseTest('benefits-onboarding@gusto.com', 'Benefits BoR', 'Benefits BoR', 'Medium', 'Email', 'BOR Case Queue');
		Test.stopTest();
	}

	// Email - newplans@gusto.com
	public static testMethod void newPlansGustoEmail() {
		Test.startTest();
		emailToCaseTest('newplans@gusto.com', 'Benefits New Plan Case', 'Benefits New Plan Case', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - benefits-newplans@gusto.com
	public static testMethod void benefitsNewPlansGustoEmail() {
		Test.startTest();
		emailToCaseTest('benefits-newplans@gusto.com', 'Benefits New Plan Case', 'Benefits New Plan Case', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - renewalcarriercomms@gusto.com
	public static testMethod void renewalCarrierCommsGustoEmail() {
		Test.startTest();
		emailToCaseTest('renewalcarriercomms@gusto.com', 'Benefits Renewal Case', 'Benefits Renewal Case', 'Medium', 'Email', null);
		Test.stopTest();
	}
	// Email - renewals@gusto.com
	public static testMethod void renewalsGustoEmail() {
		Test.startTest();
		emailToCaseTest('renewals@gusto.com', 'Benefits Renewal Case', 'Benefits Renewal Case', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - cashout-support@gusto.com
	public static testMethod void cashoutSupportGustoEmail() {
		Test.startTest();
		emailToCaseTest('cashout-support@gusto.com', 'Modern Bank', 'Modern Bank', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - cash-reserve-support@gusto.com
	public static testMethod void cashReserveSupportGustoEmail() {
		Test.startTest();
		emailToCaseTest('cash-reserve-support@gusto.com', 'Modern Bank', 'Modern Bank', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - flexible-pay-support@gusto.com
	public static testMethod void flexiblePaySupportGustoEmail() {
		Test.startTest();
		emailToCaseTest('flexible-pay-support@gusto.com', 'Modern Bank', 'Modern Bank', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - compliance@gusto.com
	public static testMethod void complianceGustoEmail() {
		Test.startTest();
		emailToCaseTest('compliance@gusto.com', 'Payroll Compliance', 'Payroll Compliance', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - compliance@zenpayroll.com
	public static testMethod void complianceZenPayrollEmail() {
		Test.startTest();
		emailToCaseTest('compliance@zenpayroll.com', 'Payroll Compliance', 'Payroll Compliance', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - payopsptserrors@gusto.com
	public static testMethod void payOpsPTSErrorsGustoEmail() {
		Test.startTest();
		emailToCaseTest('payopsptserrors@gusto.com', 'Tax Ops', 'Tax Ops', 'Medium', 'Email', 'PTS Errors Queue');
		Test.stopTest();
	}

	// Email - payrollops@gusto.com
	public static testMethod void payrollOpsGustoEmail() {
		Test.startTest();
		emailToCaseTest('payrollops@gusto.com', 'Tax Ops', 'Tax Ops', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - payrollops@zenpayroll.com
	public static testMethod void payrollOpsZenPayrollEmail() {
		Test.startTest();
		emailToCaseTest('payrollops@zenpayroll.com', 'Tax Ops', 'Tax Ops', 'Low', 'HelloFax Email', null);
		Test.stopTest();
	}

	// Email - garnishments@gusto.com
	public static testMethod void garnishmentsGustoEmail() {
		Test.startTest();
		emailToCaseTest('garnishments@gusto.com', 'Tax Ops', 'Tax Ops', 'Medium', 'Email', 'Garnishments Queue');
		Test.stopTest();
	}

	// Email - payrollonboarding@gusto.com
	public static testMethod void payrollOnboardingGustoEmail() {
		Test.startTest();
		emailToCaseTest('payrollonboarding@gusto.com', 'Payroll Transfer Case', 'Payroll Transfer Case', 'Medium', 'Email', 'Company Migration - Case Queue');
		Test.stopTest();
	}

	// Email - memberfulfillment@gusto.com
	public static testMethod void memberFulfillmentGustoEmail() {
		Test.startTest();
		emailToCaseTest('memberfulfillment@gusto.com', 'Member Fulfillment Emails', 'Member Fulfillment Emails', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - poa.support@gusto.com
	public static testMethod void poaSupportGustoEmail() {
		Test.startTest();
		emailToCaseTest('poa.support@gusto.com', 'Tax Res', 'Tax Res', 'Medium', 'Email', 'TaxRes POA Queue');
		Test.stopTest();
	}

	// Email - assurance@gusto.com
	public static testMethod void assuranceGustoEmail() {
		Test.startTest();
		emailToCaseTest('assurance@gusto.com', 'Risk Assurance', 'Risk Assurance', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - underwriting@gusto.com
	public static testMethod void underwritingGustoEmail() {
		Test.startTest();
		emailToCaseTest('underwriting@gusto.com', 'Risk Assurance', 'Risk Assurance', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - recovery@gusto.com
	public static testMethod void recoveryGustoEmail() {
		Test.startTest();
		emailToCaseTest('recovery@gusto.com', 'Recovery Cases', 'Recovery Cases', 'Medium', 'Email', 'Recovery Case');
		Test.stopTest();
	}

	// Email - taxcompliance@gusto.com
	public static testMethod void taxComplianceGustoEmail() {
		Test.startTest();
		emailToCaseTest('taxcompliance@gusto.com', 'Payroll Compliance', 'Tax Compliance', 'High', 'Email', 'Payroll Compliance Queue');
		Test.stopTest();
	}

	// Email - heretohelp@gusto.com
	public static testMethod void hereToHelpGustoEmail() {
		Test.startTest();
		emailToCaseTest('heretohelp@gusto.com', 'Sales Cases', 'Sales Cases', 'Medium', 'Outreach Email', 'Sales Case Queue');
		Test.stopTest();
	}

	// Email - payrollaudit@gusto.com
	public static testMethod void payrollAuditGustoEmail() {
		Test.startTest();
		emailToCaseTest('payrollaudit@gusto.com', 'PayrollOps Audit', 'PayrollOps Audit', 'Medium', 'Email', 'PayrollOps Audit Queue');
		Test.stopTest();
	}

	// Email - security-check@gusto.com
	public static testMethod void securityCheckGustoEmail() {
		Test.startTest();
		emailToCaseTest('security-check@gusto.com', 'Risk Assurance', 'Risk Assurance', 'Medium', 'Email', 'Risk Security Check');
		Test.stopTest();
	}

	// Email - wallet@gusto.com
	public static testMethod void walletGustoEmail() {
		Test.startTest();
		emailToCaseTest('wallet@gusto.com', 'Modern Bank', 'Modern Bank', 'Medium', 'Email', null);
		Test.stopTest();
	}

	// Email - agencynotices@gusto.com
	public static testMethod void agencyNoticesGustoEmail() {
		Test.startTest();
		emailToCaseTest('agencynotices@gusto.com', 'Benefits Compliance', 'Benefits Compliance', 'Medium', 'Email', 'Agency Notices');
		Test.stopTest();
	}
}