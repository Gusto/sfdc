/*
 * @name			CreateWarningMessagesLwcTest
 * @author			Deepika Saini
 * @date			28/02/2025
 * @description		Test Confitmation Coverage Email Warning Messages.
 */

@isTest
public class CreateWarningMessagesLwcTest {
	/**
	 * @Author      : Deepika Saini
	 * @Description : Create the Setup of Test Data
	 * @Parm        : null
	 * @Return      : null
	 **/
	@testSetup
	static void setup() {
		createBenefitNewPlanCaseRecord();
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Creating a new Instance of Account, Opportunity, Contact, Benefit_Order__c..
	 * @Parm        : null
	 * @Return      : null
	 **/
	public static void createBenefitNewPlanCaseRecord() {
		//Create new Account
		CreateWarningMessagesLwcTest.skipTrigger(true);
		Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('test acc1').setZPCompanyId('100989011').build();
		insert objAcc;

		//Create Benefits New Plan Opportunity.
		Opportunity objOpp = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test New Plan Opportunity')
			.setAccountId(objAcc.Id)
			.setStage('SAL')
			.setCloseDate(System.today())
			.build();
		insert objOpp;

		//Create Contact.
		ContactTriggerHelper.skipTrigger = true;
		List<Contact> list_Contact = new List<Contact>();
		list_Contact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objOpp.AccountId)
				.setFirstName('Neha 1')
				.setLastName('Test August 6 ')
				.setEmail('neha.dabastest+1@lirik.io')
				.build()
		);
		insert list_Contact;

