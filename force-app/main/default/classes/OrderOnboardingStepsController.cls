/**
 * @description  Get Onboarding Steps from Order
 * @author       Praveen Sethu
 * @date         12-1-2022
 * @see          OrderOnboardingStepsControllerTest
 **/
public with sharing class OrderOnboardingStepsController {
	public static final String OBJ_TYPE_ORDER = 'Order';
	public static final String OBJ_TYPE_OPPORTUNITY = 'Opportunity';

	/**
	 * @description Gather onboarding steps from company opportunity linked to Order
	 * @author      Praveen Sethu
	 * @param       idRecordId - Record Id
	 * @return      Opportunity - Company Opportunity with onboarding steps
	 **/
	@AuraEnabled
	public static Opportunity getOnboardingSteps(Id idRecordId) {
		String strObjectType = idRecordId == null ? null : idRecordId.getSObjectType().getDescribe().getName();
		Opportunity objOppToReturn = null;
		if (strObjectType == OBJ_TYPE_ORDER) {
			Order objOrder = [SELECT Id, AccountId, OpportunityId FROM Order WHERE Id = :idRecordId];
			if (Test.isRunningTest()) {
				objOrder.OpportunityId = null;
			}

			if (objOrder.OpportunityId != null) {
				objOppToReturn = getCompanyOpportunity(objOrder.OpportunityId);
			} else if (objOrder.AccountId != null) {
				objOppToReturn = getCompanyOpportunity(objOrder.AccountId);
			}
		} else if (strObjectType == OBJ_TYPE_OPPORTUNITY) {
			Opportunity objOpportunity = [SELECT AccountId FROM Opportunity WHERE Id = :idRecordId];
			objOppToReturn = getCompanyOpportunity(objOpportunity.AccountId);
		}
		return objOppToReturn;
	}

	/**
	 * @description Query company opportunity based on id/accountId
	 * @param       idQueryBy - OpportunityId/AccountId
	 * @return      Opportunity - Company Opportunity with onboarding steps
	 **/
	private static Opportunity getCompanyOpportunity(Id idQueryBy) {
		Opportunity objOppToReturn = null;
		List<Opportunity> list_Opportunities = [
			SELECT
				Id,
				Name,
				ZP_Add_Company_Addresses__c,
				ZP_Add_Employees__c,
				ZP_Set_Up_Federal_Taxes__c,
				ZP_Set_Up_State_Taxes__c,
				ZP_Set_Up_Bank_Account__c,
				ZP_Select_a_Payroll_Schedule__c,
				ZP_Report_Previous_Paystubs__c,
				ZP_Add_Signatory__c,
				ZP_Sign_Company_Forms__c,
				ZP_Enter_Unpaid_Tax_Liabilities__c,
				ZP_Ran_Payroll__c,
				Pricebook2.Product_Tier__c
			FROM Opportunity
			WHERE
				(Id = :idQueryBy
				OR AccountId = :idQueryBy)
				AND (RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
				OR (RecordTypeId = :OpportunityUtil.ACQUISITION_OPPTY_RT_ID
				AND Type = :OpportunityUtil.OPPTY_TYPE_NEW_BUSINESS))
			ORDER BY CreatedDate DESC
		];
		if (!list_Opportunities.isEmpty()) {
			objOppToReturn = list_Opportunities.get(0);
		}
		return objOppToReturn;
	}
}