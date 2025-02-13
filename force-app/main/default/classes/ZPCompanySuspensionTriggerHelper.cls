/*
 * @name         ZPCompanySuspensionTriggerHelper
 * @author       Praveen Sethu
 * @date         12-29-2022
 * @description  Responsible for updating Overall Company Suspension Status on Account and Company Opportunity
 * @test classes ZPCompanySuspensionTriggerHelperTest
 */
public class ZPCompanySuspensionTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;
	public static final String ACCOUNT_OVERALL_STATUS_ACTIVE = 'Active';
	public static final String ACCOUNT_OVERALL_STATUS_SUSPENDED = 'Suspended';

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Runs before insert business logic
	 * @param:          list_CompanySuspensions - list of new records from trigger context
	 * @return:         NA
	 */
	public void OnBeforeInsert(List<ZP_Company_Suspension__c> list_CompanySuspensions) {
		try {
			for (ZP_Company_Suspension__c objSuspension : list_CompanySuspensions) {
				objSuspension.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (queue == true) {
				processInformation(list_CompanySuspensions, 'Insert');
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPCompanySuspensionTriggerHelper', 'OnBeforeInsert', ex);
		}
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Runs after insert business logic. Kicks off queuable job
	 * @param:          map_CompanySuspensions - Map of new records from trigger context
	 * @return:         NA
	 */
	public void OnAfterInsert(Map<ID, ZP_Company_Suspension__c> map_CompanySuspensions) {
		if (queue == false) {
			ZPCompanySuspensionQueue updateJob = new ZPCompanySuspensionQueue(map_CompanySuspensions.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Runs before update business logic
	 * @param:          map_OldCompanySuspensions - Map of new records from trigger old context
	 * @param:          map_NewSuspensions - Map of new records from trigger new context
	 * @return:         NA
	 */
	public void OnBeforeUpdate(Map<ID, ZP_Company_Suspension__c> map_OldCompanySuspensions, Map<ID, ZP_Company_Suspension__c> map_NewSuspensions) {
		try {
			for (ZP_Company_Suspension__c company : map_NewSuspensions.values()) {
				company.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (queue == true) {
				processInformation(map_NewSuspensions.values(), 'Update');
			}
		} catch (Exception ex) {
			ExceptionLogUtil.logException('ZPCompanySuspensionTriggerHelper', 'OnBeforeUpdate', ex);
		}
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Runs after update business logic
	 * @param:          map_OldCompanySuspensions - Map of new records from trigger old context
	 * @param:          map_NewSuspensions - Map of new records from trigger new context
	 * @return:         NA
	 */
	public void OnAfterUpdate(Map<ID, ZP_Company_Suspension__c> map_OldCompanySuspensions, Map<ID, ZP_Company_Suspension__c> map_NewSuspensions) {
		if (queue == false) {
			ZPCompanySuspensionQueue updateJob = new ZPCompanySuspensionQueue(map_NewSuspensions.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Map suspension data from staging to user facing object and links to Accunt
	 * @param:          zpSuspension - ZP Suspension data
	 * @param:          objAcc - Company Account
	 * @return:         Company_Suspension__c - User facing company suspension record
	 */
	private Company_Suspension__c mapSuspensionData(ZP_Company_Suspension__c zpSuspension, Account objAcc) {
		Company_Suspension__c suspension = new Company_Suspension__c();
		suspension.Books_Closed__c = zpSuspension.Books_Closed__c;
		suspension.Comments__c = zpSuspension.Comments__c;
		suspension.Company_Id__c = zpSuspension.Company_Id__c;
		suspension.Created_At__c = zpSuspension.Created_At__c;
		suspension.Deleted_At__c = zpSuspension.Deleted_At__c;
		if (zpSuspension.Deleted_At__c != null) {
			suspension.Deleted__c = true;
		} else {
			suspension.Deleted__c = false;
		}
		suspension.External_Key__c = zpSuspension.External_Key__c;
		suspension.File_Quarterly_Forms__c = zpSuspension.File_Quarterly_Forms__c;
		suspension.File_Yearly_Forms__c = zpSuspension.File_Yearly_Forms__c;
		suspension.Id__c = zpSuspension.Id__c;
		suspension.Leaving_For__c = zpSuspension.Leaving_For__c;
		suspension.Liabilities_Rescheduled__c = zpSuspension.Liabilities_Rescheduled__c;
		suspension.Reason__c = zpSuspension.Reason__c;
		suspension.Reconcile_Tax_Method__c = zpSuspension.Reconcile_Tax_Method__c;
		suspension.Suspended_At__c = zpSuspension.Suspended_At__c;
		suspension.Unsuspended_At__c = zpSuspension.Unsuspended_At__c;
		suspension.Updated_At__c = zpSuspension.Updated_At__c;
		suspension.Account__c = objAcc.id;
		return suspension;
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Business logic that updates overall suspension status on Account and Opportunity
	 * @param:          list_NewSuspensions - List of suspension records from trigger context
	 * @return:         NA
	 */
	private void processInformation(List<ZP_Company_Suspension__c> list_NewSuspensions, String type) {
		// Declare all variables
		Set<String> set_CompanyIds = new Set<String>();
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		List<Company_Suspension__c> list_SuspensionsToUpsert = new List<Company_Suspension__c>();
		Map<String, String> map_DMLErrors = new Map<String, String>();

		for (ZP_Company_Suspension__c objSuspension : list_NewSuspensions) {
			if (objSuspension.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (objSuspension.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				objSuspension.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (String.isNotBlank(objSuspension.Company_Id__c)) {
				set_CompanyIds.add(objSuspension.Company_Id__c);
			}
			objSuspension.Message__c = '';
		}

		// query all company accounts and opportunities
		Map<String, Account> map_Accounts = getAccounts(set_CompanyIds);
		Map<String, ZP_Company_Suspension__c> map_Suspensions = getLatestSuspension(set_CompanyIds);

		for (ZP_Company_Suspension__c objSuspension : list_NewSuspensions) {
			if (objSuspension.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}

			if (String.isNotBlank(objSuspension.Company_Id__c) && map_Accounts.containsKey(objSuspension.Company_Id__c)) {
				// get company account from map
				Account objAcc = map_Accounts.get(objSuspension.Company_Id__c);

				// map suspension data from staging object to user facing object and add it to a list
				list_SuspensionsToUpsert.add(mapSuspensionData(objSuspension, objAcc));

				if (map_Suspensions.containsKey(objSuspension.Company_Id__c)) {
					ZP_Company_Suspension__c objMostRecentSuspension = map_Suspensions.get(objSuspension.Company_Id__c);

					if (objSuspension.Unsuspended_At__c != null && objMostRecentSuspension.Unsuspended_At__c <= Date.today().addDays(1)) {
						objAcc.ZP_Company_Overall_Status__c = ACCOUNT_OVERALL_STATUS_ACTIVE;
						objAcc.ZP_Company_Suspension_Reason__c = '';
						objAcc.ZP_Company_Suspension_Date__c = null;

						// update company opportunity
						for (Opportunity objOppty : objAcc.Opportunities) {
							if (objOppty.ZP_Company_Suspended__c) {
								objOppty.ZP_Company_Suspended__c = false;
								map_OpptysToUpdate.put(objOppty.Id, objOppty);
							}
						}
					} else {
						objAcc.ZP_Company_Suspension_Reason__c = objMostRecentSuspension.Reason__c;
						objAcc.ZP_Company_Suspension_Date__c = objMostRecentSuspension.Suspended_At__c;
						objAcc.ZP_Company_Overall_Status__c = ACCOUNT_OVERALL_STATUS_SUSPENDED;

						// update company opportunity
						for (Opportunity objOppty : objAcc.Opportunities) {
							if (!objOppty.ZP_Company_Suspended__c) {
								objOppty.ZP_Company_Suspended__c = true;
								map_OpptysToUpdate.put(objOppty.Id, objOppty);
							}
						}
					}

					map_AccountsToUpdate.put(objAcc.Id, objAcc);
				}
			} else {
				setProcessingState(IntegrationUtils.ERROR_STATE, 'Account does not exist for the Company Id', objSuspension);
			}
		}

		// update overall status on Account
		if (!map_AccountsToUpdate.isEmpty()) {
			List<Database.SaveResult> saveResult = Database.update(map_AccountsToUpdate.values(), false);
			map_DMLErrors = Utils.processSaveResult(saveResult, map_AccountsToUpdate.values(), 'ZP_Company_ID__c', true, 'ZPCompanySuspensionTriggerHepler-processInformation');
		}

		if (map_DMLErrors.keySet().size() > 0) {
			for (ZP_Company_Suspension__c objSuspension : list_NewSuspensions) {
				if (map_DMLErrors.containsKey(objSuspension.Company_ID__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLErrors.get(objSuspension.Company_ID__c), objSuspension);
				}
			}
		}

		// update overall status on Opportunity
		map_DMLErrors = new Map<String, String>();
		OpportunityTriggerHelper.skipTrigger = true;
		if (!map_OpptysToUpdate.isEmpty()) {
			List<Database.SaveResult> saveResult = Database.update(map_OpptysToUpdate.values(), false);
			map_DMLErrors = Utils.processSaveResult(saveResult, map_OpptysToUpdate.values(), 'Source_Id__c', true, 'ZPCompanySuspensionTriggerHepler-processInformation');
		}

		for (ZP_Company_Suspension__c suspension : list_NewSuspensions) {
			if (map_DMLErrors.containsKey(suspension.Company_ID__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, map_DMLErrors.get(suspension.Company_ID__c), suspension);
			} else if (suspension.processing_state__c == IntegrationUtils.QUEUED_STATE) {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, suspension);
			}
		}

		// update user facing company suspension record
		if (list_SuspensionsToUpsert.size() > 0) {
			upsert list_SuspensionsToUpsert Id__c;
		}
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Set Processing State of ZP Company Suspension context record
	 * @param:          strState - processing state
	 * @param:          strMessage - success or error message
	 * @param:          objSuspension - company suspension trigger context record
	 * @return:         objSuspension - company suspension trigger context record
	 */
	private Zp_Company_Suspension__c setProcessingState(String strState, String strMessage, Zp_Company_Suspension__c objSuspension) {
		objSuspension.Processing_State__c = strState;
		objSuspension.Message__c = strMessage;
		objSuspension.Last_Processed__c = System.now();
		return objSuspension;
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Query accounts and opportunities
	 * @param:          set_CompanyIds - Set of company Ids
	 * @return:         map_Accounts - Map of account Ids and Account
	 */
	private Map<String, Account> getAccounts(Set<String> set_CompanyIds) {
		Id idCompanyOpptyRType = Cache.getRecordTypeId('Opportunity', 'Company Opportunity');
		Id idCompanyAccRType = Cache.getRecordTypeId('Account', 'Company');
		Map<String, Account> map_Accounts = new Map<String, Account>();
		for (Account objAcc : [
			SELECT
				Id,
				Name,
				ZP_Company_ID__c,
				(SELECT Id, StageName, IsClosed, IsWon, Name, ZP_Company_ID__c, Source_Id__c, ZP_Company_Suspended__c FROM Opportunities WHERE RecordTypeId = :idCompanyOpptyRType AND IsClosed = FALSE)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanyIds AND RecordTypeId = :idCompanyAccRType
		]) {
			map_Accounts.put(objAcc.ZP_Company_ID__c, objAcc);
		}
		return map_Accounts;
	}

	/*
	 * @author:         Praveen Sethu
	 * @description:   	Build a map of company Id and  most recent zp company suspension record
	 * @param:          set_CompanyIds - Set of company Ids
	 * @return:         map_Suspensions - Map of company Id and company suspension
	 */
	private Map<String, ZP_Company_Suspension__c> getLatestSuspension(Set<String> set_CompanyIds) {
		Map<String, ZP_Company_Suspension__c> map_Suspensions = new Map<String, ZP_Company_Suspension__c>();

		for (ZP_Company_Suspension__c objSuspension : [
			SELECT Id, Company_ID__c, Unsuspended_At__c, Reason__c, Suspended_At__c
			FROM ZP_Company_Suspension__c
			WHERE Company_Id__c IN :set_CompanyIds
			ORDER BY Created_At__c DESC
		]) {
			if (!map_Suspensions.containsKey(objSuspension.Company_ID__c)) {
				map_Suspensions.put(objSuspension.Company_ID__c, objSuspension);
			}
		}

		return map_Suspensions;
	}
}