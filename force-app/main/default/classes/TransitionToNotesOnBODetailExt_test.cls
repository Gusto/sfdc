@isTest
public class TransitionToNotesOnBODetailExt_test {
	public static final String strHSAEmailMacroBody = 'HSA - Email Macro'; 
	public static final String strFSAEmailMacroBody = 'FSA - Email Macro'; 
	@testSetup
	static void setup() {
		TransitionToNotesOnBODetailExt_test.skipTrigger(true);
		createTTFAndTTIARecord();
		createBenefitNewPlanCaseRecord();
		TransitionToNotesOnBODetailExt_test.skipTrigger(false);
	}

	static testMethod void testDisplayEditTTIA() {
		test.startTest();
		//Fetch BO where order status is not Approved.
		List<Benefit_Order__c> list_BO = [SELECT id FROM Benefit_Order__c WHERE Opportunity__r.Name != 'Test New Plan Opportunity'];
		if (list_BO.size() > 0) {
			PageReference pageRef = Page.TransitionToNotesOnBODetail;
			Test.setCurrentPage(pageRef);
			ApexPages.StandardController sc = new ApexPages.StandardController(list_BO[0]);
			ApexPages.currentPage().getParameters().put('Id', list_BO[0].Id);
			TransitionToNotesOnBODetailExt dedit = new TransitionToNotesOnBODetailExt(sc);
			System.assert(dedit.QAObj.Id != null);
			System.assertEquals(dedit.QAObj.Benefit_Order__c, list_BO[0].Id);
		}

		test.stopTest();
	}

	static testMethod void testSendNPSurveyConfirmationEmail() {
		//If the case record type is Benefits New Plan or Benefits Change, pull the survey url from 'NP Survey URL' on the case.
		//Fetch BO where order status is Approved.
		List<Benefit_Order__c> list_BO = [SELECT Id, Opportunity__c, Opportunity__r.AccountId FROM Benefit_Order__c WHERE Opportunity__r.Name = 'Test New Plan Opportunity'];
		List<Contact> list_Contact = [SELECT Id, AccountId FROM Contact LIMIT 1];

		//Create new case record having record type as : Benefits New Plan Case
		Id idNewPlan = Cache.getRecordTypeId('Case', 'Benefits New Plan Case');
		Case objCase = new Case(
			Subject = 'Test Case 1',
			ContactId = list_Contact[0].Id,
			AccountId = list_Contact[0].AccountId,
			RecordTypeId = idNewPlan,
			Priority = 'Medium',
			Direction__c = 'Inbound',
			Origin = 'Email',
			Benefit_Order__c = list_BO[0].Id,
			Integration_Id__c = 'hippo-Benefits_New_Plan-' + list_BO[0].Opportunity__c,
			Opportunity__c = list_BO[0].Opportunity__c
		);
		CaseTriggerHelper.skipTrigger = true;
		insert objCase;

		List<CaseTeamRole> list_CaseTeamRoles = [SELECT Id FROM CaseTeamRole WHERE Name = 'Customer Contact'];
		Id idCaseTeamRole = null;
		if (list_CaseTeamRoles != null && list_CaseTeamRoles.size() > 0) {
			idCaseTeamRole = list_CaseTeamRoles[0].Id;
		}

		List<CaseTeamMember> list_CaseTeams = new List<CaseTeamMember>();
		for (Contact objContact : [SELECT Id FROM Contact WHERE Zp_User_Id__c LIKE '7500%']) {
			list_CaseTeams.add(new CaseTeamMember(MemberId = objContact.Id, ParentId = objCase.Id, TeamRoleId = idCaseTeamRole));
		}
		if (list_CaseTeams.size() > 0) {
			insert list_CaseTeams;
		}

		List<Case> list_Case = [SELECT Id, Renewal_Survey_URL__c, NP_Survey_URL__c FROM Case WHERE Id = :objCase.Id];
		System.assert(list_Case.size() > 0);
		Test.startTest();

		List<Carrier_Order__c> list_CO = [
			SELECT Id, Benefit_Order__c, Carrier__r.Carrier_Unique_Name__c, Implementation_Stage__c, Order_Type__c, Order_Assignment__c, Carrier__r.Name
			FROM Carrier_Order__c
			WHERE Benefit_Order__c = :list_BO[0].Id
		];
		System.assert(list_CO.size() > 0);
		if (list_CO.size() > 0) {
			PageReference objPageRef = Page.CarrierOrderApprove;
			objPageRef.getParameters().put('id', String.valueOf(list_CO[0].Id));
			test.setCurrentPage(objPageRef);
			ApexPages.StandardController sc = new ApexPages.StandardController(list_BO[0]);
			CarrierOrderApproveExt objExtension = new CarrierOrderApproveExt(sc);
			objExtension.carrierObj.Implementation_Stage__c = 'Approved';
			objExtension.carrierObj.Order_Type__c = '';
			objExtension.updateCarrier();
		}

		for (Carrier_Order__c objCO : list_CO) {
			objCO.Implementation_Stage__c = 'Approved';
		}
		TransitionToNotesOnBODetailExt_test.skipTrigger(true);
		update list_CO;
		TransitionToNotesOnBODetailExt_test.skipTrigger(false);
		CaseTriggerHelper.skipTrigger = true;

		BenefitOrderHelper.skipTrigger = true;
		list_BO[0].Order_Status__c = 'Approved';
		update list_BO[0];
		BenefitOrderHelper.skipTrigger = false;

		PageReference pageRef = Page.TransitionToNotesOnBODetail;
		pageRef.getParameters().put('id', String.valueOf(list_BO[0].Id));
		test.setCurrentPage(pageRef);

		ApexPages.StandardController sc = new ApexPages.StandardController(list_BO[0]);
		TransitionToNotesOnBODetailExt extension = new TransitionToNotesOnBODetailExt(sc);
		System.assert(extension.blnShowConfirmationEmailBtn == true);

		extension.invokeConfirmationEmail();
			//Validate cc address added or not in the send email.
		List<EmailMessage> list_EmailMessage = [SELECT Id, CcAddress, HtmlBody FROM EmailMessage WHERE ParentId = :objCase.Id AND Email_Template_Name__c = 'OE_Confirmation_Email_Default'];
		if(OrganizationUtilities.canSendEmails()){	
			System.assert(list_EmailMessage.size() > 0);
			String strCCAddress = list_EmailMessage[0].CcAddress;
			System.assert(strCCAddress.contains('testuser01@gusto.com'));
			System.assert(strCCAddress.contains('testuser02@gusto.com'));
			System.assert(strCCAddress.contains('testuser03@gusto.com'));
		}

		Test.stopTest();

		//Validate NP Survey URL & TAdA Email Macro added in email body or not.
		if (OrganizationUtilities.canSendEmails() && list_EmailMessage.size() > 0) {
			System.assert(list_EmailMessage[0].HtmlBody.contains(list_Case[0].NP_Survey_URL__c));
			System.assert(list_EmailMessage[0].HtmlBody.contains(strHSAEmailMacroBody));
			System.assert(list_EmailMessage[0].HtmlBody.contains(strFSAEmailMacroBody));
		}
	}

