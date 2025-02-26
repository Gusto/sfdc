public class OpportunityHelper {
	public final static Id ACQUISITION_OPPTY_RT_ID = Cache.getRecordTypeId('Opportunity', 'Acquisition');
	public static Map<String, Opportunity_Config__mdt> map_OpportunityConfigData;
	public static Map<String, List<PriceBookEntry>> map_PaymentPlanNameAndPriceBookEntry = new Map<String, List<PriceBookEntry>>();
	public static Map<String, Pricebook2> map_NameAndPaymentPlan = new Map<String, Pricebook2>();
	public static Map<String, Map<String, OpportunityLineItem>> map_IDANDOpportunityLineItems = new Map<String, Map<String, OpportunityLineItem>>();
	public static boolean blnLineItemUpdated = false;

	public final static Map<String, String> map_ProductNameAndExternalId = new Map<String, String>{
		'Legacy Premium' => 'premium',
		'Premium' => 'premium_v2',
		'Premium CRB' => 'premium_crb',
		'Premium Multi-EIN' => 'premium_multi_ein',
		'Simple' => 'simple',
		'Plus' => 'plus',
		'contractor_only' => 'contractor_only',
		'Advanced Time-Off' => 'Advanced time-off',
		'HR Services' => 'HR services',
		'Advanced Time-Off Premium' => 'Advanced time-off premium',
		'Next-Day Direct Deposit' => 'Next-day direct deposit',
		'Performance And Engagement' => 'Performance & engagement',
		'Priority Support' => 'Priority support',
		'Priority Support and HR Services' => 'Priority Support and HR Services',
		'Time And Project Tracking' => 'Time and project tracking',
		'Wholesale' => 'wholesale',
		'Core' => 'core',
		'Complete' => 'complete',
		'Core (S-Corp)' => 'core_s_corp',
		'GustoHR Pro' => 'GustoHRPro'
	};

	public static Set<String> excludedFields = new Set<String>();
  
	public OpportunityHelper() {
		//createCollections();
	}
	public static void createCollections() {
		map_OpportunityConfigData = new Map<String, Opportunity_Config__mdt>();
		// Iterate through the metadata records and populate the map
		for (Opportunity_Config__mdt opportunityConfig : Opportunity_Config__mdt.getAll().values()) {
			if (opportunityConfig.Record_Type_Name__c != null) {
				if (opportunityConfig.Opportunity_Type__c != null) {
					map_OpportunityConfigData.put(opportunityConfig.Record_Type_Name__c + '-' + opportunityConfig.Opportunity_Type__c, opportunityConfig);
				} else {
					map_OpportunityConfigData.put(opportunityConfig.Record_Type_Name__c, opportunityConfig);
				}
			}
		}
		getAllPricebookData();
	}

	public static void createUpdateAcquisitionOpportunity(List<Account> list_NewAccounts, Map<Id, Account> map_OldAccounts, Map<Id, List<Opportunity>> map_AccountIdANDOpportunities) {
		System.debug('list_NewAccounts: ' + list_NewAccounts);
		Set<String> set_CompanyIds = new Set<String>();
		List<Opportunity> list_AcquisitionOpportunitiesToInsert = new List<Opportunity>();
		List<Opportunity> list_AcquisitionOpportunitiesToUpdate = new List<Opportunity>();
		PriceBook2 objPriceBook = new PriceBook2();
		Opportunity objOppToInsert = new Opportunity();
		for (Account objAcc : list_NewAccounts) {
			System.debug('objAcc.ZP_Company_ID__c: ' + objAcc.ZP_Company_ID__c);
			System.debug('objAcc.id: ' + objAcc.id);
			if (String.isNotBlank(objAcc.ZP_Company_ID__c)) {
				set_CompanyIds.add(objAcc.ZP_Company_ID__c);
			}
		}

		System.debug('set_CompanyIds: ' + set_CompanyIds);
		System.debug('ACQUISITION_OPPTY_RT_ID: ' + ACQUISITION_OPPTY_RT_ID);

		createCollections();
		System.debug('map_OpportunityConfigData: ' + map_OpportunityConfigData);
		System.debug('map_PaymentPlanNameAndPriceBookEntry: ' + map_PaymentPlanNameAndPriceBookEntry);
		System.debug('map_NameAndPaymentPlan: ' + map_NameAndPaymentPlan);

		for (String opportunityConfigName : map_OpportunityConfigData.keySet()) {
			if (opportunityConfigName.contains('Acquisition')) {
				Opportunity_Config__mdt objOpportunityConfig = map_OpportunityConfigData.get(opportunityConfigName);
				System.debug('objOpportunityConfig: ' + objOpportunityConfig);
				if (objOpportunityConfig != null && String.isNotBlank(objOpportunityConfig.Payment_Plan_Name__c)) {
					objPriceBook = map_NameAndPaymentPlan.get(objOpportunityConfig.Payment_Plan_Name__c);
					System.debug('objPriceBook: ' + objPriceBook);
					break;
				}
			}
		}

		/**Map<Id, List<Opportunity>> map_AccountIdANDOpportunities = new Map<Id, List<Opportunity>>();
		for (Opportunity objOpportunity : [
			SELECT ID, AccountId, StageName, Type, Additional_Opportunity_Services__c, Current_Tier__c, Number_of_Contractors__c, NumberOfEmployees__c
			FROM Opportunity
			WHERE RecordTypeId = :ACQUISITION_OPPTY_RT_ID AND Account.ZP_Company_ID__c IN :set_CompanyIds
		]) {
			if (!map_AccountIdANDOpportunities.containsKey(objOpportunity.AccountId)) {
				map_AccountIdANDOpportunities.put(objOpportunity.AccountId, new List<Opportunity>());
			}
			map_AccountIdANDOpportunities.get(objOpportunity.AccountId).add(objOpportunity);
		} **/

		System.debug('map_AccountIdANDOpportunities: ' + map_AccountIdANDOpportunities);
		for (Account objAccount : list_NewAccounts) {
			List<Opportunity> list_RelatedOpps = map_AccountIdANDOpportunities.get(objAccount.Id);
			System.debug('list_RelatedOpps: ' + list_RelatedOpps);
			if (list_RelatedOpps == null || list_RelatedOpps.isEmpty()) {
				list_AcquisitionOpportunitiesToInsert.add(mapOpportunityFields(objAccount, objPriceBook, null, objOppToInsert));
			} else {
				Boolean blnClosedLostNewBiz = false;
				Boolean blnClosedLostWinback = false;
				Boolean blnClosedWonNewBiz = false;
				Boolean blnClosedWonWinback = false;
				Boolean blnOpenNewBiz = false;
				Boolean blnOpenWinback = false;
				Opportunity objExistingNewBizOpportunity = null;
				Opportunity objExistingWinbackOpportunity = null;

				for (Opportunity objOpp : list_RelatedOpps) {
					System.debug('objOpp.StageName: ' + objOpp.StageName);
					System.debug('objOpp.Type: ' + objOpp.Type);
					if (objOpp.StageName == 'Closed Won' && objOpp.Type == 'New Business') {
						blnClosedWonNewBiz = true;
						objExistingNewBizOpportunity = objOpp;
					} else if (objOpp.StageName == 'Closed Won' && objOpp.Type == 'Winback') {
						blnClosedWonWinback = true;
						objExistingWinbackOpportunity = objOpp;
					} else if (objOpp.StageName == 'Closed Lost' && objOpp.Type == 'New Business') {
						blnClosedLostNewBiz = true;
						objExistingNewBizOpportunity = objOpp;
					} else if (objOpp.StageName == 'Closed Lost' && objOpp.Type == 'Winback') {
						blnClosedLostWinback = true;
						objExistingWinbackOpportunity = objOpp;
					} 

					if (objOpp.StageName != 'Closed Lost' && objOpp.StageName != 'Closed Won' && objOpp.Type == 'New Business') {
						blnOpenNewBiz = true;
						objExistingNewBizOpportunity = objOpp;
					} else if (objOpp.StageName != 'Closed Lost' && objOpp.StageName != 'Closed Won' && objOpp.Type == 'Winback') {
						blnOpenWinback = true;
						objExistingWinbackOpportunity = objOpp;
					}
				}

				System.debug('blnClosedLostNewBiz: ' + blnClosedLostNewBiz);
				System.debug('blnClosedLostWinback: ' + blnClosedLostWinback);
				System.debug('blnClosedWonNewBiz: ' + blnClosedWonNewBiz);
				System.debug('blnClosedWonWinback: ' + blnClosedWonWinback);
				System.debug('objExistingNewBizOpportunity: ' + objExistingNewBizOpportunity);
				System.debug('objExistingWinbackOpportunity: ' + objExistingWinbackOpportunity);
				if (blnClosedLostNewBiz && !blnClosedWonNewBiz && !blnOpenNewBiz && !blnOpenWinback) {
					list_AcquisitionOpportunitiesToInsert.add(mapOpportunityFields(objAccount, objPriceBook, objExistingNewBizOpportunity, objOppToInsert));
				} else if (blnClosedLostWinback && !blnClosedWonWinback && blnClosedWonNewBiz && !blnOpenNewBiz && !blnOpenWinback) {
					list_AcquisitionOpportunitiesToInsert.add(mapOpportunityFields(objAccount, objPriceBook, objExistingWinbackOpportunity, objOppToInsert));
				} else if (blnOpenNewBiz) {
					//update existing new business opportunity
					if (map_OldAccounts != null && objExistingNewBizOpportunity != null) {
						list_AcquisitionOpportunitiesToUpdate.add(updateExistingOpportunity(objAccount, map_OldAccounts.get(objAccount.Id), objExistingNewBizOpportunity));
					}
				} else if (blnOpenWinback) {
					//update existing winback opportunity
					if (map_OldAccounts != null && objExistingWinbackOpportunity != null) {
						list_AcquisitionOpportunitiesToUpdate.add(updateExistingOpportunity(objAccount, map_OldAccounts.get(objAccount.Id), objExistingWinbackOpportunity));
					}
				}
			}
		}

		System.debug('list_AcquisitionOpportunitiesToInsert: ' + list_AcquisitionOpportunitiesToInsert);

		if (!list_AcquisitionOpportunitiesToInsert.isEmpty()) {
			blnLineItemUpdated = true;
			OpportunityTriggerHelper.skipTrigger = true;
			insert list_AcquisitionOpportunitiesToInsert;
			createOpportunityLineItems(list_AcquisitionOpportunitiesToInsert, list_NewAccounts);
			OpportunityTriggerHelper.skipTrigger = false;
		}
		System.debug('list_AcquisitionOpportunitiesToUpdate: ' + list_AcquisitionOpportunitiesToUpdate);
		if (!list_AcquisitionOpportunitiesToUpdate.isEmpty()) {
			blnLineItemUpdated = true;
			update list_AcquisitionOpportunitiesToUpdate;
			createOpportunityLineItems(list_AcquisitionOpportunitiesToUpdate, list_NewAccounts);
		}
	}

	public static Opportunity mapOpportunityFields(Account objAccount, PriceBook2 objPriceBook, Opportunity objExistingOpportunity, Opportunity objOppToInsert) {
		//Opportunity objOppToInsert = new Opportunity();
		System.debug('objAccount1111:' + objAccount);
		System.debug('objExistingOpportunity1211:' + objExistingOpportunity);
		if (objExistingOpportunity == null) {
			objOppToInsert.Name = objAccount.Name + ' - New Business';
			objOppToInsert.Source_Id__c = objAccount.ZP_Company_ID__c + '-newbusiness' + '-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year();
			objOppToInsert.Type = 'New Business';
		} else {
			objOppToInsert.Name = objAccount.Name + ' - Winback';
			objOppToInsert.Source_Id__c = objAccount.ZP_Company_ID__c + '-winback' + '-' + System.today().month() + '-' + System.today().day() + '-' + System.today().year();
			objOppToInsert.Type = 'Winback';
		}

		objOppToInsert.ZP_Company_ID__c = objAccount.ZP_Company_ID__c;
		objOppToInsert.AccountId = objAccount.Id;

		if (objOppToInsert.Type == 'New Business' && (objOppToInsert.StageName == null || objOppToInsert.StageName == 'New')) {
			objOppToInsert.StageName = 'Prospecting';
		} else if (objOppToInsert.Type == 'Winback' && (objOppToInsert.StageName == null || objOppToInsert.StageName == 'New')) {
			objOppToInsert.StageName = 'Prospecting';
		}
		//objOppToInsert.StageName = 'New';

		System.debug('objOppToInsert before update:' + objOppToInsert);
		System.debug('objAccount before update:' + objAccount);

		if (objOppToInsert.Type == 'New Business' && (objOppToInsert.CloseDate == null || (UserUtils.isIntgUser(UserInfo.getUserId()) && objAccount.Converted_Lead_Id__c != null))) {
			Integer intNoOfDays = Integer.valueOf(map_OpportunityConfigData.get('Acquisition-New Business').No_Of_Closed_Days__c);
			objOppToInsert.CloseDate = map_OpportunityConfigData.get('Acquisition-New Business').No_Of_Closed_Days__c != null ? Date.today().addDays(intNoOfDays) : Date.today().addDays(30);
		} else if (objOppToInsert.Type == 'Winback' && (objOppToInsert.CloseDate == null || objAccount.Converted_Lead_Id__c != null)) {
			//else if (objOppToInsert.Type == 'Winback' && (objOppToInsert.CloseDate == null || (objAccount.Converted_Lead_Id__c != null && UserUtils.isIntgUser(UserInfo.getUserId())))) {
			Integer intNoOfDays = Integer.valueOf(map_OpportunityConfigData.get('Acquisition-New Business').No_Of_Closed_Days__c);
			objOppToInsert.CloseDate = map_OpportunityConfigData.get('Acquisition-Winback').No_Of_Closed_Days__c != null ? Date.today().addDays(intNoOfDays) : Date.today().addDays(90);
		}

		System.debug('objOppToInsert after update:' + objOppToInsert);
		objOppToInsert.RecordTypeId = ACQUISITION_OPPTY_RT_ID;

		if (objAccount.Tier__c != null) {
			objOppToInsert.Current_Tier__c = objAccount.Tier__c;
		} else {
			objOppToInsert.Current_Tier__c = 'Simple';
		}

		if (objAccount.Number_of_Active_Employees__c != null && objAccount.Number_of_Active_Employees__c > 0) {
			objOppToInsert.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
		} else if (objAccount.NumberOfEmployees != null && objAccount.NumberOfEmployees > 0) {
			objOppToInsert.NumberOfEmployees__c = objAccount.NumberOfEmployees;
		} else if (objAccount.NumberOfEmployees_Lead__c != null && objAccount.NumberOfEmployees_Lead__c > 0) {
			objOppToInsert.NumberOfEmployees__c = objAccount.NumberOfEmployees_Lead__c;
		} else {
			objOppToInsert.NumberOfEmployees__c = 1;
		}

		//objOppToInsert.EE_Active_Count__c = objAcc.Number_of_Active_Employees__c;
		objOppToInsert.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
		objOppToInsert.International_Employees__c = objAccount.International_Employees__c;
		objOppToInsert.International_Contractors__c = objAccount.International_Contractors__c;
		if (objPriceBook != null) {
			objOppToInsert.PriceBook2Id = objPriceBook.Id;
		}
		System.debug('objOppToInsert after update:' + objOppToInsert);
		return objOppToInsert;
	}

	public static Opportunity updateExistingOpportunity(Account newAccount, Account oldAccount, Opportunity existingOpportunity) {
		existingOpportunity.NumberOfEmployees__c = 0;
		if (newAccount.Tier__c != oldAccount.Tier__c) {
			existingOpportunity.Current_Tier__c = newAccount.Tier__c;
		}

		if (newAccount.Additional_Services__c != oldAccount.Additional_Services__c) {
			existingOpportunity.Additional_Opportunity_Services__c = newAccount.Additional_Services__c;
		}

		System.debug('newAccount.Number_of_Active_Employees__c: ' + newAccount.Number_of_Active_Employees__c);
		System.debug('oldAccount.Number_of_Active_Employees__c: ' + oldAccount.Number_of_Active_Employees__c);
		System.debug('newAccount.NumberOfEmployees: ' + newAccount.NumberOfEmployees);
		System.debug('oldAccount.NumberOfEmployees: ' + oldAccount.NumberOfEmployees);
		System.debug('newAccount.NumberOfEmployees_Lead__c: ' + newAccount.NumberOfEmployees_Lead__c);
		System.debug('oldAccount.NumberOfEmployees_Lead__c: ' + oldAccount.NumberOfEmployees_Lead__c);
		if (newAccount.Number_of_Active_Employees__c != oldAccount.Number_of_Active_Employees__c) {
			existingOpportunity.NumberOfEmployees__c = newAccount.Number_of_Active_Employees__c;
		} else if (newAccount.NumberOfEmployees != oldAccount.NumberOfEmployees) {
			existingOpportunity.NumberOfEmployees__c = newAccount.NumberOfEmployees;
		} else if (newAccount.NumberOfEmployees_Lead__c != oldAccount.NumberOfEmployees_Lead__c) {
			existingOpportunity.NumberOfEmployees__c = newAccount.NumberOfEmployees_Lead__c;
		}

		if (newAccount.Number_of_Active_Contractors__c != oldAccount.Number_of_Active_Contractors__c) {
			existingOpportunity.Number_of_Contractors__c = newAccount.Number_of_Active_Contractors__c;
		}

		if (newAccount.International_Employees__c != oldAccount.International_Employees__c) {
			existingOpportunity.International_Employees__c = newAccount.International_Employees__c;
		}

		if (newAccount.International_Contractors__c != oldAccount.International_Contractors__c) {
			existingOpportunity.International_Contractors__c = newAccount.International_Contractors__c;
		}
		System.debug('existingOpportunity21111: ' + existingOpportunity);
		return existingOpportunity;
	}

	public static void createOpportunityLineItems(List<Opportunity> list_Opportunities, List<Account> list_Accounts) {
		String strPaymentPlanName = 'Payroll Product Catalog';
		Boolean blnContractorOnly = false;
		Set<String> set_AccountId = new Set<String>();
		Map<Id, Account> map_IdAndAccount = new Map<Id, Account>();
		Map<String, Account> mapZPCompanyIDAndAccount = new Map<String, Account>();
		System.debug('list_Opportunities: ' + list_Opportunities);
		System.debug('map_OpportunityConfigData: ' + map_OpportunityConfigData);
		List<Account> list_AccountsToCheck = new List<Account>();
		for (Opportunity objOpportunity : list_Opportunities) {
			if (objOpportunity.AccountId != null) {
				set_AccountId.add(objOpportunity.AccountId);
			}
		}

		if (list_Accounts != null && !list_Accounts.isEmpty()) {
			list_AccountsToCheck = list_Accounts;
		} else {
			for (Account objAccount : [
				SELECT
					Id,
					ZP_Company_ID__c,
					Name,
					Tier__c,
					Number_of_Active_Employees__c,
					NumberOfEmployees,
					NumberOfEmployees_Lead__c,
					Number_of_Active_Contractors__c,
					International_Employees__c,
					International_Contractors__c,
					Active_Company_Size__c
				FROM Account
				WHERE Id IN :set_AccountId
			]) {
				list_AccountsToCheck.add(objAccount);
			}
		}

		for (Account objAccount : list_AccountsToCheck) {
			mapZPCompanyIDAndAccount.put(objAccount.ZP_Company_ID__c, objAccount);
			//map_IdAndAccount.put(objAccount.Id, objAccount);
		}

		if (map_OpportunityConfigData != null && !map_OpportunityConfigData.isEmpty()) {
			for (String opportunityConfigName : map_OpportunityConfigData.keySet()) {
				if (opportunityConfigName.contains('Acquisition')) {
					Opportunity_Config__mdt objOpportunityConfig = map_OpportunityConfigData.get(opportunityConfigName);
					System.debug('objOpportunityConfig: ' + objOpportunityConfig);
					if (objOpportunityConfig != null && String.isNotBlank(objOpportunityConfig.Payment_Plan_Name__c)) {
						strPaymentPlanName = objOpportunityConfig.Payment_Plan_Name__c;
						break;
					}
				}
			}
		}

		System.debug('strPaymentPlanName: ' + strPaymentPlanName);
		// Step 1: Prepare data
		System.debug('map_PaymentPlanNameAndPriceBookEntry: ' + map_PaymentPlanNameAndPriceBookEntry);
		Map<String, PriceBookEntry> map_ProductIdAndPriceBookEntry = preparePriceBookEntryData(map_PaymentPlanNameAndPriceBookEntry.get(strPaymentPlanName));
		System.debug('map_ProductIdAndPriceBookEntry: ' + map_ProductIdAndPriceBookEntry);
		Map<String, OpportunityLineItem> map_ProductNameAndOppLineItem = new Map<String, OpportunityLineItem>();
		prepareExistingOpportunityLineItems(list_Opportunities);

		System.debug('map_ProductNameAndOppLineItem: ' + map_ProductNameAndOppLineItem);
		// Step 2: Process opportunities
		List<OpportunityLineItem> list_OpportunityLineItemsToInsert = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_OpportunityLineItemsToUpdate = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_OpportunityLineItemsToDelete = new List<OpportunityLineItem>();
		System.debug('map_ProductIdAndPriceBookEntry.keySet(): ' + map_ProductIdAndPriceBookEntry.keySet());
		System.debug('list_Opportunities: ' + list_Opportunities);
		for (Opportunity objOpportunity : list_Opportunities) {
			String strCurrentTier = objOpportunity.Current_Tier__c != null ? objOpportunity.Current_Tier__c : 'simple';
			Set<String> set_ProductNameToCheck = new Set<String>();

			if (strCurrentTier == 'contractor_only' || strCurrentTier == 'Contractor Only') {
				blnContractorOnly = true;
			}
			System.debug('strCurrentTier: ' + strCurrentTier);
			System.debug('map_ProductNameAndExternalId: ' + map_ProductNameAndExternalId);
			String strExternalId = map_ProductNameAndExternalId.get(strCurrentTier);
			if (strExternalId == null) {
				strExternalId = map_ProductNameAndExternalId.get(strCurrentTier.toLowerCase());
			}
			System.debug('strExternalId: ' + strExternalId);
			if (map_ProductIdAndPriceBookEntry.containsKey(strExternalId)) {
				set_ProductNameToCheck.add(strExternalId.toLowerCase());
				if (objOpportunity.Additional_Opportunity_Services__c != null) {
					for (String strService : objOpportunity.Additional_Opportunity_Services__c.split(';')) {
						System.debug('strService: ' + strService);
						String strServiceExternalId = map_ProductNameAndExternalId.get(strService.trim());
						if (strServiceExternalId == null) {
							strServiceExternalId = map_ProductNameAndExternalId.get(strService.toLowerCase());
						}
						System.debug('strServiceExternalId: ' + strServiceExternalId);
						if (strServiceExternalId != null) {
							set_ProductNameToCheck.add(strServiceExternalId.trim().toLowerCase());
						}
					}
				}
			}

			System.debug('set_ProductNameToCheck11: ' + set_ProductNameToCheck);
			for (String strProductToAdd : set_ProductNameToCheck) {
				OpportunityLineItem objOpportunityLineItem = new OpportunityLineItem();
				Boolean blnUpdateOppLineItem = false;
				Boolean blnCreateOppLineItem = false;
				System.debug('strProductToAdd: ' + strProductToAdd);
				System.debug('map_IDANDOpportunityLineItems: ' + map_IDANDOpportunityLineItems);
				if (!map_IDANDOpportunityLineItems.isEmpty() && map_IDANDOpportunityLineItems.containsKey(objOpportunity.Id)) {
					map_ProductNameAndOppLineItem = map_IDANDOpportunityLineItems.get(objOpportunity.Id);
					System.debug('map_ProductNameAndOppLineItem.keySet()1111: ' + map_ProductNameAndOppLineItem.keySet());
				}

				System.debug('map_ProductNameAndOppLineItem: ' + map_ProductNameAndOppLineItem);
				if (map_ProductNameAndOppLineItem != null && map_ProductNameAndOppLineItem.containsKey(strProductToAdd)) {
					if (map_ProductIdAndPriceBookEntry.containsKey(strProductToAdd.toLowerCase())) {
						objOpportunityLineItem = map_ProductNameAndOppLineItem.get(strProductToAdd);
						//objOpportunityLineItem = updateOpportunityLineItem(objOpportunity, objOpportunityLineItem, map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()), blnContractorOnly);

						objOpportunityLineItem = prepareOpportunityLineItemData(
							objOpportunity,
							objOpportunityLineItem,
							map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()),
							blnContractorOnly,
							mapZPCompanyIDAndAccount.get(objOpportunity.ZP_Company_ID__c),
							true
						);
						blnUpdateOppLineItem = true;
					}
				} else {
					System.debug('map_ProductIdAndPriceBookEntry.keySet()11: ' + map_ProductIdAndPriceBookEntry.keySet());
					System.debug('strProductToAdd2321: ' + strProductToAdd);
					if (map_ProductIdAndPriceBookEntry.containsKey(strProductToAdd.toLowerCase())) {
						objOpportunityLineItem = prepareOpportunityLineItemData(
							objOpportunity,
							objOpportunityLineItem,
							map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()),
							blnContractorOnly,
							mapZPCompanyIDAndAccount.get(objOpportunity.ZP_Company_ID__c),
							false
						);
						blnCreateOppLineItem = true;
					}
				}

				if (blnCreateOppLineItem) {
					list_OpportunityLineItemsToInsert.add(objOpportunityLineItem);
				} else if (blnUpdateOppLineItem) {
					list_OpportunityLineItemsToUpdate.add(objOpportunityLineItem);
				}
			}

			System.debug('map_ProductNameAndOppLineItem.keySet(): ' + map_ProductNameAndOppLineItem.keySet());
			System.debug('set_ProductNameToCheck: ' + set_ProductNameToCheck);
			for (String strExisitngProductName : map_ProductNameAndOppLineItem.keySet()) {
				System.debug('strExisitngProductName: ' + strExisitngProductName);
				if (set_ProductNameToCheck != null && !set_ProductNameToCheck.contains(strExisitngProductName)) {
					list_OpportunityLineItemsToDelete.add(map_ProductNameAndOppLineItem.get(strExisitngProductName));
				}
			}
		}

		System.debug('list_OpportunityLineItemsToDelete: ' + list_OpportunityLineItemsToDelete);
		if (!list_OpportunityLineItemsToDelete.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			delete list_OpportunityLineItemsToDelete;
			OpportunityTriggerHelper.skipTrigger = false;
		}
		System.debug('list_OpportunityLineItemsToInsert: ' + list_OpportunityLineItemsToInsert);
		System.debug('list_OpportunityLineItemsToUpdate: ' + list_OpportunityLineItemsToUpdate);
		if (!list_OpportunityLineItemsToInsert.isEmpty()) {
			insert list_OpportunityLineItemsToInsert;
		}

		if (!list_OpportunityLineItemsToUpdate.isEmpty()) {
			update list_OpportunityLineItemsToUpdate;
		}
	}

	private static Map<String, PriceBookEntry> preparePriceBookEntryData(List<PriceBookEntry> list_PriceBookEntry) {
		System.debug('list_PriceBookEntry: ' + list_PriceBookEntry);
		Map<String, PriceBookEntry> map_ProductIdAndPriceBookEntry = new Map<String, PriceBookEntry>();
		if (list_PriceBookEntry != null && !list_PriceBookEntry.isEmpty()) {
			for (PriceBookEntry objPriceBookEntry : list_PriceBookEntry) {
				if (objPriceBookEntry.Product2 != null && objPriceBookEntry.Product2.ExternalID != null) {
					map_ProductIdAndPriceBookEntry.put(objPriceBookEntry.Product2.ExternalID.toLowerCase(), objPriceBookEntry);
				}
			}
		}
		return map_ProductIdAndPriceBookEntry;
	}

	private static void getAllPricebookData() {
		Map<String, PriceBookEntry> map_ProductIdAndPriceBookEntry = new Map<String, PriceBookEntry>();
		for (PriceBookEntry objPriceBookEntry : [
			SELECT
				Id,
				UnitPrice,
				Product2.Name,
				Product2.ExternalID,
				Product2.Product_Type__c,
				toLabel(Product2.Product_Category__c),
				Product2.Discounts_Available__c,
				Base_Price__c,
				PriceBook2.Name,
				PriceBook2Id
			FROM PriceBookEntry
			WHERE PriceBook2.IsActive = TRUE
		]) {
			List<PriceBookEntry> list_PriceBookEntry = map_PaymentPlanNameAndPriceBookEntry.get(objPriceBookEntry.PriceBook2.Name);
			if (list_PriceBookEntry == null) {
				list_PriceBookEntry = new List<PriceBookEntry>();
			}
			list_PriceBookEntry.add(objPriceBookEntry);
			map_PaymentPlanNameAndPriceBookEntry.put(objPriceBookEntry.PriceBook2.Name, list_PriceBookEntry);
			map_NameAndPaymentPlan.put(objPriceBookEntry.PriceBook2.Name, objPriceBookEntry.PriceBook2);
		}
	}

	private static void prepareExistingOpportunityLineItems(List<Opportunity> list_Opportunities) {
		System.debug('list_Opportunities11: ' + list_Opportunities);
		Map<String, OpportunityLineItem> map_ProductNameAndOppLineItem = new Map<String, OpportunityLineItem>();
		Set<String> set_OpportunityIds = new Set<String>();

		for (Opportunity objOpportunity : list_Opportunities) {
			set_OpportunityIds.add(objOpportunity.Id);
		}
		System.debug('set_OpportunityIds11: ' + set_OpportunityIds);
		if (!set_OpportunityIds.isEmpty()) {
			for (OpportunityLineItem objOpportunityLineItem : [
				SELECT Id, OpportunityId, Product2.Name, Product2.ExternalId, Base_Price__c, Quantity, TotalPrice, Unit_Price__c
				FROM OpportunityLineItem
				WHERE OpportunityId IN :set_OpportunityIds
			]) {
				Map<String, OpportunityLineItem> tempMap = map_IDANDOpportunityLineItems.get(objOpportunityLineItem.OpportunityId);
				if (tempMap == null) {
					tempMap = new Map<String, OpportunityLineItem>();
				}
				System.debug('objOpportunityLineItem.OpportunityId: ' + objOpportunityLineItem.OpportunityId);
				System.debug('tempMap: ' + tempMap);
				tempMap.put(objOpportunityLineItem.Product2.ExternalId, objOpportunityLineItem);
				map_IDANDOpportunityLineItems.put(objOpportunityLineItem.OpportunityId, tempMap);
				//map_ProductNameAndOppLineItem.put(objOpportunityLineItem.Product2.ExternalId, objOpportunityLineItem);
			}
		}
		System.debug('map_IDANDOpportunityLineItems211: ' + map_IDANDOpportunityLineItems);
	}

	/**private static OpportunityLineItem updateOpportunityLineItem(Opportunity objOpportunity, OpportunityLineItem objOpportunityLineItem, PriceBookEntry priceBookEntry, Boolean blnContractorOnly) {
		Decimal intNoOFEmp = objOpportunity.NumberOfEmployees__c != null && objOpportunity.NumberOfEmployees__c > 0? objOpportunity.NumberOfEmployees__c : 1;
		Decimal intNoOfContractors = objOpportunity.Number_of_Contractors__c != null ? objOpportunity.Number_of_Contractors__c : 0;

		if (blnContractorOnly && intNoOfContractors == 0) {
			intNoOfContractors = 1;
		}

		if (intNoOFEmp + intNoOfContractors != objOpportunityLineItem.Quantity && !blnContractorOnly) {
			Decimal basePrice = priceBookEntry.Base_Price__c != null ? priceBookEntry.Base_Price__c : 0;
			Decimal totalEmpPrice = intNoOFEmp * priceBookEntry.UnitPrice != null ? intNoOFEmp * priceBookEntry.UnitPrice : 0;
			Decimal totalContPrice = intNoOfContractors * priceBookEntry.UnitPrice;

			objOpportunityLineItem.Quantity = intNoOFEmp + intNoOfContractors;
			objOpportunityLineItem.TotalPrice = basePrice + totalEmpPrice + totalContPrice;
		} else if (intNoOfContractors != objOpportunityLineItem.Quantity && blnContractorOnly) {
			Decimal basePrice = priceBookEntry.Base_Price__c;
			Decimal totalContPrice = intNoOfContractors * priceBookEntry.UnitPrice;

			objOpportunityLineItem.Quantity = intNoOfContractors;
			objOpportunityLineItem.TotalPrice = basePrice + totalContPrice;

			objOpportunityLineItem.Base_Price__c = basePrice;
			objOpportunityLineItem.Unit_Price__c = priceBookEntry.UnitPrice;
		}

		return objOpportunityLineItem;
	} **/

	private static OpportunityLineItem prepareOpportunityLineItemData(
		Opportunity objOpportunity,
		OpportunityLineItem objOpportunityLineItem,
		PriceBookEntry priceBookEntry,
		Boolean blnContractorOnly,
		Account objAccount,
		Boolean blnUpdate
	) {
		System.debug('objOpportunity: ' + objOpportunity);
		System.debug('objOpportunityLineItem: ' + objOpportunityLineItem);
		System.debug('priceBookEntry: ' + priceBookEntry);
		System.debug('blnContractorOnly: ' + blnContractorOnly);
		Decimal basePrice = 0;
		Decimal decQuantity = 1;
		if (priceBookEntry != null && priceBookEntry.Base_Price__c != null) {
			basePrice = priceBookEntry.Base_Price__c;
		}

		Decimal totalEmpPrice = 0;
		Decimal totalContPrice = 0;

		if (!blnUpdate) {
			objOpportunityLineItem.OpportunityId = objOpportunity.Id;
			objOpportunityLineItem.Product2 = priceBookEntry.Product2;
			objOpportunityLineItem.PricebookEntryId = priceBookEntry.Id;
		}

		if (objAccount != null) {
			System.debug('objOpportunity.NumberOfEmployees__c: ' + objOpportunity.NumberOfEmployees__c);
			System.debug('objOpportunity.Number_of_Contractors__c: ' + objOpportunity.Number_of_Contractors__c);
			System.debug('objAccount.Number_of_Active_Employees__c: ' + objAccount.Number_of_Active_Employees__c);
			System.debug('objAccount.Number_of_Active_Contractors__c: ' + objAccount.Number_of_Active_Contractors__c);
			System.debug('objAccount.Active_Company_Size__c: ' + objAccount.Active_Company_Size__c);
			System.debug('objAccount.NumberOfEmployees_Lead__c: ' + objAccount.NumberOfEmployees_Lead__c);
			System.debug('objAccount.International_Employees__c: ' + objAccount.International_Employees__c);
			System.debug('objAccount.International_Contractors__c: ' + objAccount.International_Contractors__c);

			if (objAccount.Active_Company_Size__c != null && objAccount.Active_Company_Size__c > 0 && !blnContractorOnly) {
				decQuantity = objAccount.Active_Company_Size__c;
				totalEmpPrice = decQuantity * priceBookEntry.UnitPrice;
			} else if (objAccount.Number_of_Active_Contractors__c != null && objAccount.Number_of_Active_Contractors__c > 0 && blnContractorOnly) {
				decQuantity = objAccount.Number_of_Active_Contractors__c;
				totalEmpPrice = decQuantity * priceBookEntry.UnitPrice;
			} else if (!blnContractorOnly) {
				if (objOpportunity.NumberOfEmployees__c != null && objOpportunity.NumberOfEmployees__c > 0) {
					decQuantity = objOpportunity.NumberOfEmployees__c;
					totalEmpPrice = decQuantity * priceBookEntry.UnitPrice;
				} else if (objAccount.NumberOfEmployees_Lead__c != null && objAccount.NumberOfEmployees_Lead__c > 0) {
					decQuantity = objAccount.NumberOfEmployees_Lead__c;
					totalEmpPrice = decQuantity * priceBookEntry.UnitPrice;
				} else {
					decQuantity = 1;
					totalEmpPrice = 0;
				}
			}

			System.debug('decQuantity: ' + decQuantity);
			System.debug('totalEmpPrice: ' + totalEmpPrice);
			System.debug('totalContPrice: ' + totalContPrice);
		} else {
			if (objOpportunity.NumberOfEmployees__c > 0 && !blnContractorOnly) {
				decQuantity = objOpportunity.NumberOfEmployees__c;
				totalEmpPrice = objOpportunity.NumberOfEmployees__c * priceBookEntry.UnitPrice;
			} else if (objOpportunity.NumberOfEmployees__c == 0 && !blnContractorOnly) {
				decQuantity = 1;
				totalEmpPrice = 0;
			}

			if (objOpportunity.Number_of_Contractors__c > 0 && !blnContractorOnly) {
				decQuantity += objOpportunity.Number_of_Contractors__c;
				totalContPrice = objOpportunity.Number_of_Contractors__c * priceBookEntry.UnitPrice;
			} else if (objOpportunity.Number_of_Contractors__c > 0 && blnContractorOnly) {
				decQuantity = objOpportunity.Number_of_Contractors__c;
				totalContPrice = objOpportunity.Number_of_Contractors__c * priceBookEntry.UnitPrice;
			} else if (objOpportunity.Number_of_Contractors__c == 0 && blnContractorOnly) {
				if (totalEmpPrice == 0) {
					decQuantity = 1;
				}
				totalContPrice = 0;
			}
		}

		/**if (objOpportunity.NumberOfEmployees__c > 0 && !blnContractorOnly) {
			objOpportunityLineItem.Quantity = objOpportunity.NumberOfEmployees__c;
			totalEmpPrice = objOpportunity.NumberOfEmployees__c * priceBookEntry.UnitPrice;
		} else if (objOpportunity.NumberOfEmployees__c == 0 && !blnContractorOnly) {
			objOpportunityLineItem.Quantity = 1;
			totalEmpPrice = 0;
		}

		if (objOpportunity.Number_of_Contractors__c > 0 && !blnContractorOnly) {
			objOpportunityLineItem.Quantity += objOpportunity.Number_of_Contractors__c;
			totalContPrice = objOpportunity.Number_of_Contractors__c * priceBookEntry.UnitPrice;
		} else if (objOpportunity.Number_of_Contractors__c > 0 && blnContractorOnly) {
			objOpportunityLineItem.Quantity = objOpportunity.Number_of_Contractors__c;
			totalContPrice = objOpportunity.Number_of_Contractors__c * priceBookEntry.UnitPrice;
		} else if (objOpportunity.Number_of_Contractors__c == 0 && blnContractorOnly) {
			objOpportunityLineItem.Quantity = 1;
			totalContPrice = 0;
		} **/

		objOpportunityLineItem.Quantity = decQuantity;
		objOpportunityLineItem.Base_Price__c = basePrice;
		objOpportunityLineItem.Unit_Price__c = priceBookEntry.UnitPrice;

		System.debug('objOpportunityLineItem.Quantity: ' + objOpportunityLineItem.Quantity);
		System.debug('objOpportunityLineItem.Base_Price__c: ' + objOpportunityLineItem.Base_Price__c);
		System.debug('objOpportunityLineItem.Unit_Price__c: ' + objOpportunityLineItem.Unit_Price__c);

		//objOpportunityLineItem.TotalPrice = basePrice + totalEmpPrice + totalContPrice;
		objOpportunityLineItem.TotalPrice = basePrice + totalEmpPrice;

		System.debug('objOpportunityLineItem.TotalPrice:' + objOpportunityLineItem.TotalPrice);
		return objOpportunityLineItem;
	}

	public static void validateAcquisitionOpportunity(List<Opportunity> list_NewOpportunities) {
		Set<String> set_AccountIds = new Set<String>();
		Map<String, List<Opportunity>> map_AccountIdAndOpportunities = new Map<String, List<Opportunity>>();
		Map<String, Account> map_AccountIdAndAccount = new Map<String, Account>();
		for (Opportunity objOpportunity : list_NewOpportunities) {
			set_AccountIds.add(objOpportunity.AccountId);
		}

		for (Account objAccount : [SELECT Id, ZP_Company_Overall_Status__c FROM Account WHERE Id IN :set_AccountIds]) {
			map_AccountIdAndAccount.put(objAccount.Id, objAccount);
		}

		for (Opportunity objOpportunity : [
			SELECT Id, AccountId, Type, StageName, Account.ZP_Company_Overall_Status__c
			FROM Opportunity
			WHERE AccountId IN :set_AccountIds AND RecordTypeId = :ACQUISITION_OPPTY_RT_ID
		]) {
			if (!map_AccountIdAndOpportunities.containsKey(objOpportunity.AccountId)) {
				map_AccountIdAndOpportunities.put(objOpportunity.AccountId, new List<Opportunity>());
			}
			map_AccountIdAndOpportunities.get(objOpportunity.AccountId).add(objOpportunity);
		}

		for (Opportunity objOpportunity : list_NewOpportunities) {
			if (objOpportunity.RecordTypeId == ACQUISITION_OPPTY_RT_ID) {
				if (map_AccountIdAndOpportunities.containsKey(objOpportunity.AccountId)) {
					List<Opportunity> list_Opportunities = map_AccountIdAndOpportunities.get(objOpportunity.AccountId);
					for (Opportunity objOpp : list_Opportunities) {
						if (objOpp.StageName != 'Closed Won' && objOpp.StageName != 'Closed Lost' && objOpportunity.Type == 'New Business' && objOpp.Type == 'New Business') {
							objOpportunity.addError('Cannot create a new opportunity: An open New Business Opportunity already exists.');
						}

						if (objOpp.StageName == 'Closed Won' && objOpportunity.Type == 'New Business' && objOpp.Type == 'New Business') {
							objOpportunity.addError('Cannot create a New Business Opportunity: A Closed Won New Business Opportunity already exists.');
						}

						if (objOpp.StageName != 'Closed Won' && objOpp.StageName != 'Closed Lost' && objOpportunity.Type == 'Winback' && objOpp.Type == 'Winback') {
							objOpportunity.addError('Cannot create a Winback Opportunity: An open Winback Opportunity already exists.');
						}

						if (objOpp.StageName != 'Closed Won' && objOpportunity.Type == 'Winback' && objOpp.Type == 'New Business') {
							objOpportunity.addError('Cannot create a Winback Opportunity: New Business Opportunity is not Closed WON.');
						}
					}
				} else {
					if (objOpportunity.Type == 'Winback') {
						objOpportunity.addError('Cannot create a Winback Opportunity: No New Business Opportunity exists.');
					}
				}
			}
		}

		for (Opportunity objOpportunity : list_NewOpportunities) {
			if (map_AccountIdAndAccount.containsKey(objOpportunity.AccountId)) {
				if (objOpportunity.Type == 'Winback' && map_AccountIdAndAccount.get(objOpportunity.AccountId).ZP_Company_Overall_Status__c != 'Suspended') {
					objOpportunity.addError('Cannot create a Winback Opportunity: Account Overall Status is not Suspended.');
				}
			}
		}
	}

	public static void checkAccessOfOpportunity(List<Opportunity> list_Opportunities) {
		System.debug('list_Opportunities 111: ' + list_Opportunities);
		System.debug('Schema.sObjectType.Opportunity.isUpdateable(): ' + Schema.sObjectType.Opportunity.isUpdateable());
		if (!Schema.sObjectType.Opportunity.isUpdateable()) {
			for (Opportunity objOpportunity : list_Opportunities) {
				objOpportunity.addError('You do not have permission to update the Stage for this Opportunity.');
				// If the user lacks access to this record, throw an error
				if (!Schema.sObjectType.Opportunity.fields.StageName.isUpdateable()) {
					//opp.addError('You do not have permission to update the Stage for this Opportunity.');
				}
			}

			return; // Stop further execution
		}
	}

	public static void updateEmployeeCounts(Opportunity objOppty, Opportunity objOldOppty, Account objAccount) {
		//Account objAccount = map_Accounts.get(objOppty.AccountId);

		if (objOppty.RecordTypeId == ACQUISITION_OPPTY_RT_ID && objOppty.StageName != OpportunityUtil.CLOSED_WON_STAGE) {
			if (objOldOppty == null) {
				if (objAccount.Number_of_Active_Employees__c != null && objAccount.Number_of_Active_Employees__c > 0) {
					objOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
				} else if (objAccount.NumberOfEmployees != null && objAccount.NumberOfEmployees > 0) {
					objOppty.NumberOfEmployees__c = objAccount.NumberOfEmployees;
				} else if (objAccount.NumberOfEmployees_Lead__c != null && objAccount.NumberOfEmployees_Lead__c > 0) {
					objOppty.NumberOfEmployees__c = objAccount.NumberOfEmployees_Lead__c;
				} else {
					objOppty.NumberOfEmployees__c = 0;
				}

				//objOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
				objOppty.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
			} else {
				if (objOppty.NumberOfEmployees__c != objAccount.Number_of_Active_Employees__c && objAccount.Number_of_Active_Employees__c > 0) {
					objOppty.NumberOfEmployees__c = objAccount.Number_of_Active_Employees__c;
				} else if (objOppty.NumberOfEmployees__c != objAccount.NumberOfEmployees && objAccount.NumberOfEmployees > 0) {
					objOppty.NumberOfEmployees__c = objAccount.NumberOfEmployees;
				} else if (objOppty.NumberOfEmployees__c != objAccount.NumberOfEmployees_Lead__c && objAccount.NumberOfEmployees_Lead__c > 0) {
					objOppty.NumberOfEmployees__c = objAccount.NumberOfEmployees_Lead__c;
				}

				if (objOppty.Number_of_Contractors__c != objAccount.Number_of_Active_Employees__c) {
					objOppty.Number_of_Contractors__c = objAccount.Number_of_Active_Contractors__c;
				}
			}
		}
		System.debug('objOppty.NumberOfEmployees__c11: ' + objOppty.NumberOfEmployees__c);
	}

	public static void updateOpportunityOnBeforeTrigger(List<Opportunity> list_NewOpportunity, Boolean blnInsert) {
		createCollections();
		Set<String> set_AccountId = new Set<String>();
		Map<Id, List<Opportunity>> map_AccountIdANDOpportunities = new Map<Id, List<Opportunity>>();
		Map<Id, Account> map_IdAndAccount = new Map<Id, Account>();
		PriceBook2 objPriceBook = new PriceBook2();

		for (String opportunityConfigName : map_OpportunityConfigData.keySet()) {
			if (opportunityConfigName.contains('Acquisition')) {
				Opportunity_Config__mdt objOpportunityConfig = map_OpportunityConfigData.get(opportunityConfigName);
				System.debug('objOpportunityConfig: ' + objOpportunityConfig);
				if (objOpportunityConfig != null && String.isNotBlank(objOpportunityConfig.Payment_Plan_Name__c)) {
					objPriceBook = map_NameAndPaymentPlan.get(objOpportunityConfig.Payment_Plan_Name__c);
					System.debug('objPriceBook121: ' + objPriceBook);
					break;
				}
			}
		}

		for (Opportunity objNewOpportunity : list_NewOpportunity) {
			if (objNewOpportunity.AccountId != null) {
				set_AccountId.add(objNewOpportunity.AccountId);
			}
		}

		for (Account objAccount : [
			SELECT
				Id,
				ZP_Company_ID__c,
				Name,
				Tier__c,
				Number_of_Active_Employees__c,
				NumberOfEmployees,
				NumberOfEmployees_Lead__c,
				Number_of_Active_Contractors__c,
				International_Employees__c,
				International_Contractors__c,
				Converted_Lead_Id__c
			FROM Account
			WHERE Id IN :set_AccountId
		]) {
			map_IdAndAccount.put(objAccount.Id, objAccount);
		}
		map_AccountIdANDOpportunities = queryAllOpportunityDataForCloning(set_AccountId);

		for (Opportunity objNewOpportunity : list_NewOpportunity) {
			if (objNewOpportunity.RecordTypeId == ACQUISITION_OPPTY_RT_ID) {
				Boolean blnFirstNewBiz = false;
				Boolean blnClosedLostNewBiz = false;
				Boolean blnClosedLostWinback = false;
				Boolean blnClosedWonNewBiz = false;
				Boolean blnClosedWonWinback = false;
				Opportunity objExistingNewBizOpportunity = null;
				Opportunity objExistingWinbackOpportunity = null;

				List<Opportunity> list_RelatedOpps = map_AccountIdANDOpportunities.get(objNewOpportunity.AccountId);

				if (list_RelatedOpps == null) {
					blnFirstNewBiz = true;
				}

				if (!blnFirstNewBiz) {
					for (Opportunity objOpp : list_RelatedOpps) {
						System.debug('objOpp.StageName: ' + objOpp.StageName);
						System.debug('objOpp.Type: ' + objOpp.Type);
						if (objOpp.StageName == 'Closed Won' && objOpp.Type == 'New Business') {
							blnClosedWonNewBiz = true;
							objExistingNewBizOpportunity = objOpp;
						} else if (objOpp.StageName == 'Closed Won' && objOpp.Type == 'Winback') {
							blnClosedWonWinback = true;
							objExistingWinbackOpportunity = objOpp;
						} else if (objOpp.StageName == 'Closed Lost' && objOpp.Type == 'New Business') {
							blnClosedLostNewBiz = true;
							objExistingNewBizOpportunity = objOpp;
						} else if (objOpp.StageName == 'Closed Lost' && objOpp.Type == 'Winback') {
							blnClosedLostWinback = true;
							objExistingWinbackOpportunity = objOpp;
						}

						if (objOpp.StageName != 'Closed Lost' && objOpp.StageName != 'Closed Won' && objOpp.Type == 'New Business') {
							objExistingNewBizOpportunity = objOpp;
						} else if (objOpp.StageName != 'Closed Lost' && objOpp.StageName != 'Closed Won' && objOpp.Type == 'Winback') {
							objExistingWinbackOpportunity = objOpp;
						}
					}
				}
				Account objAccount = map_IdAndAccount.get(objNewOpportunity.AccountId);
				Map<Id, Opportunity> map_IdAndUpdatedOpportunity = new Map<Id, Opportunity>();

				if (blnClosedLostNewBiz && !blnClosedWonNewBiz && blnInsert && Trigger.isBefore) {
					System.debug('objNewOpportunity2111:' + objNewOpportunity);
					Opportunity objClonedOpportunity = objExistingNewBizOpportunity.clone(false, true, false, false);
					System.debug('objNewOpportunity3111:' + objNewOpportunity);
					// Copy values from cloned object to the new one
					objNewOpportunity.Name = objClonedOpportunity.Name;
					if (objNewOpportunity.StageName == '') {
						objNewOpportunity.StageName = 'Prospecting';
					}
					//objNewOpportunity.StageName = 'Prospecting';
					objNewOpportunity.Type = objClonedOpportunity.Type;
					for (String fieldName : objClonedOpportunity.getPopulatedFieldsAsMap().keySet()) {
						System.debug('fieldName11111: ' + fieldName);
						if (!excludedFields.contains(fieldName) && fieldName != 'StageName' && fieldName != 'Id' && fieldName != 'CloseDate' && fieldName != 'Stage_Detail__c' && fieldName != 'Stage_Detail_2__c' && fieldName != 'Is_Fraud__c') {
							objNewOpportunity.put(fieldName, objClonedOpportunity.get(fieldName));
						}
					}
				}
				System.debug('objNewOpportunity11:' + objNewOpportunity);
				if (blnClosedLostWinback && !blnClosedWonWinback) {
					//objNewOpportunity = objExistingWinbackOpportunity.clone(false, false, false, false);
				}

				System.debug('objNewOpportunity22:' + objNewOpportunity);
				if (blnFirstNewBiz) {
					objNewOpportunity = mapOpportunityFields(objAccount, objPriceBook, null, objNewOpportunity);
				}

				System.debug('objNewOpportunity33:' + objNewOpportunity);
				if (!blnClosedLostNewBiz && !blnClosedWonNewBiz && !blnClosedLostWinback && !blnClosedWonWinback) {
					objNewOpportunity = mapOpportunityFields(objAccount, objPriceBook, null, objNewOpportunity);
					System.debug('objNewOpportunity44:' + objNewOpportunity);
				} else if (blnClosedLostNewBiz && !blnClosedWonNewBiz && !blnClosedLostWinback && !blnClosedWonWinback) {
					objNewOpportunity = mapOpportunityFields(objAccount, objPriceBook, null, objNewOpportunity);
					System.debug('objNewOpportunity55:' + objNewOpportunity);
				} else if (!blnClosedLostNewBiz && blnClosedWonNewBiz) {
					objNewOpportunity = mapOpportunityFields(objAccount, objPriceBook, objExistingWinbackOpportunity, objNewOpportunity);
					System.debug('objNewOpportunity66:' + objNewOpportunity);
				} else if (!blnClosedLostNewBiz && blnClosedWonNewBiz && blnClosedLostWinback && !blnClosedWonWinback) {
					objNewOpportunity = mapOpportunityFields(objAccount, objPriceBook, objExistingWinbackOpportunity, objNewOpportunity);
					System.debug('objNewOpportunity77:' + objNewOpportunity);
				}
			}
		}
	}

	public static Map<Id, List<Opportunity>> queryAllOpportunityDataForCloning(Set<String> set_AccountIds) {
		// Get all fields of Opportunity
		Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap();
		Map<Id, List<Opportunity>> map_AccountIdANDOpportunities = new Map<Id, List<Opportunity>>();
		// Define system-generated fields to exclude

		// Collect all field names except system fields
		List<String> fieldNames = new List<String>();
		for (String fieldName : fieldMap.keySet()) {
			Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
			if (fieldDescribe.isUpdateable()) {
				fieldNames.add(fieldName);
			} else {
				excludedFields.add(fieldName);
			}
		}

		// Build and execute SOQL query
		String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM Opportunity WHERE Accountid IN :set_AccountIds AND RecordTypeId = :ACQUISITION_OPPTY_RT_ID';
		System.debug('SOQL Query: ' + query);

		for (Opportunity objOppty : Database.query(query)) {
			if (!map_AccountIdANDOpportunities.containsKey(objOppty.AccountId)) {
				map_AccountIdANDOpportunities.put(objOppty.AccountId, new List<Opportunity>());
			}
			map_AccountIdANDOpportunities.get(objOppty.AccountId).add(objOppty);
		}
		return map_AccountIdANDOpportunities;
	}

	public static void updateCloseDateToMatchAPD(Opportunity objNewOppty, Opportunity objOldOppty) {
		if (objOldOppty == null && objNewOppty.Anchor_Pay_Date__c != null && !objNewOppty.IsClosed) {
			objNewOppty.CloseDate = objNewOppty.Anchor_Pay_Date__c;
		} else if (objOldOppty != null && objNewOppty != null && objNewOppty.Anchor_Pay_Date__c != objOldOppty.Anchor_Pay_Date__c && !objNewOppty.IsClosed) {
			objNewOppty.CloseDate = objNewOppty.Anchor_Pay_Date__c;
		}
	}

	public static void syncPaymentInvoiceValuesToOppty(Set<Id> set_OppIds) {
		String strPaymentPlanName = 'Payroll Product Catalog';
		createCollections();
		Map<Id, Opportunity> map_OpptysToUpdate = new Map<Id, Opportunity>();
		List<Opportunity> list_Opportunities = new List<Opportunity>();

		List<OpportunityLineItem> list_OpportunityLineItemsToInsert = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_OpportunityLineItemsToUpdate = new List<OpportunityLineItem>();
		List<OpportunityLineItem> list_OpportunityLineItemsToDelete = new List<OpportunityLineItem>();
		Boolean blnContractorOnly = false;

		for (Opportunity objOpportunity : [
			SELECT
				Id,
				NumberOfEmployees__c,
				Number_of_Contractors__c,
				AccountId,
				Pricebook2Id,
				Pricebook2.Name,
				Additional_Opportunity_Services__c,
				International_Contractors__c,
				International_Employees__c,
				Payment_Invoice__r.Pricing__c,
				Payment_Invoice__r.Employee_Count__c,
				Payment_Invoice__r.Contractor_Count__c,
				toLabel(Payment_Invoice__r.Additional_Invoiced_Services__c),
				Payment_Invoice__r.Payment_Plan_Name__c,
				Payment_Invoice__r.International_Contractors__c,
				Payment_Invoice__r.International_Employees__c,
				Payment_Invoice__r.Priority_Support__c,
				Current_Tier__c,
				(SELECT Id, Quantity, Discount, Product2.Name, OpportunityId, PricebookEntry.Pricebook2Id, PricebookEntryId, Product2.ExternalId FROM OpportunityLineItems)
			FROM Opportunity
			WHERE Id IN :set_OppIds
		]) {
			list_Opportunities.add(objOpportunity);
			for (OpportunityLineItem objOpportunityLineItem : objOpportunity.OpportunityLineItems) {
				Map<String, OpportunityLineItem> tempMap = map_IDANDOpportunityLineItems.get(objOpportunityLineItem.OpportunityId);
				if (tempMap == null) {
					tempMap = new Map<String, OpportunityLineItem>();
				}
				System.debug('objOpportunityLineItem.OpportunityId: ' + objOpportunityLineItem.OpportunityId);
				System.debug('tempMap: ' + tempMap);
				tempMap.put(objOpportunityLineItem.Product2.ExternalId, objOpportunityLineItem);
				map_IDANDOpportunityLineItems.put(objOpportunityLineItem.OpportunityId, tempMap);
			}
		}

		if (map_OpportunityConfigData != null && !map_OpportunityConfigData.isEmpty()) {
			for (String opportunityConfigName : map_OpportunityConfigData.keySet()) {
				if (opportunityConfigName.contains('Acquisition')) {
					Opportunity_Config__mdt objOpportunityConfig = map_OpportunityConfigData.get(opportunityConfigName);
					System.debug('objOpportunityConfig: ' + objOpportunityConfig);
					if (objOpportunityConfig != null && String.isNotBlank(objOpportunityConfig.Payment_Plan_Name__c)) {
						strPaymentPlanName = objOpportunityConfig.Payment_Plan_Name__c;
						break;
					}
				}
			}
		}

		System.debug('strPaymentPlanName: ' + strPaymentPlanName);
		// Step 1: Prepare data
		System.debug('map_PaymentPlanNameAndPriceBookEntry: ' + map_PaymentPlanNameAndPriceBookEntry);
		Map<String, PriceBookEntry> map_ProductIdAndPriceBookEntry = preparePriceBookEntryData(map_PaymentPlanNameAndPriceBookEntry.get(strPaymentPlanName));
		System.debug('map_ProductIdAndPriceBookEntry: ' + map_ProductIdAndPriceBookEntry);
		Map<String, OpportunityLineItem> map_ProductNameAndOppLineItem = new Map<String, OpportunityLineItem>();

		System.debug('map_ProductNameAndOppLineItem: ' + map_ProductNameAndOppLineItem);

		for (Opportunity objOpp : list_Opportunities) {
			// sync additional services between payment invoice and opportunity
			if (objOpp.Additional_Opportunity_Services__c != objOpp.Payment_Invoice__r.Additional_Invoiced_Services__c) {
				objOpp.Additional_Opportunity_Services__c = objOpp.Payment_Invoice__r.Additional_Invoiced_Services__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of international contractors between invoice and opportunity
			if (objOpp.International_Contractors__c != objOpp.Payment_Invoice__r.International_Contractors__c) {
				objOpp.International_Contractors__c = objOpp.Payment_Invoice__r.International_Contractors__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of international employees between invoice and opportunity
			if (objOpp.International_Employees__c != objOpp.Payment_Invoice__r.International_Employees__c) {
				objOpp.International_Employees__c = objOpp.Payment_Invoice__r.International_Employees__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of employees between invoice and opportunity
			if (objOpp.NumberOfEmployees__c != objOpp.Payment_Invoice__r.Employee_Count__c) {
				objOpp.NumberOfEmployees__c = objOpp.Payment_Invoice__r.Employee_Count__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}

			// sync number of contracrors between invoice and opportunity
			if (objOpp.Number_of_Contractors__c != objOpp.Payment_Invoice__r.Contractor_Count__c) {
				objOpp.Number_of_Contractors__c = objOpp.Payment_Invoice__r.Contractor_Count__c;
				map_OpptysToUpdate.put(objOpp.Id, objOpp);
			}
		}

		for (Opportunity objOpportunity : map_OpptysToUpdate.values()) {
			String strCurrentTier = objOpportunity.Current_Tier__c != null ? objOpportunity.Current_Tier__c : 'simple';
			Set<String> set_ProductNameToCheck = new Set<String>();

			if (strCurrentTier == 'contractor_only' || strCurrentTier == 'Contractor Only') {
				blnContractorOnly = true;
			}
			System.debug('strCurrentTier: ' + strCurrentTier);
			System.debug('map_ProductNameAndExternalId: ' + map_ProductNameAndExternalId);
			String strExternalId = map_ProductNameAndExternalId.get(strCurrentTier);
			if (strExternalId == null) {
				strExternalId = map_ProductNameAndExternalId.get(strCurrentTier.toLowerCase());
			}
			System.debug('strExternalId: ' + strExternalId);
			if (map_ProductIdAndPriceBookEntry.containsKey(strExternalId)) {
				set_ProductNameToCheck.add(strExternalId.toLowerCase());
				if (objOpportunity.Additional_Opportunity_Services__c != null) {
					for (String strService : objOpportunity.Additional_Opportunity_Services__c.split(';')) {
						System.debug('strService: ' + strService);
						String strServiceExternalId = map_ProductNameAndExternalId.get(strService.trim());
						if (strServiceExternalId == null) {
							strServiceExternalId = map_ProductNameAndExternalId.get(strService.toLowerCase());
						}
						System.debug('strServiceExternalId: ' + strServiceExternalId);
						if (strServiceExternalId != null) {
							set_ProductNameToCheck.add(strServiceExternalId.trim().toLowerCase());
						}
					}
				}
			}

			System.debug('set_ProductNameToCheck11: ' + set_ProductNameToCheck);
			for (String strProductToAdd : set_ProductNameToCheck) {
				OpportunityLineItem objOpportunityLineItem = new OpportunityLineItem();
				Boolean blnUpdateOppLineItem = false;
				Boolean blnCreateOppLineItem = false;
				System.debug('strProductToAdd: ' + strProductToAdd);
				System.debug('map_IDANDOpportunityLineItems: ' + map_IDANDOpportunityLineItems);
				if (!map_IDANDOpportunityLineItems.isEmpty() && map_IDANDOpportunityLineItems.containsKey(objOpportunity.Id)) {
					map_ProductNameAndOppLineItem = map_IDANDOpportunityLineItems.get(objOpportunity.Id);
					System.debug('map_ProductNameAndOppLineItem.keySet()1111: ' + map_ProductNameAndOppLineItem.keySet());
				}

				System.debug('map_ProductNameAndOppLineItem: ' + map_ProductNameAndOppLineItem);
				if (map_ProductNameAndOppLineItem != null && map_ProductNameAndOppLineItem.containsKey(strProductToAdd)) {
					if (map_ProductIdAndPriceBookEntry.containsKey(strProductToAdd.toLowerCase())) {
						objOpportunityLineItem = map_ProductNameAndOppLineItem.get(strProductToAdd);
						//objOpportunityLineItem = updateOpportunityLineItem(objOpportunity, objOpportunityLineItem, map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()), blnContractorOnly);

						objOpportunityLineItem = prepareOpportunityLineItemData(
							objOpportunity,
							objOpportunityLineItem,
							map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()),
							blnContractorOnly,
							null,
							true
						);
						blnUpdateOppLineItem = true;
					}
				} else {
					System.debug('map_ProductIdAndPriceBookEntry.keySet()11: ' + map_ProductIdAndPriceBookEntry.keySet());
					System.debug('strProductToAdd2321: ' + strProductToAdd);
					if (map_ProductIdAndPriceBookEntry.containsKey(strProductToAdd.toLowerCase())) {
						objOpportunityLineItem = prepareOpportunityLineItemData(
							objOpportunity,
							objOpportunityLineItem,
							map_ProductIdAndPriceBookEntry.get(strProductToAdd.toLowerCase()),
							blnContractorOnly,
							null,
							false
						);
						blnCreateOppLineItem = true;
					}
				}

				if (blnCreateOppLineItem) {
					list_OpportunityLineItemsToInsert.add(objOpportunityLineItem);
				} else if (blnUpdateOppLineItem) {
					list_OpportunityLineItemsToUpdate.add(objOpportunityLineItem);
				}
			}

			System.debug('map_ProductNameAndOppLineItem.keySet(): ' + map_ProductNameAndOppLineItem.keySet());
			System.debug('set_ProductNameToCheck: ' + set_ProductNameToCheck);
			for (String strExisitngProductName : map_ProductNameAndOppLineItem.keySet()) {
				System.debug('strExisitngProductName: ' + strExisitngProductName);
				if (set_ProductNameToCheck != null && !set_ProductNameToCheck.contains(strExisitngProductName)) {
					list_OpportunityLineItemsToDelete.add(map_ProductNameAndOppLineItem.get(strExisitngProductName));
				}
			}
		}

		if (!map_OpptysToUpdate.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			update map_OpptysToUpdate.values();
			OpportunityTriggerHelper.skipTrigger = false;
		}

		System.debug('list_OpportunityLineItemsToDelete: ' + list_OpportunityLineItemsToDelete);
		if (!list_OpportunityLineItemsToDelete.isEmpty()) {
			OpportunityTriggerHelper.skipTrigger = true;
			delete list_OpportunityLineItemsToDelete;
			OpportunityTriggerHelper.skipTrigger = false;
		}
		System.debug('list_OpportunityLineItemsToInsert: ' + list_OpportunityLineItemsToInsert);
		System.debug('list_OpportunityLineItemsToUpdate: ' + list_OpportunityLineItemsToUpdate);
		if (!list_OpportunityLineItemsToInsert.isEmpty()) {
			insert list_OpportunityLineItemsToInsert;
		}

		if (!list_OpportunityLineItemsToUpdate.isEmpty()) {
			update list_OpportunityLineItemsToUpdate;
		}
	}
}