/**
 * @name         MassAdvisorAssignmentCtrlTest
 * @author       Bhagat Singh
 * @date         26 June 2024
 * @description  MassAdvisorAssignmentCtrl class code coverage.
 **/
@isTest
private class MassAdvisorAssignmentCtrlTest {
	@testSetup
	static void makeData() {
		List<Account> list_Account = new List<Account>();
		list_Account.add(new TestDataFactory.AccountBuilder().setName('Test Account 01').setRecordTypeId(AccountUtil.COMPANY_ACCOUNT_RT_ID).setZPCompanyId('7757616923580731').build());
		insert list_Account;

		List<Opportunity> list_Opp = new List<Opportunity>();
		list_Opp.add(
			new TestDataFactory.OpportunityBuilder()
				.setRecordTypeId(OpportunityUtil.BENEFITS_RENEWAL_OPPTY_RT_ID)
				.setName('Test Opp - BNP Ren')
				.setAccountId(list_Account[0].Id)
				.setCloseDate(System.today())
				.build()
		);
		insert list_Opp;
	}

	/**
	 * @author       Bhagat Singh
	 * @description  This method validate mass update Advisor_Assignment__c field values on selected opportunity records.
	 * @param        NA
	 * @return       NA
	 **/
	@isTest
	static void massUpdateAdvisorAssignment() {
		Test.startTest();
		List<Opportunity> list_Opp = [SELECT Id, Advisor_Assignment__c FROM Opportunity WHERE Account.ZP_Company_ID__c = '7757616923580731'];
		ApexPages.currentPage().getParameters().put('Id', list_Opp.get(0).id);
		ApexPages.StandardSetController objSSC = new ApexPages.StandardSetController(list_Opp);
		objSSC.setSelected(list_Opp);
		MassAdvisorAssignmentCtrl objCon = new MassAdvisorAssignmentCtrl(objSSC);
		objCon.getStep();
		objCon.cancel();
		objCon.objOpportunity.Advisor_Assignment__c = 'Escalated ER';
		objCon.updateOpportunity();

		Test.stopTest();

		list_Opp = [SELECT Id, Advisor_Assignment__c FROM Opportunity WHERE Account.ZP_Company_ID__c = '7757616923580731'];
		System.assertEquals('Escalated ER', list_Opp[0].Advisor_Assignment__c, 'Advisor Assignment not updated on opportunity');
	}
}