	static testMethod void testSendRenewalSurveyConfirmationEmail() {
		//If the case record type is Benefits Renewal, pull the survey url from 'Renewal Survey URL' on the case.
		//Fetch BO where order status is Approved.
		List<Benefit_Order__c> list_BO = [SELECT Id, Opportunity__c, Opportunity__r.AccountId FROM Benefit_Order__c WHERE Opportunity__r.Name = 'Test New Plan Opportunity'];
		List<Contact> list_Contact = [SELECT Id, AccountId FROM Contact LIMIT 1];

		//Update BO order status
		TransitionToNotesOnBODetailExt_test.skipTrigger(true);
		list_BO[0].Order_Status__c = 'Approved';
		update list_BO[0];

		//Update CO
		List<Carrier_Order__c> list_CO = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c = :list_BO[0].Id];
		for (Carrier_Order__c objCO : list_CO) {
			objCO.Implementation_Stage__c = 'Approved';
		}
		update list_CO;
		TransitionToNotesOnBODetailExt_test.skipTrigger(false);

		//Create new case record having record type as : Benefits Renewal Case
		Id idRenewal = Cache.getRecordTypeId('Case', 'Benefits Renewal Case');
		Case objCase = new Case(
			Subject = 'Test Case 1',
			ContactId = list_Contact[0].Id,
			AccountId = list_Contact[0].AccountId,
			RecordTypeId = idRenewal,
			Priority = 'Medium',
			Direction__c = 'Inbound',
			Origin = 'Email',
			Benefit_Order__c = list_BO[0].Id,
			Integration_Id__c = 'hippo-Benefits_New_Plan-' + list_BO[0].Opportunity__c,
			Opportunity__c = list_BO[0].Opportunity__c
		);

		insert objCase;

