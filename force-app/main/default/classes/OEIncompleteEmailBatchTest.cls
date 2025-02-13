/**
* @name         OEIncompleteEmailBatchTest
* @author       Neha Dabas
* @date         August 18, 2020
* @description  Test class for OEIncompleteEmailBatch
* @revisions    Date ------------ Name ------------ Comments       
**/
@isTest
public class OEIncompleteEmailBatchTest {
    /**
    * @Author      : Bhagat Singh
    * @Description : Test Class setup method
    **/
    @testsetup
    static void setupData() {
        createTestData();
    }

    /**
    * @Author      : Bhagat Singh
    * @Description : Create test data for batch class.
    **/
    public static void createTestData(){
        Utils.skipTrigger(true);
        Account objAcc = new TestDataFactory.AccountBuilder().setRecordTypeId('Company').setZPCompanyID('100989001').setName('Test Account 1').build();
		insert objAcc;
        
        List<Opportunity> list_Opps = new List<Opportunity>();
        list_Opps.add(new TestDataFactory.OpportunityBuilder()
        .setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
        .setName('Benefits New Plan')
        .setAccountId(objAcc.Id)
        .setNumberOfEE(5)
        .setId('HIBORTRANSFER6582')
        .setBenefitsState('CA')
        .setStage('SAL')
        .setCloseDate(System.today().addDays(30))
        .setOrderGenerated(false)
        .build());
        list_Opps.add(new TestDataFactory.OpportunityBuilder()
        .setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
        .setName('Benefits Renewal')
        .setAccountId(objAcc.Id)
        .setNumberOfEE(5)
        .setId('HIBORTRANSFER6583')
        .setBenefitsState('CA')
        .setStage('SAL')
        .setCloseDate(System.today().addDays(30))
        .setOrderGenerated(false)
        .build());
        insert list_Opps;

        List<Contact> list_Contact = new List<Contact>();
        list_Contact.add(new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAcc.Id)
			.setFirstName('Morgan')
			.setLastName('Brown')
			.setEmail('mlhartman892323@gmail.com')
			.setEmployeeId('7757869431943859')
			.build());
        list_Contact.add(new TestDataFactory.ContactBuilder()
			.setRecordTypeId(ContactUtil.COMPANY_CONTACT_RT_ID)
			.setAccountId(objAcc.Id)
			.setFirstName('Morgan')
			.setLastName('Brown')
			.setEmail('mlhartman892324@gmail.com')
			.setEmployeeId('7757869431943860')
			.build());
        insert list_Contact;

        List<Benefit_Order__c> list_BenefitOrder = new List<Benefit_Order__c>();
		list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'New Plan'))
				.setName('Test Benefit New Plan')
				.setAccount(objAcc.id)
				.setOpp(list_Opps[0].Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('OE Extended')
				.setOpenEnrollmentStartDate(System.today().addDays(-3))
				.setOpenEnrollmentEndDate(System.today().addDays(-1))
				.setFinalExtensionDate(System.today().addDays(2))
				.build()
		);

        list_BenefitOrder.add(
			new TestDataFactory.BenefitOrderBuilder()
				.setRecordType(Cache.getRecordTypeId('Benefit_Order__c', 'Renewal'))
				.setName('Test Benefit Renewal')
				.setAccount(objAcc.id)
				.setOpp(list_Opps[1].Id)
				.setCoverageEffectiveDate(System.today())
				.setOwnerID(UserInfo.getUserId())
				.setSubmissionDeadline(System.today())
				.setStatus('OE')
				.setOpenEnrollmentStartDate(System.today().addDays(-3))
				.setOpenEnrollmentEndDate(System.today().addDays(-1))
				.setFinalExtensionDate(System.today().addDays(2))
				.build()
		);
		insert list_BenefitOrder;

		List<Case> list_Case = new List<Case>();
        list_Case.add(new TestDataFactory.CaseBuilder()
			.setAccountId(objAcc.Id)
			.setRecordTypeId('Benefits New Plan Case')
			.setSubject('Test User Role Changes')
            .setContactId(list_Contact[0].Id)
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test2@gusto.com')
			.setDescription('Test User Role Change')
            .setBenefitOrder(list_BenefitOrder[0].Id)
            .setOpportunity(list_Opps[0].Id)
            .setIntegrationId('hippo-Benefits_New_Plan-'+list_Opps[0].Id)
			.build());
        list_Case.add(new TestDataFactory.CaseBuilder()
			.setAccountId(objAcc.Id)
			.setRecordTypeId('Benefits Renewal Case')
			.setSubject('Test User Role Changes')
            .setContactId(list_Contact[1].Id)
			.setOrigin('Email')
			.setStatus('New')
			.setSuppliedEmail('test2@gusto.com')
			.setDescription('Test User Role Change')
            .setBenefitOrder(list_BenefitOrder[0].Id)
            .setOpportunity(list_Opps[0].Id)
            .setIntegrationId('hippo-Benefits_Renewal-'+list_Opps[1].Id)
			.build());
        insert list_Case;
    }

    /**
    * @Author      : Bhagat Singh
    * @Description : Validate OEIncompleteEmailBatch.
    **/
    @isTest
    static void testReminderEmailBatch() {
        Test.startTest();
        Database.executeBatch(new OEIncompleteEmailBatch());

        Test.stopTest();
    }
}