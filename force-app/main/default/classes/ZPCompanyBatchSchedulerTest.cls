/**
 * @name         : ZPCompanyBatchSchedulerTest
 * @author       : Praveen Sethu
 * @date         : 11-19-2021
 * @description  : Validate ZP Company Batch runs and converts Lead
 * @test classes : NA
 **/
@isTest
public class ZPCompanyBatchSchedulerTest {
	@testSetup
	static void setupTestData() {
		Configuration_Settings__c objConfigSettings = new TestDataFactory.ConfigurationSettingsBuilder()
			.setZPCompanyBatchSize(10)
			.setNightBatchSize(25)
			.setJobThreshold(1)
			.setTotalItemsRemaining(200)
			.build();

		insert objConfigSettings;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('Company1')
			.setLastName('Lead LName1')
			.setEmail('zpcompanylead1@zpcompany.com')
			.setPhone('8976567823')
			.setCompany('Test Company Name 1')
			.setOwnerId(UserInfo.getUserId())
			.setLeadSource(LeadUtil.LEADSOURCE_LEGALZOOM)
			.setZPCompanyID('companyId1')
			.build();

		LeadTriggerHelper.skipTrigger = true;
		insert objLead;
		LeadTriggerHelper.skipTrigger = false;

		// Create ZP Company and put in Queued Status - Skip Trigger
		// Validate ZP Company Batch runs and converts Leads
		ZPCompanyTriggerHelper.skipTrigger = true;
		ZP_Company__c objZPCompany = new TestDataFactory.ZPCompanyBuilder()
			.setZPCompanyId(objLead.ZP_Company_ID__c)
			.setName('Test ZP Company 1')
			.setCreatedByEmail(objLead.Email)
			.setProcessingState(IntegrationUtils.QUEUED_STATE)
			.setCreatedAtDate(System.today())
			.setCompanyLeadNumberofEmployees(50)
			.setPartnerProgramCompanyDataId('PPCD1')
			.setPartnerBilling(ZPCompanyUtil.BILLING_PARTNER_BILLED)
			.build();
		objZPCompany.Is_Changed__c = true;
		insert objZPCompany;
		ZPCompanyTriggerHelper.skipTrigger = false;
	}
	/**
	 * @Author      : Praveen Sethu
	 * @Description : Validate ZP Company Batch runs and converts Lead
	 * @Parm        : N/A
	 * @Return      : N/A
	 **/
	@isTest
	static void testBatchExecution() {
		Test.startTest();
		ZPCompanyBatchScheduler clsScehule = new ZPCompanyBatchScheduler();
		clsScehule.execute(null);
		Test.stopTest();

		// Assert if Lead is Conveted and Account, Oppty are created
		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Email = 'zpcompanylead1@zpcompany.com'];

		System.assertEquals(true, objLeadAssert.IsConverted);
		System.assertNotEquals(null, objLeadAssert.ConvertedAccountId);
		System.assertNotEquals(null, objLeadAssert.ConvertedOpportunityId);
	}
}