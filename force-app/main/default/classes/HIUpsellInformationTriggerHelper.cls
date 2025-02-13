public with sharing class HIUpsellInformationTriggerHelper {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;

	public static Id idOppRecord = OpportunityUtil.BENEFITS_CHANGE_OPPTY_RT_ID;
	public static Id idBORecord = BenefitOrderUtil.BOR_BENEFIT_ORDER_RT_ID;
	public static Id idCORecord = CarrierOrderUtil.REC_TYPE_BOR;
	public static Carrier__c objCarrier;
	public static Map<String, Opportunity> map_opptyIdCustomToOpp;

	/**
	 * @description         BeforeInsert handler
	 *
	 * @param list_UpsellInfo Trigger.new (IDs have not been assigned, and Trigger.old does not exist)
	 */
	public void processBeforeInsert(List<HI_Upsell_Information__c> list_UpsellInfo) {
		if (queue) {
			processInformation(list_UpsellInfo);
		} else {
			for (HI_Upsell_Information__c objUpsellInfo : list_UpsellInfo) {
				objUpsellInfo.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	/**
	 * @description Handle AfterInsert
	 *
	 * @param map_UpsellInfo Trigger.newMap (note: Trigger.old does not exist in insert context)
	 */
	public void processAfterInsert(Map<Id, HI_Upsell_Information__c> map_UpsellInfo) {
		if (!queue) {
			HIUpsellInformationQueue updateJob = new HIUpsellInformationQueue(map_UpsellInfo.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	/**
	 * @description           BeforeUpdate handler
	 *
	 * @param map_OldUpsellObj Trigger.oldMap
	 * @param map_NewUpsellObj    Trigger.new
	 */
	public void processBeforeUpdate(Map<Id, HI_Upsell_Information__c> map_OldUpsellObj, Map<Id, HI_Upsell_Information__c> map_NewUpsellObj) {
		if (queue) {
			processInformation(map_NewUpsellObj.values());
		} else {
			for (HI_Upsell_Information__c objUpsellInfo : map_NewUpsellObj.values()) {
				objUpsellInfo.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	/**
	 * @description           AfterUpdate handler
	 *
	 * @param map_OldUpsellObj Trigger.oldMap
	 * @param map_NewUpsellObj    Trigger.new
	 */
	public void processAfterUpdate(Map<Id, HI_Upsell_Information__c> map_OldUpsellObj, Map<Id, HI_Upsell_Information__c> map_NewUpsellObj) {
		if (!queue) {
			HIUpsellInformationQueue updateJob = new HIUpsellInformationQueue(map_NewUpsellObj.values());
			ID jobID = System.enqueueJob(updateJob);
		}
	}

	private void processInformation(List<HI_Upsell_Information__c> list_upsellInfoObj) {
		Set<String> set_companyIds = new Set<String>();
		Set<String> set_UserId = new Set<String>();
		List<Policy__c> list_policyToInsert = new List<Policy__c>();

		map_opptyIdCustomToOpp = new Map<String, Opportunity>();

		Map<String, String> map_dmlUpsertErrors = new Map<String, String>();

		for (HI_Upsell_Information__c objUpsell : list_upsellInfoObj) {
			if (objUpsell.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (String.isBlank(objUpsell.Company_Id__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, HIUpsellInformationUtil.COMPANY_ID_EMPTY, objUpsell);
				continue;
			}
			if (String.isBlank(objUpsell.External_Key__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, HIUpsellInformationUtil.EXTERNAL_KEY_EMPTY, objUpsell);
				continue;
			}
			if (String.isBlank(objUpsell.Benefit_Type__c)) {
				setProcessingState(IntegrationUtils.ERROR_STATE, HIUpsellInformationUtil.BENEFIT_TYPE_EMPTY, objUpsell);
				continue;
			}
			if (String.isNotBlank(objUpsell.Company_id__c)) {
				set_companyIds.add(objUpsell.Company_id__c);
			}
			if (String.isNotBlank(objUpsell.User_Id__c)) {
				set_UserId.add(objUpsell.User_Id__c);
			}
		}

		Map<String, String> map_CompanyUserBenefitType = new Map<String, String>();
		if(objCarrier == null) {
			objCarrier = HIUpsellInformationUtil.getActiveTadaCarrier();
		}

		String strBenefitType = null;

		for (HI_Upsell_Information__c objUpsellInfo : [
			SELECT Company_id__c, User_Id__c, Benefit_Type__c
			FROM HI_Upsell_Information__c
			WHERE Benefit_Type__c != NULL AND Company_id__c IN :set_companyIds AND User_Id__c IN :set_UserId
		]) {
			String strCompanyIdUserIdKey = objUpsellInfo.Company_id__c + '~' + objUpsellInfo.User_Id__c;
			strBenefitType = map_CompanyUserBenefitType.get(strCompanyIdUserIdKey);
			if (String.isBlank(strBenefitType)) {
				strBenefitType = objUpsellInfo.Benefit_Type__c;
			}
			strBenefitType += ',' + objUpsellInfo.Benefit_Type__c;
			map_CompanyUserBenefitType.put(strCompanyIdUserIdKey, strBenefitType);
		}

		Set<String> set_processedCompanyId = new Set<String>();
		Map<String, Account> map_companyIdAccount = getAccounts(set_companyIds);
		Map<String, Map<String, Opportunity>> map_oppType = getOpportunityMap(set_companyIds);
		Map<String, ZP_User__c> map_ZPUser = new Map<String, ZP_User__c>();

		if (!set_UserId.isEmpty()) {
			map_ZPUser = getZPUserMap(set_UserId);
		}

		List<Opportunity> list_opptyToUpsert = new List<Opportunity>();
		Set<Id> set_OpptyIdsAlreadyExist = new Set<Id>();
		Map<Id, HI_Upsell_Information__c> map_accountIdWithBenefitType = new Map<Id, HI_Upsell_Information__c>();
		Boolean blnNewBenefitType = false;

		if (!set_companyIds.isEmpty()) {
			for (HI_Upsell_Information__c objUpsellInfo : list_upsellInfoObj) {
				if (objUpsellInfo.Processing_State__c == IntegrationUtils.DEAD_STATE) {
					continue;
				}
				if (!map_companyIdAccount.containsKey(objUpsellInfo.Company_Id__c)) {
					setProcessingState(IntegrationUtils.ERROR_STATE, HIUpsellInformationUtil.COMPANY_NOT_EXIST, objUpsellInfo);
					continue;
				}
				if (set_processedCompanyId.contains(objUpsellInfo.Company_Id__c)) {
					continue;
				}
				Map<String, Opportunity> map_oppIdToOpp = new Map<String, Opportunity>();
				if (map_oppType.containsKey(objUpsellInfo.Company_Id__c)) {
					map_oppIdToOpp = map_oppType.get(objUpsellInfo.Company_Id__c);
				}
				String strUpsellObjType = '';
				if (objUpsellInfo.Type__c == HIUpsellInformationUtil.STR_NEW_BENEFIT) {
					blnNewBenefitType = true;
					strUpsellObjType = HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA;
				} else if (objUpsellInfo.Type__c == HIUpsellInformationUtil.STR_TRANSFER_BENEFIT) {
					strUpsellObjType = HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA;
				}
				Opportunity objOpp = new Opportunity();

				//If Opportunity Exist then update Benefit Notes on Opportunity level
				if (map_oppIdToOpp.containsKey(strUpsellObjType) || map_opptyIdCustomToOpp.containsKey(objUpsellInfo.External_Key__c)) {
					if (map_oppIdToOpp.containsKey(strUpsellObjType) && map_oppIdToOpp.get(strUpsellObjType) != null) {
						objOpp = map_oppIdToOpp.get(strUpsellObjType);
					} else if (map_opptyIdCustomToOpp.containsKey(objUpsellInfo.External_Key__c) && map_opptyIdCustomToOpp.get(objUpsellInfo.External_Key__c) != null) {
						objOpp = map_opptyIdCustomToOpp.get(objUpsellInfo.External_Key__c);
					}

					set_OpptyIdsAlreadyExist.add(objOpp.Id);
					string strKey = objUpsellInfo.Company_id__c + '~' + objUpsellInfo.User_Id__c;
					if (!map_CompanyUserBenefitType.isEmpty() && map_CompanyUserBenefitType.containsKey(strKey) && !objOpp?.isClosed) {
						objOpp.Benefits_Notes__c = map_CompanyUserBenefitType.get(strKey);
						list_opptyToUpsert.add(objOpp);
					}
				} else if (!map_oppIdToOpp.containsKey(strUpsellObjType) && !map_opptyIdCustomToOpp.containsKey(objUpsellInfo.External_Key__c)) {
					//Commented this line by AKS because we need to open for all TAda Type Dated 26th March 2020
					objOpp = getOpportunityRecord(map_companyIdAccount, map_ZPUser, objUpsellInfo, strUpsellObjType);
					if (objOpp.AccountId != null) {
						map_accountIdWithBenefitType.put(objOpp.AccountId, objUpsellInfo);
					}
					list_opptyToUpsert.add(objOpp);
				}
				set_processedCompanyId.add('' + objUpsellInfo.Company_Id__c);
			}

			if (!list_opptyToUpsert.isEmpty()) {
				if (!blnNewBenefitType) {
					OpportunityTriggerHelper.skipTrigger = true;
				}
				upsert list_opptyToUpsert;
			}

			List<Benefit_Order__c> list_benefitOrders = new List<Benefit_Order__c>();
			String strRecordTypeName = ' - ' + BenefitOrderUtil.BENEFIT_ORDER_RT_BENEFITS_BOR;
			//For All Transfer type of opportunities create BO and CO
			Map<String, Id> map_OppHIUpsell = new Map<String, Id>();

			for (Opportunity objOpp : list_opptyToUpsert) {
				if (!set_OpptyIdsAlreadyExist?.contains(objOpp.Id) && objOpp.Type == HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA) {
					HI_Upsell_Information__c objUpsellInfo = map_accountIdWithBenefitType?.get(objOpp.AccountId);
					if (String.isNotBlank(objUpsellInfo.User_Id__c)) {
						map_OppHIUpsell.put(objUpsellInfo.User_Id__c, objOpp.id);
					}
					//Create BO
					Benefit_Order__c objBenefitOrder = getBenefitOrderRecord(objOpp, objUpsellInfo, strRecordTypeName);
					list_benefitOrders.add(objBenefitOrder);
				}
			}

			//Create Opportunity Contact Role
			if (!map_OppHIUpsell.isEmpty()) {
				createOpportunityContactRoles(map_OppHIUpsell);
			}

			//Create benefit Order
			if (!list_benefitOrders.isEmpty()) {
				insert list_benefitOrders;

				Map<Id, Id> map_boAndAccountId = new Map<Id, Id>();
				List<Carrier_Order__c> list_carrierOrder = new List<Carrier_Order__c>();
				Set<Id> set_benefitOrderIds = new Set<Id>();

				for (Benefit_Order__c objBenefitOrder : list_benefitOrders) {
					set_benefitOrderIds.add(objBenefitOrder.Id);
					Carrier_Order__c objCarrierOrder = getCarrierOrderRecord(objBenefitOrder);
					list_carrierOrder.add(objCarrierOrder);
					map_boAndAccountId.put(objBenefitOrder.Id, objBenefitOrder.Account__c);
				}

				if (!list_carrierOrder.isEmpty()) {
					insert list_carrierOrder;
					list<Carrier_Order_Line_Item__c> list_CarrierOrderLineItems = new List<Carrier_Order_Line_Item__c>();
					for (Carrier_Order__c objCarrierOrder : list_carrierOrder) {
						Id idAccount = null;
						if (!map_boAndAccountId.isEmpty() && map_boAndAccountId.containsKey(objCarrierOrder.Benefit_Order__c)) {
							idAccount = map_boAndAccountId.get(objCarrierOrder.Benefit_Order__c);
						}
						if (idAccount != null && map_accountIdWithBenefitType?.containsKey(idAccount)) {
							String strBenefitTypeVal = map_accountIdWithBenefitType?.get(idAccount).Benefit_Type__c;
							if (String.isNotBlank(strBenefitTypeVal)) {
								for (String strBenType : strBenefitTypeVal.split(';')) {
									strBenType = strBenType.Trim();
									if (strBenType == HIUpsellInformationUtil.STR_FSA) {
										strBenType = HIUpsellInformationUtil.STR_FSA_MEDICAL;
									} else if (strBenType == HIUpsellInformationUtil.STR_DCA) {
										strBenType = HIUpsellInformationUtil.STR_FSA_DEPENDENT;
									}
									list_CarrierOrderLineItems.add(
										new Carrier_Order_Line_Item__c(Carrier_Order__c = objCarrierOrder.Id, Benefit_Types__c = strBenType, Renewal_Date__c = objCarrierOrder.Renewal_Date__c)
									);
								}
							}
						}
					}
					if (!list_CarrierOrderLineItems.isEmpty()) {
						insert list_CarrierOrderLineItems;
					}
				}
				//Send BO and TADA CO for Advocate assignement
				BTAssignmentUtil objAssignmentUtil = new BTAssignmentUtil();
				// SJay - 08/11/2020 - Added boolean parameter to function call
				objAssignmentUtil.processBOForAdvocateAssignment(list_benefitOrders, false);
				update list_benefitOrders;

				//get Update Bo Record
				List<Opportunity> list_opptyUpdate = new List<Opportunity>();
				for (Benefit_Order__c objBenefitOrder : [
					SELECT ownerId, Id, Opportunity__c
					FROM Benefit_Order__c
					WHERE id IN :set_benefitOrderIds
				]) {
					Opportunity objOpp = new Opportunity(
						Id = objBenefitOrder.Opportunity__c,
						StageName = OpportunityUtil.CLOSED_WON_STAGE,
						Benefits_Current_Setup_Step__c = OpportunityUtil.COMPLETED_BENEFITSCURRENTSTEP,
						Order_Generated__c = true,
						OwnerId = objBenefitOrder.OwnerId
					);
					list_opptyUpdate.add(objOpp);
				}
				//Get BO Owner Id
				if (!list_opptyUpdate.isEmpty()) {
					OpportunityTriggerHelper.skipTrigger = true;
					update list_opptyUpdate;
				}
			}
			//if upsellObj type is Type is "New TAdA Plan" then policy should be create
			//Added by AKS dated 26th March 2020
			if (blnNewBenefitType) {
				map<String, Policy__c> map_policyObj = getPolicies(set_companyIds);
				map_oppType = getOpportunityMap(set_companyIds);
				for (HI_Upsell_Information__c objUpsell : list_upsellInfoObj) {
					if (objUpsell.Processing_State__c == IntegrationUtils.DEAD_STATE || objUpsell.Processing_State__c == IntegrationUtils.ERROR_STATE) {
						continue;
					}
					Map<String, Opportunity> map_opptyObj = new Map<String, Opportunity>();
					if (map_oppType.containskey(objUpsell.Company_Id__c)) {
						map_opptyObj = map_oppType.get(objUpsell.Company_Id__c);
					}
					String strUpsellType = '';
					//Changes by AKS dated 29th Sept 2020 Earlier Type was 'new_upsellObj'
					if (String.isNotBlank(objUpsell.Type__c) && objUpsell.Type__c == HIUpsellInformationUtil.STR_NEW_BENEFIT) {
						strUpsellType = HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA;
						if (!map_opptyObj.containsKey(strUpsellType)) {
							setProcessingState(IntegrationUtils.ERROR_STATE, HIUpsellInformationUtil.OPPTY_DONT_EXIST, objUpsell);
							continue;
						} else {
							Opportunity objOpp = map_opptyObj.get(strUpsellType);
							String strUpsellObjType = objUpsell.Benefit_Type__c;
							if (String.isNotBlank(strUpsellObjType)) {
								for (String strBenType : strUpsellObjType.split(';')) {
									strBenType = strBenType.Trim();
									if (strBenType == HIUpsellInformationUtil.STR_FSA) {
										strBenType = HIUpsellInformationUtil.STR_FSA_MEDICAL;
									} else if (strBenType == HIUpsellInformationUtil.STR_DCA) {
										strBenType = HIUpsellInformationUtil.STR_FSA_DEPENDENT;
									}
									if (!map_policyObj.containsKey(objOpp.Id + '-' + strBenType)) {
										Policy__c objPolicy = getPolicyRecord(objOpp, objUpsell, strBenType);
										list_policyToInsert.add(objPolicy);
									}
								}
							}
						}
					}
				}
				if (!list_policyToInsert.isEmpty()) {
					List<Database.SaveResult> saveResult = Database.insert(list_policyToInsert, false);
					map_dmlUpsertErrors = Utils.processSaveResult(saveResult, list_policyToInsert, 'Integration_Id__c', false, 'HIUpsellInformationTriggerHelper-processInformation');
				}
			}
		}

		for (HI_Upsell_Information__c objUpsell : list_upsellInfoObj) {
			if (objUpsell.Processing_State__c == IntegrationUtils.DEAD_STATE || objUpsell.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_dmlUpsertErrors.containsKey(objUpsell.Id__c)) {
				if (map_dmlUpsertErrors?.get(objUpsell.Id__c).contains(HIUpsellInformationUtil.DUPLICATE_VALUE_ERROR_MSG)) {
					setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, objUpsell);
				} else {
					setProcessingState(IntegrationUtils.ERROR_STATE, map_dmlUpsertErrors.get(objUpsell.Id__c), objUpsell);
				}
			} else {
				setProcessingState(IntegrationUtils.PROCESSED_STATE, IntegrationUtils.PROCESSED_STATE, objUpsell);
			}
		}
	}

	//By AKS Dated 29th Sept 2020
	private static Map<String, ZP_User__c> getZPUserMap(Set<String> set_UserIdTemp) {
		Map<String, ZP_User__c> map_ZPUserTemp = new Map<String, ZP_User__c>();
		for (ZP_User__c objZPUser : [
			SELECT Id, Id__c, Name, Email__c
			FROM ZP_User__c
			WHERE Id__c IN :set_UserIdTemp
		]) {
			map_ZPUserTemp.put(objZPUser.Id__c, objZPUser);
		}
		return map_ZPUserTemp;
	}

	private static Map<String, Policy__c> getPolicies(Set<String> set_companyIds) {
		Map<String, Policy__c> map_policyObj = new Map<String, Policy__c>();
		for (Policy__c objPolicy : [
			SELECT Id, Benefit_Type__c, Opportunity__c, Name
			FROM Policy__c
			WHERE Opportunity__r.Account.ZP_Company_Id__c IN :set_companyIds AND Benefit_Type__c IN :HIUpsellInformationUtil.POLICY_BENEFIT_TYPES
		]) {
			map_policyObj.put(objPolicy.Opportunity__c + '-' + objPolicy.Benefit_Type__c, objPolicy);
		}

		return map_policyObj;
	}

	private static Map<String, Account> getAccounts(Set<String> set_companyIds) {
		Map<String, Account> map_accountObj = new Map<String, Account>();
		for (Account objAcc : [
			SELECT Id, ZP_Company_Id__c, Name
			FROM Account
			WHERE ZP_Company_Id__c IN :set_companyIds
		]) {
			map_accountObj.put(objAcc.ZP_Company_Id__c, objAcc);
		}
		return map_accountObj;
	}
	private static Map<String, Map<String, Opportunity>> getOpportunityMap(Set<String> set_companyIds) {
		Map<String, Map<String, Opportunity>> map_sourceIdToOppTypeMap = new Map<String, Map<String, Opportunity>>();
		for (Opportunity objOpp : [
			SELECT Id, Source_Id__c, ID__c, Name, Type, AccountId, Account.ZP_Company_Id__c, isClosed, Benefits_Notes__c
			FROM Opportunity
			WHERE Account.ZP_Company_Id__c IN :set_companyIds AND RecordTypeId = :idOppRecord
		]) {
			if (!objOpp.isClosed) {
				Map<String, Opportunity> map_opptyTypeToOppty = new Map<String, Opportunity>();
				if (map_sourceIdToOppTypeMap.containsKey(objOpp.Account.ZP_Company_Id__c)) {
					map_opptyTypeToOppty = map_sourceIdToOppTypeMap.get(objOpp.Account.ZP_Company_Id__c);
				}

				if (objOpp.Type == HIUpsellInformationUtil.UPSELL_TYPE_NEW_TADA || objOpp.Type == HIUpsellInformationUtil.UPSELL_TYPE_TRANSFER_TADA) {
					map_opptyTypeToOppty.put(objOpp.Type, objOpp);
				} else {
					map_opptyTypeToOppty.put(HIUpsellInformationUtil.STR_CHANGE, objOpp);
				}
				map_sourceIdToOppTypeMap.put(objOpp.Account.ZP_Company_Id__c, map_opptyTypeToOppty);
			} else if (objOpp.isClosed && objOpp.Source_ID__c != null) {
				map_opptyIdCustomToOpp.put(objOpp.Source_ID__c, objOpp);
			}
		}
		return map_sourceIdToOppTypeMap;
	}

	// populating HI_State__c object fields
	public HI_Upsell_Information__c setProcessingState(String strProcessingState, String strMessage, HI_Upsell_Information__c objUpsell) {
		objUpsell.Processing_State__c = strProcessingState;
		objUpsell.Message__c = objUpsell.Message__c + '-' + strMessage;
		objUpsell.Last_Processed__c = System.now();
		return objUpsell;
	}

	/**
	 * @description   Method to get the Benefit Order record for Insert
	 *
	 * @author         Swati Arya
	 * @param oppObj  Opportunity record
	 * @param upsellInfoObj  HI Upsell Information record
	 * @param strRecordTypeName  String record type name
	 *
	 * @return Benefit_Order__c Returns the Benefit Order record to insert
	 */
	public Benefit_Order__c getBenefitOrderRecord(Opportunity oppObj, HI_Upsell_Information__c upsellInfoObj, String strRecordTypeName) {
		String strBenefitOrderName = oppObj.Name.left(80 - strRecordTypeName.length()) + strRecordTypeName;

		Benefit_Order__c objBenefitOrder = new Benefit_Order__c(
			RecordTypeId = idBORecord,
			Opportunity__c = oppObj.Id,
			Account__c = oppObj.AccountId,
			Name = strBenefitOrderName,
			BoR_Id__c = upsellInfoObj.External_Key__c,
			Order_Status__c = BenefitOrderUtil.STATUS_PENDING_ER_SIGNATURE,
			Qualification_Follow_Up_Date__c = Date.today()
		);

		return objBenefitOrder;
	}

	/**
	 * @description   Method to get the Carrier record for Insert
	 *
	 * @author         Swati Arya
	 * @param boObj  Benefit Order record
	 *
	 * @return Carrier_Order__c Returns the Carrier record to insert
	 */
	private Carrier_Order__c getCarrierOrderRecord(Benefit_Order__c objBenefitOrder) {
		String strBenefitOrderName = objBenefitOrder.Name;
		if (String.isNotBlank(strBenefitOrderName) && strBenefitOrderName.indexOf(' - ') > 0) {
			strBenefitOrderName = strBenefitOrderName.subString(0, strBenefitOrderName.indexOf(' - ')) + ' - ' + objCarrier.Name;
		}

		Carrier_Order__c objCarrierOrder = new Carrier_Order__c(
			Name = strBenefitOrderName,
			Benefit_Order__c = objBenefitOrder.Id,
			RecordTypeId = idCORecord,
			Implementation_Stage__c = CarrierOrderUtil.IMPLEMENTATION_STAGE_PENDING_ER,
			Carrier__c = objCarrier.Id
		);

		return objCarrierOrder;
	}

	/**
	 * @description   Method to get the Policy record for Insert
	 *
	 * @author         Swati Arya
	 * @param oppObj  Opportunity Record
	 * @param upsellObj HI Upsell Information record
	 * @param strBenType  Benefit Type
	 *
	 * @return Policy__c Returns the policy record to insert
	 */
	private Policy__c getPolicyRecord(Opportunity objOpp, HI_Upsell_Information__c upsellObj, String strBenType) {
		Policy__c objPolicy = new Policy__c(
			Opportunity__c = objOpp.Id,
			Account__c = objOpp.AccountId, //Added by AKS dated 29th Sept 2020
			Id__c = objOpp.Id + '-' + strBenType,
			External_Key__c = objOpp.Id + '-' + strBenType,
			Benefit_Type__c = strBenType,
			Carrier__c = objCarrier.Id,
			Name = objCarrier.Name + strBenType,
			Integration_Id__c = upsellObj.Id__c
		);

		return objPolicy;
	}

	/**
	 * @description   Method to create the opportunity contact roles
	 *
	 * @author         Swati Arya
	 * @param map_OppHIUpsell Map of User Id to Opportunity Id record
	 *
	 * @return
	 */
	public void createOpportunityContactRoles(Map<string, Id> map_OppHIUpsell) {
		Map<String, Id> map_contactId = new Map<String, Id>();

		for (Contact objCon : [SELECT Id, ZP_User_Id__c FROM Contact WHERE ZP_User_Id__c IN :map_OppHIUpsell.keySet()]) {
			map_contactId.put(objCon.ZP_User_Id__c, objCon.Id);
		}
		
		if (map_contactId.isEmpty()) {
			return;
		} else {
			OpportunityContactRole objOpptyContactRole;
			List<OpportunityContactRole> list_oppContactRole = new List<OpportunityContactRole>();
			for (String strKey : map_contactId.keySet()) {
				//get Contact Id
				String strContactId = map_contactId.containsKey(strKey) ? map_contactId.get(strKey) : null;
				String strOppId = map_OppHIUpsell.containsKey(strKey) ? map_OppHIUpsell.get(strKey) : null;
				if (strContactId != null && strOppId != null) {
					list_oppContactRole.add(new OpportunityContactRole(OpportunityId = strOppId, ContactId = strContactId, Role = Label.Benefits_Admin));
				}
			}
			if (!list_oppContactRole.isEmpty()) {
				insert list_oppContactRole;
			}
		}
	}

	/**
	 * @description    Get the Opportunity record to insert
	 *
	 * @author         Swati Arya
	 * @param map_companyIdAccount contains map of Company Id to Account
	 * @param map_ZPUser Map of Id to ZP User record
	 * @param upsellObj HI_Upsell_Information record
	 * @param strUpsellObjType String benfit upsell type
	 *
	 * @return Opportunity Returns the Opportunity record to insert
	 */
	public Opportunity getOpportunityRecord(Map<String, Account> map_companyIdAccount, Map<string, ZP_User__c> map_ZPUser, HI_Upsell_Information__c upsellObj, String strUpsellObjType) {
		Opportunity objOpp = new Opportunity(
			Name = map_companyIdAccount?.get(upsellObj.Company_Id__c).Name,
			AccountId = map_companyIdAccount?.get(upsellObj.Company_Id__c).Id,
			RecordTypeId = idOppRecord,
			Type = strUpsellObjType,
			StageName = OpportunityUtil.SAL_STAGE,
			TAdA_Mode__c = upsellObj.Mode__c,
			closeDate = System.today() + 30,
			Source_ID__c = upsellObj.External_Key__c,
			Benefits_Notes__c = upsellObj.Benefit_Type__c,
			ID__c = HIUpsellInformationUtil.STR_HI_BENEFIT_INTEREST + upsellObj.Id__c
		);

		if (!map_ZPUser.isEmpty() && String.isNotBlank(upsellObj.User_Id__c) && map_ZPUser.containsKey(upsellObj.User_Id__c)) {
			objOpp.Users_Email__c = map_ZPUser.get(upsellObj.User_Id__c).Email__c;
		}
		return objOpp;
	}
}