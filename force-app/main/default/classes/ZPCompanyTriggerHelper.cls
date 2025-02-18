/**
 * @author       Aurobind Ravichandran
 * @date         3/27/2017
 * @description  Process ZP Companies, Converts Company Leads and other Attribution data
 * @see ZPCompanyTriggerHelperTest
 */
public without sharing class ZPCompanyTriggerHelper {
	public static Boolean skipTrigger = false;
	private static Integer counter = 0;
	public static Boolean queue = false;
	public static String updateType = '';
	public static Boolean blnInsert = false;
	public static Boolean blnTestExceptions = false;
	public static final String MANUAL_ENQUEUE = 'Manually Enqueued';
	public static final String GUSTO_GLOBAL = 'Gusto Global';

	private Map<String, Account> partnerAccountMap;
	private Map<String, Id> companyOwnerIdMap = new Map<String, Id>();
	public static List<String> list_Competitors;
	public static List<String> list_Partners;
	public static List<String> list_Employees;
	public static Map<String, ZP_Accounting_Firm__c> map_matchingAcctFirms = new Map<String, ZP_Accounting_Firm__c>();
	public static Map<String, ZP_Accounting_Firm__c> map_ZPAcctFirms = new Map<String, ZP_Accounting_Firm__c>();
	Map<String, String> countryMap = new Map<String, String>{ 'USA' => 'United States' };
	Map<String, String> countryCodeMap = new Map<String, String>{ 'USA' => 'US' };
	public Set<String> set_EmbeddedPartnerId = new Set<String>();
	public Set<String> set_EmbeddedPartnerUUID = new Set<String>();
	Set<String> set_parentCompanyIds = new Set<String>();
	public Map<String, Account> map_AllAccounts = new Map<String, Account>();

	public void onBeforeInsert(List<ZP_Company__c> companys) {
		counter++;
		try {
			// Filter fraudulent records and update proccessing state to "Dead"
			companys = returnRecordsToProcess(companys, null);
			for (ZP_Company__c company : companys) {
				// Throw an exception when Testing: START
				if (blnTestExceptions) {
					Integer x = 1 / 0;
				}
				// Throw an exception when Testing: END
				// Set Is Changed as true on insert
				company.Is_Changed__c = true;
				company.Is_Changed_Reward_Eligible__c = true;
				company.Processing_State__c = IntegrationUtils.QUEUED_STATE;

				/*
					Alex: if Joined Date is not null, set Joined Date Updated
					Date: Jan 7th
					*/
				if (company.Joined_Date__c != null) {
					company.Joined_Date_Updated__c = System.now();
				}

				//@By :Prashant :28-05-2020 : update a checkbox to know id Accountant lead value is updated
				if (company.Accountant_Lead_Id__c != null && company.Accountant_Lead_Id__c != '') {
					company.IsChangedAccoutantLeadId__c = true;
				} else {
					company.IsChangedAccoutantLeadId__c = false;
				}

				if (
					company.Onboarding_Survey_Offer_Benefits__c ||
					(!company.Onboarding_Survey_Offer_Benefits__c &&
					(company.Onboarding_Survey_Interested_Benefit_Opt__c == 'SMALL_GROUP_HEALTH_INSURANCE' ||
					company.Onboarding_Survey_Interested_Benefit_Opt__c == 'LEARNING_MORE'))
				) {
					company.Process_HI_Opp_Creation__c = true;
				}
			}
			if (queue == true) {
				if (updateType == 'LeadConversion') {
					processLeadConversion(companys);
				} else {
					processInformation(companys);
				}
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPCompanyTriggerHelper', 'OnBeforeInsert', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void onAfterInsert(Map<ID, ZP_Company__c> newCompanyMap) {
		if (queue == false) {
			List<ZP_Company__c> list_ZPCompaniesToProcess = new List<ZP_Company__c>();

			for (ZP_Company__c objZPCompany : newCompanyMap.values()) {
				if (objZPCompany.Processing_State__c != IntegrationUtils.DEAD_STATE) {
					list_ZPCompaniesToProcess.add(objZPCompany);
				}
			}

			Integer intTriggerSize = list_ZPCompaniesToProcess.size();
			Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
			Integer intBatch = config?.ZP_Company_Batch_Size__c?.intValue() != null && config?.ZP_Company_Batch_Size__c?.intValue() != 0 ? config.ZP_Company_Batch_Size__c.intValue() : 3;

			// Avoid procesing large chunk of zp companies
			if (intTriggerSize <= intBatch) {
				ZPCompanyQueue updateJob = new ZPCompanyQueue(list_ZPCompaniesToProcess);
				updateJob.blnInsert = true;
				ID jobID = System.enqueueJob(updateJob);
			}
		}
	}

	public Boolean validateStatus(List<ZP_Company__c> list_ZPCompanies) {
		ZP_Company__c objZPCompany = list_ZPCompanies[0];
		if (objZPCompany.Processing_State__c == MANUAL_ENQUEUE) {
			return true;
		}
		return false;
	}

	public void onBeforeUpdate(Map<ID, ZP_Company__c> oldCompanyMap, Map<ID, ZP_Company__c> newCompanyMap) {
		counter++;

		try {
			if (!validateStatus(newCompanyMap.values())) {
				// Filter fraudulent records and update proccessing state to "Dead"
				List<ZP_Company__c> list_ZPCompaniesToProcess = returnRecordsToProcess(newCompanyMap.values(), oldCompanyMap);

				for (ZP_Company__c company : list_ZPCompaniesToProcess) {
					// Throw an exception when Testing: START
					if (blnTestExceptions) {
						Integer x = 1 / 0;
					}
					// Throw an exception when Testing: END

					ZP_Company__c oldZPCompany = oldCompanyMap.containsKey(company.Id) ? oldCompanyMap.get(company.Id) : null;
					if (company.Processing_State__c != IntegrationUtils.DEAD_STATE) {
						company.Processing_State__c = IntegrationUtils.QUEUED_STATE;
					}

					if (company.Filing_State_Code__c != oldZPCompany.Filing_State_Code__c && company.CreatedDate.adddays(90) > System.today() && oldZPCompany.Skip_Onboarding_Opp_Creation__c) {
						company.Skip_Onboarding_Opp_Creation__c = false;
						company.HI_Reason__c = '';
					}

					/*
					Alex: if Joined Date is not null, set Joined Date Updated
					Date: Jan 7th
					*/
					if (company.Joined_Date__c != oldCompanyMap.get(company.Id).Joined_Date__c) {
						company.Joined_Date_Updated__c = System.now();
					}

					//@By :Prashant :28-05-2020 : Check if checkbox field is set to true then process account update
					if (company.Accountant_Lead_Id__c != null && company.Accountant_Lead_Id__c != '' && company.Accountant_Lead_Id__c != oldCompanyMap.get(company.Id).Accountant_Lead_Id__c) {
						company.IsChangedAccoutantLeadId__c = true;
					}

					/**
					 * Added By  : David (Dato) Tsamalashvili
					 * Date      : Sep 23, 2020
					 * Desc      : If survey response was filled out later on - capture it and mark zp company to run automation for HI creation.
					 */
					if (oldZPCompany != null) {
						Date date_validation = Date.today().addDays(-30);
						if (company.CreatedDate > date_validation && company.Onboarding_Survey_Offer_Benefits__c == true && oldZPCompany.Onboarding_Survey_Offer_Benefits__c == false) {
							company.Process_HI_Opp_Creation__c = true;
						} else if (
							company.CreatedDate > date_validation &&
							company.Onboarding_Survey_Offer_Benefits__c == false &&
							(company.Onboarding_Survey_Interested_Benefit_Opt__c == 'SMALL_GROUP_HEALTH_INSURANCE' ||
							company.Onboarding_Survey_Interested_Benefit_Opt__c == 'LEARNING_MORE')
						) {
							if (
								oldZPCompany.Onboarding_Survey_Interested_Benefit_Opt__c == null ||
								oldZPCompany.Onboarding_Survey_Interested_Benefit_Opt__c == '' ||
								(oldZPCompany.Onboarding_Survey_Interested_Benefit_Opt__c != 'SMALL_GROUP_HEALTH_INSURANCE' &&
								oldZPCompany.Onboarding_Survey_Interested_Benefit_Opt__c != 'LEARNING_MORE')
							) {
								company.Process_HI_Opp_Creation__c = true;
							}
						}

						if (!company.Is_Changed_Reward_Eligible__c) {
							if (company.Reward_Eligible__c != oldZPCompany.Reward_Eligible__c || company.Managing_Accounting_Firm_Id__c != oldZPCompany.Managing_Accounting_Firm_Id__c) {
								company.Is_Changed_Reward_Eligible__c = true;

								if (String.isNotBlank(oldZPCompany.Managing_Accounting_Firm_Id__c)) {
									company.Old_Managing_Accounting_Firm_ID__c = oldZPCompany.Managing_Accounting_Firm_Id__c;
								}
							}
						}
					}
				}
				if (queue == true) {
					if (updateType == 'LeadConversion') {
						processLeadConversion(list_ZPCompaniesToProcess);
					} else {
						processInformation(list_ZPCompaniesToProcess);
					}
				}
			} else if (validateStatus(newCompanyMap.values())) {
				processInformation(newCompanyMap.values());
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPCompanyTriggerHelper', 'OnBeforeUpdate', 'Exception On Line ' + ex.getLineNumber() + '-' + ex.getMessage(), ex.getStackTraceString());
		}
	}

	public void onAfterUpdate(Map<ID, ZP_Company__c> oldCompanyMap, Map<ID, ZP_Company__c> newCompanyMap) {
		if (queue == false) {
			List<ZP_Company__c> list_ZPCompaniesToProcess = new List<ZP_Company__c>();
			Map<Id, ZP_Company__c> map_prioritizedZPCompanies = new Map<Id, ZP_Company__c>();
			for (ZP_Company__c objZPCompany : newCompanyMap.values()) {
				if (objZPCompany.Processing_State__c != IntegrationUtils.DEAD_STATE && objZPCompany.Processing_State__c != IntegrationUtils.PROCESSED_STATE) {
					list_ZPCompaniesToProcess.add(objZPCompany);
				}
			}

			Integer intTriggerSize = list_ZPCompaniesToProcess.size();
			Configuration_Settings__c config = Configuration_Settings__c.getOrgDefaults();
			Integer intBatch = config?.ZP_Company_Batch_Size__c?.intValue() != null && config?.ZP_Company_Batch_Size__c?.intValue() != 0 ? config.ZP_Company_Batch_Size__c.intValue() : 3;

			// Avoid procesing large chunk of zp companies
			if (intTriggerSize <= intBatch) {
				if (!list_ZPCompaniesToProcess.isEmpty()) {
					ZPCompanyQueue updateJob = new ZPCompanyQueue(list_ZPCompaniesToProcess);
					ID jobID = System.enqueueJob(updateJob);
				}
			} else {
				// Check if any prioritized field is getting updated for any of the zp companies getting updated. If yes, then process them immediately.
				// Fields to prioritize are stored in Custom Metadata
				ZP_Company_Configuration_Settings__mdt objConfig = ZP_Company_Configuration_Settings__mdt.getInstance('OWD');
				List<String> list_ZPCompanyFields = objConfig?.Fields_To_Prioritize__c?.split(',');
				if (list_ZPCompanyFields != null && !list_ZPCompanyFields.isEmpty()) {
					List<String> list_ZPCompanyFieldsToProcess = new List<String>();
					for (String strField : list_ZPCompanyFields) {
						list_ZPCompanyFieldsToProcess.add(strField.trim());
					}
					list_ZPCompanyFields = new List<String>(list_ZPCompanyFieldsToProcess);
				}
				if (list_ZPCompanyFields != null && !list_ZPCompanyFields.isEmpty()) {
					for (ZP_Company__c objZPCompany : list_ZPCompaniesToProcess) {
						ZP_Company__c objOldZPCompany = oldCompanyMap.get(objZPCompany.Id);
						if (map_prioritizedZPCompanies.containsKey(objZPCompany.Id)) {
							continue;
						} else {
							for (String strField : list_ZPCompanyFields) {
								if (objZPCompany.get(strField) != objOldZPCompany.get(strField)) {
									map_prioritizedZPCompanies.put(objZPCompany.Id, objZPCompany);
								}
							}
						}
					}
					if (!map_prioritizedZPCompanies.values().isEmpty()) {
						ZPCompanyQueue updateJob = new ZPCompanyQueue(map_prioritizedZPCompanies.values(), 'Prioritized', objConfig);
						ID jobID = System.enqueueJob(updateJob);
					}
				}
			}
		}
	}

	private Opportunity mapOnboardingFunnelFields(ZP_Company_Onboarding_Funnel__c funnel, Opportunity opp) {
		ZPCompanyOnboardingFunnelTriggerHelper handler = new ZPCompanyOnboardingFunnelTriggerHelper();
		opp = handler.mapOnboardingFunnelFields(funnel, opp);
		return opp;
	}

	private Account mapAccountFields(ZP_Company__c companyInfo, Account acc, Map<String, Account> map_ResellerAccounts) {
		Account objAcct = new Account();

		objAcct.Type = (companyInfo.Embedded_Payroll_Company__c == true ? AccountUtil.EMBEDDED_COMPANY_TYPE : AccountUtil.COMPANY_ACCOUNT_TYPE);
		objAcct.RecordTypeId = (companyInfo.Embedded_Payroll_Company__c == true ? Cache.getRecordTypeId('Account', 'Embedded Company') : Cache.getRecordTypeId('Account', 'Company'));

		if (String.isBlank(companyInfo.Name__c)) {
			objAcct.Name = 'NA';
		} else {
			objAcct.Name = companyInfo.Name__c;
		}

		objAcct.Sic = companyInfo.SIC_Code__c;
		objAcct.Slug__c = companyInfo.SLUG__c;
		objAcct.ZP_Company_ID__c = companyInfo.ID__c;
		if (companyInfo.Created_At__c != null) {
			objAcct.ZP_Company_Create_Date__c = date.newinstance(companyInfo.Created_At__c.year(), companyInfo.Created_At__c.month(), companyInfo.Created_At__c.day());
		}
		if (companyInfo.Benefits_Effective_Date__c != null) {
			objAcct.Benefits_Effective_Date__c = companyInfo.Benefits_Effective_Date__c;
		}

		objAcct.ZP_Company_Approval_Status__c = companyInfo.Approval_Status__c;
		if (companyInfo.Anchor_Pay_Date__c != null) {
			objAcct.Anchor_Pay_Date__c = companyInfo.Anchor_Pay_Date__c;
		}
		objAcct.Average_Salary__c = companyInfo.Average_Salary__c;
		objAcct.EE_Active_Count_Panda__c = companyInfo.Number_of_Active_Employees__c;
		objAcct.ZP_Company_Lead_ID__c = companyInfo.Company_Lead_Id__c;
		objAcct.BillingCountryCode = 'US';
		objAcct.BillingCountry = 'United States';
		objAcct.BillingStreet = companyInfo.Filing_Street__c;
		// substring first 40 characters of filing city if length exceeds more than 40 characters
		if (String.isNotBlank(companyInfo.Filing_City__c) && companyInfo.Filing_City__c.length() > 40) {
			objAcct.BillingCity = companyInfo.Filing_City__c.subString(0, 40);
		} else {
			objAcct.BillingCity = companyInfo.Filing_City__c;
		}

		objAcct.BillingStateCode = companyInfo.Filing_State_Code__c;
		objAcct.BillingPostalCode = companyInfo.Filing_Postal_Code__c;
		objAcct.First_Contractor_Payment_Date__c = companyInfo.First_Contractor_Payment_Date__c;
		objAcct.First_Payroll_Date__c = companyInfo.First_Payroll_Date__c;
		objAcct.Has_Active_WC_Policy__c = companyinfo.Has_Active_WC_Policy__c;
		objAcct.Joined_Date_Panda__c = companyInfo.Joined_Date__c;
		objAcct.ShippingCountryCode = 'US';
		objAcct.ShippingCountry = 'United States';
		objAcct.ShippingStreet = companyInfo.Mailing_Street__c;

		// substring first 40 characters of mailing city if length exceeds more than 40 characters
		if (String.isNotBlank(companyInfo.Mailing_City__c) && companyInfo.Mailing_City__c.length() > 40) {
			objAcct.ShippingCity = companyInfo.Mailing_City__c.subString(0, 40);
		} else {
			objAcct.ShippingCity = companyInfo.Mailing_City__c;
		}

		objAcct.ShippingStateCode = companyInfo.Mailing_State_Code__c;
		objAcct.ShippingPostalCode = companyInfo.Mailing_Postal_Code__c;

		if (acc.First_Month_Invoice_Generated__c || acc.Joined_Date_Panda__c == null) {
			objAcct.Number_of_Active_Contractors__c = companyInfo.Number_of_Active_Contractors__c;
			objAcct.Number_of_Active_Employees__c = companyInfo.Number_of_Active_Employees__c;
		}

		objAcct.Number_of_trial_Months__c = companyInfo.Number_of_trial_Months__c;
		objAcct.Payroll_Processing_Last_Modified__c = companyInfo.Payroll_Processing_Last_Modified__c;
		objAcct.Payroll_Processing_Status__c = companyInfo.Payroll_Processing_Status__c;
		objAcct.Sic = companyInfo.SIC_Code__c;
		objAcct.Slug__c = companyInfo.Slug__c;
		objAcct.States__c = companyInfo.States__c;
		objAcct.Corporation_Type__c = companyInfo.Tax_Payer_Type__c;
		objAcct.WC_Renewal_Date__c = companyInfo.WC_Renewal_Date__c;
		objAcct.With_Funded_Payrolls__c = companyInfo.With_Funded_Payrolls__c;
		objAcct.Previous_Payroll_Provider__c = companyInfo.previous_payroll_provider__c;
		objAcct.Has_Previous_Payroll_Provider__c = companyInfo.has_paid_w2__c;
		objAcct.Previous_Provider_Offering__c = companyInfo.previous_provider_offering__c;
		objAcct.Company_Created_Through__c = companyInfo.company_created_through__c;
		objAcct.Cashout_activated_at__c = companyInfo.Cashout_activated_at__c;
		objAcct.Cashout_deactivated_at__c = companyInfo.Cashout_deactivated_at__c;
		objAcct.Cashout_Deactivated_reason__c = companyInfo.Cashout_Deactivated_reason__c;
		objAcct.ACH_Speed__c = companyInfo.ACH_Speed__c;
		objAcct.Desired_First_Pay_Date__c = companyInfo.Desired_First_Pay_Date__c;
		objAcct.Is_Historical__c = companyInfo.Is_Historical__c;
		objAcct.Payroll_Blockers__c = companyInfo.Payroll_Blockers__c;
		objAcct.Has_Previous_Payrolls_in_Desired_Year__c = companyInfo.Has_Previous_Payrolls_in_Desired_Year__c;
		objAcct.Industry_Identification__c = companyInfo.Industry_Identification__c;
		objAcct.Pre_onboarding_Desired_First_Pay_Date__c = companyInfo.Pre_onboarding_Desired_First_Pay_Date__c;
		objAcct.user_email_confirmation_completed_at__c = companyInfo.user_email_confirmation_completed_at__c;
		objAcct.Tier_and_Plan_Status__c = companyInfo.Tier_and_Plan_Status__c;
		objAcct.Workers_Comp_Status__c = companyInfo.Workers_Comp_Status__c;
		objAcct.Provider_401K__c = companyInfo.Provider_401K__c;

		if (acc.Id == null && (companyInfo.Number_of_Active_Employees__c == null || companyInfo.Number_of_Active_Employees__c == 0) && companyInfo.Company_Lead_Number_of_Employees__c != null) {
			objAcct.NumberOfEmployees = companyInfo.Company_Lead_Number_of_Employees__c != null ? (Integer) companyInfo.Company_Lead_Number_of_Employees__c : 0;
		}
		// Set Referral Information (Referral Type and Referred By)
		if (String.isNotBlank(companyInfo.Referral_Type__c) && companyInfo.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
			objAcct.Referral_Type__c = companyInfo.Referral_Type__c;
		}

		if (companyInfo.Embedded_Payroll_Company__c) {
			objAcct.Referred_By__c = companyInfo.Embedded_Partner__c;
		} else {
			objAcct.Referred_By__c = map_ResellerAccounts.containsKey(companyInfo.Referred_by_Accounting_Firm_ID__c)
				? map_ResellerAccounts.get(companyInfo.Referred_by_Accounting_Firm_ID__c).Id
				: null;
		}

		// ZP PPCD to ZP Company Transition
		if (
			String.isNotBlank(companyInfo.Partner_Billing__c) &&
			(companyInfo.Partner_Billing__c.containsIgnoreCase(ZPCompanyUtil.BILLING_PARTNER_BILLED) || companyInfo.Partner_Billing__c.containsIgnoreCase(ZPCompanyUtil.BILLING_CLIENT_BILLED))
		) {
			if (companyInfo.Deleted_At__c == null) {
				objAcct.Sold_By__c = map_ResellerAccounts.containsKey(companyInfo.Managing_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(companyInfo.Managing_Accounting_Firm_Id__c).Id : null;

				objAcct.Partner_Billing__c = companyInfo.Partner_Billing__c;
				objAcct.Reward_Eligible__c = companyInfo.Reward_Eligible__c;
			} else {
				objAcct.Sold_By__c = null;
				objAcct.Reward_Eligible__c = false;
				objAcct.Partner_Billing__c = '';
			}

			objAcct.Original_Firm__c = map_ResellerAccounts.containsKey(companyInfo.Original_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(companyInfo.Original_Accounting_Firm_Id__c).Id : null;

			objAcct.Managing_Firm__c = objAcct.Sold_By__c;
		}
		objAcct.Onboarding_Survey_Best_Time_to_Contact__c = companyInfo.Onboarding_Survey_Best_Time_to_Contact__c;
		objAcct.Next_Payroll_Actual_Check_Date__c = companyInfo.Next_Payroll_Actual_Check_Date__c;
		objAcct.Potential_Fraud_Account__c = companyInfo.Potential_Fraud__c;
		objAcct.Date_of_GEP_Live__c = companyInfo.Date_of_GEP_Live__c;
		//Parent Account Mapping added for BMM-307
		objAcct.ParentId = map_AllAccounts.containsKey(companyInfo.Parent_Company_Id__c) ? map_AllAccounts.get(companyInfo.Parent_Company_Id__c).Id : null;

		objAcct.NAICS_Code__c = companyInfo.NAICS_Code__c;
		objAcct.Has_Benefits_401k__c = companyInfo.Has_Benefits_401k__c;
		objAcct.Product_Experiments__c = companyInfo.Product_Experiments__c;
		objAcct.International_Contractors__c = companyInfo.Active_International_Contractors__c;
		objAcct.International_Employees__c = companyInfo.Active_International_Employees__c;
		//add product interest data to account from ZP Company
		Account objAccountHaveProductInterest = updateProductInterestFields(companyInfo, acc);
		objAcct.Product_Interest__c = objAccountHaveProductInterest.Product_Interest__c;
		objAcct.Product_Interest_Countries__c = objAccountHaveProductInterest.Product_Interest_Countries__c;
		objAcct.Confirmed_MRB__c = companyInfo.Confirmed_MRB__c;

		String strHelpJourneyRouting = '';
		if (acc.Id != null) {
			strHelpJourneyRouting = acc.Help_Journey_Routing__c;
		}

		if (companyInfo.Has_any_Invited_International_Employee__c) {
			if (String.isBlank(strHelpJourneyRouting) || (String.isNotBlank(strHelpJourneyRouting) && !strHelpJourneyRouting.contains(GUSTO_GLOBAL))) {
				strHelpJourneyRouting = String.isNotBlank(strHelpJourneyRouting) ? strHelpJourneyRouting + ';' + GUSTO_GLOBAL : GUSTO_GLOBAL;
			}
		} else if (String.isNotBlank(strHelpJourneyRouting)) {
			if (strHelpJourneyRouting.contains(GUSTO_GLOBAL)) {
				strHelpJourneyRouting = strHelpJourneyRouting.replace(GUSTO_GLOBAL, '');
			}

			strHelpJourneyRouting = strHelpJourneyRouting.removeStart(';');
			strHelpJourneyRouting = strHelpJourneyRouting.removeEnd(';');
			if (strHelpJourneyRouting.contains(';;')) {
				strHelpJourneyRouting = strHelpJourneyRouting.replace(';;', ';');
			}
		}

		objAcct.Help_Journey_Routing__c = strHelpJourneyRouting;
		return objAcct;
	}

	/**
	 * Desc: Populate Product interest data to the account from ZP Company. ZP Company is a staging table and directly getting the value from Panda.
	 * @param objCompany , objAcc
	 * @return  Account
	 */
	private Account updateProductInterestFields(ZP_Company__c objCompany, Account objAcc) {
		Set<String> set_ProductInterestCountries = new Set<String>();
		Set<String> set_ExistingAccProductInterest = new Set<String>();
		List<String> list_ExistingZPCompProductInterest = new List<String>();
		List<String> list_FinalProductInterest = new List<String>();
		Boolean blnLogACall = false;
		if (String.isNotBlank(objAcc.Product_Interest__c)) {
			set_ExistingAccProductInterest.addAll(objAcc.Product_Interest__c.split(';'));
		}

		if (String.isNotBlank(objCompany.Product_Interest__c)) {
			for (String strProdInterest : objCompany.Product_Interest__c.split(';')) {
				/**if (!strProdInterest.containsIgnoreCase('international_contractor')) {
					//set_ExistingAccProductInterest.add(strProdInterest);
					list_ExistingZPCompProductInterest.add(strProdInterest);
				}**/
				list_ExistingZPCompProductInterest.add(strProdInterest);
			}
		}

		for (String strZPCompanyProdInterest : list_ExistingZPCompProductInterest) {
			if (!set_ExistingAccProductInterest.contains(strZPCompanyProdInterest)) {
				if (strZPCompanyProdInterest.containsIgnoreCase('international_payroll_landing_page_consent')) {
					strZPCompanyProdInterest = 'international_payroll_landing_page_consent';
				}
				set_ExistingAccProductInterest.add(strZPCompanyProdInterest);
			}
		}

		list_FinalProductInterest.addAll(set_ExistingAccProductInterest);
		objAcc.Product_Interest__c = String.join(list_FinalProductInterest, ';');
		//if account has the product interest country
		if (String.isNotBlank(objAcc.Product_Interest_Countries__c)) {
			set_ProductInterestCountries.addAll(objAcc.Product_Interest_Countries__c.split(';'));
			if (String.isNotBlank(objCompany.Product_Interest_Countries__c)) {
				// add the new country but don't remove the alrady added to the account.
				for (String strProductInterestCountry : objCompany.Product_Interest_Countries__c.split(';')) {
					if (!set_ProductInterestCountries.contains(strProductInterestCountry)) {
						objAcc.Product_Interest_Countries__c += ';' + strProductInterestCountry;
					}
				}
			}
		} else {
			objAcc.Product_Interest_Countries__c = objCompany.Product_Interest_Countries__c;
		}
		return objAcc;
	}

	private Opportunity mapOpportunityFields(ZP_Company__c companyInfo, Account acc, Opportunity oppty, map<String, PriceBook2> prodMap, Map<String, Account> map_ResellerAccounts) {
		Opportunity opp = new Opportunity();
		String strAccountName = acc.Name;

		// if name exceeds more than 100 characters, take the first 100 characters
		if (String.isNotBlank(strAccountName) && strAccountName.length() > 100) {
			strAccountName = strAccountName.substring(0, 100);
		}
		opp.RecordTypeId = companyInfo.Embedded_Payroll_Company__c == true ? Cache.getRecordTypeId('Opportunity', 'Embedded Company Opportunity') : Cache.getRecordTypeId('Opportunity', 'Acquisition');
		opp.Name = companyInfo.Embedded_Payroll_Company__c == true ? strAccountName + ' Embedded Company' : strAccountName + ' - New Business';

		// set default stage on embedded opps to MQL
		if (companyInfo.Embedded_Payroll_Company__c) {
			opp.StageName = OpportunityUtil.MQL_STAGE;
		}

		opp.AccountId = acc.Id;
		opp.ZP_Company_ID__c = companyInfo.ID__c;
		if (companyInfo.Anchor_Pay_Date__c != null) {
			opp.Anchor_Pay_Date__c = companyInfo.Anchor_Pay_Date__c;
		}
		if (oppty != null && oppty.Id != null && String.isNotBlank(oppty.Source_Id__c)) {
			opp.Source_Id__c = oppty.Source_Id__c;
		} else {
			opp.Source_Id__c = companyInfo.Id__c + '-newbusiness' + '-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year();
		}
		opp.ZP_First_Contractor_Payment_Date__c = companyInfo.First_Contractor_Payment_Date__c;
		opp.ZP_First_Payroll_Date__c = companyInfo.First_Payroll_Date__c;
		opp.Is_Historical__c = companyInfo.Is_Historical__c;
		opp.Fast_ACH__c = companyInfo.Fast_Ach__c;
		opp.Previous_Payroll_Provider__c = companyInfo.previous_payroll_provider__c;
		opp.Payroll_Blockers__c = companyInfo.Payroll_Blockers__c;
		opp.Has_Previous_Payrolls_in_Desired_Year__c = companyInfo.Has_Previous_Payrolls_in_Desired_Year__c;
		opp.Industry_Identification__c = companyInfo.Industry_Identification__c;
		opp.Pre_onboarding_Desired_First_Pay_Date__c = companyInfo.Pre_onboarding_Desired_First_Pay_Date__c;
		opp.International_Contractors__c = companyInfo.Active_International_Contractors__c;
		// opp.International_Employees__c = companyInfo.Active_International_Employees__c;

		if (oppty.Id == null || ((oppty.NumberOfEmployees__c == null || oppty.NumberOfEmployees__c == 0) && companyInfo.Number_of_Active_Employees__c > 0)) {
			opp.NumberOfEmployees__c = companyInfo.Number_of_Active_Employees__c;
		} else if (oppty.Id == null && companyInfo.Company_Lead_Number_of_Employees__c != null) {
			opp.NumberOfEmployees__c = companyInfo.Company_Lead_Number_of_Employees__c != null ? (Integer) companyInfo.Company_Lead_Number_of_Employees__c : 0;
		}
		if (oppty.Id == null || ((oppty.NumberOfEmployees__c == null || oppty.NumberOfEmployees__c == 0) && companyInfo.Number_of_Active_Employees__c > 0)) {
			opp.Number_of_Contractors__c = companyInfo.Number_of_Active_Contractors__c;
		}

		// Set Referral Information (Referral Type and Referred By)
		if (String.isNotBlank(companyInfo.Referral_Type__c) && companyInfo.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
			opp.Referral_Type__c = companyInfo.Referral_Type__c;
		}
		opp.Referred_By__c = map_ResellerAccounts.containsKey(companyInfo.Referred_by_Accounting_Firm_ID__c) ? map_ResellerAccounts.get(companyInfo.Referred_by_Accounting_Firm_ID__c).Id : null;

		// ZP PPCD to ZP Company Transition
		if (
			String.isNotBlank(companyInfo.Partner_Billing__c) &&
			(companyInfo.Partner_Billing__c.containsIgnoreCase('partner_billed') || companyInfo.Partner_Billing__c.containsIgnoreCase('client_billed'))
		) {
			if (companyInfo.Deleted_At__c == null) {
				// Updating Sold By based on Managing Accounting Firm Id
				opp.Sold_By__c = map_ResellerAccounts.containsKey(companyInfo.Managing_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(companyInfo.Managing_Accounting_Firm_Id__c).Id : null;
				opp.False_Sold_By__c = String.isNotBlank(companyInfo.Managing_Accounting_Firm_Id__c) &&
					map_ZPAcctFirms.containsKey(companyInfo.Managing_Accounting_Firm_Id__c) &&
					map_ZPAcctFirms.get(companyInfo.Managing_Accounting_Firm_Id__c).Created_At__c != null &&
					companyInfo.Created_At__c != null &&
					map_ZPAcctFirms.get(companyInfo.Managing_Accounting_Firm_Id__c).Created_At__c > companyInfo.Created_At__c
					? true
					: false;

				// Updating Billed To based on Partner Billing
				if (companyInfo.Partner_Billing__c.containsIgnoreCase('partner_billed')) {
					opp.Billed_To__c = 'Accountant Billed';
				} else if (companyInfo.Partner_Billing__c.containsIgnoreCase('client_billed')) {
					opp.Billed_To__c = 'Client Billed';
				}
			} else {
				opp.Sold_By__c = null;
				opp.Billed_To__c = '';
				opp.False_Sold_By__c = opp.False_Sold_By__c ? false : false;
			}

			opp.Original_Firm__c = map_ResellerAccounts.containsKey(companyInfo.Original_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(companyInfo.Original_Accounting_Firm_Id__c).Id : null;

			// Setting if Opportunity is Eligible for Discount
			opp.Discount_Eligible__c = companyInfo.Reward_Eligible__c;
		}

		opp.Tier_and_Plan_Status__c = companyInfo.Tier_and_Plan_Status__c;
		opp.Product_Experiments_Opportunity__c = companyInfo.Product_Experiments__c;
		//Adding BDO field mappings
		opp.Contribution_to_EE_Health_Coverage_cost__c = companyInfo.Contribution_to_EE_Health_Coverage_cost__c;
		if (String.isNotBlank(companyInfo.Currently_Offer_Health_Benefits__c)) {
			opp.Currently_Offer_Health_Benefits__c = companyInfo.Currently_Offer_Health_Benefits__c == 'true' ? 'Yes' : companyInfo.Currently_Offer_Health_Benefits__c;
		}
		opp.Existing_Health_Benefits_Renewal_Date__c = companyInfo.Existing_Health_Benefits_Renewal_Date__c;
		opp.Interest_in_adding_benefits_to_Gusto__c = companyInfo.Interest_in_adding_benefits_to_Gusto__c;
		opp.Interested_in_offering_HI_to_employees__c = companyInfo.Interested_in_offering_HI_to_employees__c;
		opp.Open_to_Switching_Broker__c = companyInfo.Open_to_Switching_Broker__c;
		opp.Which_Gusto_Benefits_Interested_In__c = companyInfo.Which_Gusto_Benefits_Interested_In__c;
		opp.When_To_Start_Offering_Benefits__c = companyInfo.When_To_Start_Offering_Benefits__c;
		opp.Who_To_Contact__c = companyInfo.Who_To_Contact__c;
		opp.Initiated_by_Accountant__c = companyInfo.Initiated_by_Accountant__c;
		opp.Want_to_switch_brokers__c = companyInfo.Want_to_switch_brokers__c;
		opp.Recommended_Add_On__c = companyInfo.Recommended_Add_On__c;
		opp.Recommended_Benefits__c = companyInfo.Recommended_Benefits__c;
		opp.Recommended_Plan__c = companyInfo.Recommended_Plan__c;
		opp.Selected_Add_On__c = companyInfo.Selected_Add_On__c;
		opp.Selected_Benefits__c = companyInfo.Selected_Benefits__c;
		opp.Selected_Plan__c = companyInfo.Selected_Plan__c;
		return opp;
	}

	public void processInformation(List<ZP_Company__c> companyList) {
		partnerAccountMap = new Map<String, Account>();
		Map<String, String> dmlLeadInsertErrorsMap = new Map<String, String>();
		Set<String> companyIdSet = new Set<String>();
		Set<String> emailIdSet = new Set<String>();
		Set<String> failedCompanyEmailSet = new Set<String>();
		Set<String> newCompanyIdNoLeadSet = new Set<String>();
		map<String, ZP_Company__c> companyMap = new Map<String, ZP_Company__c>();
		List<Account> accountList = new List<Account>();
		List<Opportunity> opportunityList = new List<Opportunity>();
		List<Contact> contactList = new List<Contact>();
		map<String, String> emailIdCompanyIdMap = new Map<String, String>();
		Map<String, String> map_AccountantLeadIdAndSourceId = new Map<String, String>();
		List<Account> list_AccountsToUpdateSoldBYAccountantLead = new List<Account>();
		Set<Id> set_leadId = new Set<Id>();
		Map<String, Date> map_AccountantLeadIdCreatedDateMap = new Map<String, Date>();
		Set<String> set_FirmIds = new Set<String>();
		list_Competitors = Label.Competitors.toLowerCase().split(',');
		list_Partners = Label.Partners.toLowerCase().split(',');
		list_Employees = Label.Employees.toLowerCase().split(',');
		Set<String> set_RewardEligibleFirms = new Set<String>();
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
		List<Account> list_AccountsToUpdate = new List<Account>();
		Map<String, String> map_DmlUpdateErrors = new Map<String, String>();

		List<Partner_Program_Company_Data__c> list_PartnerPrograms = new List<Partner_Program_Company_Data__c>();
		Map<String, String> map_DmlPartnerProgramUpsertErrors = new Map<String, String>();
		Map<String, String> dmlUpsertErrorsMap = new Map<String, String>();

		for (ZP_Company__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (company.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				company.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			//@By :Prashant :28-05-2020 : if accountant lead id is not null
			if (company.IsChangedAccoutantLeadId__c == true) {
				if (String.isNotBlank(company.Accountant_Lead_Id__c) && String.isNotBlank(company.ID__c)) {
					map_AccountantLeadIdAndSourceId.put(company.Accountant_Lead_Id__c, company.ID__c);
				}
				// Update Map with Accountant Lead Id and ZP Company Created Date
				map_AccountantLeadIdCreatedDateMap.put(company.Accountant_Lead_Id__c, company.CreatedDate.date());
			}

			companyMap.put(company.Created_By_Email__c, company);
			companyIdSet.add(company.Id__c);
			company.Message__c = '';
			if (String.isNotBlank(company.Referred_by_Accounting_Firm_ID__c)) {
				set_FirmIds.add(company.Referred_by_Accounting_Firm_ID__c);
			}

			// Add old and new firm ids
			if (String.isNotBlank(company.Managing_Accounting_Firm_Id__c)) {
				set_FirmIds.add(company.Managing_Accounting_Firm_Id__c);

				if (company.Is_Changed_Reward_Eligible__c) {
					set_RewardEligibleFirms.add(company.Managing_Accounting_Firm_Id__c);
				}
			}

			if (String.isNotBlank(company.Old_Managing_Accounting_Firm_Id__c)) {
				set_FirmIds.add(company.Old_Managing_Accounting_Firm_Id__c);

				if (company.Is_Changed_Reward_Eligible__c) {
					set_RewardEligibleFirms.add(company.Old_Managing_Accounting_Firm_Id__c);
				}
			}

			if (String.isNotBlank(company.Original_Accounting_Firm_Id__c)) {
				set_FirmIds.add(company.Original_Accounting_Firm_Id__c);
			}

			if (String.isNotBlank(company.Parent_Company_Id__c)) {
				set_parentCompanyIds.add(company.Parent_Company_Id__c);
			}

			if (String.isNotBlank(company.Embedded_Partner_Id__c)) {
				set_EmbeddedPartnerId.add(company.Embedded_Partner_Id__c);
			}

			if (String.isNotBlank(company.Embedded_Partner_UUID__c)) {
				set_EmbeddedPartnerUUID.add(company.Embedded_Partner_UUID__c);
			}
		}

		Map<String, Id> companySoldByMap = getCompanySoldbyMap(companyIdSet);

		for (ZP_Company__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (company.Created_By_Email__c != null && company.Created_By_Email__c != '') {
				emailIdSet.add(company.Created_By_Email__c);
				emailIdCompanyIdMap.put(company.Created_By_Email__c, company.Id__c);
				company.Created_With_Lead__c = true;
			}
		}

		// get matching ZP Accounting Firms records
		getZPAccoutingFirms(emailIdSet, set_FirmIds);

		Set<String> set_WOLeadConversionCompanyIds = new Set<String>(); //Yuvraj 28-07-2020

		Map<String, Contact> matchingContactsMap = getContactsByEmail(emailIdSet);

		// get matching leads and convert them. If there are errors log them.
		Map<String, Lead> matchingLeadsMap = getAllLeadsByEmail(emailIdSet);

		/**
		 * Added by David (Dato) Tsamalashvili - April 17, 2020
		 * If lead doesn't exist - flag it for workato
		 */
		List<Lead> createLeadList = new List<Lead>();
		Map<String, Account> map_ResellerAccounts = getAccountsFirm(set_FirmIds); //to Get Account id from Accounts
		for (ZP_Company__c zp : companyList) {
			if (
				zp.Created_By_Email__c != null &&
				zp.company_created_through__c != null &&
				(zp.company_created_through__c == 'onboarding_companies_service' ||
				zp.company_created_through__c == 'public_api') &&
				zp.Account__c == null &&
				!matchingLeadsMap.containsKey(zp.Created_By_Email__c) &&
				!matchingContactsMap.containsKey(zp.Created_By_Email__c) &&
				!zp.Embedded_Payroll_Company__c
			) {
				Lead newLead = new Lead();
				newLead.LastName = zp.Company_Lead_Last_Name__c;
				newLead.RecordTypeId = Cache.getRecordTypeId('Lead', 'Company');
				newLead.Company = zp.Name__c;
				newLead.NumberOfEmployees = zp.Company_Lead_Number_of_Employees__c != null ? (Integer) zp.Company_Lead_Number_of_Employees__c : 0;
				newLead.LeadSource = zp.Company_Lead_Source__c;
				newLead.ZP_Company_Lead_ID__c = zp.Company_Lead_Id__c;
				newLead.Email = zp.Created_By_Email__c;
				newLead.Lead_Type__c = 'Company';
				newLead.Referral_Type__c = zp.Referral_Type__c;
				newLead.Lead_Creation_Offer__c = 'Product Registration';
				newLead.ZP_Company_Id__c = zp.Id__c;
				newlead.Referred_By__c = map_ResellerAccounts.containsKey(zp.Referred_by_Accounting_Firm_ID__c) ? map_ResellerAccounts.get(zp.Referred_by_Accounting_Firm_ID__c).Id : null;
				newLead.Phone = zp.Company_Lead_Phone__c;
				newLead.Status = LeadUtil.LEAD_STATUS_MQL;

				// Lead Promotion Changes
				if (String.isNotBlank(Zp.Created_By_Email__c) && String.isNotBlank(zp.Company_Lead_Phone__c)) {
					String strDomain = Zp.Created_By_Email__c.toLowerCase().split('@')[1];
					if (!list_Competitors.contains(strDomain) && !list_Partners.contains(strDomain) && !list_Employees.contains(strDomain)) {
						if (String.isBlank(Zp.Referral_Type__c)) {
							newLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
						} else {
							if (String.isNotBlank(Zp.Referral_Type__c) && Zp.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_US)) {
								newLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_CR;
							}

							if (String.isNotBlank(Zp.Referral_Type__c) && Zp.Referral_Type__c.equalsIgnoreCase(LeadUtil.REFERRAL_TYPE_UR)) {
								newLead.MQL_Reason__c = LeadUtil.LEADCREATION_OFFER_PR;
							}
						}
					}
				} else {
					newLead.MQL_Reason__c = 'SAL';
				}
				// Set Lead Creation Offer as Product Registration
				if (String.isBlank(zp.Referral_Type__c)) {
					newlead.Lead_Creation_Offer__c = LeadUtil.LEADCREATION_OFFER_PROD_GEN;
				}
				newLead.FirstName = ZPCompanyUtil.LEAD_NAME_NA;
				createLeadList.add(newLead);
			}
		}

		if (createLeadList.size() > 0) {
			List<Database.SaveResult> leadInsertResults = Database.insert(createLeadList, false);
			dmlLeadInsertErrorsMap = Utils.processSaveResult(leadInsertResults, createLeadList, 'Email', false, 'ZPCompanyTriggerHelper :: ProcessInformation :: Create Lead');
			if (dmlLeadInsertErrorsMap.keySet().size() > 0) {
				for (ZP_Company__c company : companyList) {
					if (dmlLeadInsertErrorsMap.containsKey(company.Created_By_Email__c)) {
						setProcessingState(IntegrationUtils.ERROR_STATE, 'Lead Creation Failed', company);
						failedCompanyEmailSet.add(company.Created_By_Email__c);
					}
				}
			}
		}
		matchingLeadsMap = getLeadsByEmail(emailIdSet);

		for (ZP_Company__c zp : companyList) {
			if (zp.Created_By_Email__c != null && zp.Created_By_Email__c != '' && !matchingLeadsMap.containsKey(zp.Created_By_Email__c) && zp.CreatedDate >= Date.today().addDays(-1)) {
				zp.Force_Lead_Creation__c = true;
			}

			if (zp.Created_By_Email__c != null && zp.Created_By_Email__c != '' && !matchingLeadsMap.containsKey(zp.Created_By_Email__c)) {
				set_WOLeadConversionCompanyIds.add(zp.ID__c);
			}
		}

		//update matching leads with companyid if it does not exist
		List<Lead> leadUpdateList = new List<Lead>();
		for (lead l : matchingLeadsMap.values()) {
			ZP_Company__c objZPCompany = companyMap.containsKey(l.Email) ? companyMap.get(l.Email) : null;
			Boolean blnIsLeadUpdated = false;
			if ((l.ZP_Company_ID__c == null || l.ZP_Company_ID__c == '') && emailIdCompanyIdMap.containsKey(l.email)) {
				l.ZP_Company_ID__c = emailIdCompanyIdMap.get(l.email);
				if (l.Status != null && (l.Status == 'Raw' || l.Status == 'AQL')) {
					l.Status = 'MQL';
					l.MQL_Reason__c = 'SAL';
					blnIsLeadUpdated = true;
				}
			}
			if (objZPCompany != null) {
				blnIsLeadUpdated = true;
				l.Referred_By__c = map_ResellerAccounts.containsKey(objZPCompany.Referred_by_Accounting_Firm_ID__c)
					? map_ResellerAccounts.get(objZPCompany.Referred_by_Accounting_Firm_ID__c).Id
					: null;
			}
			if (blnIsLeadUpdated) {
				leadUpdateList.add(l);
			}
		}

		if (leadUpdateList.size() > 0) {
			updateLeadInformation(leadUpdateList, companyMap);
		}

		processConvertedLeads(companyMap, emailIdSet, companyIdSet);
		Map<String, Account> accountMap = getAccounts(companyIdSet);
		matchingLeadsMap = getLeadsByEmail(emailIdSet);

		// insert account if account does not exist and contact exists with matching email address
		for (ZP_Company__c objCompany : companyList) {
			List<Account> list_AccsToInsert = new List<Account>();
			if (
				matchingContactsMap != null &&
				accountMap != null &&
				matchingLeadsMap != null &&
				matchingLeadsMap.containsKey(objCompany.Created_By_Email__c) &&
				matchingContactsMap.containsKey(objCompany.Created_By_Email__c) &&
				!accountMap.containsKey(objCompany.ID__c)
			) {
				Account objAcc = new Account();
				objAcc = mapAccountFields(objCompany, objAcc, map_ResellerAccounts);
				list_AccsToInsert.add(objAcc);
				accountMap.put(objCompany.ID__c, objAcc);
			}

			if (list_AccsToInsert.size() > 0) {
				List<Database.UpsertResult> saveResult = Database.upsert(list_AccsToInsert, Account.Fields.ZP_Company_ID__c, false);
				dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, list_AccsToInsert, 'ZP_Company_ID__c', true, 'ZPCompanyTriggerHepler-accountInsert');
			}
		}

		Map<Id, Lead> map_ldIdToLead = new Map<Id, Lead>();
		Map<String, Set<String>> map_companyIdToChildCompanyIds = getAllChildAccountsZPCompanIds(companyIdSet);

		if (matchingLeadsMap != null && matchingLeadsMap.size() > 0) {
			for (Lead ld : matchingLeadsMap.values()) {
				map_ldIdToLead.put(ld.Id, ld);
			}
		}

		List<Database.LeadConvertResult> convertResults = new List<Database.LeadConvertResult>();
		if (LABEL.ZP_Company_Lead_Conversion_Flag == 'true') {
			List<Database.LeadConvert> lst_leadsToConvert = populateZPCompanyConversionList(companyList, emailIdSet, matchingLeadsMap, accountMap, matchingContactsMap);
			if (lst_leadsToConvert.size() > 0) {
				convertResults = Database.convertLead(lst_leadsToConvert, false);
			}
		} else {
			LeadConversion.ConversionResult conversionResult = LeadConversion.convert(matchingLeadsMap.values());
			convertResults = conversionResult.convertResults;
		}
		integer i = 0;
		for (Lead l : matchingLeadsMap.values()) {
			if (i >= convertResults.size()) {
				break;
			}
			Database.LeadConvertResult result = convertResults[i];
			if (result.getErrors().size() > 0) {
				String error = Utils.ConsolidateErrors(result.getErrors());
				failedCompanyEmailSet.add(l.Email);
				ZP_Company__c zpCompany = companyMap.get(l.email);
				setProcessingState(IntegrationUtils.ERROR_STATE, error, zpCompany);
			} else if (result.OpportunityId == null) {
				failedCompanyEmailSet.add(l.email);
				ZP_Company__c zpCompany = companyMap.get(l.email);
				setProcessingState(IntegrationUtils.ERROR_STATE, 'OpportunityId is not generated', zpCompany);
			}
			i = i + 1;
		}
		matchingContactsMap = getContactsByEmail(emailIdSet);
		accountMap = getAccounts(companyIdSet);
		for (ZP_Company__c company : companyList) {
			// do not try to upsert account if lead conversion is pending
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE || company.Message__c == ZPCompanyUtil.ASYNC_LEAD_CONVERSION_PENDING) {
				continue;
			}
			if (failedCompanyEmailSet.contains(company.Created_By_Email__c)) {
				continue;
			}

			Partner_Program_Company_Data__c objPartnerProgram = mapProgramData(company, accountMap, map_ResellerAccounts);

			if (String.isNotBlank(objPartnerProgram.Id__c)) {
				list_PartnerPrograms.add(objPartnerProgram);
			}

			if (String.isNotBlank(objPartnerProgram.Managing_Accounting_Firm_Id__c) && objPartnerProgram.Managing_Accounting_Firm__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Managing Accounting Firm does not exist', company);
			}

			if (String.isNotBlank(objPartnerProgram.Original_Accounting_Firm_Id__c) && objPartnerProgram.Original_Accounting_Firm__c == null) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Original Accounting Firm does not exist', company);
			}

			Account acc = new Account();
			if (accountMap.containsKey(company.Id__c)) {
				acc = accountMap.get(company.Id__c);

				/* Adding below code to associate Original Accounting firm with Accounting company for Free Partner Payroll project*/
				if (map_ResellerAccounts.containsKey(company.Original_Accounting_Firm_Id__c) && company.Is_Original_Firm__c == true && company.Deleted_At__c == null) {
					Account objResellerAccount = map_ResellerAccounts.get(company.Original_Accounting_Firm_Id__c);
					Account objResellerAccountToUpdate = map_AccountsToUpdate.containsKey(objResellerAccount.Id)
						? map_AccountsToUpdate.get(objResellerAccount.Id)
						: new Account(Id = objResellerAccount.Id);

					if (objResellerAccount.Reseller_Company__c == null && acc.Id != null) {
						objResellerAccountToUpdate.Reseller_Company__c = acc.Id;
						map_AccountsToUpdate.put(objResellerAccountToUpdate.Id, objResellerAccountToUpdate);
					}
				}
			} else if (company.Created_With_Lead__c == true) {
				if (!matchingContactsMap.containsKey(company.Created_By_Email__c) && !matchingLeadsMap.containsKey(company.Created_By_Email__c)) {
					if (company.Account__c == null) {
						company.Force_Lead_Creation__c = true;
					}
				}
			} else {
				newCompanyIdNoLeadSet.add(company.Id__c);
			}

			if (String.isNotBlank(company.ID__c) && String.isNotBlank(company.Parent_Company_Id__c) && company.ID__c == company.Parent_Company_Id__c) {
				setProcessingState(IntegrationUtils.DEAD_STATE, company.Message__c += 'The Parent Company ID indicated is the same as the Company ID being updated.', company);
				continue;
			}
			if (
				String.isNotBlank(company.Parent_Company_Id__c) &&
				String.isNotBlank(company.id__c) &&
				map_companyIdToChildCompanyIds?.containskey(company.Id__c) &&
				map_companyIdToChildCompanyIds.get(company.Id__c).contains(company.Parent_Company_Id__c)
			) {
				setProcessingState(IntegrationUtils.DEAD_STATE, company.Message__c += 'The Parent Company ID is already found as a Child or Grandchild within the same hierarchy.', company);
				continue;
			}

			if (company.Embedded_Payroll_Company__c) {
				company.Embedded_Partner__c = getEmbeddedPartnerAccount(company);
			}

			acc = mapAccountFields(company, acc, map_ResellerAccounts);
			accountList.add(acc);

			Contact con = new Contact();
			if (matchingContactsMap.containsKey(company.Created_By_Email__c)) {
				con = matchingContactsMap.get(company.Created_By_Email__c);
				con.RecordTypeId = (company.Embedded_Payroll_Company__c == true ? Cache.getRecordTypeId('Contact', 'Embedded Company') : Cache.getRecordTypeId('Contact', 'Company'));
			}

			contactList.add(con);
		}

		if (!list_PartnerPrograms.isEmpty()) {
			List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_PartnerPrograms, Partner_Program_Company_Data__c.Fields.Id__c, false);
			map_DmlPartnerProgramUpsertErrors = Utils.processUpsertResult(list_UpsertResults, list_PartnerPrograms, 'Company_Id__c', true, 'ZPCompanyTriggerHepler-processInformation');
		}

		if (accountList.size() > 0) {
			if (AccountTriggerHelper.skipTrigger) {
				AccountTriggerHelper.skipTrigger = false;
			}

			List<Database.UpsertResult> saveResult = Database.upsert(accountList, Account.Fields.ZP_Company_ID__c, false);
			dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult, accountList, 'ZP_Company_ID__c', true, 'ZPCompanyTriggerHepler-processInformation');
		}
		// Handle the dml errors via addError
		if (dmlUpsertErrorsMap.keySet().size() > 0) {
			for (ZP_Company__c company : companyList) {
				if (dmlUpsertErrorsMap.containsKey(company.ID__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpsertErrorsMap.get(company.ID__c), company);
					failedCompanyEmailSet.add(company.Created_By_Email__c);
				}
			}
		}

		// We are looking for Reseller Leads where Accountant lead Id matches with ZP Company - if matches we are updating related Account /Opportunity
		if (map_AccountantLeadIdAndSourceId != null && !map_AccountantLeadIdAndSourceId.isEmpty()) {
			Map<String, Id> map_SourceIdWithLeadId = getLeadsByAccountingFirmId(map_AccountantLeadIdAndSourceId);
			if (map_SourceIdWithLeadId.size() > 0) {
				Map<String, Account> map_Accounts = getAccounts(map_SourceIdWithLeadId.keySet());
				if (map_Accounts.size() > 0) {
					for (Account objAcc : map_Accounts.values()) {
						if (map_SourceIdWithLeadId.containsKey(objAcc.ZP_Company_ID__c)) {
							objAcc.Sold_By_Accountant_Lead__c = map_SourceIdWithLeadId.get(objAcc.ZP_Company_ID__c);
							set_leadId.add(objAcc.Sold_By_Accountant_Lead__c);
							list_AccountsToUpdateSoldBYAccountantLead.add(objAcc);
						}
					}
				}
				if (list_AccountsToUpdateSoldBYAccountantLead.size() > 0) {
					AccountTriggerHelper.skipTrigger = true;
					update list_AccountsToUpdateSoldBYAccountantLead;
					AccountTriggerHelper.skipTrigger = false;

					//By:Prashant :17-07-2020 : ABC Add Clients to MQL :https://app.asana.com/0/1165890935117693/1178323609672257
					if (set_leadId.size() > 0) {
						List<Lead> list_LeadsToUpdate = updateClientToMQL(set_leadId, map_AccountantLeadIdCreatedDateMap);

						if (list_LeadsToUpdate.size() > 0) {
							update list_LeadsToUpdate;
						}
					}
				}
			}
			for (ZP_Company__c company : companyList) {
				if (map_AccountantLeadIdAndSourceId.containsKey(company.Accountant_Lead_Id__c)) {
					if (map_AccountantLeadIdAndSourceId.get(company.Accountant_Lead_Id__c) == company.Id__c) {
						company.IsChangedAccoutantLeadId__c = false;
					}
				}
			}
		}
		accountMap = getAccounts(companyIdSet);
		Map<String, ZP_Company_Onboarding_Funnel__c> funnelMap = getOnboardingFunnelRecords(companyIdSet);
		Map<String, Opportunity> opportunityMap = getOpportunitys(companyIdSet);
		Map<String, PriceBook2> prodMap = PricebookQueryHelper.getActivePricebooksMap();

		for (ZP_Company__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (failedCompanyEmailSet.contains(company.Created_By_Email__c)) {
				continue;
			}

			setCustomersReferralLink(company, map_ResellerAccounts, map_AccountsToUpdate);

			if (accountMap.containsKey(company.Id__c)) {
				Account acc = accountMap.get(company.Id__c);
				Account objAccountToUpdate = map_AccountsToUpdate.containsKey(acc.Id) ? map_AccountsToUpdate.get(acc.Id) : new Account(Id = acc.Id);
				Boolean blnIsAccUpdated = false;

				Opportunity opp = new Opportunity();
				Boolean bln_updateOpp = false;
				if (opportunityMap.containsKey(company.Id__c)) {
					opp = opportunityMap.get(company.Id__c);
				}

				Id oppId = opp != null ? opp.Id : null;

				// We want to update opportunity when the related accounting firms merged
				if ((!opp.IsWon || newCompanyIdNoLeadSet.contains(company.Id__c))) {
					opp = mapOpportunityFields(company, acc, opp, prodMap, map_ResellerAccounts);
					company.Message__c = company.Message__c + opp.Id;

					if (funnelMap.containsKey(company.Id__c)) {
						opp = mapOnboardingFunnelFields(funnelMap.get(company.Id__c), opp);
					}
					if (newCompanyIdNoLeadSet.contains(company.ID__c) && companySoldbyMap.containsKey(company.ID__c)) {
						if (opp.Sold_By__c == null) {
							opp.Sold_By__c = companySoldbyMap.get(company.ID__c);
							if (acc.Sold_By__c == null) {
								objAccountToUpdate.Sold_By__c = companySoldbyMap.get(company.ID__c);
								blnIsAccUpdated = true;
							}
						}
					} else if (newCompanyIdNoLeadSet.contains(company.ID__c) && companyOwnerIdMap.containsKey(company.ID__c)) {
						if (opp.OwnerId == null || opp.OwnerId == UserInfo.getUserId()) {
							opp.OwnerId = companyOwnerIdMap.get(company.ID__c);
						}
					}
					bln_updateOpp = true;
				}
				if (
					(opp.IsClosed && opp.IsWon) &&
					(map_ZPAcctFirms.containsKey(company.Old_Managing_Accounting_Firm_Id__c) && map_ZPAcctFirms.get(company.Old_Managing_Accounting_Firm_Id__c).Merged_Firm_ID__c != null)
				) {
					opp.Sold_By__c = map_ResellerAccounts.containsKey(company.Managing_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(company.Managing_Accounting_Firm_Id__c).Id : null;
					bln_updateOpp = true;
				}

				if (opp != null && !opp.IsClosed && acc.Sold_By_Accountant_Lead__c != null) {
					opp.SoldBy_Accountant_Lead__c = acc.Sold_By_Accountant_Lead__c;
					bln_updateOpp = true;
				}

				if (opp != null && !opp.IsClosed && set_WOLeadConversionCompanyIds.contains(company.Id__c)) {
					opp.Created_W_O_Lead_Conversion__c = true;
					bln_updateOpp = true;
				}

				if (company.Deleted_At__c != null && String.isNotBlank(company.Created_By_Email__c) && map_matchingAcctFirms.containsKey(company.Created_By_Email__c)) {
					// Set Account Qualification Status to Unqualified
					if (acc.Qualified_Status__c != AccountUtil.QUALIFIED_STATUS_UNQUALIFIED) {
						objAccountToUpdate.Qualified_Status__c = AccountUtil.QUALIFIED_STATUS_UNQUALIFIED;
						objAccountToUpdate.Qualified_Status_Detail__c = AccountUtil.QUALIFIED_STATUS_DETAIL_DELETED_ACCOUNT;
						blnIsAccUpdated = true;

						// Set Opportunity Qualification Status to Unqualified
						if (opp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID || opp.RecordTypeId == OpportunityUtil.ACQUISITION_OPPTY_RT_ID) {
							opp.StageName = OpportunityUtil.CLOSED_LOST_STAGE;
							opp.Stage_Detail__c = OpportunityUtil.BENEFITS_BYOB_STAGE_DETAIL;
							opp.Additional_Reasons_Lost__c = OpportunityUtil.ADDITIONAL_REASONS_LOST_DUPLICATE_TEST_ACCOUNT;
							opp.Closed_Details__c = OpportunityUtil.ACCIDENTAL_DIRECT_SIGN_UP;
							bln_updateOpp = true;
						}
					}
				}

				if (bln_updateOpp) {
					opportunityList.add(opp);
				}

				if (blnIsAccUpdated) {
					map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
				}
			}
		}

		Map<String, String> dmlOpportunityUpsertErrorsMap = new Map<String, String>();
		if (opportunityList.size() > 0) {
			List<Database.UpsertResult> saveResult = Database.upsert(opportunityList, Opportunity.Fields.Source_Id__c, false);
			dmlOpportunityUpsertErrorsMap = Utils.processUpsertResult(saveResult, opportunityList, 'Source_Id__c', true, 'ZPCompanyTriggerHepler-processInformation');
		}

		Map<String, String> map_dmlAccountUpdateErrors = new Map<String, String>();
		if (!map_AccountsToUpdate.isEmpty()) {
			list_accountsToUpdate = map_AccountsToUpdate.values();

			AccountTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> saveResult = Database.update(list_accountsToUpdate, false);
			map_dmlAccountUpdateErrors = Utils.processSaveResult(saveResult, list_accountsToUpdate, 'ZP_Company_ID__c', true, 'ZPCompanyTriggerHepler-processInformation');
			AccountTriggerHelper.skipTrigger = false;
		}

		// Update PPCD records where Account is not set
		List<Partner_Program_Company_Data__c> list_PPCDsToUpsert = new List<Partner_Program_Company_Data__c>();
		for (Partner_Program_Company_Data__c objPPCD : list_PartnerPrograms) {
			if (String.isNotBlank(objPPCD.Id__c) && String.isNotBlank(objPPCD.Company_Id__c) && objPPCD.Account__c == null && accountMap.containsKey(objPPCD.Company_Id__c)) {
				objPPCD.Account__c = accountMap.get(objPPCD.Company_Id__c).Id;
				list_PPCDsToUpsert.add(objPPCD);
			}
		}

		if (!list_PPCDsToUpsert.isEmpty()) {
			upsert list_PPCDsToUpsert Id__c;
		}

		Set<String> set_CompanyIds = new Set<String>();

		for (ZP_Company__c company : companyList) {
			if (company.account__c == null && accountMap.containsKey(company.ID__c)) {
				company.account__c = accountMap.get(company.ID__c).id;
				company.Account_Created_Date_Time__c = accountMap.get(company.ID__c).createdDate;
			}
			if (company.Deleted_At__c != null && company.Created_By_Email__c != null && map_matchingAcctFirms.containsKey(company.Created_By_Email__c)) {
				set_CompanyIds.add(company.ID__c);
			}
			if (dmlOpportunityUpsertErrorsMap.containsKey(company.ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlOpportunityUpsertErrorsMap.get(company.ID__c), company);
			} else if (map_dmlAccountUpdateErrors.containsKey(company.ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_dmlAccountUpdateErrors.get(company.ID__c), company);
			} else if (map_DmlPartnerProgramUpsertErrors.containsKey(company.ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DmlPartnerProgramUpsertErrors.get(company.ID__c), company);
			} else if (company.processing_state__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, company);
			}
			// Set Is Changed as false after ZP Company is Processed
			if (company.Processing_State__c == IntegrationUtils.PROCESSED_STATE) {
				company.Is_Changed__c = false;
				company.Is_Changed_Reward_Eligible__c = false;
			}
			//BMM-387
			if (
				String.isNotBlank(company.ID__c) &&
				String.isNotBlank(company.Parent_Company_Id__c) &&
				company.ID__c != company.Parent_Company_Id__c &&
				!map_AllAccounts.containsKey(company.Parent_Company_Id__c)
			) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, company.Message__c = 'Parent Company not found, no parent has been set.', company);
			}
		}
	}

	/**
	 * @author       Swati Arya
	 * @description  Method to get the Embedded Partner Account for Embedded Payroll Company
	 * @param        objZPCompany Zp Company Record
	 **/
	private Id getEmbeddedPartnerAccount(ZP_Company__c objZPCompany) {
		Id idAccount = null;
		if (objZPCompany.Embedded_Partner_UUID__c != null && map_AllAccounts.containsKey(objZPCompany.Embedded_Partner_UUID__c) && map_AllAccounts.get(objZPCompany.Embedded_Partner_UUID__c) != null) {
			idAccount = map_AllAccounts.get(objZPCompany.Embedded_Partner_UUID__c).Id;
		} else if (
			objZPCompany.Embedded_Partner_Id__c != null &&
			map_AllAccounts.containsKey(objZPCompany.Embedded_Partner_Id__c) &&
			map_AllAccounts.get(objZPCompany.Embedded_Partner_Id__c) != null
		) {
			idAccount = map_AllAccounts.get(objZPCompany.Embedded_Partner_Id__c).Id;
		}
		return idAccount;
	}

	private void processLeadConversion(List<ZP_Company__c> companyList) {
		partnerAccountMap = new Map<String, Account>();

		Set<String> companyIdSet = new Set<String>();
		Set<String> emailIdSet = new Set<String>();
		map<String, ZP_Company__c> companyMap = new Map<String, ZP_Company__c>();
		List<Account> accountList = new List<Account>();
		map<String, String> emailIdCompanyIdMap = new Map<String, String>();
		for (ZP_Company__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			companyMap.put(company.Created_By_Email__c, company);
			companyIdSet.add(company.Id__c);
		}

		for (ZP_Company__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (company.Created_By_Email__c != null && company.Created_By_Email__c != '') {
				emailIdSet.add(company.Created_By_Email__c);
				emailIdCompanyIdMap.put(company.Created_By_Email__c, company.Id__c);
			}
		}

		// get matching leads and convert them. If there are errors log them.
		Map<String, Lead> matchingLeadsMap = getLeadsByEmail(emailIdSet);

		Map<String, Contact> matchingContactsMap = getContactsByEmail(emailIdSet);

		//update matching leads with companyid if it does not exist
		List<Lead> leadUpdateList = new List<Lead>();
		for (lead l : matchingLeadsMap.values()) {
			if ((l.ZP_Company_ID__c == null || l.ZP_Company_ID__c == '') && emailIdCompanyIdMap.containsKey(l.email)) {
				l.ZP_Company_ID__c = emailIdCompanyIdMap.get(l.email);
				if (l.Status != null && (l.Status == 'AQL' || l.Status == 'Raw')) {
					l.Status = 'MQL';
					l.MQL_Reason__c = 'SAL';
				}

				leadUpdateList.add(l);
			}
		}
		if (leadUpdateList.size() > 0) {
			updateLeadInformation(leadUpdateList, companyMap);
		}

		processConvertedLeads(companyMap, emailIdSet, companyIdSet);

		matchingLeadsMap = getLeadsByEmail(emailIdSet);
		if (matchingLeadsMap.values().size() > 0) {
			LeadConversion.ConversionResult conversionResult = LeadConversion.convert(matchingLeadsMap.values());
			List<Database.LeadConvertResult> convertResults = conversionResult.convertResults;
			integer i = 0;
			for (Lead l : matchingLeadsMap.values()) {
				Database.LeadConvertResult result = convertResults[i];
				if (result.getErrors().size() > 0) {
					String error = Utils.ConsolidateErrors(result.getErrors());
					ZP_Company__c zpCompany = companyMap.get(l.email);
				} else if (result.OpportunityId == null) {
					ZP_Company__c zpCompany = companyMap.get(l.email);
				}
				i = i + 1;
			}
		}
	}

	private void updateLeadInformation(List<Lead> leadUpdateList, Map<String, ZP_Company__c> companyMap) {
		Map<String, String> dmlLeadUpdateErrorsMap = new Map<String, String>();
		if (leadUpdateList.size() > 0) {
			List<Database.SaveResult> saveResult = database.update(leadUpdateList, false);
			dmlLeadUpdateErrorsMap = Utils.processSaveResult(saveResult, leadUpdateList, 'Email', true, 'ZPCompanyTriggerHepler-updateLeadInformation');
		}
		// Handle the dml errors via addError
		for (ZP_Company__c company : companyMap.values()) {
			if (dmlLeadUpdateErrorsMap.containsKey(company.Created_By_Email__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlLeadUpdateErrorsMap.get(company.Created_By_Email__c), company);
			} else if (company.processing_state__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, company);
			}
		}
	}

	//If the lead is manually converted this function will update the lead, account and opportunity with ID's
	private void processConvertedLeads(map<String, ZP_Company__c> companyMap, Set<String> emailSet, set<String> zpCompanyIdSet) {
		map<String, Lead> leadMap = getAllLeadsByEmail(emailSet);
		Set<Id> oppIdSet = new Set<id>();
		Set<Id> accountIdSet = new Set<id>();
		map<String, Opportunity> oppMap = getOpportunityMap(zpCompanyIdSet);
		map<String, String> opportunityMap = new Map<String, String>();
		map<String, String> accountMap = new Map<String, String>();
		List<Opportunity> oppList = new List<Opportunity>();
		List<Account> accList = new List<Account>();
		List<Lead> leadList = new List<Lead>();
		if (leadMap.size() > 0) {
			for (Lead l : leadMap.values()) {
				ZP_Company__c company = new ZP_Company__c();
				if (companyMap.containsKey(l.Email)) {
					company = companyMap.get(l.Email);
				} else {
					continue;
				}
				if (oppMap.containsKey(company.ID__c)) {
					continue;
				}

				if (l.IsConverted && (l.zp_company_id__c == null || l.zp_company_id__c == '')) {
					if (l.ConvertedOpportunityId != null) {
						oppIdSet.add(l.ConvertedOpportunityId);
						opportunityMap.put(l.ConvertedOpportunityId, company.ID__c);
					}
					if (l.ConvertedAccountId != null) {
						accountIdSet.add(l.ConvertedAccountId);
						accountMap.put(l.ConvertedAccountId, company.ID__c);
					}
					if (l.ZP_Company_ID__c == null || l.ZP_Company_ID__c == '') {
						l.ZP_Company_ID__c = company.ID__c;
						leadList.add(l);
					}
				}
			}
		}
		if (oppIdSet.size() > 0) {
			for (Opportunity opp : [SELECT Id, Source_id__c, ZP_Company_ID__c, ZP_Company_Setup_Step__c FROM Opportunity WHERE id IN :oppIdSet]) {
				if (opportunityMap.containsKey(opp.Id) && (opp.Source_ID__c == null || opp.Source_ID__c == '')) {
					opp.ZP_Company_ID__c = opportunityMap.get(opp.Id);
					opp.Source_ID__c = opportunityMap.get(opp.Id);
					oppList.add(opp);
				}
			}
		}

		if (accountIdSet.size() > 0) {
			for (Account acc : [SELECT Id, ZP_Company_ID__c FROM Account WHERE id IN :accountIdSet]) {
				if (accountMap.containsKey(acc.Id) && (acc.ZP_Company_ID__c == null || acc.ZP_Company_ID__c == '')) {
					acc.ZP_Company_ID__c = accountMap.get(acc.Id);
					accList.add(acc);
				}
			}
		}

		if (leadList.size() > 0) {
			update leadList;
		}
		if (accList.size() > 0) {
			AccountTriggerHelper.skipTrigger = true;
			update accList;
			AccountTriggerHelper.skipTrigger = false;
		}
		if (oppList.size() > 0) {
			OpportunityTriggerHelper.skipTrigger = true;
			update oppList;
			OpportunityTriggerHelper.skipTrigger = false;
		}
	}

	/*
	 * @author          Praveen Sethu
	 * @description     Map ZP Company Data on to PPCD object
	 * @param          ZP_Company__c current company record
	 * @param          map_CompanyAccounts Map of Company Id and Account
	 * @param          map_ResellerAccounts Map of Accounting Firm Id and Account
	 * @return:         objProgram - PPCD record to upsert
	 */
	private Partner_Program_Company_Data__c mapProgramData(ZP_Company__c objZPCompany, Map<String, Account> map_CompanyAccounts, Map<String, Account> map_ResellerAccounts) {
		Partner_Program_Company_Data__c objProgram = new Partner_Program_Company_Data__c(
			Id__c = objZPCompany.Partner_Program_Company_Data_Id__c,
			Deleted_At__c = objZPCompany.Deleted_At__c,
			Is_Original_Firm__c = objZPCompany.Is_Original_Firm__c,
			Partner_Billing__c = objZPCompany.Partner_Billing__c,
			Reward_Eligible__c = objZPCompany.Reward_Eligible__c,
			Company_Id__c = objZPCompany.Id__c,
			Managing_Accounting_Firm_Id__c = objZPCompany.Managing_Accounting_Firm_Id__c,
			Original_Accounting_Firm_Id__c = objZPCompany.Original_Accounting_Firm_Id__c
		);

		objProgram.Account__c = map_CompanyAccounts.containsKey(objZPCompany.Id__c) ? map_CompanyAccounts.get(objZPCompany.Id__c).Id : null;
		objProgram.Managing_Accounting_Firm__c = map_ResellerAccounts.containsKey(objZPCompany.Managing_Accounting_Firm_Id__c)
			? map_ResellerAccounts.get(objZPCompany.Managing_Accounting_Firm_Id__c).Id
			: null;
		objProgram.Original_Accounting_Firm__c = map_ResellerAccounts.containsKey(objZPCompany.Original_Accounting_Firm_Id__c)
			? objProgram.Original_Accounting_Firm__c = map_ResellerAccounts.get(objZPCompany.Original_Accounting_Firm_Id__c).Id
			: null;
		return objProgram;
	}

	private map<String, Opportunity> getOpportunityMap(Set<String> zpCompanyIdSet) {
		map<String, Opportunity> oppMap = new Map<String, Opportunity>();
		for (Opportunity opp : [
			SELECT Id, Source_id__c, ZP_Company_ID__c, Pricebook2Id, ZP_Company_Setup_Step__c, NumberOfEmployees__c
			FROM Opportunity
			WHERE ZP_Company_Id__c IN :zpCompanyIdSet
			ORDER BY CreatedDate ASC
		]) {
			oppMap.put(opp.ZP_Company_Id__c, opp);
		}
		return oppMap;
	}

	private map<String, ZP_Company_Onboarding_Funnel__c> getOnboardingFunnelRecords(Set<String> companyIdSet) {
		map<String, ZP_Company_Onboarding_Funnel__c> funnelMap = new Map<String, ZP_Company_Onboarding_Funnel__c>();
		for (ZP_Company_Onboarding_Funnel__c funnel : [
			SELECT
				Id,
				Name,
				Add_Addresses_Completed__c,
				Add_Bank_Info_Completed__c,
				Add_Employees_Completed__c,
				Add_Signatory_Completed__c,
				Company_Id__c,
				Create_User_Account_Completed__c,
				Deleted_At__c,
				External_Key__c,
				Federal_Tax_Setup_Completed__c,
				Historical_Liabilities_Completed__c,
				Last_Processed__c,
				Message__c,
				Payroll_Schedule_Completed__c,
				Previous_Paystubs_Completed__c,
				Processing_State__c,
				Ran_Payroll__c,
				Sign_All_Forms_Completed__c,
				Sign__c,
				ID__c,
				State_Setup_Completed__c,
				Verify_Bank_Info_Completed__c,
				add_addresses_completed_at__c,
				add_bank_info_completed_at__c,
				Add_employees_completed_at__c,
				add_signatory_completed_at__c,
				create_user_account_completed_at__c,
				federal_tax_setup_completed_at__c,
				historical_liabilities_completed_at__c,
				onboarding_completed_at__c,
				payroll_schedule_completed_at__c,
				previous_paystubs_completed_at__c,
				ran_payroll_at__c,
				Sign_all_forms_completed_at__c,
				State_setup_completed_at__c,
				verify_bank_info_completed_at__c,
				add_addresses_started_at__c,
				add_bank_info_started_at__c,
				add_contractors_started_at__c,
				add_employees_started_at__c,
				add_signatory_started_at__c,
				federal_tax_setup_started_at__c,
				historical_liabilities_started_at__c,
				payroll_schedule_started_at__c,
				previous_paystubs_started_at__c,
				setup_benefits_started_at__c,
				setup_wc_started_at__c,
				sign_all_forms_started_at__c,
				state_setup_started_at__c,
				verify_bank_info_started_at__c,
				Company_Employee_Pay_Types__c,
				Current_payroll__c,
				Registered_with_IRS__c,
				Has_Bank_Account__c,
				Already_hired_employees__c,
				Previous_Payroll_Provider__c
			FROM ZP_Company_Onboarding_Funnel__c
			WHERE Company_Id__c IN :companyIdSet AND Deleted_At__c = NULL
		]) {
			funnelMap.put('' + funnel.Company_Id__c, funnel);
		}
		return funnelMap;
	}

	private Map<String, Account> getAccounts(Set<String> companyIdSet) {
		Map<String, Account> accountMap = new Map<String, Account>();
		Id idCompanyAccountRecType = Cache.getRecordTypeId('Account', 'Company');
		Id idEmbeddedCompanyRecType = Cache.getRecordTypeId('Account', 'Embedded Company');

		for (Account objAcc : [
			SELECT
				Id,
				Name,
				Joined_Date_Panda__c,
				ZP_Company_ID__c,
				ZP_Company_Overall_Status__c,
				OwnerId,
				ZP_Company_Suspension_Date__c,
				Pricing__c,
				createdDate,
				Sold_By__c,
				Sold_By_Accountant_Lead__c,
				Potential_Fraud_Account__c,
				Product_Interest__c,
				Product_Interest_Countries__c,
				With_Funded_Payrolls__c,
				First_Month_Invoice_Generated__c,
				Number_of_Active_Employees__c,
				RecordTypeId,
				Qualified_Status__c,
				Owner.IsActive,
				ParentId,
				Help_Journey_Routing__c,
				Provider_401K__c
			FROM Account
			WHERE ZP_Company_ID__c IN :companyIdSet OR ZP_Company_ID__c IN :set_EmbeddedPartnerId OR ZP_Company_ID__c IN :set_EmbeddedPartnerUUID OR ZP_Company_ID__c IN :set_parentCompanyIds
		]) {
			if (objAcc.RecordTypeId == idCompanyAccountRecType || objAcc.RecordTypeId == idEmbeddedCompanyRecType) {
				accountMap.put('' + objAcc.ZP_Company_ID__c, objAcc);
			}
			map_AllAccounts.put(objAcc.ZP_Company_ID__c, objAcc);
		}
		return accountMap;
	}

	private map<String, Lead> getLeadsByEmail(Set<String> emailIdSet) {
		Map<String, Lead> leadMap = new Map<String, Lead>();
		Id idCompanyLeadRecType = Cache.getRecordTypeId('Lead', 'Company');
		for (Lead l : [
			SELECT
				Id,
				Name,
				email,
				LeadSource,
				Status,
				ABC_Match_Account__c,
				MQL_Reason__c,
				DuplicateConversionLead__c,
				Phone,
				DoNotCall,
				NumberOfEmployees,
				Send_to_Slack_Channel__c,
				SDR__c,
				Sold_By__c,
				Referred_By__c,
				IsConverted,
				CreatedDate,
				RecordTypeId,
				OwnerId,
				Unique_Email_Address__c,
				ZP_Company_Lead_ID__c,
				ZP_Company_ID__c,
				ZP_Firm_ID__c
			FROM Lead
			WHERE Email IN :emailIdSet AND isconverted = FALSE AND RecordTypeId = :idCompanyLeadRecType
		]) {
			leadMap.put(l.Email.toLowerCase(), l);
		}
		return leadMap;
	}

	private map<String, Contact> getContactsByEmail(Set<String> emailIdSet) {
		Map<String, Contact> contactMap = new Map<String, Contact>();
		for (Contact c : [SELECT Id, Name, email, RecordTypeId, OwnerId, ZP_User_Id__c, LastName FROM Contact WHERE Email IN :emailIdSet]) {
			contactMap.put(c.Email, c);
		}
		return contactMap;
	}

	private map<String, Lead> getAllLeadsByEmail(Set<String> emailIdSet) {
		Map<String, Lead> leadMap = new Map<String, Lead>();
		Id idCompanyLeadRecType = Cache.getRecordTypeId('Lead', 'Company');
		for (Lead l : [
			SELECT Id, Name, email, isConverted, RecordTypeId, OwnerId, Unique_Email_Address__c, ZP_Company_Lead_ID__c, ZP_Company_ID__c, ConvertedAccountId, ConvertedOpportunityId
			FROM Lead
			WHERE Email IN :emailIdSet AND RecordTypeId = :idCompanyLeadRecType
		]) {
			leadMap.put(l.Email, l);
		}
		return leadMap;
	}

	//Query for Mapping Account to Lead
	private Map<String, Account> getAccountsFirm(Set<String> set_FirmIds) {
		Map<String, Account> accountMap = new Map<String, Account>();
		Id idResellerRType = Cache.getRecordTypeId('Account', 'Reseller');
		for (Account objAccount : [
			SELECT
				Id,
				ZP_Firm_ID__c,
				Name,
				Reseller_Company__c,
				Customers_Reward_Eligible__c,
				Customers_Reward_Ineligible__c,
				Setup_Customers_Reward_Eligible__c,
				Setup_Customers_Reward_Ineligible__c,
				Customers_Referral_Link__c,
				(SELECT Id, Is_Active_Customer__c FROM AccountsReferredBy__r WHERE Is_Active_Customer__c = TRUE AND With_Funded_Payrolls__c = TRUE)
			FROM Account
			WHERE ZP_Firm_ID__c IN :set_FirmIds AND RecordTypeId = :idResellerRType
		]) {
			accountMap.put(objAccount.ZP_Firm_ID__c, objAccount);
		}
		return accountMap;
	}

	/**
	 * @author Prashant
	 * @since 28-May-2020, 10-june-2020
	 */
	private Map<String, Id> getLeadsByAccountingFirmId(Map<String, String> map_AccountingLeadIdAndSourceId) {
		Map<String, Id> map_SourceIdAndLeadId = new Map<String, Id>();
		Id idResellerLeadRecType = Cache.getRecordTypeId('Lead', 'Reseller');
		try {
			for (Lead objLead : [SELECT Id, ZP_Firm_Id__c FROM Lead WHERE ZP_Firm_Id__c = :map_AccountingLeadIdAndSourceId.keySet() AND RecordTypeId = :idResellerLeadRecType]) {
				if (map_AccountingLeadIdAndSourceId.containsKey(objLead.ZP_Firm_Id__c)) {
					map_SourceIdAndLeadId.put(map_AccountingLeadIdAndSourceId.get(objLead.ZP_Firm_Id__c), objLead.Id);
				}
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logExceptionWithId(
				'ZPCompanyTriggerHelper',
				'getLeadsByAccountingFirmId',
				objEx.getMessage() +
				' ON Line ' +
				objEx.getLineNumber(),
				objEx.getStackTraceString(),
				map_AccountingLeadIdAndSourceId.keySet()
			);
		}
		return map_SourceIdAndLeadId;
	}

	private Map<String, Opportunity> getOpportunitys(Set<String> companyIdSet) {
		Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
		Id idCompanyOpptyRecType = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		Id idAcquisitionOppRecType = Cache.getRecordTypeId('Opportunity', 'Acquisition');
		Id idEmbeddedCompanyRecType = Cache.getRecordTypeId('Opportunity', 'Embedded Company Opportunity');
		for (Opportunity opp : [
			SELECT
				Id,
				StageName,
				Created_W_O_Lead_Conversion__c,
				A_B_Test_Log__c,
				IsClosed,
				IsWon,
				Name,
				SoldBy_Accountant_Lead__c,
				ZP_Company_ID__c,
				Source_Id__c,
				NumberOfEmployees__c,
				Fast_ACH__c,
				Onboarding_Funnel_Id__c,
				Pricebook2Id,
				ZP_Company_Setup_Step__c,
				Payment_Invoice__c
			FROM Opportunity
			WHERE
				ZP_Company_ID__c IN :companyIdSet
				AND (RecordTypeId = :idCompanyOpptyRecType
				OR RecordTypeId = :idEmbeddedCompanyRecType
				OR (RecordTypeId = :idAcquisitionOppRecType
				AND Type = 'New Business'))
			ORDER BY CreatedDate ASC
		]) {
			oppMap.put('' + opp.ZP_Company_ID__c, opp);
		}
		return oppMap;
	}

	/**
	 * @author      : Sandeep Golla
	 * @description : Get ZP Accounting Firms records by ZP Company email
	 * @param       : List<String> - Zp Company Created By Email
	 * @return      : Map<String, ZP_Accounting_Firm__c> records
	 **/
	private static void getZPAccoutingFirms(Set<String> emailIdSet, Set<String> firmIds) {
		for (ZP_Accounting_Firm__c objFirm : [
			SELECT Id, Name, Created_By_Email__c, Id__c, Merged_Firm_ID__c, Created_At__c
			FROM ZP_Accounting_Firm__c
			WHERE Created_By_Email__c IN :emailIdSet OR Id__c IN :firmIds
		]) {
			if (objFirm.Created_By_Email__c != null) {
				map_matchingAcctFirms.put(objFirm.Created_By_Email__c, objFirm);
			}
			if (objFirm.ID__c != null) {
				map_ZPAcctFirms.put(objFirm.Id__c, objFirm);
			}
		}
	}

	private Zp_Company__c setProcessingState(String state, String message, Zp_Company__c company) {
		company.Processing_State__c = state;
		company.Message__c = message;
		if (state == IntegrationUtils.ERROR_STATE) {
			company.Error_Message__c = message;
		}
		company.Last_Processed__c = System.now();
		return company;
	}

	private map<String, String> getCompanySoldbyMap(Set<String> companyIdSet) {
		map<String, Id> companySoldByMap = new Map<String, Id>();
		companyOwnerIdMap = new Map<String, Id>();
		map<String, Set<String>> companyUserIdMap = new Map<String, Set<String>>();
		Set<String> zpUserIdSet = new Set<String>();
		Set<String> allUserIdSet = new Set<String>();
		for (ZP_User_Role__c role : [SELECT Id, User_Id__c, Company_Id__c FROM ZP_User_Role__c WHERE Company_Id__c IN :companyIdSet AND Type__c = 'Role::PayrollAdmin']) {
			// and Is_Primary__c=true
			Set<String> userIdSet = new Set<String>();
			if (companyUserIdMap.containskey(role.Company_Id__c)) {
				userIdSet = companyUserIdMap.get(role.Company_Id__c);
			}
			userIdSet.add(role.User_Id__c);
			companyUserIdMap.put(role.Company_Id__c, userIdSet);
			allUserIdSet.add(role.User_Id__c);
		}
		if (companyUserIdMap.size() > 0) {
			Set<String> accountingFirmSet = new Set<String>();
			map<String, String> userIdAccountingFirmMap = new Map<String, String>();
			for (ZP_User_Role__c role : [SELECT Id, User_Id__c, Company_Id__c, Accounting_Firm_Id__c FROM ZP_User_Role__c WHERE User_Id__c IN :allUserIdSet AND Type__c = 'Role::Accountant']) {
				//and Accounting_Firm_Id__c!=''
				if (role.Accounting_Firm_Id__c != null && role.Accounting_Firm_Id__c != '') {
					userIdAccountingFirmMap.put(role.User_Id__c, role.Accounting_Firm_Id__c);
				} else {
					zpUserIdSet.add(role.User_Id__c);
				}
			}
			if (userIdAccountingFirmMap.size() > 0) {
				map<String, String> accountingFirmMap = new Map<String, String>();
				for (Account acc : [SELECT id, ZP_Firm_Id__c FROM Account WHERE ZP_Firm_Id__c IN :userIdAccountingFirmMap.values()]) {
					accountingFirmMap.put(acc.ZP_Firm_Id__c, acc.Id);
				}
				if (accountingFirmMap.size() > 0) {
					for (String companyId : companyIdSet) {
						if (companyUserIdMap.containsKey(companyId)) {
							Set<String> userIdSet = companyUserIdMap.get(companyId);
							for (String usrId : userIdSet) {
								if (userIdAccountingFirmMap.containsKey(usrId)) {
									if (accountingFirmMap.containsKey(userIdAccountingFirmMap.get(usrId))) {
										companySoldByMap.put(companyId, accountingFirmMap.get(userIdAccountingFirmMap.get(usrId)));
									}
								}
							}
						}
					}
				}
			}
		}

		if (zpUserIdSet.size() > 0) {
			Id idResellerLeadRecType = Cache.getRecordTypeId('Lead', 'Reseller');
			map<String, String> userEmailMap = new Map<String, String>();
			map<String, String> userOwnerIdMap = new Map<String, String>();
			for (ZP_User__c user : [SELECT Id, Id__c, email__c FROM ZP_User__c WHERE Id__c IN :zpUserIdSet]) {
				userEmailMap.put(user.Id__c, user.Email__c);
			}
			map<String, String> emailOwnerIdMap = new Map<String, String>();
			for (Lead l : [SELECT Id, OwnerId, Email FROM Lead WHERE email IN :userEmailMap.values() AND RecordTypeId = :idResellerLeadRecType]) {
				emailOwnerIdMap.put(l.Email, l.OwnerId);
			}
			for (String companyId : companyIdSet) {
				if (companyUserIdMap.containsKey(companyId)) {
					Set<String> userIdSet = companyUserIdMap.get(companyId);
					for (String usrId : userIdSet) {
						//String usrId = companyUserIdMap.get(companyId);
						if (emailOwnerIdMap.containsKey(userEmailMap.get(usrId))) {
							companyOwnerIdMap.put(companyId, emailOwnerIdMap.get(userEmailMap.get(usrId)));
						}
					}
				}
			}
		}

		return companySoldByMap;
	}

	/**
	 * @author   Prashant
	 * @since    06-08-2020
	 * @Asana    https://app.asana.com/0/1165890935117693/1178323609672257
	 * ABC Add Clients to MQL(This method is call from ZP Company TriggerHelper)
	 */
	public List<Lead> updateClientToMQL(Set<Id> set_soldByAccountantId, Map<String, Date> map_AccountantLeadIdCreatedDateMap) {
		Id recordTypeId = Cache.getRecordTypeId('Lead', 'Reseller');
		Set<String> set_stagesToCompare = new Set<String>{ 'AQL', 'Raw', 'Future Opportunity', 'Unqualified' };

		List<String> list_NotIncludeEmails = Label.Excluded_Email_Domains.split(',');
		List<Lead> list_Resleads = querySoldByAccountantLeadInfo(set_soldByAccountantId);
		List<Lead> list_leadsToUpdate = new List<Lead>();

		for (Lead objLead : list_Resleads) {
			String emailDomain = '';
			if (String.isNotBlank(objLead.Email)) {
				emailDomain = objLead.Email.split('@').get(1);
			}
			// Added by Praveen - Promote Lead to MQL only when ZP Company was created within one day from current date
			if (
				objLead.recordTypeId == recordTypeId &&
				set_stagesToCompare.contains(objLead.Status) &&
				objLead.Email != null &&
				objLead.Phone != null &&
				(objLead.MQL_Date__c == null || (objLead.MQL_Date__c != null && objLead.MQL_Date__c < Date.today().addDays(-7))) &&
				(!list_NotIncludeEmails.contains(emailDomain)) &&
				(objLead.DoNotCall == false) &&
				(objLead.ABC_Match_Account__c == null) &&
				map_AccountantLeadIdCreatedDateMap != null &&
				map_AccountantLeadIdCreatedDateMap.containsKey(objLead.ZP_Firm_ID__c) &&
				map_AccountantLeadIdCreatedDateMap.get(objLead.ZP_Firm_ID__c).daysBetween(Date.today()) <= 1
			) {
				objLead.Status = 'MQL';
				objLead.MQL_Reason__c = 'Added Client';

				list_leadsToUpdate.add(objLead);
			}
		}
		return list_leadsToUpdate;
	}

	/*** Query Leads ****/
	public static List<Lead> querySoldByAccountantLeadInfo(Set<Id> set_leadId) {
		return [SELECT Id, Status, RecordTypeId, Email, DoNotCall, ABC_Match_Account__c, Phone, MQL_Date__c, ZP_Firm_Id__c FROM Lead WHERE Id IN :set_leadId];
	}

	/**
	 * @author      : Praveen Sethu
	 * @description : Filters list of ZP Companies and removes Fraudulent records
	 * @param        : List<ZP_Company__c> - Unfiltered List
	 * @return      : List<ZP_Company__c> - Filtered List
	 **/
	public List<ZP_Company__c> returnRecordsToProcess(List<ZP_Company__c> list_ZPCompanies, Map<ID, ZP_Company__c> oldCompanyMap) {
		// List to contain filtered list of ZP Companies to Process
		List<ZP_Company__c> list_ZPCompaniesToProcess = new List<ZP_Company__c>();
		Set<String> set_FraudEmails = new Set<String>();

		// Fetch all fraudulent email domains from custom metadata
		Map<String, Fraud_Settings__mdt> map_FraudSettings = Fraud_Settings__mdt.getAll();
		for (String strKey : map_FraudSettings.keySet()) {
			set_FraudEmails.add(map_FraudSettings.get(strKey).Email_Domain__c);
		}

		List<String> list_CompanyFields = new List<String>(ZP_Company__c.SObjectType.getDescribe().fields.getMap().keySet());

		for (ZP_Company__c objZPCompany : list_ZPCompanies) {
			String strFieldsUpdated = '';
			ZP_Company__c oldZPCompany = oldCompanyMap != null && oldCompanyMap.containsKey(objZPCompany.Id) ? oldCompanyMap.get(objZPCompany.Id) : null;

			// Fake record is set by Mulesoft by calling OpenAI to check if company name is legit. If not Fake record is set to True
			if (objZPCompany.Fake_Record__c) {
				objZPCompany.Processing_State__c = IntegrationUtils.DEAD_STATE;
				objZPCompany.Message__c = 'Fraudulent company name';
			} else if (oldZPCompany != null && oldZPCompany.Fake_Record__c != objZPCompany.Fake_Record__c && !objZPCompany.Fake_Record__c) {
				objZPCompany.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				objZPCompany.Message__c = '';
			}

			if (!ZPCompanyUtil.set_InactiveStatus.contains(objZPCompany.Processing_State__c)) {
				objZPCompany.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}

			// Logic to remove fraudulent records and mark them as Dead
			for (String strFraudEmail : set_FraudEmails) {
				if (String.isNotBlank(objZPCompany.Created_By_Email__c) && objZPCompany.Created_By_Email__c.containsIgnoreCase(strFraudEmail)) {
					objZPCompany.Processing_State__c = IntegrationUtils.DEAD_STATE;
					objZPCompany.Message__c = 'Fraudulent record';
				}
			}
			List<String> list_FraudCompanyNames = System.Label.Fraud_Company_Name.split(',');

			for (String strFraudName : list_FraudCompanyNames) {
				// block based on company name
				if (String.isNotBlank(objZPCompany.Name__c) && objZPCompany.Name__c.containsIgnoreCase(strFraudName)) {
					objZPCompany.Processing_State__c = IntegrationUtils.DEAD_STATE;
					objZPCompany.Message__c = 'Fraudulent record';
				}
			}

			// Take all fields and compare old/new values and set boolean flag to true only if at aleast one field has changed
			if (oldCompanyMap != null) {
				if (oldZPCompany != null && !objZPCompany.Is_Changed__c) {
					for (String strField : list_CompanyFields) {
						// processing_state__c and is_changed__c are custom fields that are manipulated by code. Hence ignoring these two fields
						if (String.isNotBlank(strField) && !ZPCompanyUtil.set_AllowChangeFields.contains(strField.toLowerCase())) {
							if (objZPCompany.get(strField) != oldZPCompany.get(strField)) {
								objZPCompany.Is_Changed__c = true;
								strFieldsUpdated = strFieldsUpdated + strField + ',';
							}
						}
					}
				}

				if (objZPCompany.Is_Changed__c && String.isNotBlank(strFieldsUpdated)) {
					objZPCompany.Fields_Updated__c = strFieldsUpdated;
				}

				// Do not update to processed if triggered by Batch
				if (!objZPCompany.Is_Changed__c && !ZPCompanyUtil.set_InactiveStatus.contains(objZPCompany.Processing_State__c) && !System.isBatch() && !System.isQueueable()) {
					objZPCompany.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
					objZPCompany.Message__c = IntegrationUtils.PROCESSED_STATE;
					objZPCompany.No_Update_Counter__c = objZPCompany.No_Update_Counter__c == null ? 1 : objZPCompany.No_Update_Counter__c + 1;
				}
			}
		}

		// Add anything record whose processing state is not Dead to list of ZP Companies to Process
		for (ZP_Company__c objZPCompany : list_ZPCompanies) {
			if (objZPCompany.Processing_State__c != IntegrationUtils.DEAD_STATE && objZPCompany.Processing_State__c != IntegrationUtils.PROCESSED_STATE) {
				list_ZPCompaniesToProcess.add(objZPCompany);
			}
		}

		// Return filtered list of records to process
		return list_ZPCompaniesToProcess;
	}

	/**
	 * @author          Praveen Sethu
	 * @description     Update Customers Eligibility whenever Reward Eligible changes
	 * @param          ZP_Company__c current company record
	 * @param          map_ResellerAccounts Map of ZP firm Id and Account
	 * @param          map_AccountsToUpdate Map of Account Ids to update
	 * @return:         void
	 */
	public void setCustomersReferralLink(ZP_Company__c company, Map<String, Account> map_ResellerAccounts, Map<Id, Account> map_AccountsToUpdate) {
		Account objResellerAcct = map_ResellerAccounts.containsKey(company.Managing_Accounting_Firm_Id__c) ? map_ResellerAccounts.get(company.Managing_Accounting_Firm_Id__c) : null;

		if (objResellerAcct != null) {
			Integer intCount = 0;
			for (Account objAccnt : objResellerAcct.AccountsReferredBy__r) {
				intCount = intCount + 1;
			}

			// Update only when count does not match with Account
			if (objResellerAcct.Customers_Referral_Link__c != intCount) {
				objResellerAcct = map_AccountsToUpdate.containsKey(objResellerAcct.Id) ? map_AccountsToUpdate.get(objResellerAcct.Id) : objResellerAcct;

				objResellerAcct.Customers_Referral_Link__c = intCount;
				map_AccountsToUpdate.put(objResellerAcct.Id, objResellerAcct);
			}
		}
	}
	/**
	 * @description               to be used through ZP Company lead conversion
	 *
	 * @param list_zpCompanies
	 * @param set_emailIdSet
	 * @param map_emailToLead
	 * @param map_compIdToAccount
	 * @param map_emailToContact
	 * @return                    `List<Database.LeadConvert>` List of leads to convert
	 */
	public static List<Database.LeadConvert> populateZPCompanyConversionList(
		List<ZP_Company__c> list_zpCompanies,
		Set<String> set_emailIdSet,
		Map<String, Lead> map_emailToLead,
		Map<String, Account> map_compIdToAccount,
		Map<String, Contact> map_emailToContact
	) {
		//init
		Map<String, Opportunity> map_compIdToOpp = new Map<String, Opportunity>();
		Set<String> set_compIdSet = new Set<String>();
		List<Database.LeadConvert> lst_leadConvert = new List<Database.LeadConvert>();

		//get all company ids
		for (ZP_Company__c zp : list_zpCompanies) {
			if (String.isNotBlank(zp.Id__c)) {
				set_compIdSet.add(zp.Id__c);
			}
		}

		if (set_compIdSet.size() > 0) {
			//query opps based on zp company id
			for (Opportunity op : [
				SELECT Id, ZP_Company_ID__c, OwnerId
				FROM Opportunity
				WHERE ZP_Company_ID__c IN :set_compIdSet AND RecordTypeId = :RecordTypes.getRecordTypeIdFromDeveloperName('Opportunity', 'Acquisition')
			]) {
				map_compIdToOpp.put(op.ZP_Company_ID__c, op);
			}
		}

		//iterate over zp companies and assamle LeadConvert list
		for (ZP_Company__c zp : list_zpCompanies) {
			//check if Legacy id and created by email exist, check if we have tracked existing lead email
			if (String.isNotBlank(zp.Id__c) && String.isNotBlank(zp.Created_By_Email__c) && set_emailIdSet.contains(zp.Created_By_Email__c)) {
				//get existing data
				Account acc = map_compIdToAccount.containsKey(zp.Id__c) ? map_compIdToAccount.get(zp.Id__c) : null;
				Opportunity opp = map_compIdToOpp.containsKey(zp.Id__c) ? map_compIdToOpp.get(zp.Id__c) : null;
				Contact con = map_emailToContact.containsKey(zp.Created_By_Email__c) ? map_emailToContact.get(zp.Created_By_Email__c) : null;
				Lead ld = map_emailToLead.containsKey(zp.Created_By_Email__c) ? map_emailToLead.get(zp.Created_By_Email__c) : null;
				//Id id_ownerId = null;

				if (ld != null) {
					Database.LeadConvert leadConvert = new Database.LeadConvert();
					//set existing account id
					if (acc != null) {
						leadConvert.setAccountId(acc.Id);
						//set exisitng contact id only if account id is set
						if (con != null) {
							leadConvert.setContactId(con.Id);
						}
					}

					System.debug('opp inside lead conversion ' + opp);
					//set exisitng opp id
					if (opp != null) {
						leadConvert.setOpportunityId(opp.Id);
					}

					leadConvert.setLeadId(ld.Id);
					leadConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);

					// for large firm ids, kick off queuable job to convert lead
					if (zp.Is_Large_Firm_Id__c) {
						if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
							System.enqueueJob(
								new LeadConvertQueueable(leadConvert.getLeadId(), leadConvert.getAccountId(), leadConvert.getContactId(), leadConvert.getOpportunityId(), zp.Id, null, false)
							);
							zp.Message__c = ZPCompanyUtil.ASYNC_LEAD_CONVERSION_PENDING;
						}
					} else {
						lst_leadConvert.add(leadConvert);
					}
				}
			}
		}
		return lst_leadConvert;
	}

	/**
	 * @author         Debasmita rawooth
	 * @description    Get Map of Parent ZP Company Id vs Set of Parent Ids
	 * @param          Set of ZP Company Ids
	 * @return:        map_companyIdToChildCompanyIds
	 */
	private static Map<String, Set<String>> getAllChildAccountsZPCompanIds(Set<String> set_companyId) {
		Map<String, Set<String>> map_companyIdToChildCompanyIds = new Map<String, Set<String>>();
		for (String strParentCompanyId : set_companyId) {
			map_companyIdToChildCompanyIds.put(strParentCompanyId, new Set<String>());
		}

		for (Account objChildAccount : [
			SELECT
				ZP_Company_ID__c,
				Parent.ZP_Company_ID__c,
				Parent.Parent.ZP_Company_ID__c,
				Parent.Parent.Parent.ZP_Company_ID__c,
				Parent.Parent.Parent.Parent.ZP_Company_ID__c,
				Parent.Parent.Parent.Parent.Parent.ZP_Company_ID__c
			FROM Account
			WHERE
				ZP_Company_ID__c != NULL
				AND (Parent.ZP_Company_ID__c IN :set_companyId
				OR Parent.Parent.ZP_Company_ID__c IN :set_companyId
				OR Parent.Parent.Parent.ZP_Company_ID__c IN :set_companyId
				OR Parent.Parent.Parent.Parent.ZP_Company_ID__c IN :set_companyId
				OR Parent.Parent.Parent.Parent.Parent.ZP_Company_ID__c IN :set_companyId)
		]) {
			map_companyIdToChildCompanyIds.get(objChildAccount.Parent.ZP_Company_ID__c)?.add(objChildAccount.ZP_Company_ID__c);
			map_companyIdToChildCompanyIds.get(objChildAccount.Parent.Parent.ZP_Company_ID__c)?.add(objChildAccount.ZP_Company_ID__c);
			map_companyIdToChildCompanyIds.get(objChildAccount.Parent.Parent.Parent.ZP_Company_ID__c)?.add(objChildAccount.ZP_Company_ID__c);
			map_companyIdToChildCompanyIds.get(objChildAccount.Parent.Parent.Parent.Parent.ZP_Company_ID__c)?.add(objChildAccount.ZP_Company_ID__c);
			map_companyIdToChildCompanyIds.get(objChildAccount.Parent.Parent.Parent.Parent.Parent.ZP_Company_ID__c)?.add(objChildAccount.ZP_Company_ID__c);
		}
		return map_companyIdToChildCompanyIds;
	}
}