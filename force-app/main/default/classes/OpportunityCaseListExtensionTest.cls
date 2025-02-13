/**
 * @description  Tests if cases related to lead and conveted opportunity is queried
 * @author       Praveen Sethu
 * @date         01-05-2022
 * @see          NA
 * @see          NA
 **/
@isTest
public class OpportunityCaseListExtensionTest {
	/**
	 * @description Tests if cases related to lead and conveted opportunity is queried
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	@isTest
	public static void testGetCases() {
		// Skip all triggers
		LeadTriggerHelper.skipTrigger = true;
		OpportunityTriggerHelper.skipTrigger = true;
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		CaseTriggerHelper.skipTrigger = true;

		Lead objLead = new TestDataFactory.LeadBuilder()
			.setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
			.setFirstName('FName')
			.setLastName('LName')
			.setEmail('newcompanylead@cmplead.com')
			.setPhone('123456789')
			.setCompany('Company Lead')
			.setZPCompanyID('112121')
			.setLeadSource('Gusto')
			.setStatus(LeadUtil.LEAD_STATUS_MQL)
			.build();
		insert objLead;

		// Convert Lead
		LeadConversion.ConversionResult conversionResult = LeadConversion.convert(new List<Lead>{ objLead });

		Lead objLeadAssert = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :objLead.Id];
		System.assertEquals(true, objLeadAssert.IsConverted);

		Case objLeadCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Ops')
			.setType('Payroll Care')
			.setSubject('Test Payroll Care Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test.test1@gmail.com')
			.setDescription('Test Payroll Care Case')
			.build();
		objLeadCase.Lead__c = objLead.Id;

		Case objAccountCase = new TestDataFactory.CaseBuilder()
			.setRecordTypeId('Tax Ops')
			.setType('Payroll Care')
			.setSubject('Test Payroll Care Case')
			.setOrigin('Email')
			.setDirection('Inbound')
			.setStatus('New')
			.setSuppliedEmail('test.test2@gmail.com')
			.setDescription('Test Payroll Care Case')
			.build();
		objAccountCase.AccountId = objLeadAssert.ConvertedAccountId;

		List<Case> list_Cases = new List<Case>{ objLeadCase, objAccountCase };
		insert list_Cases;

		Test.startTest();
		ApexPages.StandardController controller = new ApexPages.StandardController(new Opportunity(Id = objLeadAssert.ConvertedOpportunityId));
		OpportunityCaseListExtension extension = new OpportunityCaseListExtension(controller);

		PageReference pageRef = Page.OpportunityRelatedCases; // Add your VF page Name here
		pageRef.getParameters().put('id', String.valueOf(objLeadAssert.ConvertedOpportunityId));
		Test.setCurrentPage(Page.OpportunityRelatedCases);
		List<Case> list_CasesAssert = extension.getCases();
		Test.stopTest();

		System.assertEquals(list_Cases.size(), list_CasesAssert.size());
	}
}