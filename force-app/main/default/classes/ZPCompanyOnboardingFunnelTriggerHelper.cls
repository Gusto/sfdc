/**
 * @description  Updates Onboarding fields on Opportunity and Orders
 * @author       Praveen Sethu
 * @date         01-19-2022
 * @see          ZPCompanyOnboardingTriggerHelperTest
 **/
public class ZPCompanyOnboardingFunnelTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static Boolean queue = false;
	public static Boolean blnSkipOrderStatusFilter = false;
	private Map<String, String> funnelSetupStepIntegrationValueMap;

	public void OnBeforeInsert(List<ZP_Company_Onboarding_Funnel__c> list_Companies) {
		counter++;
		try {
			for (ZP_Company_Onboarding_Funnel__c objComp : list_Companies) {
				objComp.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (queue == true) {
				processInformation(list_Companies, 'Insert');
			}
		} catch (Exception ex) {
			system.debug('EXCEPTION :: ' + ex.getStackTraceString());
		}
	}

	public void OnAfterInsert(Map<ID, ZP_Company_Onboarding_Funnel__c> map_NewCompanies) {
		enqueueZPOnboardingJob(map_NewCompanies);
		checkOnboardingSteps(map_NewCompanies.values(), null);
	}

	public void OnBeforeUpdate(Map<ID, ZP_Company_Onboarding_Funnel__c> oldCompanyMap, Map<ID, ZP_Company_Onboarding_Funnel__c> newCompanyMap) {
		counter++;
		try {
			for (ZP_Company_Onboarding_Funnel__c company : newCompanyMap.values()) {
				if (company.Processing_State__c != IntegrationUtils.DEAD_STATE) {
					company.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				}
			}
			if (queue == true) {
				processInformation(newCompanyMap.values(), 'Update');
			}
		} catch (Exception ex) {
			system.debug('EXCEPTION :: ' + ex.getStackTraceString() + '======' + ex.getMessage() + '==Line Numbers==' + ex.getLineNumber() + '===cause=' + ex.getCause());
		}
	}

	public void OnAfterUpdate(Map<ID, ZP_Company_Onboarding_Funnel__c> oldCompanyMap, Map<ID, ZP_Company_Onboarding_Funnel__c> newCompanyMap) {
		enqueueZPOnboardingJob(newCompanyMap);
		checkOnboardingSteps(newCompanyMap.values(), oldCompanyMap);
	}

	/**
	 * Enqueue queueable job to update onboarding fields on Opportunity
	 * @param   map_NewCompanies - map of onboarding funnel records from trigger context
	 * @return  enqueued job id or null if not enqueued
	 */
	public static Id enqueueZPOnboardingJob(Map<ID, ZP_Company_Onboarding_Funnel__c> map_NewCompanies) {
		// do not enqueue job if queue is true - the record will be processed real time (synchronously) if queue is set to true
		if (queue) {
			return null;
		}

		Integer intMaxBatchSize = Configuration_Settings__c.getOrgDefaults()?.Onboarding_Funnel_Batch_Size__c?.intValue();
		intMaxBatchSize = intMaxBatchSize > 0 ? intMaxBatchSize : 5;
		Boolean blnBulkRun = map_NewCompanies.size() > intMaxBatchSize;
		if (blnBulkRun) {
			// do not enqueue. job will be picked up by nightly batch
			return null;
		}

		ZPCompanyOnboardingQueue updateJob = new ZPCompanyOnboardingQueue(map_NewCompanies.values());
		return (System.enqueueJob(updateJob));
	}

	public Opportunity mapOnboardingFunnelFields(ZP_Company_Onboarding_Funnel__c funnel, Opportunity opp) {
		if (funnelSetupStepIntegrationValueMap == null) {
			funnelSetupStepIntegrationValueMap = integrationUtils.getIntegrationValueMap('Opportunity', 'ZP_Company_Setup_Step__c');
		}
		if (funnelSetupStepIntegrationValueMap.containsKey(funnel.Sign__c)) {
			opp.ZP_Company_Setup_Step__c = funnelSetupStepIntegrationValueMap.get(funnel.Sign__c);
		} else {
			if (funnel.Sign__c != null) {
				opp.ZP_Company_Setup_Step__c = funnel.Sign__c.replace('_', ' ');
			}
		}
		opp.ZP_Create_User_Account__c = funnel.Create_User_Account_Completed__c;
		opp.ZP_Add_Company_Addresses__c = funnel.add_addresses_completed__c;
		opp.ZP_Add_Employees__c = funnel.Add_Employees_Completed__c;
		opp.ZP_Set_Up_Federal_Taxes__c = funnel.Federal_Tax_Setup_Completed__c;
		opp.ZP_Set_Up_State_Taxes__c = funnel.State_Setup_Completed__c;
		opp.ZP_Set_Up_Bank_Account__c = funnel.Add_Bank_Info_Completed__c;
		opp.ZP_Select_a_Payroll_Schedule__c = funnel.Payroll_Schedule_Completed__c;
		opp.ZP_Report_Previous_Paystubs__c = funnel.Previous_Paystubs_Completed__c;
		opp.ZP_Add_Signatory__c = funnel.Add_Signatory_Completed__c;
		opp.ZP_Sign_Company_Forms__c = funnel.Sign_All_Forms_Completed__c;
		opp.ZP_Verify_Company_Bank_Account__c = funnel.Verify_Bank_Info_Completed__c;
		opp.ZP_Enter_Unpaid_Tax_Liabilities__c = funnel.Historical_Liabilities_Completed__c;
		opp.ZP_Ran_Payroll__c = funnel.Ran_Payroll__c;
		opp.Onboarding_Funnel_Id__c = funnel.Id__c;
		opp.Add_Addresses_Completed_Date__c = funnel.add_addresses_completed_at__c;
		opp.Add_Bank_Info_Completed_Date__c = funnel.add_bank_info_completed_at__c;
		opp.Add_Employees_Completed_Date__c = funnel.Add_employees_completed_at__c;
		opp.Add_Signatory_Completed_Date__c = funnel.add_signatory_completed_at__c;
		opp.Create_User_Account_Completed_Date__c = funnel.create_user_account_completed_at__c;
		opp.Federal_Tax_Setup_Completed_Date__c = funnel.federal_tax_setup_completed_at__c;
		opp.Historical_Liabilities_Completed_Date__c = funnel.historical_liabilities_completed_at__c;
		opp.Onboarding_Completed_Date__c = funnel.onboarding_completed_at__c;
		opp.Payroll_Schedule_Completed_Date__c = funnel.payroll_schedule_completed_at__c;
		opp.Previous_Paystubs_Completed_Date__c = funnel.previous_paystubs_completed_at__c;
		opp.Ran_Payroll_Date__c = funnel.ran_payroll_at__c;
		opp.Sign_All_Forms_Completed_Date__c = funnel.Sign_all_forms_completed_at__c;
		opp.State_Setup_Completed_Date__c = funnel.State_setup_completed_at__c;
		opp.Verify_Bank_Info_Completed_Date__c = funnel.verify_bank_info_completed_at__c;
		opp.add_addresses_started_at__c = funnel.add_addresses_started_at__c;
		opp.add_bank_info_started_at__c = funnel.add_bank_info_started_at__c;
		opp.add_contractors_started_at__c = funnel.add_contractors_started_at__c;
		opp.add_employees_started_at__c = funnel.add_employees_started_at__c;
		opp.federal_tax_setup_started_at__c = funnel.federal_tax_setup_started_at__c;
		opp.historical_liabilities_started_at__c = funnel.historical_liabilities_started_at__c;
		opp.payroll_schedule_started_at__c = funnel.payroll_schedule_started_at__c;
		opp.previous_paystubs_started_at__c = funnel.previous_paystubs_started_at__c;
		opp.setup_wc_started_at__c = funnel.setup_wc_started_at__c;
		opp.sign_all_forms_started_at__c = funnel.sign_all_forms_started_at__c;
		opp.state_setup_started_at__c = funnel.state_setup_started_at__c;
		opp.verify_bank_info_started_at__c = funnel.verify_bank_info_started_at__c;
		opp.Company_Employee_Pay_Types__c = funnel.Company_Employee_Pay_Types__c;
		opp.Current_payroll__c = funnel.Current_payroll__c;
		opp.Registered_with_IRS__c = funnel.Registered_with_IRS__c;
		opp.Has_Bank_Account__c = funnel.Has_Bank_Account__c;
		opp.Already_hired_employees__c = funnel.Already_hired_employees__c;
		opp.Previous_Payroll_Provider__c = funnel.Previous_Payroll_Provider__c;
		return opp;
	}
	//Created by AKS dated 30th Sept 2019 to manage condition to update data on Order level
	public static void checkOnboardingSteps(List<ZP_Company_Onboarding_Funnel__c> lstCompanyFunnel, Map<ID, ZP_Company_Onboarding_Funnel__c> oldCompanyMap) {
		//Check for 1 to 6
		Map<string, ZP_Company_Onboarding_Funnel__c> mapCompanyFunnel = new Map<string, ZP_Company_Onboarding_Funnel__c>();
		for (ZP_Company_Onboarding_Funnel__c objBoard : lstCompanyFunnel) {
			ZP_Company_Onboarding_Funnel__c oldRec;
			if (null != oldCompanyMap && oldCompanyMap.containsKey(objBoard.Id))
				oldRec = oldCompanyMap.get(objBoard.Id);

			if (
				null == oldRec ||
				blnSkipOrderStatusFilter ||
				objBoard.Payroll_Schedule_Completed__c != oldRec.Payroll_Schedule_Completed__c ||
				objBoard.Previous_Paystubs_Completed__c != oldRec.Previous_Paystubs_Completed__c ||
				objBoard.Sign_All_Forms_Completed__c != oldRec.Sign_All_Forms_Completed__c ||
				objBoard.Add_Signatory_Completed__c != oldRec.Add_Signatory_Completed__c ||
				objBoard.Verify_Bank_Info_Completed__c != oldRec.Verify_Bank_Info_Completed__c ||
				objBoard.Create_User_Account_Completed__c != oldRec.Create_User_Account_Completed__c ||
				objBoard.Add_Addresses_Completed__c != oldRec.Add_Addresses_Completed__c ||
				objBoard.Add_Employees_Completed__c != oldRec.Add_Employees_Completed__c ||
				objBoard.Federal_Tax_Setup_Completed__c != oldRec.Federal_Tax_Setup_Completed__c ||
				objBoard.State_Setup_Completed__c != oldRec.State_Setup_Completed__c ||
				objBoard.Add_Bank_Info_Completed__c != oldRec.Add_Bank_Info_Completed__c
			) {
				if (string.isNotBlank(objBoard.Company_Id__c)) {
					mapCompanyFunnel.put(objBoard.Company_Id__c, objBoard);
				}
			}
			//Dated - 4th Sept -2020 by AKS https://app.asana.com/0/1190791132094250/1184625994147288
			if (oldRec != null && objBoard.ran_payroll_at__c != null && objBoard.ran_payroll_at__c != oldRec.ran_payroll_at__c) {
				mapCompanyFunnel.put(objBoard.Company_Id__c, objBoard);
			}
		}
		if (mapCompanyFunnel != null && mapCompanyFunnel.size() > 0) {
			UpdateOrderStatus(mapCompanyFunnel);
		}
	}

	//This code should be optimized and standardized with accounttriggerhelper
	public static void UpdateOrderStatus(Map<string, ZP_Company_Onboarding_Funnel__c> mapCompanyFunnel) {
		set<string> setCompanyid = mapCompanyFunnel.keySet();

		string query =
			'select Id,Status,AccountId,Total_Checklists_Count__c,RecordTypeId,Account.Payroll_Processing_Status__c,OpportunityId,Account.ZP_Company_Overall_Status__c, ' +
			' Opportunity.Account.Previous_Payroll__c,Opportunity.Is_Historical__c,Opportunity.Account.ZP_Company_ID__c,Account.ZP_Company_Approval_Status__c from Order ';
		query = query + 'where OpportunityId!=null and Opportunity.RecordType.DeveloperName=\'Company_Opportunity\' ';
		query = query + ' and Opportunity.Account.ZP_Company_ID__c in:setCompanyId order by lastmodifieddate desc';

		System.debug('query----->' + query);
		List<Order> lstUpdateOrder = new List<Order>();
		set<string> setFilterCompanyId = new Set<string>();
		for (Order ord : Database.query(query)) {
			//By this logic to check that one company id can accept only one latest modified order
			if (setFilterCompanyId.contains(ord.Opportunity.Account.ZP_Company_ID__c) == false) {
				//Get Company Onboarding Funnel
				ZP_Company_Onboarding_Funnel__c objBoard = mapCompanyFunnel.get(ord.Opportunity.Account.ZP_Company_ID__c);

				//BY:PR, Date:Dec-15-2020, Desc: introduced payroll and overall status filter to filter out suspended acc's order status update
				//SJay - 02/03/2021 - Added check to see if payroll date is atleast 2 months in the past.
				if (ord.Status == 'Closed: Payroll Run' || ord.Status == 'Closed: Canceled' || (objBoard.ran_payroll_at__c != null && objBoard.ran_payroll_at__c < date.today().addMonths(-2))) {
					setFilterCompanyId.add(ord.Opportunity.Account.ZP_Company_ID__c);
					continue;
				}

				// SJay - 3/14/2020 - Changes made to handle Orders in status Payroll Submitted can only go forward and no backward.
				if (objBoard != null && ord.Status != 'Payroll Submitted') {
					//If Check list available for order then status will be changed
					if (ord.Total_Checklists_Count__c > 0) {
						ord.status = 'Onboarding Steps 1 - 6';
						//After finish step 6 then move status 7
						if (AccountTriggerHelper.checkOnboardingfunnelSteps1to6(objBoard) == true && ord.Opportunity.Is_Historical__c == true && objBoard.Payroll_Schedule_Completed__c == true) {
							ord.status = 'Onboarding Step 7';
						}
						//After completing step 7 move to Step 8
						if (
							objBoard.Payroll_Schedule_Completed__c == true &&
							((ord.Opportunity.Is_Historical__c == false && AccountTriggerHelper.checkOnboardingfunnelSteps1to6(objBoard) == true) ||
							(ord.status == 'Onboarding Step 7' &&
							objBoard.Previous_Paystubs_Completed__c == true))
						) {
							ord.status = 'Onboarding Steps 8 - 9';
						}
						//After completing steps 8 to 9 move to steps 10
						if (
							ord.status == 'Onboarding Steps 8 - 9' &&
							objBoard.Sign_All_Forms_Completed__c == true &&
							objBoard.Add_Signatory_Completed__c == true &&
							ord.Opportunity.Is_Historical__c == true
						) {
							ord.status = 'Onboarding Step 10';
						}
						//After completing steps 10 move to Ready for Approval
						if (
							(ord.status == 'Onboarding Step 10' && objBoard.Verify_Bank_Info_Completed__c == true) ||
							(ord.status == 'Onboarding Steps 8 - 9' &&
							objBoard.Sign_All_Forms_Completed__c == true &&
							objBoard.Add_Signatory_Completed__c == true &&
							ord.Opportunity.Is_Historical__c == false)
						) {
							ord.status = 'Ready for Approval';
						}

						if (ord.status == 'Ready for Approval') {
							if (ord.Account.ZP_Company_Approval_Status__c == 'Approved') {
								ord.Status = 'Account Approved';
							}

							if (ord.Account.Payroll_Processing_Status__c == 'Funded' || ord.Account.Payroll_Processing_Status__c == 'Paid') {
								ord.Status = 'Closed: Payroll Run';
							}

							if (ord.Account.Payroll_Processing_Status__c == 'Processed') {
								ord.Status = 'Payroll Submitted';
							}
							if (ord.Account.ZP_Company_Approval_Status__c == 'Request for Information') {
								ord.Status = 'Assurance RFI';
							}
						}
					}
					//Check what are all steps has been completed track on associated order level
					ord.Onboarding_Steps_Completed__c = AccountTriggerHelper.RetriveCompletedSteps(objBoard);
				}
				// SJay - 3/14/2020 - Changes made to handle Orders in status Payroll Submitted can only go forward and no backward.
				if (ord.Status == 'Payroll Submitted') {
					if (ord.Account.Payroll_Processing_Status__c == 'Processed') {
						ord.Status = 'Payroll Submitted';
					}
					if (ord.Account.ZP_Company_Approval_Status__c == 'Request for Information') {
						ord.Status = 'Assurance RFI';
					}
				}
				if (ord.Status != 'Closed: Payroll Run' && objBoard.ran_payroll_at__c != null) {
					ord.Status = 'Closed: Payroll Run';
				}
				lstUpdateOrder.add(ord);
				setFilterCompanyId.add(ord.Opportunity.Account.ZP_Company_ID__c);
			}
		}
		if (lstUpdateOrder != null && lstUpdateOrder.size() > 0) {
			update lstUpdateOrder;
		}
	}

	private void processInformation(List<ZP_Company_Onboarding_Funnel__c> companyList, String type) {
		Set<String> companyIdSet = new Set<String>();
		List<Opportunity> opportunityList = new List<Opportunity>();

		for (ZP_Company_Onboarding_Funnel__c funnel : companyList) {
			if (funnel.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			funnel.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			if (String.isNotBlank(funnel.Company_Id__c)) {
				companyIdSet.add(funnel.Company_Id__c);
			}
			funnel.Message__c = '';
		}

		map<String, Opportunity> opportunityMap = getOpportunitys(companyIdSet, false);
		map<String, Opportunity> closedOpportunityMap = getOpportunitys(companyIdSet, true);
		map<String, Account> accountMap = getAccounts(companyIdSet);
		map<Id, User> userMap = getActiveUserMap();
		List<Opportunity> closedOpportunityList = new List<Opportunity>();
		for (ZP_Company_Onboarding_Funnel__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (!accountMap.containsKey(company.Company_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Company Id Does Not Exist', company);
				continue;
			}
			if (company.Deleted_At__c != null) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Migration record is already deleted', company);
				continue;
			}
			if (opportunityMap.containsKey(company.Company_Id__c)) {
				Opportunity opp = mapOnboardingFunnelFields(company, opportunityMap.get(company.Company_Id__c));
				opportunityList.add(opp);
			} else {
				Account acc = accountMap.get(company.Company_Id__c);
				if (acc.ZP_Company_Overall_Status__c == 'Suspended') {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Company is suspended.', company);
					continue;
				}
				Id oldOwnerId = null;

				Opportunity closedOpp;
				if (closedOpportunityMap.containsKey(company.Company_Id__c)) {
					closedOpp = closedOpportunityMap.get(company.Company_Id__c);
					closedOpp = mapOnboardingFunnelFields(company, closedOpp);
					opportunityList.add(closedOpp);
					continue;
				}
			}
		}

		Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
		if (opportunityList.size() > 0) {
			List<Database.SaveResult> saveResult = Database.update(opportunityList, false);
			dmlUpdateErrorsMap = Utils.processSaveResult(saveResult, opportunityList, 'Source_Id__c', true, 'ZPCompanyOnboardingFunnelTriggerHepler-processInformation');
		}
		// Handle the dml errors via addError
		for (ZP_Company_Onboarding_Funnel__c company : companyList) {
			if (company.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (dmlUpdateErrorsMap.containsKey(company.Company_ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, dmlUpdateErrorsMap.get(company.Company_ID__c), company);
			} else if (company.Processing_State__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Information is successfully processed', company);
			}
		}
	}

	private map<String, Account> getAccounts(Set<String> companyIdSet) {
		Map<String, Account> accountMap = new Map<String, Account>();
		Id idCompanyAccRecType = Cache.getRecordTypeId('Account', 'Company');
		Id idEmbeddedCompanyAccRecType = Cache.getRecordTypeId('Account', 'Embedded Company');
		for (Account acc : [
			SELECT Id, Name, ZP_Company_ID__c, ownerId, ZP_Company_Overall_Status__c
			FROM Account
			WHERE ZP_Company_ID__c IN :companyIdSet AND (RecordTypeId = :idCompanyAccRecType OR RecordTypeId = :idEmbeddedCompanyAccRecType)
		]) {
			accountMap.put('' + acc.ZP_Company_ID__c, acc);
		}
		return accountMap;
	}

	private map<String, Opportunity> getOpportunitys(Set<String> companyIdSet, boolean closed) {
		map<String, Opportunity> oppMap = new Map<String, Opportunity>();
		Id idCompanyOpptyRecType = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		Id idAcquisitionRecType = Cache.getRecordTypeId('Opportunity', 'Acquisition');
		Id idEmbeddedCompanyRecType = Cache.getRecordTypeId('Opportunity', 'Embedded Company Opportunity');
		for (Opportunity opp : [
			SELECT
				Id,
				AccountId,
				StageName,
				IsClosed,
				IsWon,
				Name,
				ZP_Company_ID__c,
				Source_Id__c,
				Onboarding_Funnel_Id__c,
				OwnerId,
				Referred_By__c,
				Sold_By__c,
				Remove_from_Opp_Nurture__c,
				Do_Not_Email__c,
				Exclude_from_List__c,
				RecordTypeId
			FROM Opportunity
			WHERE
				(Source_Id__c IN :companyIdSet
				OR ZP_Company_ID__c IN :companyIdSet)
				AND (RecordTypeId = :idCompanyOpptyRecType
				OR RecordTypeId = :idEmbeddedCompanyRecType
				OR RecordTypeId = :idAcquisitionRecType)
				AND IsClosed = :closed
		]) {
			if (opp.RecordTypeId == idEmbeddedCompanyRecType) {
				oppMap.put('' + opp.ZP_Company_ID__c, opp);
			} else {
				oppMap.put('' + opp.ZP_Company_ID__c, opp);
			}
		}
		return oppMap;
	}

	private map<id, User> getActiveUserMap() {
		return new Map<id, User>([SELECT Id, IsActive FROM User WHERE IsActive = TRUE]);
	}

	private ZP_Company_Onboarding_Funnel__c setProcessingState(String state, String message, ZP_Company_Onboarding_Funnel__c funnel) {
		funnel.Processing_State__c = state;
		funnel.Message__c = message;
		funnel.Last_Processed__c = System.now();
		return funnel;
	}
}