		List<Case> list_Case = [SELECT Id, Renewal_Survey_URL__c, NP_Survey_URL__c FROM Case WHERE Id = :objCase.Id];
		if(OrganizationUtilities.canSendEmails()){
			System.assert(list_Case.size() > 0);
		}

		PageReference pageRef = Page.TransitionToNotesOnBODetail;
		pageRef.getParameters().put('id', String.valueOf(list_BO[0].Id));
		Test.setCurrentPage(pageRef);

		test.startTest();
		ApexPages.StandardController sc = new ApexPages.StandardController(list_BO[0]);
		TransitionToNotesOnBODetailExt extension = new TransitionToNotesOnBODetailExt(sc);
		System.assert(extension.blnShowConfirmationEmailBtn == true);

		extension.invokeConfirmationEmail();
		if(OrganizationUtilities.canSendEmails()){
			List<EmailMessage> list_EmailMessage = [SELECT Id, HtmlBody FROM EmailMessage WHERE ParentId = :objCase.Id];
			System.assert(list_EmailMessage.size() > 0);

			if (list_EmailMessage.size() > 0) {
				System.assert(list_EmailMessage[0].HtmlBody.contains(list_Case[0].Renewal_Survey_URL__c));
			}
		}

		test.stopTest();
	}

	public static void createTTFAndTTIARecord() {
		//Create CO records
		Carrier_Order__c objCO = TestUtility.CarrierOrder();
		Benefit_Order__c objBO = new Benefit_Order__c();
		List<Benefit_Order__c> list_BO = [SELECT Id, Name, Opportunity__c, Opportunity__r.AccountId FROM Benefit_Order__c WHERE Id = :objCO.Benefit_Order__c];
		if (list_BO.size() > 0) {
			objBO = list_BO[0];
		}

		//Create "Master Company Level Documents" records;
		Master_Company_Level_Documents__c objMasterCompany = new Master_Company_Level_Documents__c(Status__c = 'Active', Name = '');
		insert objMasterCompany;

		//Create Transition to Fulfillment Test records
		Id idTTFBorRecType = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Benefits Change');
		Transition_to_Fulfillment__c objTTF = new Transition_to_Fulfillment__c(
			Opportunity__c = objBO.Opportunity__c,
			recordtypeid = idTTFBorRecType,
			Existing_MDVLiDi_Coverage__c = 'Y',
			Do_they_have_affiliates__c = false
		);
		objTTF.Parent_Transition_to_fulfillment__c = null;
		insert objTTF;

		//Create Company Level Documents Test records
		List<Company_Level_Documents__c> list_CompanyLevelDoc = new List<Company_Level_Documents__c>();
		list_CompanyLevelDoc.add(new Company_Level_Documents__c(Benefit_Order__c = objBO.id));
		list_CompanyLevelDoc.add(new Company_Level_Documents__c(Benefit_Order__c = objBO.id, Name = 'test'));
		insert list_CompanyLevelDoc;

		//Create QA Sheet Test records
		Id idQASheetRecordType = cache.getRecordTypeId('QA_Sheet__c', 'Benefit New Plan');
		QA_Sheet__c objQASheet = new QA_Sheet__c(
			RecordTypeId = idQASheetRecordType,
			Benefit_Order__c = objBO.id,
			SIC_Code__c = 'test',
			BAA_Signed_by__c = 'test',
			BSA_Signed__c = 'Yes'
		);
		insert objQASheet;

		//Create QA Lines Of Coverage Test records
		QA_Lines_Of_Coverage__c objQALine = new QA_Lines_Of_Coverage__c(Lines_Of_Coverage__c = 'Medical', QA_Sheet__c = objQASheet.Id, Color_Code__c = 'Benefits_selected_Carrier__c', S_No__c = 0);
		insert objQALine;
	}

	public static void createBenefitNewPlanCaseRecord() {
		//Create new Account
		Account objAcc = new Account(Name = 'test acc1', ZP_Company_Id__c = '100989001');
		insert objAcc;

		//Create Benefits New Plan Opportunity.
		Opportunity objOpp = new Opportunity(RecordTypeId = Cache.getRecordTypeId('Opportunity', 'Benefits New Plan'));
		objOpp.AccountId = objAcc.Id;
		objOpp.StageName = 'SAL';
		objOpp.Name = 'Test New Plan Opportunity';
		objOpp.CloseDate = System.Today();
		insert objOpp;

		//Create Contact.
		List<Contact> list_Contact = new List<Contact>();
		list_Contact.add(new Contact(FirstName = 'Neha 1', LastName = 'Test August 6 ', Email = 'neha.dabastest+1@lirik.io', AccountId = objOpp.AccountId));
		insert list_Contact;

		ContactTriggerHelper.skipTrigger = true;
		//Create New Contact records
		Id idRT = ContactUtil.COMPANY_CONTACT_RT_ID;
		List<Contact> list_NewContact = new List<Contact>();
		list_NewContact.add(new Contact(FirstName = 'Test', LastName = 'User01', recordTypeId = idRT, AccountId = objOpp.AccountId, Email = 'testuser01@gusto.com', Zp_User_Id__c = '75001'));
		list_NewContact.add(new Contact(FirstName = 'Test', LastName = 'User02', recordTypeId = idRT, AccountId = objOpp.AccountId, Email = 'testuser02@gusto.com', Zp_User_Id__c = '75002'));
		list_NewContact.add(new Contact(FirstName = 'Test', LastName = 'User03', recordTypeId = idRT, AccountId = objOpp.AccountId, Email = 'testuser03@gusto.com', Zp_User_Id__c = '75003'));
		insert list_NewContact;

		//Create Opportunity Contact Role.
		List<OpportunityContactRole> list_OppContactRole = new List<OpportunityContactRole>();
		list_OppContactRole.add(new OpportunityContactRole(ContactId = list_NewContact[0].Id, OpportunityId = objOpp.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin'));
		list_OppContactRole.add(new OpportunityContactRole(ContactId = list_NewContact[1].Id, OpportunityId = objOpp.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin'));
		list_OppContactRole.add(new OpportunityContactRole(ContactId = list_NewContact[2].Id, OpportunityId = objOpp.Id, IsPrimary = true, Check_Additional_POC__c = true, Role = 'Benefits Admin'));
		insert list_OppContactRole;
		ContactTriggerHelper.skipTrigger = false;

		//Create Benefit Order
		Benefit_Order__c objBONewPlan = new Benefit_Order__c();
		objBONewPlan.Opportunity__c = objOpp.Id;
		objBONewPlan.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
		objBONewPlan.Open_Enrollment_Start_Date__c = System.today().addDays(-3);
		objBONewPlan.Open_Enrollment_End_Date__c = System.today().addDays(-1);
		objBONewPlan.Final_Extension_Date__c = System.today();
		objBONewPlan.OwnerId = userInfo.getUserId();
		objBONewPlan.Order_Status__c = 'Ready for Qualification';
		insert objBONewPlan;

		//Create Carrier record
		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Test Carrier').setUniqueName('Test Carrier').setId('4536').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setPartnerType('TAdA').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Test Carrier 1').setUniqueName('Test Carrier 1').setId('4537').build());
		insert list_Carrier;

		//Create Email Macro
		List<Email_Macro__c> list_EmailMacro = new List<Email_Macro__c>();
		list_EmailMacro.add(new Email_Macro__c(Body__c = '<p>' + strHSAEmailMacroBody + '</p>', Benefit_Type__c = 'HSA'));
		list_EmailMacro.add(new Email_Macro__c(Body__c = '<p>' + strFSAEmailMacroBody + '</p>', Benefit_Type__c = 'FSA'));
		list_EmailMacro.add(new Email_Macro__c(Carrier__c = list_Carrier[0].Id, Body__c = '<p>Testing content</p>'));
		insert list_EmailMacro;

		//Create Carrier Order
		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		list_CO.add(
			new Carrier_Order__c(
				Order_Assignment__c = 'Carrier Switch',
				Benefit_Order__c = objBONewPlan.Id,
				Implementation_Stage__c = 'Ready For Qualification',
				Carrier__c = list_Carrier[0].Id,
				Group_Number__c = '1234'
			)
		);

		list_CO.add(
			new Carrier_Order__c(
				Order_Assignment__c = 'Carrier Switch',
				Benefit_Order__c = objBONewPlan.Id,
				Implementation_Stage__c = 'Ready For Qualification',
				Carrier__c = list_Carrier[1].Id,
				Benefit_Types__c = 'HSA;FSA',
				Group_Number__c = '3432'
			)
		);

		list_CO.add(
			new Carrier_Order__c(
				Order_Assignment__c = 'Carrier Switch',
				Benefit_Order__c = objBONewPlan.Id,
				Implementation_Stage__c = 'Ready For Qualification',
				Carrier__c = list_Carrier[2].Id,
				Group_Number__c = '1235'
			)
		);

		insert list_CO;
	}

	public static void skipTrigger(Boolean blnFlag) {
		ContactTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.skipTrigger = blnFlag;
	}
}