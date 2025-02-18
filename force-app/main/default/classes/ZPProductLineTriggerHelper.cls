/**
 * @description Trigger helper for ZP_Product_Line__c. This class is being used to execeute the scenarios for Base and Add on ZP Prod lines.
 * @author Anurag Gautam
 * @since 06/06/2023
 * @group ZP_Product_Line__c
 * Test: ZPProductLineTriggerHelperTest
 */
public with sharing class ZPProductLineTriggerHelper {
	// skipTrigger flag to controll the trigger execution
	public static boolean skipTrigger = false;
	// queue flag to indicate if its executed in Queueable context
	public static Boolean blnQueue = false;
	// Set of Company Ids after all error validation for the same ZP Product line records.
	public Set<String> set_CompanyIds = new Set<String>();
	// Set of Company Ids after dynamic validation on different records such as Accounts, ZP Companies and Payment Plan
	public static Set<String> set_CompanyIdsForAccProcessing = new Set<String>();
	public Map<String, ZP_Company__c> map_IdToZPCompany;
	// Map to hold the Accounts value against company Id
	public static Map<String, Account> map_CompanyIdToAccount = new Map<String, Account>();
	// Map after final account update
	public static Map<String, String> map_CompanyIdToAccountDMLErrors = new Map<String, String>();
	// Map to contain all processed ZP Prod line and their message for the final update.
	public static Map<String, ZP_Product_Line__c> map_IDToProdLinesWithFinalMessage = new Map<String, ZP_Product_Line__c>();

	public static Map<Id, Map<String, PriceBookEntry>> map_PBIdToMapOfProdNameToPBE = new Map<Id, Map<String, PriceBookEntry>>();
	public ZPProductLineTriggerHelper() {
		set_CompanyIds = new Set<String>();
		map_IdToZPCompany = new Map<String, ZP_Company__c>();
	}

	/**
	 * @description This method is handling the before insert trigger process such as error validation and prepare the final list.
	 * @param list_ZPProductLine Trigger.new (IDs have not been assigned, and Trigger.old does not exist)
	 */
	public void processBeforeInsert(List<ZP_Product_Line__c> list_ZPProductLine) {
		if (blnQueue) {
			processProductLineRecords(list_ZPProductLine, null);
		} else {
			for (ZP_Product_Line__c objProductLine : list_ZPProductLine) {
				objProductLine.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	/**
	 * @description This method is handling the after insert trigger process such as updating the Accounts and ZP Product lines.
	 * @param map_ZPProductLine Trigger.newMap (note: Trigger.old does not exist in insert context)
	 */
	public void processAfterInsert(Map<Id, ZP_Product_Line__c> map_ZPProductLine) {
		if (blnQueue) {
			// this method is preparing the list of companies for the final update.
			processTierAndPricingChanges(map_ZPProductLine.values());
			// updating the ZP Product lines after processing.
			updateZPProductLineProcessingState(map_ZPProductLine.values());
		} else {
			ZPProductLineQueue objInsertJob = new ZPProductLineQueue(map_ZPProductLine.values());
			ID idInsertJob = System.enqueueJob(objInsertJob);
		}
	}

	/**
	 * @description * @description This method is handling the before update trigger process such as error validation and prepare the final list.
	 * @param map_OldZPProductLine Trigger.oldMap
	 * @param map_ZPProductLine    Trigger.new
	 */
	public void processBeforeUpdate(Map<Id, ZP_Product_Line__c> map_OldZPProductLine, Map<Id, ZP_Product_Line__c> map_ZPProductLine) {
		if (blnQueue) {
			processProductLineRecords(map_ZPProductLine.values(), map_OldZPProductLine);
		} else {
			for (ZP_Product_Line__c objProductLine : map_ZPProductLine.values()) {
				// Get the old ZP Product line record from Trigger.oldMap
				ZP_Product_Line__c objOldProductLine = map_OldZPProductLine != null && map_OldZPProductLine.containsKey(objProductLine.Id) ? map_OldZPProductLine.get(objProductLine.Id) : null;

				// if created at changes - revert back to old value
				if (objOldProductLine != null && objOldProductLine.Created_At__c != null && objOldProductLine.Created_At__c != objProductLine.Created_At__c) {
					objProductLine.Created_At__c = objOldProductLine.Created_At__c;
				}
				objProductLine.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	/**
	 * @description This method is handling the after update trigger process such as updating the Accounts and ZP Product lines.
	 * @param map_OldZPProductLine Trigger.oldMap
	 * @param map_ZPProductLine    Trigger.new
	 */
	public void processAfterUpdate(Map<Id, ZP_Product_Line__c> map_OldZPProductLine, Map<Id, ZP_Product_Line__c> map_ZPProductLine) {
		if (blnQueue) {
			// this method is preparing the list of companies for the final update.
			processTierAndPricingChanges(map_ZPProductLine.values());
			// updating the ZP Product lines after processing.
			updateZPProductLineProcessingState(map_ZPProductLine.values());
		} else {
			ZPProductLineQueue objUpdateJob = new ZPProductLineQueue(map_ZPProductLine.values());
			ID idUpdateJob = System.enqueueJob(objUpdateJob);
		}
	}

	/**
	 * @description This method is being used to update the ZP product line records after account update process. This would be the final Processing state value.
	 * @param List of all ZP Product lines for final update.
	 */
	public void updateZPProductLineProcessingState(List<ZP_Product_Line__c> list_ZPProductLine) {
		List<ZP_Product_Line__c> list_ZPProductLinesToUpdate = new List<ZP_Product_Line__c>();
		// Populating processing state and message based on DML error or success.
		for (ZP_Product_Line__c objProductLine : map_IDToProdLinesWithFinalMessage.values()) {
			if (map_CompanyIdToAccountDMLErrors.containsKey(objProductLine.Company_Id__c)) {
				list_ZPProductLinesToUpdate.add(
					new ZP_Product_Line__c(
						Id = objProductLine.Id,
						Processing_State__c = IntegrationUtils.ERROR_STATE,
						Message__c = map_CompanyIdToAccountDMLErrors.get(objProductLine.Company_Id__c),
						Last_Processed__c = System.now()
					)
				);
			} else {
				objProductLine.Last_Processed__c = System.now();
				list_ZPProductLinesToUpdate.add(objProductLine);
			}
		}

		for (ZP_Product_Line__c objProductLine : list_ZPProductLine) {
			if (!map_IDToProdLinesWithFinalMessage.containsKey(objProductLine.Id) && IntegrationUtils.QUEUED_STATE.equalsIgnoreCase(objProductLine.Processing_State__c)) {
				if (ZPProductLineUtil.STATUS_DELETED.equalsIgnoreCase(objProductLine.Status__c)) {
					list_ZPProductLinesToUpdate.add(
						new ZP_Product_Line__c(
							Id = objProductLine.Id,
							Processing_State__c = IntegrationUtils.DEAD_STATE,
							Message__c = ZPProductLineUtil.PRODUCT_DEACTIVATED_MESSAGE,
							Last_Processed__c = System.now()
						)
					);
				} else {
					list_ZPProductLinesToUpdate.add(
						new ZP_Product_Line__c(
							Id = objProductLine.Id,
							Processing_State__c = IntegrationUtils.PROCESSED_STATE,
							Message__c = ZPProductLineUtil.SUCCESS_MESSAGE,
							Last_Processed__c = System.now()
						)
					);
				}
			}
		}
		// Skipping the trigger so that avoid racing condition and unnecessary trigger execution
		ZPProductLineTriggerHelper.skipTrigger = true;
		Database.update(list_ZPProductLinesToUpdate, false);
		ZPProductLineTriggerHelper.skipTrigger = false;
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : This method is being used to validate current ZP product line records also its validatating against accounts and ZP Companies.
	 * @param       : List of ZP product lines to validate and process further.
	 * @param       : Map of old ZP product lines
	 * @return      : N/A
	 **/
	public void processProductLineRecords(List<ZP_Product_Line__c> list_ZPProductLine, Map<Id, ZP_Product_Line__c> map_OldZPProductLine) {
		//set of base product Ids to check if add-ons are having their corresponding base ZP prod lines.
		Set<String> set_BaseProductIds = new Set<String>();
		// Map of Prod Id to payment plans. This map is being used to check if current ZP Products are having their payment plan exists.
		Map<String, PriceBook2> map_ProdPricingIdToPaymentPlan = new Map<String, PriceBook2>();
		Map<String, PriceBook2> map_PaymentPlanNameToPaymentPlan = new Map<String, PriceBook2>();
		// Map of Prod Id to Price Book entries . This map is being used to check if current ZP Products are having their payment plan exists.
		Map<String, PriceBookEntry> map_ProdPricingIdToPBE = new Map<String, PriceBookEntry>();
		Map<String, PriceBookEntry> map_PBENameToPBE = new Map<String, PriceBookEntry>();

		//iterating over the all ZP Prod Lines
		for (ZP_Product_Line__c objProductLine : list_ZPProductLine) {
			// if dead state then we are not considering records for the further processing.
			if (IntegrationUtils.DEAD_STATE.equalsIgnoreCase(objProductLine.Processing_State__c)) {
				continue;
			}

			// If Company Id is blank then its not a valid record. We will move into error state.
			if (String.isBlank(objProductLine.Company_Id__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_COMPANY_ID_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// If Type is blank then its not a valid record. We will move into error state.
			if (String.isBlank(objProductLine.Type__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_TYPE_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// If Type is add-on and Parent Id is balnk then we will not proceding further with record as no add-ons can be have without base product.
			if (ZPProductLineUtil.TYPE_ADD_ON.equalsIgnoreCase(objProductLine.Type__c) && String.isBlank(objProductLine.Parent_ID__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_PARENT_ID_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// If Pricing Plan Id is blank then its not a valid record. We will move into error state.
			if (String.isBlank(objProductLine.Pricing_Plan_ID__c)) {
				//stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_PRICING_PLAN_ID_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				//continue;
			}

			// If Product Line Id is blank then its not a valid record. We will move into error state.
			if (String.isBlank(objProductLine.Product_Line_ID__c)) {
				//stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_PRODUCT_LINE_ID_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				//continue;
			}

			// If Start date is null then its not a valid record. We will move into error state.
			if (objProductLine.Start_Date__c == null) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_START_DATE_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// If Status is blank then its not a valid record. We will move into error state.
			if (String.isBlank(objProductLine.Status__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_STATUS_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// If Status is deleted then we will move into deleted state.
			if (ZPProductLineUtil.STATUS_DELETED.equalsIgnoreCase(objProductLine.Status__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.PROCESSED_STATE, ZPProductLineUtil.PRODUCT_DEACTIVATED_MESSAGE);
				objProductLine.Last_Processed__c = System.now();
			}

			// Moving ZP Product Lines to backlog state if start date in future and our batch job will be picking it. And we will be reprocessing once date is current.
			if (objProductLine.Start_Date__c > System.now() && !ZPProductLineUtil.STATUS_DELETED.equalsIgnoreCase(objProductLine.Status__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.BACKLOG, ZPProductLineUtil.ERR_MSG_FUTURE_START_DATE);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// colecting all base ids to check of add-ons
			if (objProductLine.Type__c.containsIgnoreCase(ZPProductLineUtil.TYPE_BASE) && String.isNotBlank(objProductLine.Company_Base_ID__c)) {
				set_BaseProductIds.add(objProductLine.Company_Base_ID__c);
			}

			// set processing state to Queued
			objProductLine.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			objProductLine.Message__c = '';

			set_CompanyIds.add(objProductLine.Company_Id__c);
		}

		// building a map of company Id and most recent effective base product line record
		List<ZP_Product_Line__c> list_ExistingZPProductLines = ZPProductLineUtil.queryZPProductLine(set_CompanyIds);
		for (ZP_Product_Line__c objProductLine : list_ExistingZPProductLines) {
			if (objProductLine.Type__c.containsIgnoreCase(ZPProductLineUtil.TYPE_BASE) && String.isNotBlank(objProductLine.Company_Base_ID__c)) {
				set_BaseProductIds.add(objProductLine.Company_Base_ID__c);
			}
		}

		if (!set_CompanyIds.isEmpty()) {
			//fetching accounts
			List<Account> list_ExistingAccountsBasedOnCompanyIds = [
				SELECT ZP_Company_Id__c, Tier__c, Current_Tier_Start_Date__c, Pricing__c, Additional_Services__c, Priority_Support__c
				FROM Account
				WHERE ZP_Company_Id__c IN :set_CompanyIds
			];
			for (Account objAccount : list_ExistingAccountsBasedOnCompanyIds) {
				map_CompanyIdToAccount.put(objAccount.ZP_Company_Id__c, objAccount);
			}
			// fetching ZP Companies
			map_IdToZPCompany = ZPProductLineUtil.queryZPCompany(set_CompanyIds);
		}

		List<PriceBook2> list_AllPaymentPlans = ZPProductLineUtil.queryPaymentPlans();
		for (PriceBook2 objPaymentPlan : list_AllPaymentPlans) {
			// populating payment plan map based on company Ids to assign tier and price value
			
			if (objPaymentPlan.Product_Line_ID__c == null || objPaymentPlan.Pricing_Plan_ID__c == null) {
				map_PaymentPlanNameToPaymentPlan.put(objPaymentPlan.Name, objPaymentPlan);
			} else {
				map_ProdPricingIdToPaymentPlan.put(objPaymentPlan.Product_Line_ID__c + '#' + objPaymentPlan.Pricing_Plan_ID__c, objPaymentPlan);
			}

			// populating pricebook entries map based on company Ids to assign additional services values
			for (PriceBookEntry objPriceBookEntry : objPaymentPlan.PriceBookEntries) {
				if (objPriceBookEntry.Product2.Product_Line_ID__c == null || objPriceBookEntry.Product2.Pricing_Plan_ID__c == null) {
					map_PBENameToPBE.put(objPriceBookEntry.Product2.ExternalId, objPriceBookEntry);
				} else {
					map_ProdPricingIdToPBE.put(objPriceBookEntry.Product2.Product_Line_ID__c + '#' + objPriceBookEntry.Product2.Pricing_Plan_ID__c, objPriceBookEntry);
				}
			}
		}

		// Iterating over the ZP Product lines again for the dynamic validation such as for Accounts, Payment Plans
		for (ZP_Product_Line__c objProductLine : list_ZPProductLine) {
			// If not in Queued state then this is not to proceed further. As we have already setup the queued state after successfull validation.
			if (!IntegrationUtils.QUEUED_STATE.equalsIgnoreCase(objProductLine.Processing_State__c)) {
				continue;
			}

			// If Company is dead then we are not considering for the Tier updates.
			if (map_IdToZPCompany?.containsKey(objProductLine.Company_Id__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.DEAD_STATE, ZPProductLineUtil.ERR_MSG_ZP_COMPANY_DEAD);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// Adding error in case Account doesn't exits for the this ZP Product Line record.
			if (!map_CompanyIdToAccount?.containsKey(objProductLine.Company_Id__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_COMPANY_ID_DOES_NOT_EXIST);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// Setting the error state if add-on doesn't have the base product.
			if (ZPProductLineUtil.TYPE_ADD_ON.equalsIgnoreCase(objProductLine.Type__c) && !set_BaseProductIds.contains(objProductLine.Parent_ID__c)) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_BASE_PRODUCT);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}

			// adding error for add-on ZP prod lines if corresponding PBE doesn't exist.
			if (
				ZPProductLineUtil.TYPE_ADD_ON.equalsIgnoreCase(objProductLine.Type__c) &&
				!map_ProdPricingIdToPBE.containsKey(objProductLine.Product_Line_ID__c + '#' + objProductLine.Pricing_Plan_ID__c)
			) {
				//stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_PRODUCT_ERROR);
				//objProductLine.Last_Processed__c = System.now();
				//continue;
			}

			// adding error for base ZP prod lines if corresponding Payment plan doesn't exist.
			if (
				objProductLine.Type__c.containsIgnoreCase(ZPProductLineUtil.TYPE_BASE) &&
				!map_ProdPricingIdToPaymentPlan.containsKey(objProductLine.Product_Line_ID__c + '#' + objProductLine.Pricing_Plan_ID__c) &&
				!map_PBENameToPBE.containsKey(objProductLine.Product_Name__c)
			) {
				stampProcessingStatusAndMessage(objProductLine, IntegrationUtils.ERROR_STATE, ZPProductLineUtil.ERR_MSG_PRODUCT_ERROR);
				objProductLine.Last_Processed__c = System.now();
				continue;
			}
			set_CompanyIdsForAccProcessing.add(objProductLine.Company_Id__c);
		}
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : This method is being used to prepare the final ZP Product lines list for the account updates.
	 * @param       : List of ZP Product line to update the Accounts.
	 * @return      : N/A
	 **/

	public void processTierAndPricingChanges(List<ZP_Product_Line__c> list_ZPProductLine) {
		List<ZP_Product_Line__c> list_ZPProdLinesForAccountUpdate = new List<ZP_Product_Line__c>();

		for (ZP_Product_Line__c objProductLine : list_ZPProductLine) {
			if (set_CompanyIdsForAccProcessing.contains(objProductLine.Company_Id__c)) {
				list_ZPProdLinesForAccountUpdate.add(objProductLine);
			}
		}

		if (!list_ZPProdLinesForAccountUpdate.isEmpty()) {
			// updating account's tier , pricing , and addional services
			udpateAccountFields(list_ZPProdLinesForAccountUpdate);
		}
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : This method updating Account's Tier , Pricing and Additional Services based on ZP Product line records.
	 * @param       : Final list of ZP Product line to update the Accounts
	 * @return      : N/A
	 **/
	public void udpateAccountFields(List<ZP_Product_Line__c> list_ZPProdLinesForAccountUpdate) {
		// This map will have the value of account records for update.
		Map<Id, Account> map_AccountsToUpdate = new Map<Id, Account>();
		// Map to contain the value of Payment Plan so that we can update tier and pricing on account.
		Map<String, PriceBook2> map_ProdPricingIdToPaymentPlan = new Map<String, PriceBook2>();
		Map<String, PriceBook2> map_PaymentPlanNameToPaymentPlan = new Map<String, PriceBook2>();
		// Map to contain the value of Payment Plan so that we can update Additional Services on account.
		Map<String, PriceBookEntry> map_ProdPricingIdToPBE = new Map<String, PriceBookEntry>();
		Map<String, PriceBookEntry> map_PBENameToPBE = new Map<String, PriceBookEntry>();
		// This map is used to determine/populate correct list of add-ons against the base product.
		Map<String, ZP_Product_Line__c> map_CompanyIdToBaseProdLine = new Map<String, ZP_Product_Line__c>();
		// having the values of add-on products related company Id and being used to determine all active add-ons for the account.
		Map<String, List<ZP_Product_Line__c>> map_CompanyIdToAddonProdLines = new Map<String, List<ZP_Product_Line__c>>();
		Set<String> set_CompanyIdsToProcess = new Set<String>();
		// Key to populate coorect add-ons and base product mapping. Because one company Id can have multiple active base.
		Set<String> set_RecentAddonLineKey = new Set<String>();

		//Map to company Id and Time Kiosk Quantity
		Map<String, String> map_CompanyIdAndTimeKioskQauntity = new Map<String, String>();

		for (ZP_Product_Line__c objProductLine : list_ZPProdLinesForAccountUpdate) {
			set_CompanyIdsToProcess.add(objProductLine.Company_Id__c);
		}

		// querying ZP Proudct line based on company Ids
		List<ZP_Product_Line__c> list_ZPProductLineRecords = ZPProductLineUtil.queryZPProductLine(set_CompanyIdsToProcess);

		// building a map of company Id and most recent effective base product line record
		for (ZP_Product_Line__c objProductLine : list_ZPProductLineRecords) {
			// taking most recent base products which are having active status and start date is not in future.
			if (
				(ZPProductLineUtil.STATUS_ACTIVE.equalsIgnoreCase(objProductLine.Status__c) && objProductLine.Start_Date__c <= System.Now()) ||
				(ZPProductLineUtil.STATUS_INACTIVE.equalsIgnoreCase(objProductLine.Status__c) && objProductLine.Start_Date__c > System.Now())
			) {
				if (
					String.isBlank(objProductLine.Parent_ID__c) &&
					!map_CompanyIdToBaseProdLine.containsKey(objProductLine.Company_Id__c) &&
					objProductLine.Type__c.containsIgnoreCase(ZPProductLineUtil.TYPE_BASE)
				) {
					map_CompanyIdToBaseProdLine.put(objProductLine.Company_Id__c, objProductLine);
				}
			}
		}

		// building a map of company Id & list of their add-on product lines based on latest base product line
		for (ZP_Product_Line__c objProductLine : list_ZPProductLineRecords) {
			if (String.isNotBlank(objProductLine.Parent_ID__c) && ZPProductLineUtil.TYPE_ADD_ON.equalsIgnoreCase(objProductLine.Type__c)) {
				// populating Price b map based on company Ids to assign tier and price value
				if (objProductLine.Start_Date__c <= System.Now()) {
					if (map_CompanyIdToBaseProdLine.containsKey(objProductLine.Company_Id__c)) {
						ZP_Product_Line__c objLatestBaseProductLine = map_CompanyIdToBaseProdLine.get(objProductLine.Company_Id__c);
						// compare company base Id from base product line and parent Id from add-on product line
						String strKeyToCheck = objProductLine.Parent_ID__c + '#' + objProductLine.Product_Line_ID__c + '#' + objProductLine.Pricing_Plan_ID__c;
						// making sure each add-ons must be mapped to correct base products via company ids
						if (objLatestBaseProductLine.Company_Base_Id__c == objProductLine.Parent_ID__c && !set_RecentAddonLineKey.contains(strKeyToCheck)) {
							List<ZP_Product_Line__c> tempList = map_CompanyIdToAddonProdLines.get(objProductLine.Company_Id__c);
							if (tempList == null) {
								tempList = new List<ZP_Product_Line__c>();
							}
							tempList.add(objProductLine);
							map_CompanyIdToAddonProdLines.put(objProductLine.Company_Id__c, tempList);
							set_RecentAddonLineKey.add(strKeyToCheck);
						}
					}
				}
			}
		}

		for (PriceBook2 objPaymentPlan : ZPProductLineUtil.queryPaymentPlans()) {
			Map<String, PriceBookEntry> map_Temp = new Map<String, PriceBookEntry>();
			// populating payment plan map based on company Ids to assign tier and price value
			if (objPaymentPlan.Product_Line_ID__c == null || objPaymentPlan.Pricing_Plan_ID__c == null) {
				map_PaymentPlanNameToPaymentPlan.put(objPaymentPlan.Name, objPaymentPlan);
			} else {
				map_ProdPricingIdToPaymentPlan.put(objPaymentPlan.Product_Line_ID__c + '#' + objPaymentPlan.Pricing_Plan_ID__c, objPaymentPlan);
			}
			// populating pricebook entries map based on company Ids to assign additional services values
			for (PriceBookEntry objPriceBookEntry : objPaymentPlan.PriceBookEntries) {
				if (objPriceBookEntry.Product2.Product_Line_ID__c == null || objPriceBookEntry.Product2.Pricing_Plan_ID__c == null) {
					map_PBENameToPBE.put(objPriceBookEntry.Product2.ExternalId, objPriceBookEntry);
				} else {
					map_ProdPricingIdToPBE.put(objPriceBookEntry.Product2.Product_Line_ID__c + '#' + objPriceBookEntry.Product2.Pricing_Plan_ID__c, objPriceBookEntry);
				}
				map_Temp.put(objPriceBookEntry.Product2.Product_Type__c, objPriceBookEntry);
			}

			map_PBIdToMapOfProdNameToPBE.put(objPaymentPlan.Id, map_Temp);
		}

		for (String strCompanyId : set_CompanyIdsToProcess) {
			boolean blnAccountToUpdate = false;
			if (map_CompanyIdToAccount.containsKey(strCompanyId)) {
				Account objAccToUpdate = map_CompanyIdToAccount.get(strCompanyId);

				// updating Tier and Pricing on the Account
				if (map_CompanyIdToBaseProdLine.containsKey(strCompanyId)) {
					ZP_Product_Line__c objBaseProductLine = map_CompanyIdToBaseProdLine.get(strCompanyId);
					// updating tier and pricing values
					if (map_ProdPricingIdToPaymentPlan.containsKey(objBaseProductLine.Product_Line_ID__c + '#' + objBaseProductLine.Pricing_Plan_ID__c)) {
						PriceBook2 paymentPlanRecord = map_ProdPricingIdToPaymentPlan.get(objBaseProductLine.Product_Line_ID__c + '#' + objBaseProductLine.Pricing_Plan_ID__c);
						// checking if account doesn't have the same Tier value
						if (objAccToUpdate.Tier__c != paymentPlanRecord.Product_Tier__c) {
							objAccToUpdate.Tier__c = paymentPlanRecord.Product_Tier__c;
							objBaseProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
							objBaseProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
							map_IDToProdLinesWithFinalMessage.put(objBaseProductLine.Id, objBaseProductLine);
							blnAccountToUpdate = true;
						}

						// checking if account doesn't have the same Pricing value
						if (objAccToUpdate.Pricing__c != paymentPlanRecord.Name) {
							objAccToUpdate.Pricing__c = paymentPlanRecord.Name;

							objBaseProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
							objBaseProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
							map_IDToProdLinesWithFinalMessage.put(objBaseProductLine.Id, objBaseProductLine);
							blnAccountToUpdate = true;
						}

						if (objAccToUpdate.Current_Tier_Start_Date__c != objBaseProductLine.Start_Date__c) {
							objAccToUpdate.Current_Tier_Start_Date__c = objBaseProductLine.Start_Date__c;
							blnAccountToUpdate = true;
						}
					}

					if (map_PBENameToPBE.containsKey(objBaseProductLine.Product_Name__c)) {
						PriceBookEntry objPriceBookEntry = map_PBENameToPBE.get(objBaseProductLine.Product_Name__c);
						
						if (objAccToUpdate.Tier__c != objPriceBookEntry.Product2.Name) {
							objAccToUpdate.Tier__c = objPriceBookEntry.Product2.Name;
							objBaseProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
							objBaseProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
							map_IDToProdLinesWithFinalMessage.put(objBaseProductLine.Id, objBaseProductLine);
							blnAccountToUpdate = true;
						}

						// checking if account doesn't have the same Pricing value
						if (objAccToUpdate.Pricing__c != objPriceBookEntry.PriceBook2.Name) {
							objAccToUpdate.Pricing__c = objPriceBookEntry.PriceBook2.Name;

							objBaseProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
							objBaseProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
							map_IDToProdLinesWithFinalMessage.put(objBaseProductLine.Id, objBaseProductLine);
							blnAccountToUpdate = true;
						}

						if (objAccToUpdate.Current_Tier_Start_Date__c != objBaseProductLine.Start_Date__c) {
							objAccToUpdate.Current_Tier_Start_Date__c = objBaseProductLine.Start_Date__c;
							blnAccountToUpdate = true;
						}
					}
				}

				// updating Additional Services and Priority Support checkbox on the Account
				if (map_CompanyIdToAddonProdLines.containsKey(strCompanyId)) {
					List<String> list_AdditionalServices = new List<String>();
					// updating additional services
					for (ZP_Product_Line__c objAddOnProductLine : map_CompanyIdToAddonProdLines.get(strCompanyId)) {
						// if add-on is active
						if (ZPProductLineUtil.STATUS_ACTIVE.equalsIgnoreCase(objAddOnProductLine.Status__c)) {
							if (map_ProdPricingIdToPBE.containsKey(objAddOnProductLine.Product_Line_ID__c + '#' + objAddOnProductLine.Pricing_Plan_ID__c)) {
								PriceBookEntry objPriceBookEntry = map_ProdPricingIdToPBE.get(objAddOnProductLine.Product_Line_ID__c + '#' + objAddOnProductLine.Pricing_Plan_ID__c);
								list_AdditionalServices.add(objPriceBookEntry.Product2.Product_Category__c);
								objAddOnProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
								objAddOnProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
								map_IDToProdLinesWithFinalMessage.put(objAddOnProductLine.Id, objAddOnProductLine);
							}

							if (map_PBENameToPBE.containsKey(objAddOnProductLine.Product_Name__c)) {
								PriceBookEntry objPriceBookEntry = map_PBENameToPBE.get(objAddOnProductLine.Product_Name__c);
								System.debug('objAddOnProductLine.Product_Name__c:' + objAddOnProductLine.Product_Name__c);
								String strAddOn = ZPProductLineUtil.map_ExternalIdAndProductName.get(objAddOnProductLine.Product_Name__c);
								System.debug('strAddOn:' + strAddOn);
								if (strAddOn == null) {
									strAddOn = objAddOnProductLine.Product_Name__c;
								}
								list_AdditionalServices.add(strAddOn);
								objAddOnProductLine.Processing_State__c = IntegrationUtils.PROCESSED_STATE;
								objAddOnProductLine.Message__c = ZPProductLineUtil.SUCCESS_MESSAGE;
								map_IDToProdLinesWithFinalMessage.put(objAddOnProductLine.Id, objAddOnProductLine);

							}
							if (String.isNotBlank(objAddOnProductLine.Assigned_Quantity__c)) {
								map_CompanyIdAndTimeKioskQauntity.put(strCompanyId, objAddOnProductLine.Assigned_Quantity__c);
							}
						}
					}
					System.debug('list_AdditionalServices1211:' + list_AdditionalServices);
					String strAdditionalServices = !list_AdditionalServices.isEmpty() ? String.join(list_AdditionalServices, ';') : '';

					// checking if account doesn't have the same Additional Services values
					if (objAccToUpdate.Additional_Services__c != strAdditionalServices) {
						objAccToUpdate.Additional_Services__c = strAdditionalServices;
						blnAccountToUpdate = true;
					}
					// marking priority support checkbox value.
					Boolean blnPrioritySupport = String.isNotBlank(strAdditionalServices) && strAdditionalServices.containsIgnoreCase(ZPProductLineUtil.ADD_SERVICES_PRIORITY_SUPPORT);
					if (objAccToUpdate.Priority_Support__c != blnPrioritySupport) {
						objAccToUpdate.Priority_Support__c = blnPrioritySupport;
						blnAccountToUpdate = true;
					}
				} else {
					// if add-on doesn't exist and additional services is blank. then clearing the current addional services values. this scenario would be possible when customer remving all add-ons.
					if (String.isNotBlank(objAccToUpdate.Additional_Services__c)) {
						objAccToUpdate.Additional_Services__c = '';
						blnAccountToUpdate = true;
					}

					// if no add-on then marking priority support to false.
					if (objAccToUpdate.Priority_Support__c) {
						objAccToUpdate.Priority_Support__c = false;
						blnAccountToUpdate = true;
					}
				}

				// checking if current company is eligible for update
				if (blnAccountToUpdate) {
					map_AccountsToUpdate.put(objAccToUpdate.Id, objAccToUpdate);
				}
			}
		}
		System.debug('map_AccountsToUpdate:' + map_AccountsToUpdate);
		// Finally updating the accounts.
		if (!map_AccountsToUpdate.isEmpty()) {
			List<Database.SaveResult> list_AccSaveResults = Database.update(map_AccountsToUpdate.values(), false);
			map_CompanyIdToAccountDMLErrors = Utils.processSaveResult(list_AccSaveResults, map_AccountsToUpdate.values(), 'ZP_Company_ID__c', true, 'processBeforeInsert');
		}
		//createTimeKioskOpportunityLineItem(map_CompanyIdAndTimeKioskQauntity);
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : Creating Time Kiosk OLIs based on assigned quantity data passed in Product line.
	 * @param       : CompanyId with assigned quantity values
	 * @return      : N/A
	 **/
	public void createTimeKioskOpportunityLineItem(Map<String, String> map_CompanyIdAndTimeKioskQauntity) {
		System.debug('map_CompanyIdAndTimeKioskQauntity:' + map_CompanyIdAndTimeKioskQauntity);
		// Map to store JSON data for each Company ID
		Map<String, List<AssignedQuantityItem>> map_CompanyIdToTimeKioskQuantity = new Map<String, List<AssignedQuantityItem>>();
		// Map to store Opportunities by Company ID
		Map<String, Opportunity> map_CompanyIdToOpportunity = new Map<String, Opportunity>();
		// Create Opportunity Line Items based on the JSON data
		List<OpportunityLineItem> list_OLIForUpsert = new List<OpportunityLineItem>();
		Map<String, String> map_ProductTypeAndLineItem = new Map<String, String>();
		// Check if JSON data is provided
		if (map_CompanyIdAndTimeKioskQauntity != null) {
			// Deserialize the JSON into a list of records
			for (String strCompanyId : map_CompanyIdAndTimeKioskQauntity.keySet()) {
				//List<Map<String, Object>> list_assignedQty = (List<Map<String, Object>>) JSON.deserializeUntyped(map_CompanyIdAndTimeKioskQauntity.get(strCompanyId));

				// Deserialize the JSON string into an instance of the wrapper class
				AssignedQuantityWrapper wrapper = (AssignedQuantityWrapper) JSON.deserialize(map_CompanyIdAndTimeKioskQauntity.get(strCompanyId), AssignedQuantityWrapper.class);
				// Access the parsed data
				List<AssignedQuantityItem> assignedQtyList = wrapper.assigned_qty;

				map_CompanyIdToTimeKioskQuantity.put(strCompanyId, assignedQtyList);
			}
		}
		// Query Opportunities based on Company IDs and store them
		for (Opportunity objOpportunity : ZPProductLineUtil.queryOpportunity(map_CompanyIdAndTimeKioskQauntity.keySet())) {
			map_CompanyIdToOpportunity.put(objOpportunity.ZP_Company_ID_from_Account__c, objOpportunity);

			for (OpportunityLineItem objOLI : objOpportunity.opportunityLineItems) {
				map_ProductTypeAndLineItem.put(objOLI.Product2.Product_Type__c, objOLI.Id);
			}
		}

		// Iterate through Company IDs and associated JSON data
		for (String strCompanyId : map_CompanyIdAndTimeKioskQauntity.keySet()) {
			Opportunity objOpportunity = map_CompanyIdToOpportunity.get(strCompanyId);
			for (AssignedQuantityItem item : map_CompanyIdToTimeKioskQuantity.get(strCompanyId)) {
				// Extract product type and quantity from the JSON data
				String strProductType = item.name;
				Decimal quantity = Decimal.valueOf(item.quantity);

				// Retrieve the PriceBookEntry for the product type
				PriceBookEntry objPBE = map_PBIdToMapOfProdNameToPBE.get(objOpportunity.Pricebook2Id).get(strProductType);

				// Create Opportunity Line Item
				if (quantity > 0) {
					OpportunityLineItem oli = new OpportunityLineItem();
					oli.OpportunityId = objOpportunity.Id;
					oli.PricebookEntryId = objPBE.Id;
					oli.Quantity = quantity;
					oli.UnitPrice = objPBE.UnitPrice;

					if (map_ProductTypeAndLineItem.containsKey(strProductType)) {
						oli.Id = map_ProductTypeAndLineItem.get(strProductType);
					}
					list_OLIForUpsert.add(oli);
				}
			}
		}

		// Insert the Opportunity Line Items
		upsert list_OLIForUpsert;
	}

	/**
	 * @author      : Anurag Gautam
	 * @description : This method is setting error messages and product line's processing status.
	 * @param       : Current ZP Product Line record, Processing State for the same record, and error message.
	 * @return      : N/A
	 **/
	public void stampProcessingStatusAndMessage(ZP_Product_Line__c productLineRecord, String strProcessingState, String strMessage) {
		productLineRecord.Processing_State__c = strProcessingState;
		productLineRecord.Last_Processed__c = System.now();
		productLineRecord.Message__c = strMessage;
	}

	class AssignedQuantityWrapper {
		public List<AssignedQuantityItem> assigned_qty { get; set; }
	}

	class AssignedQuantityItem {
		public String name { get; set; }
		public String quantity { get; set; }
	}
}