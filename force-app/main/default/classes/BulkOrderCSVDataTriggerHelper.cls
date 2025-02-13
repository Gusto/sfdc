/**
Created by : Gaurav Khare
Created Date : 4/23/2019
Reference :  https://docs.google.com/document/d/1Fu6dW-Z2AlZ33iRVyo9XudYTjMSDJyuq4jZlyb-C-hM/edit?ts=5cb7bd3f
**/

public class BulkOrderCSVDataTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Integer counter = 0;
	public static Boolean queue = false;
	public Boolean isOrderCreated = true;
	public Boolean isCaseCreated = true;
	public Map<string, List<string>> bulkMReqIdToListCompanyIdMap;
	Map<ID, Bulk_Migration_Request__c> bulkMReqIdTobulkMReqMap;

	public void OnBeforeInsert(List<Bulk_Order_CSV_Data__c> recList) {
		counter++;
		if (!queue) {
			for (Bulk_Order_CSV_Data__c rec : recList) {
				rec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterInsert(Map<ID, Bulk_Order_CSV_Data__c> newMap) {
		if (queue == false) {
			BulkOrderCSVDataTriggerQueue updateJob = new BulkOrderCSVDataTriggerQueue(newMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeUpdate(Map<ID, Bulk_Order_CSV_Data__c> oldMap, Map<ID, Bulk_Order_CSV_Data__c> newMap) {
		counter++;
		if (queue == true) {
			processInformation(newMap);
		} else {
			for (Bulk_Order_CSV_Data__c rec : newMap.values()) {
				rec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public void OnAfterUpdate(Map<ID, Bulk_Order_CSV_Data__c> oldMap, Map<ID, Bulk_Order_CSV_Data__c> newMap) {
		if (queue == false) {
			BulkOrderCSVDataTriggerQueue updateJob = new BulkOrderCSVDataTriggerQueue(newMap.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	public void OnBeforeDelete(Bulk_Order_CSV_Data__c[] recToDelete, Map<ID, Bulk_Order_CSV_Data__c> oldMap) {
		counter++;
	}

	public void OnAfterDelete(Bulk_Order_CSV_Data__c[] deletedRecs, Map<ID, Bulk_Order_CSV_Data__c> oldMap) {
		counter++;
	}

	public void OnUndelete(Bulk_Order_CSV_Data__c[] restoredRecs) {
		counter++;
	}

	private void processInformation(Map<ID, Bulk_Order_CSV_Data__c> newMap) {
		Map<Id, List<Bulk_Order_CSV_Data__c>> bulkMReqIdToCSVMap = new Map<Id, List<Bulk_Order_CSV_Data__c>>();
		bulkMReqIdToListCompanyIdMap = new Map<string, List<string>>();
		for (Bulk_Order_CSV_Data__c rec : newMap.values()) {
			if (rec.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			//   1. Get the map for Bulk Migration To List of CSV Orders (in case for more than 1 Bulk Req - (Csv Orders) in inserted)
			//   (though at a time one Bulk req - List csv set will be insert)
			//   2. Also make map of Bulk Mig Req -  List of CompanyId req
			//   3. Create another map of BulkReqId To BulkReq Object-- will used later in create Orders and Create case

			if (rec.Processing_State__c != IntegrationUtils.QUEUED_STATE) {
				rec.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
			if (!bulkMReqIdToCSVMap.containsKey(rec.Bulk_Migration_Request__c)) {
				bulkMReqIdToCSVMap.put(rec.Bulk_Migration_Request__c, new List<Bulk_Order_CSV_Data__c>{ rec });
				bulkMReqIdToListCompanyIdMap.put(rec.Bulk_Migration_Request__c, new List<String>{ rec.Company_ID__c });
			} else {
				bulkMReqIdToCSVMap.get(rec.Bulk_Migration_Request__c).add(rec);
				bulkMReqIdToListCompanyIdMap.get(rec.Bulk_Migration_Request__c).add(rec.Company_ID__c);
			}
		}

		bulkMReqIdTobulkMReqMap = new Map<ID, Bulk_Migration_Request__c>(
			[
				SELECT
					Id,
					OwnerId,
					Transition_To_Fulfillment__c,
					Primary_Point_of_Contact__c,
					Reseller_Account__c,
					Bulk_Migration_Owner__c,
					Total_Client_Orders__c,
					Total_Amount__c,
					Have_Run_Payroll__c,
					Number_of_Closed_Opportunities__c,
					Total_Closed_Won_MRR__c
				FROM Bulk_Migration_Request__c
				WHERE Id IN :bulkMReqIdToCSVMap.keySet()
			]
		);

		// Create Orders
		createOrders(bulkMReqIdToCSVMap);

		if (isOrderCreated) {
			// create Case only if any Order has been created
			createCase(bulkMReqIdToCSVMap);
			linkCaseAndOrders(bulkMReqIdToCSVMap);
		}
	}

	//   Loop through all records of CSV Orders for every Bulk req (Though it will be 1 at a time)
	//   Get all accounts associted with Company Id from CSV Order record (1 CSV Order rec = 1 company Id = 1 Account)
	//    While getting the account, all get child opportunity (get latest one with RecordType = Company opportunity)
	//   Create Map for Company Id To Account  :  As we need to process correctly created orders (There may be failure case also)
	//    Create Map for Company Id To Opp :  As we need to process correctly created orders (There may be failure case also)
	//    Stamp Bul Migration Id on Both Account and Oppoertunity while creating Map only, will update them later if Ordesr created
	//    These maps would be used when we check Orders created with success
	//    From Account we will also check of Joined_date

	private void createOrders(Map<Id, List<Bulk_Order_CSV_Data__c>> mapBulkMReqIdToCSV) {
		Map<string, String> errorMap = new Map<string, String>();
		Map<string, String> tempErrMap = new Map<string, String>();

		Map<string, Account> compIdToAccMap = new Map<string, Account>(); // created as we need to consider accounts for successfull orders only
		Map<string, Opportunity> compIdToOppMap = new Map<string, Opportunity>(); // created as we need to consider opps for successfull orders only

		integer countProcessedOrders = 0;
		integer countPayrollAccounts = 0;
		double oppAmount = 0;
		double closedOppAmount = 0;
		integer countClosedOpps = 0;

		Map<String, Account> mapAccToUpdate = new Map<String, Account>();
		Map<String, Opportunity> mapOppToUpdate = new Map<String, Opportunity>();
		List<Bulk_Migration_Request__c> listBulMReqToUpdate = new List<Bulk_Migration_Request__c>();

		List<Order> ordersToCreateList = new List<Order>();
		Order objOrder;

		Map<String, Account> map_ZPCompanyIdToAccount = new Map<String, Account>();
		Set<String> set_CompanyIds = new Set<String>();
		for (Id idBulkMReq : mapBulkMReqIdToCSV.keySet()) {
			set_CompanyIds.addAll(bulkMReqIdToListCompanyIdMap.get(idBulkMReq));
		}

		// Get Account and Opportunity for zp company Id provided
		for (Account objAcc : [
			SELECT
				Id,
				ZP_Company_ID__c,
				Joined_Date_Panda__c,
				Number_of_Active_Employees__c,
				Number_of_Active_Contractors__c,
				(
					SELECT Id, amount, Previous_Payroll_Provider__c, stageName, ZP_Company_ID__c
					FROM Opportunities
					WHERE RecordTypeId = :cache.getRecordTypeId('Opportunity', 'Company Opportunity') AND ZP_Company_ID__c IN :set_CompanyIds
					ORDER BY CreatedDate DESC
					LIMIT 1
				)
			FROM Account
			WHERE ZP_Company_ID__c IN :set_CompanyIds
		]) {
			map_ZPCompanyIdToAccount.put(objAcc.ZP_Company_ID__c, objAcc);
		}

		// Loop through All bulk reqIds
		for (Id bulMReqId : mapBulkMReqIdToCSV.keySet()) {
			// Mostly this would be 1 record
			List<Bulk_Order_CSV_Data__c> recList = mapBulkMReqIdToCSV.get(BulMReqId);

			List<String> list_CompanyIds = bulkMReqIdToListCompanyIdMap.get(bulMReqId);
			if (list_CompanyIds == null || list_CompanyIds.isEmpty()) {
				continue;
			}

			List<Account> list_Accounts = new List<Account>();
			for (String strCompanyId : list_CompanyIds) {
				Account objAccount = map_ZPCompanyIdToAccount.get(strCompanyId);
				if (objAccount != null) {
					list_Accounts.add(objAccount);
				}
			}

			// Set Bulk Req Id on Account and Opportunity and Keep them in map
			// create another map for closed Won opps
			for (Account acc : list_Accounts) {
				acc.Bulk_Migration__c = BulMReqId;
				compIdToAccMap.put(acc.ZP_Company_ID__c, acc);
				if (acc.opportunities != null && acc.opportunities.size() > 0 && acc.opportunities[0].ZP_Company_ID__c == acc.ZP_Company_ID__c) {
					acc.opportunities[0].Bulk_Migration__c = BulMReqId;
					compIdToOppMap.put(acc.ZP_Company_ID__c, acc.opportunities[0]);
				}
			}

			// Loop for every bulk Migration Request record ":  Mostly this would be 1
			Bulk_Migration_Request__c objBulMReq = bulkMReqIdTobulkMReqMap.get(BulMReqId);
			string bulkOwnerId = objBulMReq.OwnerId; //Bulk_Migration_Owner__c
			for (Bulk_Order_CSV_Data__c csv : recList) {
				try {
					// Any parsing data error would be captured
					objOrder = new Order();
					if (compIdToAccMap.size() > 0 && compIdToAccMap.containsKey(csv.Company_ID__c)) {
						objOrder.AccountId = compIdToAccMap.get(csv.Company_ID__c).Id;
						ObjOrder.Contractor_Count__c = compIdToAccMap.get(csv.Company_ID__c).Number_of_Active_Contractors__c;
						ObjOrder.Active_Employee_Count__c = compIdToAccMap.get(csv.Company_ID__c).Number_of_Active_Employees__c;
					} else {
						tempErrMap.put(String.valueOf(csv.Id), 'No matching account found for given company id');
						continue;
					}

					if (compIdToOppMap.size() > 0 && compIdToOppMap.containsKey(csv.Company_ID__c)) {
						objOrder.OpportunityId = compIdToOppMap.get(csv.Company_ID__c).Id;
						if (csv.Previous_Payroll_Provider__c != null) {
							objOrder.Previous_Payroll_Provider__c = csv.Previous_Payroll_Provider__c;
						} else {
							objOrder.Previous_Payroll_Provider__c = compIdToOppMap.get(csv.Company_ID__c).Previous_Payroll_Provider__c;
						}
					}
					objOrder.Bulk_Migration__c = BulMReqId;
					objOrder.OwnerId = objBulMReq.OwnerId;
					objOrder.Transition_to_Fulfillment__c = objBulMReq.Transition_To_Fulfillment__c;
					objOrder.Status = (string.valueOf(objOrder.OwnerId).startsWith('00G') ? 'Drafted' : 'Assigned');
					objOrder.CSV_For_Order__c = csv.Id;
					objOrder.RecordTypeId = cache.getRecordTypeId('Order', 'Company Migration');
					if (!string.isBlank(bulkOwnerId)) {
						ObjOrder.ownerId = bulkOwnerId;
					}
					if (csv.First_Pay_Date__c != null) {
						try {
							objOrder.First_Check_Date__c = Date.valueOf(csv.First_Pay_Date__c);
						} catch (Exception e) {
							tempErrMap.put(String.valueOf(csv.Id), 'Date is in invalid format');
							continue;
						}
					}
					if (csv.No_of_Inactive_Employees_Paid_in_20XX__c != null) {
						objOrder.Inactive_Employee_Count__c = Integer.valueOf(csv.No_of_Inactive_Employees_Paid_in_20XX__c);
					}
					if (csv.No_of_Active_Employees__c != null) {
						objOrder.Active_Employee_Count__c = Integer.valueOf(csv.No_of_Active_Employees__c);
					}
					if (csv.No_of_Contractors__c != null) {
						objOrder.Contractor_Count__c = Integer.valueOf(csv.No_of_Contractors__c);
					}
					objOrder.Pay_Schedules__c = csv.Pay_Schedule__c;
					objOrder.Pay_Schedule_2__c = csv.Pay_Schedule_2__c;
					objOrder.Tax_Payer_Type__c = csv.Entity_type__c;
					objOrder.States__c = csv.State_Operated_In__c;
					if (
						csv.Benefits_Deductions__c == 'Yes' ||
						csv.Benefits_Deductions__c == 'Y' ||
						csv.Benefits_Deductions__c == '1' ||
						csv.Benefits_Deductions__c == 'True' ||
						csv.Benefits_Deductions__c == 'TRUE'
					) {
						objOrder.Has_Benefits__c = true;
					} else {
						objOrder.Has_Benefits__c = false;
					}
					objOrder.Deductions_List__c = csv.List_deductions__c;
					objOrder.Reimbursements_List__c = csv.Additional_Reimbursements_Pay_Types__c;
					objOrder.EffectiveDate = system.now().date();
					ordersToCreateList.add(objOrder);
				} catch (Exception e) {
					tempErrMap.put(String.valueOf(csv.Id), e.getMessage());
					continue;
				}
			}
		} // outer loops ends

		if (ordersToCreateList.size() > 0) {
			OrderTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> saveResult = database.insert(ordersToCreateList, false);
			OrderTriggerHelper.skipTrigger = false;
			errorMap = Utils.processSaveResult(saveResult, ordersToCreateList, 'CSV_For_Order__c', true, 'BulkOrderCSVDataTriggerHelper-createOrders');
			// No need to create the case if all Orders failed
			if (errorMap.size() == ordersToCreateList.size()) {
				isOrderCreated = false;
			}
		} else {
			isOrderCreated = false;
		}
		if (tempErrMap.size() > 0) {
			errorMap.putAll(tempErrMap);
		}
		for (Id BulMReqId : mapBulkMReqIdToCSV.keySet()) {
			// Mostly 1 record
			Bulk_Migration_Request__c objBulMReq = bulkMReqIdTobulkMReqMap.get(BulMReqId);
			List<Bulk_Order_CSV_Data__c> recList = mapBulkMReqIdToCSV.get(objBulMReq.id);
			for (Bulk_Order_CSV_Data__c csv : recList) {
				if (errorMap != null && errorMap.containsKey(csv.Id)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, errorMap.get(csv.Id), csv);
				} else if (csv.processing_state__c == IntegrationUtils.QUEUED_STATE) {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, csv);
					countProcessedOrders++;
					// For sucessfully created Orders Update Acc and Opp as well with Bulk Mig id (1 Order = 1 company Id = 1 Acc (1 Opp))
					// Also get  Joined_Date_Panda__c (PayRollAccs) and update on Bulk Migration
					if (compIdToAccMap.containsKey(csv.Company_ID__c)) {
						mapAccToUpdate.put(csv.Company_ID__c, compIdToAccMap.get(csv.Company_ID__c));
						// Count PayRoll Accounts where Joined_Date_Panda__c is not null
						if (compIdToAccMap.get(csv.Company_ID__c).Joined_Date_Panda__c != null) {
							countPayrollAccounts++;
						}
					}
					// For sucessfully created Orders Update Acc and Opp as well with Bulk Mig id
					// Also get opp amount and update on Bulk Migration
					if (compIdToOppMap.size() > 0 && compIdToOppMap.containsKey(csv.Company_ID__c)) {
						mapOppToUpdate.put(csv.Company_ID__c, compIdToOppMap.get(csv.Company_ID__c));
						if (compIdToOppMap.get(csv.Company_ID__c).amount != null) {
							oppAmount = oppAmount + compIdToOppMap.get(csv.Company_ID__c).amount;
							// if Closed Opp then get its sum and stamp on Bilk Mig
							if (compIdToOppMap.get(csv.Company_ID__c).stageName == 'Closed Won') {
								closedOppAmount = closedOppAmount + compIdToOppMap.get(csv.Company_ID__c).amount;
								countClosedOpps++;
							}
						}
					}
				}
			}
			// 11th-June-19:// modified : more CSV upload for same Bulk Mig Request
			objBulMReq.Total_Client_Orders__c = (objBulMReq.Total_Client_Orders__c == null ? 0 : objBulMReq.Total_Client_Orders__c) + countProcessedOrders;
			objBulMReq.Total_Amount__c = (objBulMReq.Total_Amount__c == null ? 0 : objBulMReq.Total_Amount__c) + oppAmount;
			objBulMReq.Have_Run_Payroll__c = (objBulMReq.Have_Run_Payroll__c == null ? 0 : objBulMReq.Have_Run_Payroll__c) + countPayrollAccounts;
			objBulMReq.Number_of_Closed_Opportunities__c = (objBulMReq.Number_of_Closed_Opportunities__c == null ? 0 : objBulMReq.Number_of_Closed_Opportunities__c) + countClosedOpps;
			objBulMReq.Total_Closed_Won_MRR__c = (objBulMReq.Total_Closed_Won_MRR__c == null ? 0 : objBulMReq.Total_Closed_Won_MRR__c) + closedOppAmount;
		}

		if (isOrderCreated) {
			// do following only when Orders have been created
			if (mapAccToUpdate.size() > 0) {
				AccountTriggerHelper.skipTrigger = true;
				update mapAccToUpdate.values();
				AccountTriggerHelper.skipTrigger = false;
			}
			if (mapOppToUpdate.size() > 0) {
				OpportunityTriggerHelper.skipTrigger = true;
				update mapOppToUpdate.values();
				OpportunityTriggerHelper.skipTrigger = false;
			}
		}
	}

	// If Orders are created then Create Case as well
	private void createCase(Map<Id, List<Bulk_Order_CSV_Data__c>> mapBulkMReqIdToCSV) {
		Map<String, String> errorMap = new Map<String, String>();
		List<Case> caseToCreateList = new List<Case>();
		Map<Case, Id> caseToBulkReqIdMap = new Map<Case, Id>();
		List<Bulk_Migration_Request__c> bulkMReqToUpdate = new List<Bulk_Migration_Request__c>();
		Case cse;

		for (Bulk_Migration_Request__c bulMReq : bulkMReqIdTobulkMReqMap.values()) {
			// Mostly 1 rec
			string bulkOwnerId = bulMReq.OwnerId;
			cse = new case();
			if (!string.isBlank(bulkOwnerId)) {
				cse.ownerId = bulkOwnerId;
			}
			cse.RecordTypeId = cache.getRecordTypeId('Case', 'Payroll Transfer Case');
			if (bulMReq.Primary_Point_of_Contact__c == null && bulMReq.Reseller_Account__c == null) {
				errorMap.put(bulMReq.Id, 'Error in creating case: Account and Contact missing on Bulk Migration Request');
			} else {
				cse.ContactId = bulMReq.Primary_Point_of_Contact__c;
				cse.AccountId = bulMReq.Reseller_Account__c;
				cse.Type = 'Payroll Transfer';
				cse.Status = 'New';
				cse.Bulk_Migration__c = bulMReq.Id;
				cse.Origin = 'Bulk';
				caseToCreateList.add(cse);
			}
		}
		// On error update error message on Bulk Mig object
		if (caseToCreateList.size() > 0) {
			CaseTriggerHelper.skipTrigger = true;
			List<Database.SaveResult> saveResult = database.insert(caseToCreateList, false);
			CaseTriggerHelper.skipTrigger = false;
			integer i = 0;
			Bulk_Migration_Request__c objBulMReq;
			for (Database.SaveResult result : saveResult) {
				objBulMReq = bulkMReqIdTobulkMReqMap.get(caseToCreateList[i].Bulk_Migration__c);
				if (!result.isSuccess()) {
					String errorMessage = Utils.ConsolidateErrors(result.getErrors());
					String mapKey = String.valueOf(caseToCreateList[i].Bulk_Migration__c);
					objBulMReq.Message__c = errorMessage;
				} else {
					objBulMReq.Bulk_Case__c = result.getId();
				}
				bulkMReqToUpdate.add(objBulMReq);
				i++;
			}
		}
		if (bulkMReqToUpdate.size() > 0) {
			update bulkMReqToUpdate;
		}
	}

	// Link successfully created Orders with above Case
	private void linkCaseAndOrders(Map<Id, List<Bulk_Order_CSV_Data__c>> mapBulkMReqIdToCSV) {
		List<Order> listOrderToUpdate = new List<Order>();
		bulkMReqIdTobulkMReqMap = new Map<ID, Bulk_Migration_Request__c>(
			[
				SELECT Id, Bulk_Case__c, OwnerId, (SELECT Id, Bulk_Case__c FROM Orders__r WHERE Bulk_Case__c = NULL) // When second csv is uploaded, it wil bring only newly created orders
				FROM Bulk_Migration_Request__c
				WHERE Id IN :mapBulkMReqIdToCSV.keySet()
			]
		);
		for (Bulk_Migration_Request__c objBulkReq : bulkMReqIdTobulkMReqMap.values()) {
			for (Order o : objBulkReq.orders__r) {
				o.Bulk_Case__c = objBulkReq.Bulk_Case__c;
				listOrderToUpdate.add(o);
			}
		}
		if (listOrderToUpdate.size() > 0) {
			OrderTriggerHelper.skipTrigger = true;
			update listOrderToUpdate;
			OrderTriggerHelper.skipTrigger = false;
		}
	}
	// Set processing state along with error message if any
	private Bulk_Order_CSV_Data__c setProcessingState(String state, String message, Bulk_Order_CSV_Data__c rec) {
		rec.Processing_State__c = state;
		rec.Message__c = message;
		rec.Last_Processed__c = System.now();
		return rec;
	}
}