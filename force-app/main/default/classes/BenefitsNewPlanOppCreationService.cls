/**
 * @name         : BenefitsNewPlanOppCreationService
 * @author       : Debasmita Rawooth
 * @date         : 11-10-2021
 * @description  : Handler Class for BenefitsNewPlanOppCreationBatch
 * @test classes : BenefitsNewPlanOppCreationBatchTest
 **/
public class BenefitsNewPlanOppCreationService {
	/*** All set variables ***/
	public Set<Id> set_BenefitsRecordTypeIds;

	/*** All List List Variables ***/
	public List<Opportunity> list_OpportunitiesToBeInserted;

	/*** All Map Variables ***/
	public Map<String, Boolean> map_BenefitsOpportunities;
	public Map<Id, Insurance_Quote__c> map_InsuranceQuotesToUpdate;
	public Map<String, EmailMessage> map_OpportunityIdToEmailMessage;
	public Map<String, String> map_AccountIdToPayrollOppId;
	public Map<Id, Account> map_AccountsToUpdate;

	public BenefitsNewPlanOppCreationService() {
		set_BenefitsRecordTypeIds = new Set<Id>();
		list_OpportunitiesToBeInserted = new List<Opportunity>();
		map_BenefitsOpportunities = new Map<String, Boolean>();
		map_InsuranceQuotesToUpdate = new Map<Id, Insurance_Quote__c>();
		map_OpportunityIdToEmailMessage = new Map<String, EmailMessage>();
		map_AccountIdToPayrollOppId = new Map<String, String>();
		map_AccountsToUpdate = new Map<Id, Account>();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Creates a New Benefit New Plan Opportunity record
	 * @Parm        : list_insuranceQuotes - List of Insurance quotes
	 * @Return      : N/A
	 **/
	public void createNewOpportunity(List<Insurance_Quote__c> list_InsuranceQuotes, Set<String> set_AccountIds) {
		try {
			set_BenefitsRecordTypeIds = OpportunityUtil.getBenefitRecordTypeIds();
			map_BenefitsOpportunities = queryBenefitsOpportunity(set_AccountIds);
			List<Opportunity> list_OpportunitiesToBeInserted = new List<Opportunity>();

			if (set_AccountIds.size() > 0) {
				map_AccountIdToPayrollOppId = queryPayrollOpportunity(set_AccountIds);
			}

			if (map_AccountIdToPayrollOppId.size() > 0) {
				for (EmailMessage objEmailMessage : queryEmailMessages(map_AccountIdToPayrollOppId.values())) {
					if (map_OpportunityIdToEmailMessage.containsKey(objEmailMessage.RelatedToId)) {
						if (objEmailMessage.CreatedDate > map_OpportunityIdToEmailMessage.get(objEmailMessage.RelatedToId).CreatedDate) {
							map_OpportunityIdToEmailMessage.put(objEmailMessage.RelatedToId, objEmailMessage);
						}
					} else {
						map_OpportunityIdToEmailMessage.put(objEmailMessage.RelatedToId, objEmailMessage);
					}
				}
			}

			if (list_InsuranceQuotes.size() > 0) {
				for (Insurance_Quote__c objInsuranceQuote : list_InsuranceQuotes) {
					Boolean blnHasBenefitsOpp = false;

					if (!map_BenefitsOpportunities.isEmpty() && map_BenefitsOpportunities.containsKey(objInsuranceQuote.Account__c)) {
						blnHasBenefitsOpp = map_BenefitsOpportunities.get(objInsuranceQuote.Account__c);
					}

					//checks if Account has open Benefits Opportunity
					if (objInsuranceQuote.Account__c != null && blnHasBenefitsOpp) {
						objInsuranceQuote.NewPlan_Reason__c = 'Account already has open benefits opportunity.';
						objInsuranceQuote.NewPlanProcessed__c = true;
						map_InsuranceQuotesToUpdate.put(objInsuranceQuote.Id, objInsuranceQuote);
					} else {
						Opportunity objBenfitNewPlanOpp = createNewPlanOpportunity(objInsuranceQuote);
						list_OpportunitiesToBeInserted.add(objBenfitNewPlanOpp);
						// add insurance quote to update
						objInsuranceQuote.NewPlanProcessed__c = true;
						objInsuranceQuote.NewPlan_Reason__c = 'New Plan Opportunity Created';
						map_InsuranceQuotesToUpdate.put(objInsuranceQuote.Id, objInsuranceQuote);
					}
				}

				// create new opportunities
				if (!list_OpportunitiesToBeInserted.isEmpty()) {
					OpportunityTriggerHelper.skipTrigger = true;
					insert list_OpportunitiesToBeInserted;
					QASheetHelper.createOrUpdateQASheet(list_OpportunitiesToBeInserted);
					OpportunityTriggerHelper.skipTrigger = false;
				}

				if (!map_InsuranceQuotesToUpdate.isEmpty()) {
					InsuranceQuoteTriggerHelper.blnSkipTrigger = true;
					update map_InsuranceQuotesToUpdate.values();
					InsuranceQuoteTriggerHelper.blnSkipTrigger = false;
				}

				if (!map_AccountsToUpdate.isEmpty()) {
					AccountTriggerHelper.skipTrigger = true;
					update map_AccountsToUpdate.values();
					AccountTriggerHelper.skipTrigger = false;
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('BenefitsNewPlanOppCreationBatch', 'createNewOpportunity', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Checks if Account has Open Benefits Opportunity
	 * @Parm        : set_AccountIds - Set of Account IDs
	 * @Return      : N/A
	 **/
	public Map<String, Boolean> queryBenefitsOpportunity(Set<String> set_AccountIds) {
		Map<String, Boolean> map_BenefitsOpportunity = new Map<String, Boolean>();
		for (Opportunity objOpp : [
			SELECT Id, RecordTypeId, AccountId, StageName
			FROM Opportunity
			WHERE AccountId IN :set_AccountIds AND RecordTypeId IN :set_BenefitsRecordTypeIds AND IsClosed = FALSE
		]) {
			map_BenefitsOpportunity.put(objOpp.AccountId, true);
		}
		return map_BenefitsOpportunity;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Query for Payroll Opportunities on Account
	 * @Parm        : set_AccountIds - Set of Account IDs
	 * @Return      : N/A
	 **/
	public Map<String, String> queryPayrollOpportunity(Set<String> set_AccountIds) {
		Map<String, String> map_AccountIdVsPayrollOppId = new Map<String, String>();
		for (Opportunity objOpportunity : [SELECT Id, RecordTypeId, AccountId, StageName FROM Opportunity WHERE AccountId IN :set_AccountIds AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID]) {
			map_AccountIdVsPayrollOppId.put(objOpportunity.AccountId, objOpportunity.Id);
		}
		return map_AccountIdVsPayrollOppId;
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries EmailMesages from Payroll Opportunities
	 * @Parm        : list_OpportunityIds - List of Opportunity Ids
	 * @Return      : List of Opportunities
	 **/
	public List<EmailMessage> queryEmailMessages(List<String> list_OpportunityIds) {
		return [SELECT Id, RelatedToId, MessageDate, Subject, CreatedDate, CreatedById, CreatedBy.UserRole.Name FROM EmailMessage WHERE RelatedToId IN :list_OpportunityIds AND Subject = :Label.HI_QuoteEmailSubject];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Creates and returns a New Plan Opportunity
	 * @Parm        : objInsuranceQuote - Insurance Quote record
	 * @Return      : Opportunity
	 **/
	public Opportunity createNewPlanOpportunity(Insurance_Quote__c objInsuranceQuote) {
		Integer numberOfDays = Date.daysInMonth(Date.Today().year(), Date.Today().month());
		Date dt_lastDayOfMonth = Date.newInstance(Date.Today().year(), Date.Today().month(), numberOfDays);

		Opportunity objOpportunity = new Opportunity();
		objOpportunity.RecordTypeId = OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID;

		List<String> list_HIRoles = OpportunityUtil.HI_SALES_CS_ROLES.split(',');

		if (OpportunityUtil.map_OpptyRTToDefaultValues.containsKey(objOpportunity.RecordTypeId)) {
			if (objOpportunity.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID)
				objOpportunity.Type = OpportunityUtil.map_OpptyRTToDefaultValues.get(objOpportunity.RecordTypeId)[0];
		}
		objOpportunity.StageName = OpportunityUtil.DEFAULT_HI_SALES_STAGE;
		objOpportunity.CloseDate = dt_lastDayOfMonth;
		objOpportunity.LeadSource = OpportunityUtil.INSURANCE_QUOTE;

		if (objInsuranceQuote.Account__c != null) {
			objOpportunity.AccountId = objInsuranceQuote.Account__c;
			objOpportunity.Name = objInsuranceQuote.Account__r.Name + ' - ' + OpportunityUtil.map_OpptyRTToDefaultValues.get(objOpportunity.RecordTypeId)[2];
			if (map_AccountIdToPayrollOppId != null && map_AccountIdToPayrollOppId.size() > 0 && map_AccountIdToPayrollOppId.containsKey(objInsuranceQuote.Account__c)) {
				if (
					map_OpportunityIdToEmailMessage != null &&
					map_OpportunityIdToEmailMessage.size() > 0 &&
					map_OpportunityIdToEmailMessage.containskey(map_AccountIdToPayrollOppId.get(objInsuranceQuote.Account__c))
				) {
					String strUserRoleName = UserUtils.getUserRoleName((map_OpportunityIdToEmailMessage?.get(map_AccountIdToPayrollOppId?.get(objInsuranceQuote.Account__c))?.CreatedById));
					if (list_HIRoles.contains(strUserRoleName)) {
						objOpportunity.Sent_to_Gusto_User__c = map_OpportunityIdToEmailMessage?.get(map_AccountIdToPayrollOppId?.get(objInsuranceQuote.Account__c))?.CreatedById;
						objOpportunity.HI_Lead_Pass_Role__c = map_OpportunityIdToEmailMessage?.get(map_AccountIdToPayrollOppId?.get(objInsuranceQuote.Account__c))?.CreatedBy.UserRole.Name;
					}
				}
			}
		}

		if (objInsuranceQuote.Account__r.Number_of_Active_Employees__c != null && objInsuranceQuote.Account__r.Number_of_Active_Employees__c > 1) {
			objOpportunity.NumberOfEmployees__c = objInsuranceQuote.Account__r.Number_of_Active_Employees__c;
		}

		if (String.isNotBlank(objInsuranceQuote.Census_State__c)) {
			objOpportunity.HI_Opportunity_Assignment_State__c = objInsuranceQuote.Census_State__c;
		} else if (String.isNotBlank(objInsuranceQuote.Account__r.BillingState)) {
			objOpportunity.HI_Opportunity_Assignment_State__c = objInsuranceQuote.Account__r.BillingState;
		}

		if (objInsuranceQuote.Sales_Rep__c != null) {
			objOpportunity.OwnerId = objInsuranceQuote.Sales_Rep__c;
		}

		if (String.isNotBlank(objInsuranceQuote.Account__r?.ZP_Company_ID__c)) {
			objOpportunity.ZP_Company_ID__c = objInsuranceQuote.Account__r.ZP_Company_ID__c;
		}

		// setting pricebook to allow linking policies on the opp when HI new plan is created
		new OpportunityTriggerHelper().setPricebook(objOpportunity);

		return objOpportunity;
	}
}