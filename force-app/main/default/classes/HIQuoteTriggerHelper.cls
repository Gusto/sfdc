/**
 * @name         : HIQuoteTriggerHelper
 * @author       : Debasmita Rawooth
 * @date         : 09-20-2021
 * @description  : New HIQuoteTriggerHelper Class for HIQuoteTrigger.
 * @test classes : HIQuoteTriggerHelperTest
 **/
public class HIQuoteTriggerHelper {
	// Static Variable used to Skip Triggers
	public static Boolean str_skipTrigger = false;
	public static Boolean blnHIOwnerRouting = false;

	/*** All set variables ***/
	public Set<String> set_SalesforceIds;

	/*** All Map Variables ***/
	public Map<String, Account> map_SalesforceIdToAccount;
	public Map<String, Opportunity> map_AccountIdToHIOpportunity;
	public Map<String, Opportunity> map_AccountIdToPayrollOpportunity;

	/*** All Static List Variables ***/
	public static List<Insurance_Quote__c> list_InsuranceQuotesToInsert;

	/** All Final Variables */
	public static final String STATUS_ASSIGNED = 'Assigned';
	public static final String STATUS_NOT_ASSIGNED = 'Not Assigned';
	public static final String HI_SALES_ALL_ROLES = Test.isRunningTest() ? 'Integration Users' : System.Label.Benefits_Roles;
	public static Map<Id, List<UserAccountTeamMember>> map_UserAccountTeamMembers = new Map<Id, List<UserAccountTeamMember>>();
	public static Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();

