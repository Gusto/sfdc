/**
 * @description  Calculates metrics on Reseller Account
 * @author       Praveen Sethu
 * @author       Ajay Krishna P U
 * @date         01-28-2023
 * @see          CalculateResellerMetricsBatchTest
 * @see          PartnerProgramCompanyTriggerHelperTest, AccountTriggerHelperTest.testSetRecalculateMRR
 **/

public with sharing class CalculateResellerMetricsBatch implements Database.Batchable<sObject>, Database.Stateful {
	/**
	 * @description Batch Start Method
	 * @author Praveen Sethu
	 * @param  bc Batch Context
	 * @return    return QueryLocator
	 */
	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(
			'SELECT Id, First_Client_Create_Date__c, SAL_to_First_Client_Add__c, CreatedDate, RecordTypeId, Cohort_Date__c,' +
				' Sales_Engagement_Status__c, Reseller_Type__c, Account_Owner_Role__c,' +
				' Firm_MRR__c, Calculate_Reseller_Metrics__c, Recalculate_Metrics_Tracker__c,' +
				' (SELECT Id, No_Of_Change_No_Of_Clients__c, Unique_Account_Id__c, Q_Tracking__c, No_of_adds_current_Q__c FROM Account_Related_Trackings__r WHERE Unique_Account_Id__c != NULL ORDER BY CreatedDate LIMIT 1)' +
				' FROM Account' +
				' WHERE (Calculate_Reseller_Metrics__c = TRUE OR Recalculate_Metrics_Tracker__c != NULL)' +
				' AND LastModifiedDate = LAST_N_DAYS:1'
		);
	}

	/**
	 * @description Batch Execute method
	 * @author Praveen Sethu
	 * @param  bc            Batch Context
	 * @param  list_Accounts Batch scope
	 */
	public void execute(Database.BatchableContext bc, List<Account> list_Accounts) {
		//Segregated Accounts Lists
		List<Account> list_CalculateResellerMetricsAccounts = new List<Account>();
		List<Account> list_CalculateFirmMRRAccounts = new List<Account>();

		//Additional variables in Reference
		Map<Id, Account_Related_Tracking__c> map_AccIdToTrackingToUpsert = new Map<Id, Account_Related_Tracking__c>();

		try {
			//Segregate Accounts Based on Updation Type
			for (Account objAccount : list_Accounts) {
				if (objAccount.Calculate_Reseller_Metrics__c == true) {
					list_CalculateResellerMetricsAccounts.add(objAccount);
				}

				if (Utils.isMultiPicklistContains(objAccount.Recalculate_Metrics_Tracker__c, AccountUtil.TRACKER_FIRM_MRR)) {
					list_CalculateFirmMRRAccounts.add(objAccount);
				}
			}

			//calculate Metrics
			Map<Id, Account> map_AccountsToUpdate = calculateMetricsFromOpportunity(list_CalculateResellerMetricsAccounts, map_AccIdToTrackingToUpsert);
			map_AccountsToUpdate = calculateFirmMRRAndClients(map_AccountsToUpdate, list_CalculateFirmMRRAccounts);

			//Update Changes
			AccountTriggerHelper.skipTrigger = true;
			update map_AccountsToUpdate.values();
			upsert map_AccIdToTrackingToUpsert.values() Unique_Account_Id__c;
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CalculateResellerMetricsBatch', 'execute', null, objException);
		}
	}

	/**
	 * @description Batch finish method
	 * @author Praveen Sethu
	 * @param  bc Batch context
	 */
	public void finish(Database.BatchableContext bc) {
	}

	/**
	 * @description Calculate Reseller Metrics
	 * @author Praveen Sethu
	 * @param  list_Accounts               The Accounts to be processed
	 * @param  map_AccIdToTrackingToUpsert The Account Tracking to be Updated
	 * @return                             `Map<Id, Account>`
	 */
	public Map<Id, Account> calculateMetricsFromOpportunity(List<Account> list_Accounts, Map<Id, Account_Related_Tracking__c> map_AccIdToTrackingToUpsert) {
		// Declare all variables
		Set<Id> set_AccountIds = new Set<Id>();
		Map<Id, List<Opportunity>> map_SoldByAccountToOpptyList = new Map<Id, List<Opportunity>>();
		Map<Id, List<Opportunity>> map_ReferredByAccountToOpptyList = new Map<Id, List<Opportunity>>();

		// Gather Account Ids
		for (Account objAcc : list_Accounts) {
			set_AccountIds.add(objAcc.Id);
		}

		// Query all sold by and referred by opportunities
		// Build a map of sold by and child opportunties
		// Build a map of referred by and child opportunities
		for (Opportunity objOppty : [
			SELECT Id, IsClosed, StageName, CreatedDate, RecordTypeId, Amount, Sold_by__c, Referred_by__c
			FROM Opportunity
			WHERE Sold_By__c IN :set_AccountIds OR Referred_By__c IN :set_AccountIds
			ORDER BY CreatedDate ASC
		]) {
			if (objOppty.Sold_by__c != null) {
				List<Opportunity> list_TempOppty = map_SoldByAccountToOpptyList.containsKey(objOppty.Sold_by__c) ? map_SoldByAccountToOpptyList.get(objOppty.Sold_by__c) : new List<Opportunity>();
				list_TempOppty.add(objOppty);
				map_SoldByAccountToOpptyList.put(objOppty.Sold_by__c, list_TempOppty);
			}

			if (objOppty.Referred_by__c != null) {
				List<Opportunity> list_TempOppty = map_ReferredByAccountToOpptyList.containsKey(objOppty.Referred_by__c)
					? map_ReferredByAccountToOpptyList.get(objOppty.Referred_by__c)
					: new List<Opportunity>();
				list_TempOppty.add(objOppty);
				map_ReferredByAccountToOpptyList.put(objOppty.Referred_by__c, list_TempOppty);
			}
		}

		// calculate metrics for sold by and referred by accounts
		for (Account objAccnt : list_Accounts) {
			// Declare all variables
			// Counts of Opportunities
			Integer intRefOpen = 0;
			Integer intRefClosed = 0;
			Integer intRefClosedWon = 0;
			Integer intRefClosedLost = 0;
			Integer intSoldOpen = 0;
			Integer intSoldClosed = 0;
			Integer intSoldClosedWon = 0;
			Integer intSoldClosedLost = 0;
			Integer intAddsCurrentFQ = 0;
			Integer intAddsCurrentFY = 0;

			// Amount Totals
			Decimal decSoldAmount = 0;
			Decimal decRefAmount = 0;

			// calculate metrics for referred by account
			if (map_ReferredByAccountToOpptyList.containsKey(objAccnt.Id)) {
				// get a list of referred by opportunities
				List<Opportunity> list_Opptys = map_ReferredByAccountToOpptyList.get(objAccnt.Id);

				// iterate over all referred by opportunities
				for (Opportunity objOpp : list_Opptys) {
					if (objAccnt.First_Client_Create_Date__c == null) {
						objAccnt.First_Client_Create_Date__c = objOpp.CreatedDate.date();
					}

					if (objOpp.IsClosed) {
						intRefClosed++;

						if (objOpp.StageName == OpportunityUtil.CLOSED_WON_STAGE) {
							intRefClosedWon++;

							// Days Between Opportunity and Account created date
							if (objAccnt.SAL_to_First_Client_Add__c == null) {
								objAccnt.SAL_to_First_Client_Add__c = objOpp.CreatedDate.date().daysBetween(objAccnt.CreatedDate.date());
							}

							// Company Opportunity
							if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
								// closed this fiscal quarter
								if (OpportunityUtil.isCurrentFQ(objOpp.CreatedDate.date())) {
									intAddsCurrentFQ++;
								}

								// closed this fiscal year
								if (OpportunityUtil.isCurrentFY(objOpp.CreatedDate.date())) {
									intAddsCurrentFY++;
								}

								decRefAmount += objOpp.Amount != null ? objOpp.Amount : 0;
							}
						} else if (objOpp.StageName == OpportunityUtil.CLOSED_LOST_STAGE) {
							intRefClosedLost++;
						}
					} else {
						intRefOpen++;
						// Company Opportunity
						if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
							decRefAmount += objOpp.Amount != null ? objOpp.Amount : 0;
						}
					}
				}
			}

			// calculate metrics for sold by account
			if (map_SoldByAccountToOpptyList.containsKey(objAccnt.Id)) {
				List<Opportunity> list_Opptys = map_SoldByAccountToOpptyList.get(objAccnt.Id);
				// first client created date is blank or greater than earliest sold by opportunity created date
				for (Opportunity objOpp : list_Opptys) {
					if (objAccnt.First_Client_Create_Date__c == null || objAccnt.First_Client_Create_Date__c > objOpp.CreatedDate.date()) {
						objAccnt.First_Client_Create_Date__c = objOpp.CreatedDate.date();
					}

					if (objOpp.IsClosed) {
						intSoldClosed++;

						if (objOpp.StageName == OpportunityUtil.CLOSED_WON_STAGE) {
							intSoldClosedWon++;

							// Days Between Opportunity and Account created date
							if (objAccnt.SAL_to_First_Client_Add__c == null) {
								objAccnt.SAL_to_First_Client_Add__c = objAccnt.CreatedDate.date().daysBetween(objOpp.CreatedDate.date());
							}

							// Company Opportunity
							if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
								// closed this fiscal quarter
								if (OpportunityUtil.isCurrentFQ(objOpp.CreatedDate.date())) {
									intAddsCurrentFQ++;
								}

								// closed this fiscal year
								if (OpportunityUtil.isCurrentFY(objOpp.CreatedDate.date())) {
									intAddsCurrentFY++;
								}

								decSoldAmount += objOpp.Amount != null ? objOpp.Amount : 0;
							}
						} else if (objOpp.StageName == OpportunityUtil.CLOSED_LOST_STAGE) {
							intSoldClosedLost++;
						}
					} else {
						intSoldOpen++;
						// Company Opportunity
						if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
							decSoldAmount += objOpp.Amount != null ? objOpp.Amount : 0;
						}
					}
				}
			}

			// set metrics on sold by or referred by account
			objAccnt.NumberOf_Closed_Payroll_Opps_Sold_By__c = intSoldClosedWon;
			objAccnt.Number_Of_Open_Payroll_Opps_Sold_By__c = intSoldOpen;
			objAccnt.No_Of_Closed_Lost_Sold_By__c = intSoldClosedLost;

			objAccnt.NumberOf_Closed_Payroll_Opps_Referred_By__c = intRefClosedWon;
			objAccnt.Number_Of_Open_Payroll_Opps_Referred_By__c = intRefOpen;
			objAccnt.No_Of_Closed_Lost_Referred_By__c = intRefClosedLost;

			Integer intTotalSold = intSoldOpen + intSoldClosed;
			Integer intTotalReferred = intRefOpen + intRefClosed;
			Integer intTotalClients = intTotalSold + intTotalReferred;

			objAccnt.CvR_Sold_By__c = intTotalSold > 0 ? (intSoldClosedWon * 100.0) / intTotalSold : 0;
			objAccnt.CvR_Referred_By__c = intTotalReferred > 0 ? (intRefClosedWon * 100) / intTotalReferred : 0;
			objAccnt.Total_CvR__c = intTotalClients > 0 ? ((intSoldClosedWon + intRefClosedWon) * 100.0) / intTotalClients : 0;

			// Rolling Up Amounts from Open and Closed Won Opportunities (Sold-By and Referred-By)
			objAccnt.Sold_By_Total_Amount__c = decSoldAmount;
			objAccnt.Referred_By_Total_Amount__c = decRefAmount;

			// upsert account related tracking
			Account_Related_Tracking__c objAccTrack = new Account_Related_Tracking__c(Unique_Account_Id__c = objAccnt.Id, Account__c = objAccnt.Id);

			if (!objAccnt.Account_Related_Trackings__r.isEmpty()) {
				objAccTrack = objAccnt.Account_Related_Trackings__r.get(0);
			}

			objAccTrack.No_of_Clients__c = intTotalClients;

			// Tracking number of changes in value of number of clients
			if (objAccTrack.No_Of_Change_No_Of_Clients__c == null || objAccTrack.No_Of_Change_No_Of_Clients__c == 0) {
				objAccTrack.No_Of_Change_No_Of_Clients__c = 1;
			} else if (objAccTrack.No_Of_Change_No_Of_Clients__c > 0) {
				objAccTrack.No_Of_Change_No_Of_Clients__c = objAccTrack.No_Of_Change_No_Of_Clients__c + 1;
			}

			if (OpportunityUtil.objCurrentFQ == null) {
				OpportunityUtil.fetchFiscalPeriods();
			}

			// New record or current quarter
			if (objAccTrack.Q_Tracking__c == null || objAccTrack.Q_Tracking__c == ('Q' + OpportunityUtil.objCurrentFQ.Number)) {
				objAccTrack.No_of_adds_current_Q__c = intAddsCurrentFQ;
				objAccTrack.Q_Tracking__c = 'Q' + OpportunityUtil.objCurrentFQ.Number;
			} else {
				// Current Quarter different from Quarter tracked on Record (put existing values into Last FQ and put new values in current FQ)
				objAccTrack.No_of_adds_last_Q__c = objAccTrack.No_of_adds_current_Q__c;
				objAccTrack.No_of_adds_current_Q__c = intAddsCurrentFQ;
				objAccTrack.Q_Tracking__c = 'Q' + OpportunityUtil.objCurrentFQ.Number;
			}

			objAccTrack.No_of_total_adds_in_current_FY__c = intAddsCurrentFY;

			// add records to update
			map_AccIdToTrackingToUpsert.put(objAccnt.Id, objAccTrack);

			// set reseller calculate metrics to false
			objAccnt.Calculate_Reseller_Metrics__c = false;
		}

		return new Map<Id, Account>(list_Accounts);
	}

	/**
	 * @description Calculates Firm MRR, Active Clients and Client Book Size
	 * @author Ajay Krishna P U
	 * @param  list_AccountsToProcess The Accounts to be processed
	 * @return               `Map<Id, Account>`
	 */
	public Map<Id, Account> calculateFirmMRRAndClients(Map<Id, Account> map_AccountsToUpdate, List<Account> list_AccountsToProcess) {
		Map<Id, Account> map_ResellerAccounts = new Map<Id, Account>();
		Set<Id> set_ResellerAccountIds = new Set<Id>();
		Set<Id> set_ClientAccountIds = new Set<Id>();

		//Segregate by Record Type
		for (Account objAccount : list_AccountsToProcess) {
			if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				set_ResellerAccountIds.add(objAccount.Id);
			} else {
				set_ClientAccountIds.add(objAccount.Id);
			}
		}

		//Fetch All Reseller Accounts Related to Client Accounts
		for (Partner_Program_Company_Data__c objPartnerProgram : [
			SELECT Id, Managing_Accounting_Firm__c, Account__c
			FROM Partner_Program_Company_Data__c
			WHERE Account__c IN :set_ClientAccountIds AND Managing_Accounting_Firm__c != NULL
		]) {
			set_ResellerAccountIds.add(objPartnerProgram.Managing_Accounting_Firm__c);
		}

		//Reset Reseller Metrics to 0
		for (Account objAcc : [SELECT Id, Sales_Engagement_Status__c FROM Account WHERE RecordTypeId = :AccountUtil.RESELLER_ACCOUNT_RT_ID AND Id IN :set_ResellerAccountIds]) {
			Account objAccount = getAccountReference(map_AccountsToUpdate, objAcc.Id, true);
			objAccount.Firm_MRR__c = 0;
			objAccount.Client_Book_Size__c = 0;
			objAccount.Active_Clients__c = 0;
			objAccount.Recalculate_Metrics_Tracker__c = null;
			objAccount.Sales_Engagement_Status__c = objAcc.Sales_Engagement_Status__c;
		}

		//Calculate Reseller Metrics
		for (Partner_Program_Company_Data__c objPartnerProgram : [
			SELECT Id, Managing_Accounting_Firm__c, Account__c, Account__r.Current_MRR__c, Deleted_At__c, Account__r.ZP_Company_Suspension_Date__c
			FROM Partner_Program_Company_Data__c
			WHERE Managing_Accounting_Firm__c IN :set_ResellerAccountIds
			ORDER BY Managing_Accounting_Firm__c
		]) {
			Account objAccount = getAccountReference(map_AccountsToUpdate, objPartnerProgram.Managing_Accounting_Firm__c, true);

			//check whether Client is Active
			if (objPartnerProgram.Deleted_At__c == null && objPartnerProgram.Account__r.ZP_Company_Suspension_Date__c == null) {
				objAccount.Firm_MRR__c = addValues(objAccount.Firm_MRR__c, objPartnerProgram.Account__r.Current_MRR__c);
				objAccount.Active_Clients__c = addValues(objAccount.Active_Clients__c, 1);
			}
			objAccount.Client_Book_Size__c = addValues(objAccount.Client_Book_Size__c, 1);
		}
		//Reset Reseller Metrics to 0
		for (Id idReseller : set_ResellerAccountIds) {
			Account objAccount = getAccountReference(map_AccountsToUpdate, idReseller, true);
			if (objAccount.Active_Clients__c == 0 && objAccount.Sales_Engagement_Status__c == AccountUtil.SALES_ENGMNT_STATUS_ACTIVE) {
				objAccount.Sales_Engagement_Status__c = AccountUtil.SALES_ENGMNT_STATUS_CHURNED;
			}
		}

		//Resets Client AccountIds, Since its related Resellers are updated by above conditions.
		for (Id idAccount : set_ClientAccountIds) {
			Account objAccount = getAccountReference(map_AccountsToUpdate, idAccount, true);
			objAccount.Recalculate_Metrics_Tracker__c = null;
		}

		return map_AccountsToUpdate;
	}

	/**
	 * @description	Get the Account Reference from a Map.
	 * @author Ajay Krishna P U
	 * @param map_Accounts        The Source Map
	 * @param idAccount           The key to Search on map_Accounts
	 * @param blnAddOneIfNotFound Add a new Account object If key Not found
	 * @return                    `Account`
	 */
	private Account getAccountReference(Map<Id, Account> map_Accounts, Id idAccount, Boolean blnAddOneIfNotFound) {
		Account objAccount = map_Accounts.get(idAccount);

		if (objAccount == null && blnAddOneIfNotFound == true) {
			objAccount = new Account(Id = idAccount);
			map_Accounts.put(idAccount, objAccount);
		}

		return objAccount;
	}

	/**
	 * @description	Add values @decSource + @decAdd
	 * @author Ajay Krishna P U
	 * @param decSource The Source/ initial value
	 * @param decAdd    The value to be added
	 * @return          `Decimal`
	 */
	private Decimal addValues(Decimal decSource, Decimal decAdd) {
		decSource = decSource == null ? 0 : decSource;
		decAdd = decAdd == null ? 0 : decAdd;

		return decSource + decAdd;
	}
}