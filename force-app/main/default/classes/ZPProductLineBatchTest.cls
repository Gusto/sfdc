/**
 * @name         ZPProductLineBatchTest
 * @author       Anurag Gautam
 * @date         06/27/2023
 * @description  unit testing for ZP product line batch.
 * @see ZPProductLineBatchTest
 * @see ZPProductLineBatch
 **/
@isTest
public class ZPProductLineBatchTest {
	/**
	 * @author      Anurag Gautam
	 * @description Sets common data for all the test methods
	 **/
	@testSetup
	static void testData() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder().setZPProductLineBatchSize(10).build();
		insert objConfigSettings;

		Account objCompanyAccount = new TestDataFactory.AccountBuilder().setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setName('Test ZP Company 2').setZPCompanyId('765665766').build();

		AccountTriggerHelper.skipTrigger = true;
		insert objCompanyAccount;
		AccountTriggerHelper.skipTrigger = false;

		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665766')
			.setName('Test ZP Company 2')
			.setProcessingState(IntegrationUtils.MANUAL_ENQUEUE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setJoinedDate(System.today())
			.build();

		ZP_Company__c objZPCompany1 = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId('765665768')
			.setName('Test ZP Company 3')
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setBenefitsEffectiveDate(System.today())
			.setAnchorPayDate(System.today())
			.setPartnerProgramCompanyDataId('12131323')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.setManagingAccountingFirmId('Reseller Account 1')
			.build();
		List<ZP_Company__c> list_Companies = new List<ZP_Company__c>{ objZPCompany, objZPCompany1 };
		insert list_Companies;

		// Start setting up data and create pricebook and pricebook entries
		// Create a new pricebook
		List<Pricebook2> list_PaymentPlans = new List<Pricebook2>();
		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$80 Base, $12: 1+').setActive().setProductTier('Plus').setPricingPlanId('10').setProductLineId('1').build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$40 Base, $6: 1+').setActive().setProductTier('Simple').setPricingPlanId('11').setProductLineId('2').build());

		list_PaymentPlans.add(new TestDataFactory.PriceBookBuilder().setName('$39 Base, $6: 1+').setActive().setProductTier('Core').setPricingPlanId('12').setProductLineId('3').build());
		insert list_PaymentPlans;

		// Create new products
		List<Product2> list_Products = new List<Product2>();
		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('Priority Support and HR Services - Contractor')
				.setFamily('Company')
				.setProductCategory('Priority Support and HR Services')
				.setPricingPlanId('201')
				.setProductLineId('101')
				.build()
		);

		list_Products.add(
			new TestDataFactory.ProductBuilder()
				.setName('International Contractor Add-On')
				.setFamily('Employee')
				.setProductCategory('International Contractor Service')
				.setPricingPlanId('200')
				.setProductLineId('100')
				.build()
		);

		insert list_Products;

		// Create pricebook entries
		List<PricebookEntry> list_Entries = new List<PricebookEntry>();

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(Test.getStandardPriceBookId()).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[0].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[0].Id).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[1].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[1].Id).setIsActive(true).build());

		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[0].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[2].Id).setIsActive(true).build());
		list_Entries.add(new TestDataFactory.PricebookEntryBuilder().setProductId(list_Products[1].Id).setUnitPrice(5).setPriceBookId(list_PaymentPlans[2].Id).setIsActive(true).build());

		insert list_Entries;
	}

	/**
	 * @author       Anurag Gautam
	 * @description  executing batch job when company wasn't exist earlier and then updated with current company id with skip trigger. So that batch job can pick the record.
	 **/
	@isTest
	static void executeBatchJobWhenErrorState() {
		ZPProductLineTriggerHelper.blnQueue = true;
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('1111')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('11')
			.setProductLineID('2')
			.setStatus('active')
			.setStartDate(System.now().addDays(-1))
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;

		Test.startTest();

		ZP_Product_Line__c objZPProductLineAssertBefore = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssertBefore.Message__c, ZPProductLineUtil.ERR_MSG_COMPANY_ID_DOES_NOT_EXIST, 'Company Id is not present.');

		objZPProductLine.Company_ID__c = '765665766';

		ZPProductLineTriggerHelper.skipTrigger = true;
		update objZPProductLine;
		ZPProductLineTriggerHelper.skipTrigger = false;

		String CRON_EXP = '0 0 * * * ?';
		ZPProductLineScheduler objScheduler = new ZPProductLineScheduler();
		System.schedule('ZPProductLineSchedulerTest', CRON_EXP, objScheduler);

		// Directly call Scheduler's execute method
		objScheduler.execute(null);

		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssertAfter = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssertAfter.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Simple', 'Tier is Simple.');
	}

	/**
	 * @author       Anurag Gautam
	 * @description  executing batch job when effective date is in future and then updated to current date with skip trigger. So that batch job can pick the record.
	 **/
	@isTest
	static void executeBatchJobWhenBacklogState() {
		ZPProductLineTriggerHelper.blnQueue = true;
		ZP_Product_Line__c objZPProductLine = new TestDataFactory.ZPProductLineBuilder()
			.setZPCompanyId('765665766')
			.setType('tier_base')
			.setParentID('')
			.setPricingPlanID('10')
			.setProductLineID('1')
			.setStatus('active')
			.setStartDate(System.now().addDays(4))
			.setCompanyBaseId('44444')
			.build();

		insert objZPProductLine;

		Test.startTest();

		ZP_Product_Line__c objZPProductLineAssertBefore = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssertBefore.Message__c, ZPProductLineUtil.ERR_MSG_FUTURE_START_DATE, 'Start date is in future.');

		objZPProductLine.Start_Date__c = System.now();

		ZPProductLineTriggerHelper.skipTrigger = true;
		update objZPProductLine;
		ZPProductLineTriggerHelper.skipTrigger = false;

		String CRON_EXP = '0 0 * * * ?';
		ZPProductLineScheduler objScheduler = new ZPProductLineScheduler();
		System.schedule('ZPProductLineSchedulerTest', CRON_EXP, objScheduler);

		// Directly call Scheduler's execute method
		objScheduler.execute(null);
		Test.stopTest();

		ZP_Product_Line__c objZPProductLineAssertAfter = [SELECT Id, Processing_State__c, Message__c FROM ZP_Product_Line__c WHERE Id = :objZPProductLine.Id LIMIT 1];
		System.assertEquals(objZPProductLineAssertAfter.Message__c, ZPProductLineUtil.SUCCESS_MESSAGE, 'Tier has been changed.');

		Account objAccount = [SELECT Id, Tier__c FROM Account WHERE ZP_Company_ID__c = '765665766' LIMIT 1];
		System.assertEquals(objAccount.Tier__c, 'Plus', 'Tier is plus.');
	}
}