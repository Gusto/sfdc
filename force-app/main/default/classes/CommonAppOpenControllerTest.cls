/**
 * @description  This class is used for testing CommonAppOpenController that returns app urls
 * based on object type for lwc calling it to open the url.
 * @author       Aviinandaan Dutta
 * @date         03-29-2023
 * @see          CommonAppOpenController
 **/
@isTest
public with sharing class CommonAppOpenControllerTest {
	private static final String SUCCESS = 'Url returned successfully';
	private static final String FAILURE = 'Failed to return Url. App not configured OR company id missing';

	/**
	 * @date         03-29-2023
	 * @description Setup setting records
	 **/
	@testSetup
	static void setup() {
		List<App_URL_Map__c> list_URLMaps = new List<App_URL_Map__c>();
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Hippo', Environment__c = 'Dev', URL__c = 'https://hippo.gusto-staging.com'));
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Hippo', Environment__c = 'Prod', URL__c = 'https://hippo.gusto.com'));
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Gdrive', Environment__c = 'Dev', URL__c = 'https://drive.google.com/drive/search'));
		list_URLMaps.add(new App_URL_Map__c(App_Name__c = 'Gdrive', Environment__c = 'Prod', URL__c = 'https://drive.google.com/drive/search'));
		insert list_URLMaps;
	}

	/**
	 * @date         03-29-2023
	 * @description Test if url is returned if triggering object is benefit/carrier order
	 **/
	@isTest
	static void testBenfitAndCarrierOrder() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		CarrierOrderTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('97867').build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Test Company Oppty')
			.setAccountId(objAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();
		insert objOppty;

		Carrier__c objCarrier = new TestDataFactory.CarrierBuilder().setName('Test Carrier').setState('AL').build();
		insert objCarrier;

		Test.startTest();
		Benefit_Order__c objBenefitOrder = new TestDataFactory.BenefitOrderBuilder()
			.setRecordType(BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID)
			.setName('Test Benefit Order')
			.setOpp(objOppty.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objBenefitOrder;
		Carrier_Order__c objCarrierOrder = new TestDataFactory.CarrierOrderBuilder()
			.setRecordTypeId(CarrierOrderUtil.REC_TYPE_BOR)
			.setName('Test Carrier Order')
			.setBenefitOrder(objBenefitOrder.Id)
			.setCarrier(objCarrier.Id)
			.setOwnerID(UserInfo.getUserId())
			.build();
		insert objCarrierOrder;
		Test.stopTest();

		CommonAppOpenController.ResultWrapper objResultWrapperBenefitOrder = CommonAppOpenController.getUrl(objBenefitOrder.Id, 'Hippo', '');
		System.assertEquals(true, objResultWrapperBenefitOrder.blnSuccess, SUCCESS);
		CommonAppOpenController.ResultWrapper objResultWrapperCarrierOrder = CommonAppOpenController.getUrl(objCarrierOrder.Id, 'Hippo', '');
		System.assertEquals(true, objResultWrapperCarrierOrder.blnSuccess, SUCCESS);
	}

	/**
	 * @date         03-29-2023
	 * @description Test if failure is returned if company id not found
	 **/
	@isTest
	static void testNoCompanyId() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Test Company Oppty')
			.setAccountId(objAccount.Id)
			.setStage('MQL')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		insert objOppty;
		Test.stopTest();

		CommonAppOpenController.ResultWrapper objResultWrapperOppty = CommonAppOpenController.getUrl(objOppty.Id, 'Hippo', '');
		System.assertEquals(false, objResultWrapperOppty.blnSuccess, FAILURE);

		CommonAppOpenController.ResultWrapper objResultWrapperOpptyHippoQASheet = CommonAppOpenController.getUrl(objOppty.Id, 'Hippo', 'qa_sheet');
		System.assertEquals(false, objResultWrapperOpptyHippoQASheet.blnSuccess, FAILURE);
	}

	/**
	 * @date         03-29-2023
	 * @description Test if url is returned if triggering object is opportunity
	 **/
	@isTest
	static void testOpportunity() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('97867').build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.ACQUISITION_OPPTY_RT_ID)
			.setName('Test Company Oppty')
			.setAccountId(objAccount.Id)
			.setStage('MQL')
			.setSourceID('hawaiian_ice-new_plans_application-94297')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		insert objOppty;
		Test.stopTest();

		CommonAppOpenController.ResultWrapper objResultWrapperOppty = CommonAppOpenController.getUrl(objOppty.Id, 'Gdrive', '');
		System.assertEquals(true, objResultWrapperOppty.blnSuccess, SUCCESS);

		CommonAppOpenController.ResultWrapper objResultWrapperOpptyHippoQASheet = CommonAppOpenController.getUrl(objOppty.Id, 'Hippo', 'qa_sheet');
		System.assertEquals(true, objResultWrapperOpptyHippoQASheet.blnSuccess, SUCCESS);
	}

	@isTest
	static void testQASheetLinkWithNewPlanOpportunity() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;

		Account objAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Company Account').setZPCompanyId('97867').build();
		insert objAccount;

		Opportunity objOppty = new TestDataFactory.OpportunityBuilder()
			.setRecordTypeId(OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
			.setName('Test BENEFITS_NEW_PLAN_OPPTY_RT_ID Oppty')
			.setAccountId(objAccount.Id)
			.setStage('MQL')
			.setSourceID('hawaiian_ice-new_plans_application-94297')
			.setCloseDate(System.today())
			.build();

		Test.startTest();
		insert objOppty;
		Test.stopTest();
	
		CommonAppOpenController.ResultWrapper objResultWrapperOpptyHippoQASheet = CommonAppOpenController.getUrl(objOppty.Id, 'Hippo', 'qa_sheet');
		System.assertEquals(true, objResultWrapperOpptyHippoQASheet.blnSuccess, SUCCESS);
		String strCurrentEnvironment = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox ? '-staging' : '';
		System.assertEquals('https://hippo.gusto' + strCurrentEnvironment + '.com/companies/97867/new_plans_applications/94297/qa_sheet', objResultWrapperOpptyHippoQASheet.strUrl, SUCCESS);
	}
}