		//Create New Contact records
		List<Contact> list_NewContact = new List<Contact>();
		list_NewContact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objOpp.AccountId)
				.setFirstName('Test')
				.setLastName('User01')
				.setEmail('testuser01@gusto.com')
				.setZPUserId('75001')
				.build()
		);
		list_NewContact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objOpp.AccountId)
				.setFirstName('Test')
				.setLastName('User02')
				.setEmail('testuser02@gusto.com')
				.setZPUserId('75002')
				.build()
		);
		list_NewContact.add(
			new TestDataFactory.ContactBuilder()
				.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
				.setAccountId(objOpp.AccountId)
				.setFirstName('Test')
				.setLastName('User03')
				.setEmail('testuser03@gusto.com')
				.setZPUserId('75003')
				.build()
		);
		insert list_NewContact;

		ContactTriggerHelper.skipTrigger = false;

		//Create Benefit Order
		Benefit_Order__c objBONewPlan = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.NEW_PLAN_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setAccount(objOpp.AccountId)
			.setOpp(objOpp.Id)
			.setOpenEnrollmentStartDate(System.today().addDays(-3))
			.setOpenEnrollmentEndDate(System.today().addDays(-1))
			.setFinalExtensionDate(System.today())
			.setCoverageEffectiveDate(System.today())
			.setSubmissionDeadline(System.today())
			.setOwnerID(UserInfo.getUserId())
			.setStatus('Ready for Qualification')
			.build();
		insert objBONewPlan;

		//Create Carrier record
		List<Carrier__c> list_Carrier = new List<Carrier__c>();
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Test Carrier').setUniqueName('Test Carrier').setId('4536').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Alegeus').setUniqueName('Alegeus').setPartnerType('TAdA').build());
		list_Carrier.add(new TestDataFactory.CarrierBuilder().setName('Test Carrier 1').setUniqueName('Test Carrier 1').setId('4537').build());
		insert list_Carrier;

		//Create Carrier Order
		List<Carrier_Order__c> list_CO = new List<Carrier_Order__c>();
		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
				.setOrderAssignment('Carrier Switch')
				.setBenefitOrder(objBONewPlan.Id)
				.setImplementationStage('Ready For Qualification')
				.setGroupNumber('1234')
				.setCarrier(list_Carrier[0].Id)
				.build()
		);

		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
				.setOrderAssignment('Carrier Switch')
				.setBenefitOrder(objBONewPlan.Id)
				.setImplementationStage('Ready For Qualification')
				.setGroupNumber('3432')
				.setCarrier(list_Carrier[1].Id)
				.setBenefitTypes('HSA;FSA')
				.build()
		);

		list_CO.add(
			new TestDataFactory.CarrierOrderBuilder()
				.setRecordTypeId(CarrierOrderUtil.RECTYPE_NEW_PLAN)
				.setOrderAssignment('Carrier Switch')
				.setBenefitOrder(objBONewPlan.Id)
				.setImplementationStage('Ready For Qualification')
				.setGroupNumber('1235')
				.setCarrier(list_Carrier[2].Id)
				.build()
		);

		insert list_CO;

		//Create QA Sheet Test records
		QA_Sheet__c objQASheet = new TestDataFactory.QASheetBuilder()
			.setBenefitOrderId(objBONewPlan.Id)
			.setFederalCobraState('Federal')
			.setSICCodeSupportedByAllCarriers('Yes')
			.setSICCode('test')
			.setBAASigned('Yes')
			.setBAASignedBy('test')
			.setBSASigned('Yes')
			.setBSASignedBy('test')
			.setRecordTypeId(QASheetHelper.QAS_BEN_NP_RT_ID)
			.build();
		insert objQASheet;

		//Create QA Lines Of Coverage Test records
		QA_Lines_Of_Coverage__c objQALine = new TestDataFactory.QALineOfCoverageBuilder()
			.setQASheetId(objQASheet.Id)
			.setLinesOfCoverage('Medical')
			.setColorCode('Benefits_selected_Carrier__c')
			.setSNO(0)
			.build();
		insert objQALine;

		CreateWarningMessagesLwcTest.skipTrigger(false);
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Test Benefis Order Confitmation Coverage Email Warning Messages.
	 * @Parm        : null
	 * @Return      : null
	 **/
	@isTest
	static void testBOWarningMessages() {
		List<Benefit_Order__c> list_BO = [SELECT Id, Opportunity__c, Opportunity__r.AccountId FROM Benefit_Order__c WHERE Opportunity__r.Name = 'Test New Plan Opportunity'];
		List<Contact> list_Contact = [SELECT Id, AccountId FROM Contact LIMIT 1];

		//Update BO order status
		CreateWarningMessagesLwcTest.skipTrigger(true);

		list_BO[0].Order_Status__c = BenefitOrderUtil.STATUS_APPROVED;
		update list_BO[0];

		//Update Carrier Order
		List<Carrier_Order__c> list_CO = [SELECT Id, Implementation_Stage__c FROM Carrier_Order__c WHERE Benefit_Order__c = :list_BO[0].Id];
		for (Carrier_Order__c objCO : list_CO) {
			objCO.Implementation_Stage__c = BenefitOrderUtil.STATUS_APPROVED;
		}
		update list_CO;
		CreateWarningMessagesLwcTest.skipTrigger(false);

		//Create new case record having record type as : Benefits Renewal Case
		Id idRenewal = CaseUtils.RECTYPE_RENEWAL;
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

		objCase.Carrier_Order__c = null;
		update objCase;

		List<Case> list_Case = [SELECT Id, Renewal_Survey_URL__c, NP_Survey_URL__c FROM Case WHERE Id = :objCase.Id];
		if (OrganizationUtilities.canSendEmails()) {
			System.assert(list_Case.size() > 0);
		}

		test.startTest();
		CreateWarningMessagesLwc.WarningMessagesWrapper objWrapper = CreateWarningMessagesLwc.showEmailWarningMessages(list_BO[0].Id, BenefitOrderUtil.Benefit_Order);
		System.assertEquals(objWrapper.blnIsSuccess, true);

		Id idRenewalRecord = BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID;
		list_BO[0].RecordTypeId = idRenewalRecord;
		list_BO[0].Order_Status__c = BenefitOrderUtil.STATUS_APPROVED;
		update list_BO[0];

		CreateWarningMessagesLwc.WarningMessagesWrapper objWrapper1 = CreateWarningMessagesLwc.showEmailWarningMessages(list_BO[0].Id, BenefitOrderUtil.Benefit_Order);
		System.assertEquals(objWrapper1.blnIsSuccess, true);

		Id idBO = null;
		CreateWarningMessagesLwc.WarningMessagesWrapper objWrapper2 = CreateWarningMessagesLwc.showEmailWarningMessages(idBO, BenefitOrderUtil.Benefit_Order);
		System.assertEquals(objWrapper2.blnIsSuccess, false);

		test.stopTest();
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Skip Trigger to avoid DML Exception
	 * @Parm        : Boolean Flag
	 * @Return      : null
	 **/
	public static void skipTrigger(Boolean blnFlag) {
		ContactTriggerHelper.skipTrigger = blnFlag;
		AccountTriggerHelper.skipTrigger = blnFlag;
		OpportunityTriggerHelper.skipTrigger = blnFlag;
		CaseTriggerHelper.skipTrigger = blnFlag;
		BenefitOrderHelper.skipTrigger = blnFlag;
		CarrierOrderTriggerHelper.skipTrigger = blnFlag;
	}
}