	//Constructor
	public HIQuoteTriggerHelper() {
		set_SalesforceIds = new Set<String>();
		map_SalesforceIdToAccount = new Map<String, Account>();
		map_AccountIdToHIOpportunity = new Map<String, Opportunity>();
		map_AccountIdToPayrollOpportunity = new Map<String, Opportunity>();
		list_InsuranceQuotesToInsert = new List<Insurance_Quote__c>();
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Handles After Insert Context
	 * @Parm        : list_HIQuotes - List of HI Quotes from Trigger.new
	 * @Return      : N/A
	 **/
	public void processAfterInsert(List<HI_Quote__c> list_HIQuotes) {
		setCollectionsAfter(list_HIQuotes);
		for (HI_Quote__c objHIQuote : list_HIQuotes) {
			if (String.isNotBlank(objHIQuote.Salesforce_ID__c)) {
				createInsuranceQuote(objHIQuote);
			}
			if (String.isNotBlank(objHIQuote.Census_State__c)) {
				updateAccountFilingState(objHIQuote);
			}
		}

		processDMLOperation(true);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Handles After Update Context
	 * @Parm        : list_HIQuotes - List of HI Quotes from Trigger.new
	 * @Parm        : map_OldHIQuotes - Map of HI Quote Id and HI Quote Object from Trigger.oldMap
	 * @Return      : N/A
	 **/
	public void processAfterUpdate(List<HI_Quote__c> list_HIQuotes, Map<Id, HI_Quote__c> map_OldHIQuotes) {
		setCollectionsAfter(list_HIQuotes);
		for (HI_Quote__c objHIQuote : list_HIQuotes) {
			if (String.isNotBlank(objHIQuote.Salesforce_ID__c) && objHIQuote.HI_Quote_Link__c != map_OldHIQuotes.get(objHIQuote.Id).HI_Quote_Link__c) {
				createInsuranceQuote(objHIQuote);
			}

			if (String.isNotBlank(objHIQuote.Census_State__c)) {
				updateAccountFilingState(objHIQuote);
			}
		}

		processDMLOperation(true);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries data and create collections required for after context
	 * @Parm        : list_HIQuotes - List of HIQuotes from Trigger.new
	 * @Return      : N/A
	 **/
	public void setCollectionsAfter(List<HI_Quote__c> list_HIQuotes) {
		Set<Id> set_UserIds = new Set<Id>();
		for (HI_Quote__c objHIQuote : list_HIQuotes) {
			//get SalesforceIds ids to query accounts
			if (String.isNotBlank(objHIQuote.Salesforce_ID__c)) {
				set_SalesforceIds.add(objHIQuote.Salesforce_ID__c);
			}
		}

		if (!set_SalesforceIds.isEmpty()) {
			for (Account objAcc : queryAccounts(set_SalesforceIds)) {
				String strAcctId = String.valueOf(objAcc.Id).substring(0, 15);
				map_SalesforceIdToAccount.put(strAcctId, objAcc);
				set_UserIds.add(objAcc.OwnerId);
			}

			for (opportunity objOpp : queryOpportunities(set_SalesforceIds)) {
				String strAcctId = String.valueOf(objOpp.AccountId).substring(0, 15);
				if (objOpp.RecordTypeId == OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID) {
					if (map_AccountIdToHIOpportunity.containsKey(strAcctId)) {
						if (objOpp.LastModifiedDate > map_AccountIdToHIOpportunity.get(strAcctId).LastModifiedDate) {
							map_AccountIdToHIOpportunity.put(strAcctId, objOpp);
						}
					} else {
						map_AccountIdToHIOpportunity.put(strAcctId, objOpp);
					}
				} else if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
					map_AccountIdToPayrollOpportunity.put(strAcctId, objOpp);
				}
			}
		}

		if (!set_UserIds.isEmpty()) {
			// Build a map of user Id and list of user account team members (used in HI Sales Routing)
			for (UserAccountTeamMember objAccTeamMember : AccountUtil.queryUserAccountTeamMembers(set_UserIds)) {
				List<UserAccountTeamMember> list_UserAccTeamMembers = new List<UserAccountTeamMember>();
				if (map_UserAccountTeamMembers.containsKey(objAccTeamMember.OwnerId)) {
					list_UserAccTeamMembers = map_UserAccountTeamMembers.get(objAccTeamMember.OwnerId);
				}

				list_UserAccTeamMembers.add(objAccTeamMember);
				map_UserAccountTeamMembers.put(objAccTeamMember.OwnerId, list_UserAccTeamMembers);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Updates filing state on account, if value is blank
	 * @Parm        : objHIQuote - HI Quote record from trigger context
	 * @Return      : NA
	 **/
	public void updateAccountFilingState(HI_Quote__c objHIQuote) {
		String strSalesforceId = String.valueOf(objHIQuote.Salesforce_ID__c).substring(0, 15);

		if (map_SalesforceIdToAccount.containsKey(strSalesforceId)) {
			Account objAcc = map_AccountsToUpdate.containsKey(strSalesforceId) ? map_AccountsToUpdate.get(strSalesforceId) : map_SalesforceIdToAccount.get(strSalesforceId);
			String strStateCode = Utils.getStateCode(objHIQuote.Census_State__c);

			// Check if account billing state is blank, cenus state is not blank and state code is available
			if (String.isBlank(objAcc.BillingState) && String.isNotBlank(strStateCode)) {
				objAcc.BillingState = objHIQuote.Census_State__c;
				objAcc.BillingStateCode = strStateCode;
				map_AccountsToUpdate.put(objAcc.Id, objAcc);
			}
		}
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Accounts based on Salesforce_ID__c
	 * @Parm        : set_SalesforceIds - Set of Salesforce_ID__c
	 * @Return      : List of Accounts
	 **/
	public List<Account> queryAccounts(Set<String> set_SalesforceIds) {
		return [
			SELECT
				Id,
				Name,
				HI_Owner__c,
				HI_Owner__r.UserRole.Name,
				HI_Owner__r.IsActive,
				OwnerId,
				NumberOfEmployees,
				Number_of_Active_Employees__c,
				Account_Route_Count__c,
				ZP_Company_Overall_Status__c,
				BillingState,
				BillingStateCode,
				BillingCountry,
				Medical_Deductions__c,
				Benefits_Effective_Date__c,
				Big_Desk_Pilot_Customer__c,
				HI_Active_Benefits__c,
				RecordTypeId,
				(SELECT Id, RecordTypeId, IsClosed, IsWon, CreatedDate, CloseDate, ROE_Exception__c FROM Opportunities ORDER BY CreatedDate DESC)
			FROM Account
			WHERE Id IN :set_SalesforceIds
		];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Queries Opportunities based on Account Ids
	 * @Parm        : set_AccountIds - Set of Account Ids
	 * @Return      : List of Opportunities
	 **/
	public List<Opportunity> queryOpportunities(Set<String> set_AccountIds) {
		return [
			SELECT Id, Name, RecordTypeId, AccountId, StageName, LastModifiedDate, ROE_Exception__c
			FROM Opportunity
			WHERE
				AccountId IN :set_AccountIds
				AND (RecordTypeId = :OpportunityUtil.BENEFITS_NEW_PLAN_OPPTY_RT_ID
				OR RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID)
				AND StageName NOT IN :OpportunityUtil.set_ClosedOpportunityStage
		];
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Checks if SalesforceId is Account
	 * @Parm        : objHIQuote - HI Quote record
	 * @Return      : N/A
	 **/
	public Boolean checkIfSalesforceIdIsAccount(HI_Quote__c objHIQuote) {
		return objHIQuote.Salesforce_ID__c != null && String.valueOf(objHIQuote.Salesforce_ID__c).startsWithIgnoreCase(Account.sObjectType.getDescribe().getKeyPrefix());
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Creates Insurance Quotes based on HI Quotes inserted or updated
	 * @Parm        : objHIQuote - HI_Quote__c record
	 * @Return      : NA
	 **/
	private void createInsuranceQuote(HI_Quote__c objHIQuote) {
		Insurance_Quote__c objInsuranceQuote = new Insurance_Quote__c();
		Account objAcc = null;
		Boolean blnClosedWonBenefitOpptyFound = false;
		Boolean blnOpenBenefitsOpptyFound = false;
		objInsuranceQuote.Census_Link__c = objHIQuote.Census_Link__c;
		objInsuranceQuote.Census_Part_Time_Employees__c = objHIQuote.Census_Part_Time_Employees__c;
		objInsuranceQuote.Census_Planned_W2_Hires__c = objHIQuote.Census_Planned_W2_Hires__c;
		objInsuranceQuote.Quote_Link__c = objHIQuote.HI_Quote_Link__c;
		// assume status is not assigned
		objInsuranceQuote.Status__c = STATUS_NOT_ASSIGNED;
		Boolean blnHIOwnerActive = false;
		Boolean blnROEExceptionFound = false;
		Boolean blnSkipRouting = false;
		Opportunity objLatestOppty = null;

		if (checkIfSalesforceIdIsAccount(objHIQuote)) {
			String strSalesforceId = String.valueOf(objHIQuote.Salesforce_ID__c).substring(0, 15);
			objInsuranceQuote.Account__c = strSalesforceId;
			if (map_AccountIdToHIOpportunity.containsKey(strSalesforceId)) {
				objInsuranceQuote.Opportunity__c = map_AccountIdToHIOpportunity.get(strSalesforceId).Id;
			} else if (map_AccountIdToPayrollOpportunity.containsKey(strSalesforceId)) {
				objInsuranceQuote.Opportunity__c = map_AccountIdToPayrollOpportunity.get(strSalesforceId).Id;
			}

			if (map_SalesforceIdToAccount.containsKey(strSalesforceId)) {
				// assign sales rep only when account hi owner is not null, active user and role is from benefits roles label
				objAcc = map_SalesforceIdToAccount.get(strSalesforceId);

				if (objAcc.HI_Owner__c != null) {
					String strHIOwnerRole = objAcc.HI_Owner__r?.UserRole?.Name;
					// check if hi owner role is from benefits role custom label, then set sales rep on insurance quote and set status as assigned
					if (objAcc.HI_Owner__r.IsActive == true && String.isNotBlank(strHIOwnerRole) && HI_SALES_ALL_ROLES.containsIgnoreCase(strHIOwnerRole)) {
						blnHIOwnerActive = true;
					}
				}

				//Check if there is a benefit oppty created in last 90 days which is closed won. If yes, do not route HI Owner
				if (!objAcc.Opportunities.isEmpty()) {
					objLatestOppty = objAcc.Opportunities.get(0);
					for (Opportunity objOppty : objAcc.Opportunities) {
						if (OpportunityUtil.set_BenefitRTChangeEmployees.contains(objOppty.RecordTypeId)) {
							if (objOppty.CloseDate != null && objOppty.CloseDate > System.today().addDays(-90) && objOppty.IsWon) {
								blnClosedWonBenefitOpptyFound = true;
								break;
							}
							// If open benefits opportunity is found, do not re-route HI owner
							if (!objOppty.IsClosed) {
								blnOpenBenefitsOpptyFound = true;
							}

							// Check if ROE Exception is not blank on benefits opportunity
							if ((objOppty.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_REQUESTED || objOppty.ROE_Exception__c == AccountUtil.ROE_EXCEPTION_APPROVED)) {
								blnROEExceptionFound = true;
							}
						}
					}
				}
			}
		}

		if (blnOpenBenefitsOpptyFound && blnHIOwnerActive) {
			blnSkipRouting = true;
		} else if (objAcc?.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_SUSPENDED) {
			blnSkipRouting = true;
		} else if (blnClosedWonBenefitOpptyFound) {
			blnSkipRouting = true;
		} else if ((objLatestOppty != null && objAcc.HI_Active_Benefits__c && objLatestOppty.RecordTypeId == OpportunityUtil.BENEFITS_BOR_OPPTY_RT_ID) || objAcc.Big_Desk_Pilot_Customer__c) {
			blnSkipRouting = true;
		}

		// trigger routing only for company accounts
		if (objAcc != null && blnSkipRouting == false && objAcc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
			// Get lower and uppper threshold values from custom labels
			String strNewPlanThreshold = System.Label.New_Plan_Threshold;

			Integer intNewPlanLowerThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[0]);
			Integer intNewPlanHigherThreshold = Integer.valueOf(strNewPlanThreshold.split('/')[1]);

			Boolean blnAlignedRepFound = false;
			Boolean blnSendForRouting = false;

			if (objAcc.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_NEW) {
				if (blnHIOwnerActive) {
					objInsuranceQuote.Sales_Rep__c = objAcc.HI_Owner__c;
					objInsuranceQuote.Status__c = STATUS_ASSIGNED;
				} else {
					// get hi owner from aligned rep
					if (map_UserAccountTeamMembers.containsKey(objAcc.OwnerId)) {
						// Iterate over account team members
						for (UserAccountTeamMember objAccTeamMember : map_UserAccountTeamMembers.get(objAcc.OwnerId)) {
							// Assign HI Owner based on Number of Employees and Role Names
							if (objAccTeamMember.TeamMemberRole == AccountUtil.HI_NEW_PLAN_REP) {
								// update hi routing reason based on current value of HI Owner field
								if (objAcc.HI_Owner__c == null) {
									objAcc.HI_Routing_Reason__c = 'New Plan - Insurance Quote - HI Owner null value updated to aligned ' + objAccTeamMember.TeamMemberRole;
								} else if (objAcc.HI_Owner__c != objAccTeamMember.UserId) {
									objAcc.HI_Routing_Reason__c = 'New Plan - Insurance Quote - HI Owner replaced and updated to aligned ' + objAccTeamMember.TeamMemberRole;
								}
								objInsuranceQuote.Sales_Rep__c = objAccTeamMember.UserId;
								objAcc.HI_Owner__c = objAccTeamMember.UserId;
								objInsuranceQuote.Status__c = STATUS_ASSIGNED;
								blnAlignedRepFound = true;
							}
						}
					}

					// If aligned rep not found, send to ringlead for routing
					if (!blnAlignedRepFound) {
						blnSendForRouting = true;
					}
				}
			} else if (objAcc.ZP_Company_Overall_Status__c == AccountUtil.ACCOUNT_OVERALL_STATUS_ACTIVE) {
				// If overall status is active - do not check for alignment and send for routing before checking few conditions
				if (objAcc.Medical_Deductions__c || objAcc.Benefits_Effective_Date__c != null || HI_Oppty_Router_State__mdt.getInstance(objAcc.BillingStateCode) != null) {
					blnSendForRouting = true;
				}
			}

			if (objInsuranceQuote.Sales_Rep__c == null && blnSendForRouting) {
				// If no aligned rep is found, send account to ringlead and update hi routing reason
				if (objAcc.HI_Owner__c == null) {
					objAcc.HI_Routing_Reason__c = 'New Plan - Insurance Quote - HI Owner null value and send to Routing Tool';
				} else {
					objAcc.HI_Routing_Reason__c = 'New Plan - Insurance Quote - HI Owner replaced and send to Routing Tool';
				}
				blnHIOwnerRouting = true;
				AccountUtil.sendAccountForHIOwnerRouting(objAcc.Id);
			}
			map_AccountsToUpdate.put(objAcc.Id, objAcc);
		}

		if (blnHIOwnerActive && objAcc.HI_Owner__c != null && objInsuranceQuote.Sales_Rep__c == null) {
			objInsuranceQuote.Sales_Rep__c = objAcc.HI_Owner__c;
			objInsuranceQuote.Status__c = STATUS_ASSIGNED;
		}

		if (String.isNotBlank(objHIQuote.Census_Zip_Code__c)) {
			objInsuranceQuote.Census_Zip_Code__c = objHIQuote.Census_Zip_Code__c;
		}
		if (String.isNotBlank(objHIQuote.Census_State__c)) {
			objInsuranceQuote.Census_State__c = objHIQuote.Census_State__c;
		}

		list_InsuranceQuotesToInsert.add(objInsuranceQuote);
	}

	/**
	 * @Author      : Debasmita Rawooth
	 * @Description : Post Trigger DML Inserts and Updates
	 * @Parm        : blnInsert - Boolean Flag
	 * @Return      : N/A
	 **/
	private void processDMLOperation(Boolean blnInsert) {
		if (!list_InsuranceQuotesToInsert.IsEmpty()) {
			//insert list_InsuranceQuotesToInsert;
			try {
				insert list_InsuranceQuotesToInsert;
			} catch (Exception ex) {
				ExceptionLogUtil.logException('HIQuoteTriggerHelper', 'processDMLOperation', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
			}
		}
		// update billing country first before updating billing state
		// update hi owner on account
		if (!map_AccountsToUpdate.isEmpty()) {
			List<Account> list_BillingCountryUpdateAccs = new List<Account>();
			// check if billing country is blank
			for (Account objAcc : map_AccountsToUpdate.values()) {
				if (String.isBlank(objAcc.BillingCountry)) {
					objAcc.BillingCountry = 'United States';
					list_BillingCountryUpdateAccs.add(new Account(Id = objAcc.Id, BillingCountry = 'United States'));
				}
			}

			// update billing country before updating billing state and skip account trigger
			if (!list_BillingCountryUpdateAccs.isEmpty()) {
				AccountTriggerHelper.skipTrigger = true;
				update list_BillingCountryUpdateAccs;
				AccountTriggerHelper.skipTrigger = false;
			}
			// update HI Owner on Account
			update map_AccountsToUpdate.values();
		}
	}
}