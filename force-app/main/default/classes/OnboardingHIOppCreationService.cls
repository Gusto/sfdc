/**
 * @Author      : Yuvraj/Prashant
 * Date Created : 15 Sept 2020
 * Asana        : https://app.asana.com/0/1165890935117693/1193488927825041
 * Test class   : OnboardingHIOppCreationServiceTest
 */
global with sharing class OnboardingHIOppCreationService {
	global static void doCreateOpportunity(List<ZP_Company__c> list_zpCompanies, Set<String> set_CompanIds) {
		Map<Id, ZP_Company__c> map_toUpdateZPCompany = new Map<Id, ZP_Company__c>();
		List<Opportunity> list_toCreateOpp = new List<Opportunity>();
		Set<String> set_HIOppState = queryStateNameSet();
		Map<String, Opportunity> map_Opportunity = queryOpportunity(set_CompanIds);
		Map<String, Account> map_Accounts = queryAccounts(set_CompanIds);

		if (list_zpCompanies.size() > 0) {
			for (ZP_Company__c objZpCompany : list_zpCompanies) {
				//to skip process if required as per record data
				Boolean skipProcess = false;
				Opportunity objOpp = map_Opportunity.containsKey(objZpCompany.ID__c) ? map_Opportunity.get(objZpCompany.ID__c) : null;
				Account objAcc = map_Accounts.containsKey(objZpCompany.ID__c) ? map_Accounts.get(objZpCompany.ID__c) : null;
				Id idOppOwner = objOpp != null ? objOpp.OwnerId : null;
				String strOppStage = objOpp != null ? objOpp.StageName : '';
				DateTime dtLastLogin = objOpp != null ? objOpp.Account?.Last_Login_Time__c : null;

				//criteria 1 - if Account doesn't exist
				if (objZpCompany.Account__c == null) {
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_ACCOUNT_NOT_FOUND;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objZpCompany.Account__r.BillingState == null) {
					//criteria 3 - if billing state is not present
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_NO_BILLING_STATE;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objZpCompany.Account__r.BillingAddress != null && objZpCompany.Account__r.BillingState != null && !set_HIOppState.contains(objZpCompany.Account__r.BillingState)) {
					//criteria 4 - if state not supported by HI
					objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_STATE_NOT_SUPPORTED;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (
					(objZpCompany.Company_Lead_Number_of_Employees__c == null || objZpCompany.Company_Lead_Number_of_Employees__c < 2) &&
					(objZpCompany.Number_of_Active_Employees__c == null ||
					objZpCompany.Number_of_Active_Employees__c < 2)
				) {
					//criteria 5 - if no employees on company or less then 2
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_EE_NOT_SUPPORTED;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objZpCompany.Created_At__c.adddays(90) < System.today()) {
					//criteria 6 - if Company Create over 90 days
					objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_TIMEPERIOD_NOT_SUPPORTED;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objOpp != null && UserUtils.isAdminIntgUser(idOppOwner)) {
					//criteria 7 - if Payroll Opportunity owner not sales
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_OPP_ROLE;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objOpp != null && strOppStage == OnboardingHIOppCreationUtil.CLOSED_LOST_STAGE) {
					//criteria 8 - if Payroll Opportunity is "Closed Lost"
					objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_PAY_OPP_CL;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objOpp != null && dtLastLogin == null) {
					//criteria 9 - if last login is blank - check next day
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_NO_LOGIN_TIME;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				} else if (objOpp != null && dtLastLogin != null && dtLastLogin < System.now().addDays(-60)) {
					//criteria 10 - if last login was 60 days ago - skip opp creation
					objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_NO_LOGIN_TIME_60_DAYS;
					objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
					skipProcess = true;
					map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
				}

				// Create Benefits Opportunity ONLY if existing opportunity of the same type is not present
				if (!skipProcess) {
					if (
						String.isBlank(objZpCompany.Initiated_by_Accountant__c) &&
						(((objZpCompany.Currently_Offer_Health_Benefits__c == 'Yes' || objZpCompany.Currently_Offer_Health_Benefits__c == 'True') &&
						objZpCompany.Open_to_Switching_Broker__c == 'MANUALLY_ADD') || objZpCompany.Want_to_switch_brokers__c == true)
					) {
						if (!checkExistingBenefitsOpportunity(objZpCompany.ID__c, map_Accounts, OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR)) {
							// create new hi bor opportunity if existing opportunity not present
							Opportunity objBenfitBorOpp = createNewOpportunity(OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR, objZpCompany);
							list_toCreateOpp.add(objBenfitBorOpp);
							// add zp company to update
							objZpCompany.Onboarding_HI_Opp_Created__c = true;
							objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_BOR_CREATED;
							map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
						} else {
							objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
							objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.ACCOUNT_ALREADY_HAS + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR + OnboardingHIOppCreationUtil.OPPORTUNITY;
							map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
						}
					} else if (
						objZpCompany.Onboarding_Survey_Offer_Benefits__c == false &&
						(objZpCompany.Onboarding_Survey_Interested_Benefit_Opt__c == OnboardingHIOppCreationUtil.SMALL_GROUP_HEALTH_INSURANCE ||
						objZpCompany.Onboarding_Survey_Interested_Benefit_Opt__c == OnboardingHIOppCreationUtil.LEARNING_MORE)
					) {
						if (!checkExistingBenefitsOpportunity(objZpCompany.ID__c, map_Accounts, OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP)) {
							// create new hi new plan opportunity if existing opportunity not present
							Opportunity objBenfitNewPlanOpp = createNewOpportunity(OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP, objZpCompany);
							list_toCreateOpp.add(objBenfitNewPlanOpp);
							// add zp company to update
							objZpCompany.Onboarding_HI_Opp_Created__c = true;
							objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_NP_CREATED;
						} else {
							objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
							objZpCompany.HI_Reason__c = 'Account already has ' + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP + ' Opportunity';
						}

						map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
					} else if (
						objZpCompany.Want_to_switch_brokers__c == false &&
						String.isBlank(objZpCompany.Initiated_by_Accountant__c) &&
						(objZpCompany.Currently_Offer_Health_Benefits__c == 'Yes' ||
						objZpCompany.Currently_Offer_Health_Benefits__c == 'True') &&
						String.isNotBlank(objZpCompany.Open_to_Switching_Broker__c) &&
						objZpCompany.Open_to_Switching_Broker__c != 'MANUALLY_ADD'
					) {
						if (!checkExistingBenefitsOpportunity(objZpCompany.ID__c, map_Accounts, OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB)) {
							// create new hi byb opportunity id existing opportunity not present
							Opportunity objBYBOppty = createNewOpportunity(OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB, objZpCompany);
							list_toCreateOpp.add(objBYBOppty);
							// add zp company to update
							objZpCompany.Onboarding_HI_Opp_Created__c = true;
							objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_BYB_CREATED;
						} else {
							objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
							objZpCompany.HI_Reason__c = 'Account already has ' + OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BYB + ' Opportunity';
						}

						map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
					} else {
						objZpCompany.Skip_Onboarding_Opp_Creation__c = true;
						objZpCompany.HI_Reason__c = OnboardingHIOppCreationUtil.HI_REASON_NO_CONDITION_MET;
						map_toUpdateZPCompany.put(objZpCompany.Id, objZpCompany);
					}
				}
			}

			try {
				//Update zp company
				if (!map_toUpdateZPCompany.isEmpty()) {
					ZPCompanyTriggerHelper.skipTrigger = true;
					update map_toUpdateZPCompany.values();
					ZPCompanyTriggerHelper.skipTrigger = false;
				}

				//Create new opportunities
				if (!list_toCreateOpp.isEmpty()) {
					insert list_toCreateOpp;
				}
			} catch (Exception e) {
				//Created exception log;
				ExceptionLogUtil.logException('OnboardingHIOppCreationService', 'doCreateOpportunity', e.getMessage(), 'Medium');
			}
		}
	}

	public static Map<String, Opportunity> queryOpportunity(Set<String> set_CompanIds) {
		Map<String, Opportunity> map_Opportunity = new Map<String, Opportunity>();
		for (Opportunity objOpp : [
			SELECT Id, RecordTypeId, Account.ZP_Company_ID__c, OwnerId, StageName, Account.Last_Login_Time__c
			FROM Opportunity
			WHERE Account.ZP_Company_ID__c IN :set_CompanIds AND RecordTypeId = :OpportunityUtil.COMPANY_OPPTY_RT_ID
		]) {
			map_Opportunity.put(objOpp.Account.ZP_Company_ID__c, objOpp);
		}
		return map_Opportunity;
	}

	/**
	 * Queries accounts based on ZP Company Ids - Builds a map of account ID along with list opportunities
	 * @returns Map of Company Id and Account objec
	 */
	public static Map<String, Account> queryAccounts(Set<String> set_CompanIds) {
		Map<String, Account> map_Accounts = new Map<String, Account>();
		for (Account objAcc : [
			SELECT Id, ZP_Company_ID__c, (SELECT Id, RecordType.Name, IsClosed FROM Opportunities)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanIds AND ZP_Company_ID__c != NULL
		]) {
			map_Accounts.put(objAcc.ZP_Company_ID__c, objAcc);
		}
		return map_Accounts;
	}

	/**
	 * Query HI Supported states - to validate if current Account (based on zp company) is eligible for HI Opp.
	 * @returns `Set<String>` of HI States
	 */
	public static Set<String> queryStateNameSet() {
		Set<String> set_resultSet = new Set<String>();
		for (HI_Opportunity_Router_State__c obj : [SELECT Id, State_Name__c, State__c FROM HI_Opportunity_Router_State__c WHERE State_Name__c != NULL]) {
			set_resultSet.add(obj.State_Name__c);
		}
		return set_resultSet;
	}

	/**
	 * If ZP Company/Account is eligible for HI Opportunity - create new one.
	 * @param str_RecordType
	 * @param objZpCompany
	 * @returns `Opportunity`
	 */
	public static Opportunity createNewOpportunity(String str_RecordType, ZP_Company__c objZpCompany) {
		Integer numberOfDays = Date.daysInMonth(Date.Today().year(), Date.Today().month());
		Date dt_lastDayOfMonth = Date.newInstance(Date.Today().year(), Date.Today().month(), numberOfDays);
		Map<String, Id> map_OpportunityRecTypes = OnboardingHIOppCreationUtil.getOpportunityRecordTypes();

		//Create the parent account for reference.
		Account objParentAcc = new Account(ZP_Company_ID__c = objZpCompany.Id__c);

		Opportunity objOpportunity = new Opportunity();
		if (str_RecordType == OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_BOR) {
			objOpportunity.Type = OnboardingHIOppCreationUtil.HI_OPP_TYPE_BOR;
		} else if (str_RecordType == OnboardingHIOppCreationUtil.HI_OPP_REC_TYPE_NP) {
			objOpportunity.Type = OnboardingHIOppCreationUtil.HI_OPP_TYPE_NP;
		}
		objOpportunity.RecordTypeId = map_OpportunityRecTypes.containsKey(str_RecordType) ? map_OpportunityRecTypes.get(str_RecordType) : null;
		objOpportunity.StageName = OnboardingHIOppCreationUtil.STAGE_NAME_RAW;
		objOpportunity.CloseDate = dt_lastDayOfMonth;
		objOpportunity.Account = objParentAcc;
		objOpportunity.ZP_Company_Id__c = objZpCompany.Id__c;
		objOpportunity.LeadSource = OnboardingHIOppCreationUtil.LEAD_SOURCE_BENEFITS_DURING_ONB;

		objOpportunity.Which_Gusto_benefits_interested_in__c = objZpCompany.Which_Gusto_benefits_interested_in__c;
		objOpportunity.When_to_start_offering_benefits__c = objZpCompany.When_to_start_offering_benefits__c;
		objOpportunity.Who_to_contact__c = objZpCompany.Who_to_contact__c;
		objOpportunity.Initiated_by_Accountant__c = objZpCompany.Initiated_by_Accountant__c;
		objOpportunity.Currently_Offer_Health_Benefits__c = objZpCompany.Currently_Offer_Health_Benefits__c;
		objOpportunity.Want_to_switch_brokers__c = objZpCompany.Want_to_switch_brokers__c;
		objOpportunity.Existing_Health_Benefits_Renewal_Date__c = objZpCompany.Existing_Health_Benefits_Renewal_Date__c;
		objOpportunity.Open_to_Switching_Broker__c = objZpCompany.Open_to_Switching_Broker__c;
		objOpportunity.Contribution_to_EE_Health_Coverage_cost__c = objZpCompany.Contribution_to_EE_Health_Coverage_cost__c;
		objOpportunity.Interested_in_offering_HI_to_employees__c = objZpCompany.Interested_in_offering_HI_to_employees__c;
		objOpportunity.Interest_in_adding_benefits_to_Gusto__c = objZpCompany.Interest_in_adding_benefits_to_Gusto__c;

		if (objZpCompany.Account__r.NumberOfEmployees_Lead__c != null && objZpCompany.Account__r.NumberOfEmployees_Lead__c > 1) {
			objOpportunity.NumberOfEmployees__c = objZpCompany.Account__r.NumberOfEmployees_Lead__c;
		} else if (objZpCompany.Number_of_Active_Employees__c != null && objZpCompany.Number_of_Active_Employees__c > 1) {
			objOpportunity.NumberOfEmployees__c = objZpCompany.Number_of_Active_Employees__c;
		}
		return objOpportunity;
	}

	/**
	 * Check if existing open benefits opportunity of a specific type is present for the company
	 * @param strCompanyId - Company Id of the Account
	 * @param map_Accounts - Map of Account Id and Account object
	 * @param strRecordType - Record type of the benefits opportunity that we want to check
	 * @returns `Boolean` flag to indicate if opportunity is present
	 */
	public static Boolean checkExistingBenefitsOpportunity(String strCompanyId, Map<String, Account> map_Accounts, String strRecordType) {
		Boolean blnOpptyPresent = false;

		if (map_Accounts.containsKey(strCompanyId)) {
			Account objAcc = map_Accounts.get(strCompanyId);
			for (Opportunity objOpp : objAcc.Opportunities) {
				if (objOpp.RecordType.Name == strRecordType && !objOpp.IsClosed) {
					blnOpptyPresent = true;
					break;
				}
			}
		}

		return blnOpptyPresent;
	}
}