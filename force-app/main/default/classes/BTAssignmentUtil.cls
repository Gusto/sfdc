/**
 * @name         BTAssignmentUtil
 * @author       Deepika
 * @date         24-02-2020
 * @description
 * @test class   BTAssignmentUtilTest
 **/
public with sharing class BTAssignmentUtil {
	public BTAssignmentUtil() {
	}

	//Advocate Assignment Logic Section======================Start=============================

	Map<String, Decimal> map_UserIdTadaOnlyCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdActiveBOCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdTadaCOCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdCOCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdCOLICount = new Map<String, Decimal>();
	public Map<String, Set<String>> map_skillTypeUserIds = new Map<String, Set<String>>();
	//this map is used to populate advocate to related Tada CO
	Map<String, Carrier_Order__c> map_BOIdTAdaCORec = new Map<String, Carrier_Order__c>();
	//Benefit Order BT recordtype Id
	String BO_BT_RT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Benefits BoR');
	Id iDBenefitTransferQueue = GlobalQueryHelper.getQueueNameAndIdMap(new Set<String>{BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE}).get(BTBOSideViewCtrl.BENEFIT_TRANSFER_QUEUE);

	//this map contains BOR user and Current Month Cap
	Map<String, Integer> map_UserIdCap = new Map<String, Integer>();

	Map<String, Decimal> map_BOIdLineItemCount = new Map<String, Decimal>();
	Map<String, Decimal> map_BOIdCOCount = new Map<String, Decimal>();

	//Multi-EIN functionality map to keep track of Child Multi-Ein BO Record Id and related account's Parent Id
	Map<String, String> map_MultiEinBOIdParentId = new Map<String, String>();
	//Multi-EIN functionality map to keep track of Parent Multi-Ein BO Record Id and related OwnerId
	Map<String, String> map_ParentMultiEinAccountIdOwnerId = new Map<String, String>();
	//Multi-EIN functionality map to keep track of Child Multi-Ein BO Records
	Map<Id, Benefit_Order__c> map_ChildMultiEinBOIdRecords = new Map<Id, Benefit_Order__c>();

	/*
    This method is called for BO advocate assignment from [BenefitOrderHelper] class from "beforeUpdate" method
    */
	public void processBOForAdvocateAssignment(list<Benefit_Order__c> list_BenefitOrders, Boolean isOOOContext) {
		List<Benefit_Order__c> list_BOsToAssignAdvocate = new List<Benefit_Order__c>();
		if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
			List<Benefit_Order__c> list_BOTadaOnly = new List<Benefit_Order__c>();
			List<Benefit_Order__c> list_BOExceptTadaOnly = new List<Benefit_Order__c>();
			Set<String> set_BOIds = new Set<String>();

			getUserData();
			getUserBasedBOData();
			getCapDetailsForRamping();

			for (Benefit_Order__c objBO : list_BenefitOrders) {
				if (objBO.Type__c == null) {
					return;
				}

				if (objBO.Type__c != null && objBO.Type__c == 'BOR TAdA Only') {
					list_BOTadaOnly.add(objBO);
				} else {
					list_BOExceptTadaOnly.add(objBO);
				}

				set_BOIds.add(objBO.Id);
			}

			if (set_BOIds.size() > 0) {
				getLineItemDetailsForNewBOs(set_BOIds);
			}

			if (list_BOTadaOnly.size() > 0) {
				list_BOsToAssignAdvocate.addAll(assignOwnerToBOTadaOnly(list_BOTadaOnly));
			}

			if (list_BOExceptTadaOnly.size() > 0) {
				list_BOsToAssignAdvocate.addAll(assignOwnerToBONONTadaOnly(list_BOExceptTadaOnly));
			}

			if (map_ChildMultiEinBOIdRecords.size() > 0 || map_ParentMultiEinAccountIdOwnerId.size() > 0) {
				syncMultiEinBORecordOwners();
			}

			if (map_BOIdTAdaCORec.size() > 0) {
				try {
					update map_BOIdTAdaCORec.values();
				} catch (exception ex) {
					ExceptionLogUtil.logException('BTAssignmentUtil', 'Update CO::processBOForAdvocateAssignment', ex.getMessage(), 'High');
				}
			}

			if (isOOOContext) {
				try {
					update list_BenefitOrders;
				} catch (exception ex) {
					ExceptionLogUtil.logException('BTAssignmentUtil', 'Update BO::processBOForAdvocateAssignment', ex.getMessage(), 'High');
				}
			}
		}
	}

	/**Using this method we are querying eligible,active,in office users that have the skills with the role of [Benefit Transfer Advocate] */
	public void getUserData() {
		Set<String> set_nonTadaUserId = new Set<String>();
		Set<String> set_TadaUserId = new Set<String>();

		for (User_Skill__c skillRec : [
			SELECT Id, User_Name__c, User_Role__c, User_Role__r.User__c, Skill_TADA_Check__c, User_Role__r.User__r.Out_Of_Office__c, User_Role__r.User__r.Back_In_Office_Date_Time__c
			FROM User_Skill__c
			WHERE Skill_Role_Name__c = 'Benefit Transfer Advocate' AND User_Role__r.User__r.IsActive = TRUE AND User_Role__r.User__r.Out_Of_Office__c = FALSE
		]) {
			if (skillRec.Skill_TADA_Check__c) {
				set_TadaUserId.add(skillRec.User_Role__r.User__c);
			} else {
				set_nonTadaUserId.add(skillRec.User_Role__r.User__c);
			}
		}

		if (set_TadaUserId.size() > 0) {
			map_skillTypeUserIds.put('tada', set_TadaUserId);
		}

		if (set_nonTadaUserId.size() > 0) {
			if (set_TadaUserId.size() > 0) {
				set_nonTadaUserId.removeAll(set_TadaUserId);
			}
			map_skillTypeUserIds.put('bor', set_nonTadaUserId);
		}
	}

	public void getCapDetailsForRamping() {
		if (
			map_skillTypeUserIds.size() > 0 &&
			((map_skillTypeUserIds.containsKey('bor') && map_skillTypeUserIds.get('bor').size() > 0) || (map_skillTypeUserIds.containsKey('tada') && map_skillTypeUserIds.get('tada').size() > 0))
		) {
			Integer intCurrentMonth = System.today().month();
			Integer intCurrentYear = System.today().year();
			for (Benefit_Order_Allocation__c objAllocation : [
				SELECT Id, Max_BO__c, User_Role__r.User__c
				FROM Benefit_Order_Allocation__c
				WHERE
					RecordType.Name = 'Benefits'
					AND Role_Type__c = 'Advocate'
					AND (User_Role__r.User__c IN :map_skillTypeUserIds.get('bor')
					OR User_Role__r.User__c IN :map_skillTypeUserIds.get('tada'))
					AND Month__c = :intCurrentMonth
					AND Year__c = :intCurrentYear
			]) {
				map_UserIdCap.put(objAllocation.User_Role__r.User__c, Integer.valueOf(objAllocation.Max_BO__c));
			}
		}
	}

	/**Using this method we query out the current open BO records owned by the eligible Users queried in [getUserData] method*/
	public void getUserBasedBOData() {
		if (map_skillTypeUserIds.size() > 0) {
			Set<String> set_EligibleUserIds = new Set<String>();

			//main map
			map_UserIdTadaOnlyCount = new Map<String, Decimal>();
			map_UserIdActiveBOCount = new Map<String, Decimal>();
			map_UserIdTadaCOCount = new Map<String, Decimal>();
			map_UserIdCOCount = new Map<String, Decimal>();
			map_UserIdCOLICount = new Map<String, Decimal>();

			if (map_skillTypeUserIds.containsKey('tada')) {
				set_EligibleUserIds.addAll(map_skillTypeUserIds.get('tada'));
				for (String strUserId : set_EligibleUserIds) {
					map_UserIdTadaOnlyCount.put(strUserId, 0);
				}
			}

			if (map_skillTypeUserIds.containsKey('bor')) {
				set_EligibleUserIds.addAll(map_skillTypeUserIds.get('bor'));
			}

			//We are prepopulating the maps with eligible users to include users that do not own a single BO record
			for (String strUserId : set_EligibleUserIds) {
				map_UserIdActiveBOCount.put(strUserId, 0);
				map_UserIdTadaCOCount.put(strUserId, 0);
				map_UserIdCOCount.put(strUserId, 0);
				map_UserIdCOLICount.put(strUserId, 0);
			}

			Set<String> set_ToExcludeOrderStatus = new Set<String>{ 'Canceled', 'Closed Lost', 'Closed Admin', 'Fulfilled' };

			//Owner.Type = 'User' AND
			for (Benefit_Order__c objBO : [
				SELECT Id, OwnerId, Type__c, Is_Multi_EIN__c, Initial_Owner__c, (SELECT Id, OwnerId, Is_Multi_EIN__c FROM Carrier_Orders__r)
				FROM Benefit_Order__c
				WHERE OwnerId IN :set_EligibleUserIds AND RecordTypeId = :BO_BT_RT_ID AND Order_Status__c NOT IN :set_ToExcludeOrderStatus
			]) {
				if (objBO.Type__c != null && objBO.Type__c == 'BOR TAdA Only') {
					if (map_UserIdTadaOnlyCount.containsKey(objBO.OwnerId)) {
						map_UserIdTadaOnlyCount.put(objBO.OwnerId, map_UserIdTadaOnlyCount.get(objBO.OwnerId) + 1);
					}
				}

				if (map_UserIdActiveBOCount.containsKey(objBO.OwnerId)) {
					if (objBO.Is_Multi_EIN__c == false) {
						map_UserIdActiveBOCount.put(objBO.OwnerId, map_UserIdActiveBOCount.get(objBO.OwnerId) + 1);
					} else {
						map_UserIdActiveBOCount.put(objBO.OwnerId, map_UserIdActiveBOCount.get(objBO.OwnerId) + 0.5);
					}
				}

				if (objBO.Type__c != null && objBO.Type__c.indexOf('TAdA') > -1) {
					if (map_UserIdTadaCOCount.containsKey(objBO.OwnerId)) {
						map_UserIdTadaCOCount.put(objBO.OwnerId, map_UserIdTadaCOCount.get(objBO.OwnerId) + 1);
					}
				}

				if (objBO.Carrier_Orders__r != null && objBO.Carrier_Orders__r.size() > 0) {
					Decimal decCOCount = 0;
					if (objBO.Is_Multi_EIN__c) {
						if (objBO.Type__c != null && objBO.Type__c.indexOf('TAdA') > -1) {
							if (objBO.Type__c == 'BOR TAdA Only') {
								decCOCount = 1;
							} else {
								decCOCount = objBO.Carrier_Orders__r.size();
								decCOCount = ((decCOCount - 1) / 2) + 1; //subtract tada CO + count all the other CO as half + add 1 for Tada CO back
							}
						} else {
							decCOCount = objBO.Carrier_Orders__r.size();
							decCOCount = decCOCount / 2;
						}
					} else {
						decCOCount = objBO.Carrier_Orders__r.size();
					}

					if (map_UserIdCOCount.containsKey(objBO.OwnerId)) {
						map_UserIdCOCount.put(objBO.OwnerId, map_UserIdCOCount.get(objBO.OwnerId) + decCOCount);
					}
				}
			}

			for (Carrier_Order_Line_Item__c objLI : [
				SELECT Id, Carrier_Order__r.Benefit_Order__r.OwnerId
				FROM Carrier_Order_Line_Item__c
				WHERE
					Carrier_Order__r.Benefit_Order__r.OwnerId IN :set_EligibleUserIds
					AND Carrier_Order__r.Benefit_Order__r.Owner.Type = 'User'
					AND Carrier_Order__r.Benefit_Order__r.RecordTypeId = :BO_BT_RT_ID
					AND Carrier_Order__r.Benefit_Order__r.Order_Status__c NOT IN :set_ToExcludeOrderStatus
			]) {
				if (map_UserIdCOLICount.containsKey(objLI.Carrier_Order__r.Benefit_Order__r.OwnerId)) {
					map_UserIdCOLICount.put(objLI.Carrier_Order__r.Benefit_Order__r.OwnerId, map_UserIdCOLICount.get(objLI.Carrier_Order__r.Benefit_Order__r.OwnerId) + 1);
				}
			}
		}
	}

	//this methods is used to query out related COs and COLineItems for related BOs.
	void getLineItemDetailsForNewBOs(set<String> set_BOIds) {
		if (set_BOIds != null && set_BOIds.size() > 0) {
			map_BOIdLineItemCount = new Map<String, Decimal>();
			map_BOIdCOCount = new Map<String, Decimal>();

			for (Carrier_Order__c objCO : [
				SELECT
					Id,
					Name,
					Benefit_Order__c,
					Benefit_Order__r.Is_Multi_EIN__c,
					Benefit_Order__r.Opportunity__r.Account.ParentId,
					Benefit_Order__r.Opportunity__r.AccountId,
					Carrier__r.Name,
					TAdA__c,
					Initial_Owner__c,
					(SELECT Id FROM Carrier_Order_Line_Item__r)
				FROM Carrier_Order__c
				WHERE Benefit_Order__c IN :set_BOIds
			]) {
				if (objCO.Carrier_Order_Line_Item__r != null && objCO.Carrier_Order_Line_Item__r.size() > 0) {
					if (map_BOIdLineItemCount.containsKey(objCO.Benefit_Order__c)) {
						map_BOIdLineItemCount.put(objCO.Benefit_Order__c, map_BOIdLineItemCount.get(objCO.Benefit_Order__c) + objCO.Carrier_Order_Line_Item__r.size());
					} else {
						map_BOIdLineItemCount.put(objCO.Benefit_Order__c, objCO.Carrier_Order_Line_Item__r.size());
					}
				} else {
					map_BOIdLineItemCount.put(objCO.Benefit_Order__c, 0);
				}

				if (map_BOIdCOCount.containsKey(objCO.Benefit_Order__c)) {
					map_BOIdCOCount.put(objCO.Benefit_Order__c, map_BOIdCOCount.get(objCO.Benefit_Order__c) + 1);
				} else {
					map_BOIdCOCount.put(objCO.Benefit_Order__c, 1);
				}

				if (objCO.TAdA__c) {
					map_BOIdTAdaCORec.put(objCO.Benefit_Order__c, objCO);
				}

				//By: PR, Date: March-31-2020, Desc: storing the Parent Account details for child Multi-EIN BO records.
				if (objCO.Benefit_Order__r.Is_Multi_EIN__c == true) {
					if (objCO.Benefit_Order__r.Opportunity__r.Account.ParentId != null) {
						map_MultiEINBOIdParentId.put(objCO.Benefit_Order__c, objCO.Benefit_Order__r.Opportunity__r.Account.ParentId);
					}
				}
			}
		}
	}

	//this method handles "Tada Only" BOs
	public List<Benefit_Order__c> assignOwnerToBOTadaOnly(list<Benefit_Order__c> list_BOTadaOnly) {
		List<Benefit_Order__c> list_BOsToAssignAdvocate = new List<Benefit_Order__c>();
		if (list_BOTadaOnly != null && list_BOTadaOnly.size() > 0) {
			for (Benefit_Order__c objBO : list_BOTadaOnly) {
				objBO.Assignment_Message__c = '';
				//Stop child Multi-EIN From running Assignment logic
				if (objBO.Is_Multi_EIN__c && map_MultiEinBOIdParentId.size() > 0 && map_MultiEinBOIdParentId.containsKey(objBO.Id)) {
					map_ChildMultiEinBOIdRecords.put(objBO.Id, objBO);
					continue;
				}

				Decimal intLowestCount;
				list<String> list_UserId = new List<String>();
				if (map_UserIdTadaOnlyCount.size() > 0) {
					for (String idUser : map_UserIdTadaOnlyCount.keySet()) {
						Decimal intTemp = map_UserIdTadaOnlyCount.get(idUser);
						if (intLowestCount == null) {
							intLowestCount = intTemp;
							list_UserId.add(idUser);
							continue;
						}

						if (intLowestCount == intTemp) {
							list_UserId.add(idUser);
							continue;
						}

						if (intLowestCount > intTemp) {
							intLowestCount = intTemp;
							list_UserId = new List<String>();
							list_UserId.add(idUser);
						}
					}
				}

				if (list_UserId.size() > 0) {
					objBO.OwnerId = list_UserId.get(0);
					objBO.Assignment_Message__c = 'SUCCESS: BoR-TAda only.';
					if (objBO.Initial_Owner__c == null)
						objBO.Initial_Owner__c = objBO.OwnerId;
					if (map_BOIdTAdaCORec.containsKey(objBO.Id)) {
						map_BOIdTAdaCORec.get(objBO.Id).OwnerId = objBO.OwnerId;
						if (map_BOIdTAdaCORec.get(objBO.Id).Initial_Owner__c == null)
							map_BOIdTAdaCORec.get(objBO.Id).Initial_Owner__c = objBO.OwnerId;
					}

					map_UserIdTadaOnlyCount.put(objBO.OwnerId, map_UserIdTadaOnlyCount.get(objBO.OwnerId) + 1);
					map_UserIdActiveBOCount.put(objBO.OwnerId, map_UserIdActiveBOCount.get(objBO.OwnerId) + 1);
					map_UserIdTadaCOCount.put(objBO.OwnerId, map_UserIdTadaCOCount.get(objBO.OwnerId) + 1);
					map_UserIdCOCount.put(objBO.OwnerId, map_UserIdCOCount.get(objBO.OwnerId) + 1);
					map_UserIdCOLICount.put(objBO.OwnerId, map_UserIdCOLICount.get(objBO.OwnerId) + map_BOIdLineItemCount.get(objBO.Id));

					if (objBO.Is_Multi_EIN__c && (map_MultiEinBOIdParentId.size() == 0 || !map_MultiEinBOIdParentId.containsKey(objBO.Id))) {
						map_ParentMultiEinAccountIdOwnerId.put(objBO.Account__c, objBO.OwnerId);
					}
				} else {
					//In case we can not assign the BO, we need to assign it to Benefits Transfer Queue BBO-2047
					objBO.Assignment_Message__c = 'ERROR: Eligible user not found : BoR-TAda only. Assigned to Benefits Transfer Queue';
					objBO.OwnerId = iDBenefitTransferQueue;
				}
				list_BOsToAssignAdvocate.add(objBO);
			}
		}
		return list_BOsToAssignAdvocate;
	}

	boolean isTadaBOInProcess;
	//this method is called to process all the BO object records except [BOR Tada Only] records
	public List<Benefit_Order__c> assignOwnerToBONONTadaOnly(list<Benefit_Order__c> list_BOExceptTadaOnly) {
		List<Benefit_Order__c> list_BOsToAssignAdvocate = new List<Benefit_Order__c>();
		if (list_BOExceptTadaOnly != null && list_BOExceptTadaOnly.size() > 0) {
			for (Benefit_Order__c objBO : list_BOExceptTadaOnly) {
				objBO.Assignment_Message__c = '';

				//Stop child Multi-EIN From running Assignment logic
				if (objBO.Is_Multi_EIN__c && map_MultiEinBOIdParentId.size() > 0 && map_MultiEinBOIdParentId.containsKey(objBO.Id)) {
					map_ChildMultiEinBOIdRecords.put(objBO.Id, objBO);
					continue;
				}

				isTadaBOInProcess = false;
				if (objBO.Type__c != null && objBO.Type__c.indexOf('TAdA') > -1) {
					isTadaBOInProcess = true;
				}

				boolean isUserAssigned = false;

				//level 2 qualification [how many in-process (active) BoRs do they currently own? ]
				list<String> list_LowestActiveBOCountUsers = getOwnerBasedOnLowestActiveBOCount();

				if (list_LowestActiveBOCountUsers != null && list_LowestActiveBOCountUsers.size() == 1) {
					objBO.OwnerId = list_LowestActiveBOCountUsers.get(0);
					objBO.Assignment_Message__c = 'SUCCESS: Active Benefit Order Count.';
					if (objBO.Initial_Owner__c == null)
						objBO.Initial_Owner__c = objBO.OwnerId;
					isUserAssigned = true;
				} else if ((list_LowestActiveBOCountUsers != null && list_LowestActiveBOCountUsers.size() > 1)) {
					//level 3 qualification [Whoever has the lower amount of open carrier orders with TaDa]
					list<String> list_EligibleUsersWithLowestTadaCOCount = getEligibleUsersWithLowestCount(list_LowestActiveBOCountUsers, map_UserIdTadaCOCount);

					if (list_EligibleUsersWithLowestTadaCOCount != null && list_EligibleUsersWithLowestTadaCOCount.size() == 1) {
						objBO.OwnerId = list_EligibleUsersWithLowestTadaCOCount.get(0);
						objBO.Assignment_Message__c = 'SUCCESS: TAda Carrier Order Count.';
						if (objBO.Initial_Owner__c == null)
							objBO.Initial_Owner__c = objBO.OwnerId;
						isUserAssigned = true;
					} else if ((list_EligibleUsersWithLowestTadaCOCount != null && list_EligibleUsersWithLowestTadaCOCount.size() > 1)) {
						//level 4 qualification [# of Open Carrier orders attached to the main BoR]
						list<String> list_EligibleUsersWithLowsetCOCount = getEligibleUsersWithLowestCount(list_EligibleUsersWithLowestTadaCOCount, map_UserIdCOCount);

						if ((list_EligibleUsersWithLowsetCOCount != null && list_EligibleUsersWithLowsetCOCount.size() == 1)) {
							objBO.OwnerId = list_EligibleUsersWithLowsetCOCount.get(0);
							objBO.Assignment_Message__c = 'SUCCESS: Carrier Order Count.';
							if (objBO.Initial_Owner__c == null)
								objBO.Initial_Owner__c = objBO.OwnerId;
							isUserAssigned = true;
						} else if ((list_EligibleUsersWithLowsetCOCount != null && list_EligibleUsersWithLowsetCOCount.size() > 1)) {
							//level 5 qualification [# of Lines of coverage on open carrier order]
							list<String> list_EligibleUserWithLowestLineItemCount = getEligibleUsersWithLowestCount(list_EligibleUsersWithLowsetCOCount, map_UserIdCOLICount);

							if (list_EligibleUserWithLowestLineItemCount != null && list_EligibleUserWithLowestLineItemCount.size() == 1) {
								objBO.OwnerId = list_EligibleUserWithLowestLineItemCount.get(0);
								objBO.Assignment_Message__c = 'SUCCESS: Carrier Line Item Count.';
								if (objBO.Initial_Owner__c == null)
									objBO.Initial_Owner__c = objBO.OwnerId;
								isUserAssigned = true;
							} else if (list_EligibleUserWithLowestLineItemCount != null && list_EligibleUserWithLowestLineItemCount.size() > 1) {
								objBO.OwnerId = list_EligibleUserWithLowestLineItemCount.get(0);
								objBO.Assignment_Message__c = 'SUCCESS: Carrier Line Item Count - First User.';
								if (objBO.Initial_Owner__c == null)
									objBO.Initial_Owner__c = objBO.OwnerId;
								isUserAssigned = true;
							} else {
								objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Carrier Line Item Count. Assigned to Benefits Transfer Queue';
								objBO.OwnerId = iDBenefitTransferQueue;
							}
						} else {
							objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Carrier Order Count. Assigned to Benefits Transfer Queue';
							objBO.OwnerId = iDBenefitTransferQueue;
						}
					} else {
						objBO.Assignment_Message__c = 'ERROR: Eligible user not found : TAda Carrier Order Count. Assigned to Benefits Transfer Queue';
						objBO.OwnerId = iDBenefitTransferQueue;
					}
				} else {
					//In case we can not assign the BO, we need to assign it to Benefits Transfer Queue BBO-2047
					objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Active Benefit Order Count. Assigned to Benefits Transfer Queue';
					objBO.OwnerId = iDBenefitTransferQueue;
				}
				list_BOsToAssignAdvocate.add(objBO);

				/*we are using the below code to maintain the correct record counts in the master maps that we are maintaining
                Below code is to handle the code in case assignment receives more than one [Benefit_Order__c] object records.
                */
				if (isUserAssigned) {
					if (objBO.Is_Multi_EIN__c && (map_MultiEinBOIdParentId.size() == 0 || !map_MultiEinBOIdParentId.containsKey(objBO.Id))) {
						map_ParentMultiEinAccountIdOwnerId.put(objBO.Account__c, objBO.OwnerId);
					}

					if (isTadaBOInProcess) {
						map_UserIdActiveBOCount.put(objBO.OwnerId, map_UserIdActiveBOCount.get(objBO.OwnerId) + 1);
						map_UserIdTadaCOCount.put(objBO.OwnerId, map_UserIdTadaCOCount.get(objBO.OwnerId) + 1);
						map_UserIdCOCount.put(objBO.OwnerId, map_UserIdCOCount.get(objBO.OwnerId) + map_BOIdCOCount.get(objBO.Id));
						map_UserIdCOLICount.put(objBO.OwnerId, map_UserIdCOLICount.get(objBO.OwnerId) + map_BOIdLineItemCount.get(objBO.Id));

						if (map_BOIdTAdaCORec.containsKey(objBO.Id)) {
							map_BOIdTAdaCORec.get(objBO.Id).OwnerId = objBO.OwnerId;
							if (map_BOIdTAdaCORec.get(objBO.Id).Initial_Owner__c == null)
								map_BOIdTAdaCORec.get(objBO.Id).Initial_Owner__c = objBO.OwnerId;
						}
					} else {
						map_UserIdActiveBOCount.put(objBO.OwnerId, map_UserIdActiveBOCount.get(objBO.OwnerId) + 1);
						if (map_UserIdCOCount.get(objBO.OwnerId) != null && map_BOIdCOCount.get(objBO.Id) != null) {
							map_UserIdCOCount.put(objBO.OwnerId, map_UserIdCOCount.get(objBO.OwnerId) + map_BOIdCOCount.get(objBO.Id));
						}

						if (map_UserIdCOLICount.get(objBO.OwnerId) != null && map_BOIdLineItemCount.get(objBO.Id) != null) {
							map_UserIdCOLICount.put(objBO.OwnerId, map_UserIdCOLICount.get(objBO.OwnerId) + map_BOIdLineItemCount.get(objBO.Id));
						}
					}
				}
			}
		}
		return list_BOsToAssignAdvocate;
	}

	//By: PR, Date: March-27-2020, Desc: Following method is querying parent Multi-EIN BOs and updating the Owner of the child Multi-EIN BOs
	public void syncMultiEinBORecordOwners() {
		Set<String> set_ExcludeClosedBO = Utils.setBOExclude;
		//This set will contain all the parent Account Ids
		Set<String> set_ParentAccoutIds = new Set<String>();

		//get parent account of all the Child Multi-EIN BOs included in the Assignment
		if (map_MultiEinBOIdParentId.size() > 0) {
			set_ParentAccoutIds.addAll(map_MultiEinBOIdParentId.values());
		}

		//get account of all the parent Multi-EIN BOs included in the Assignment
		if (map_ParentMultiEinAccountIdOwnerId.size() > 0) {
			set_ParentAccoutIds.addAll(map_ParentMultiEinAccountIdOwnerId.keyset());
		}

		if (set_ParentAccoutIds.size() > 0) {
			Map<String, String> map_ParentAccountIdOwnerId = new Map<String, String>();
			List<Benefit_Order__c> list_ToUpdateChildBOs = new List<Benefit_Order__c>();

			//querying all the Multi-EIN BOs related to the Accounts whose related BOs are part of Advocate assignment
			for (Benefit_Order__c objBO : [
				SELECT Id, OwnerId, Opportunity__r.AccountId, Opportunity__r.Account.ParentId, Initial_Owner__c
				FROM Benefit_Order__c
				WHERE
					(Opportunity__r.AccountId IN :set_ParentAccoutIds
					OR Opportunity__r.Account.ParentId IN :set_ParentAccoutIds)
					AND RecordTypeId = :BO_BT_RT_ID
					AND Order_Status__c NOT IN :set_ExcludeClosedBO
			]) {
				if (objBO.Opportunity__r.Account.ParentId == null) {
					//if parent BOs is part of the assignment we want to skip the owner storage
					if (!map_ParentMultiEinAccountIdOwnerId.containsKey(objBO.Opportunity__r.AccountId)) {
						map_ParentMultiEinAccountIdOwnerId.put(objBO.Opportunity__r.AccountId, objBO.OwnerId);
					}
					map_ParentAccountIdOwnerId.put(objBO.Opportunity__r.AccountId, objBO.Id);
				}

				//if BO is Child we want to get the BO and Parent Account relationship
				if (objBO.Opportunity__r.Account.ParentId != null && !map_ChildMultiEinBOIdRecords.containsKey(objBO.Id)) {
					list_ToUpdateChildBOs.add(objBO);
					map_MultiEinBOIdParentId.put(objBO.Id, objBO.Opportunity__r.Account.ParentId);
				}
			}

			//loop on all the child BOs included in the Advocate Assignmet [we do not have to perform DML on them]
			for (Benefit_Order__c objBO : map_ChildMultiEinBOIdRecords.values()) {
				String strParentId = map_MultiEinBOIdParentId.get(objBO.Id);
				if (map_ParentMultiEinAccountIdOwnerId.containsKey(strParentId)) {
					objBO.OwnerId = map_ParentMultiEinAccountIdOwnerId.get(strParentId);
					// SJay - 08/6/2020 - Added check for BO Owner to be a user and not a Queue.
					if (String.isNotBlank(objBO.OwnerId)) {
						String preFix = String.valueOf(objBO.OwnerId).left(3).toLowercase();
						if (preFix == '005')
							objBO.Initial_Owner__c = objBO.OwnerId;
					}

					objBO.Parent_Benefit_Order__c = map_ParentAccountIdOwnerId.get(strParentId);
				}
			}

			if (map_ChildMultiEinBOIdRecords.size() > 0) {
				BenefitOrderHelper.skipTrigger = false;
			}

			if (list_ToUpdateChildBOs.size() > 0) {
				//loop for All the child BOs that are not part of the Advocate Assignment
				for (Benefit_Order__c objBO : list_ToUpdateChildBOs) {
					String strParentId = map_MultiEinBOIdParentId.get(objBO.Id);
					if (map_ParentMultiEinAccountIdOwnerId.containsKey(strParentId)) {
						objBO.OwnerId = map_ParentMultiEinAccountIdOwnerId.get(strParentId);
						// SJay - 08/6/2020 - Added check for BO Owner to be a user and not a Queue.
						if (String.isNotBlank(objBO.OwnerId)) {
							String preFix = String.valueOf(objBO.OwnerId).left(3).toLowercase();
							if (preFix == '005')
								objBO.Initial_Owner__c = objBO.OwnerId;
						}
						objBO.Parent_Benefit_Order__c = map_ParentAccountIdOwnerId.get(strParentId);
					}
				}

				try {
					boolean blnPreviousVal = BenefitOrderHelper.skipTrigger;
					BenefitOrderHelper.skipTrigger = false;
					update list_ToUpdateChildBOs;
					BenefitOrderHelper.skipTrigger = blnPreviousVal;
				} catch (exception ex) {
					ExceptionLogUtil.logException('BTAssignmentUtil', 'syncMultiEinBORecordOwners', 'Error while updating Child Multi-EIN Benefit Order with Advocate :- ' + ex.getMessage(), 'high');
				}
			}
		}
	}

	//this method uses [map_UserIdActiveBOCount] map to get the user/users with lowest Active BO Count
	public list<String> getOwnerBasedOnLowestActiveBOCount() {
		list<String> list_EligibleUsers = new List<String>();

		if (map_UserIdActiveBOCount.size() > 0) {
			Decimal intLowestCount;
			set<String> set_BOROnlyUserIds = new Set<String>();
			if (isTadaBOInProcess) {
				set_BOROnlyUserIds = map_skillTypeUserIds.get('bor');
			}

			for (String strUserId : map_UserIdActiveBOCount.keySet()) {
				//for tada BOs we want to skip [NON Tada] users
				if (set_BOROnlyUserIds.size() > 0 && set_BOROnlyUserIds.contains(strUserId)) {
					continue;
				}

				//CAP implementation logic
				if (map_UserIdCap.containsKey(strUserId) && map_UserIdActiveBOCount.get(strUserId) >= map_UserIdCap.get(strUserId)) {
					continue;
				}

				Decimal intTemp = map_UserIdActiveBOCount.get(strUserId);
				if (intLowestCount == null) {
					intLowestCount = intTemp;
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount == intTemp) {
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount > intTemp) {
					intLowestCount = intTemp;
					list_EligibleUsers = new List<String>();
					list_EligibleUsers.add(strUserId);
				}
			}
		}

		return list_EligibleUsers;
	}

	//This is util method, this method receive [last criteria eligible user ids] and [next criteria related userId and record count map ]
	public list<String> getEligibleUsersWithLowestCount(List<String> list_PreviousEligibleUserIds, Map<String, Decimal> map_UserRecordCount) {
		list<String> list_EligibleUsers = new List<String>();

		if (list_PreviousEligibleUserIds != null && map_UserRecordCount != null && list_PreviousEligibleUserIds.size() > 0 && map_UserRecordCount.size() > 0) {
			Decimal intLowestCount;
			for (String strUserId : list_PreviousEligibleUserIds) {
				//For ramping purpose - CAP implementation logic
				if (!isTadaBOInProcess) {
					if (map_UserIdCap.containsKey(strUserId) && map_UserIdActiveBOCount.get(strUserId) >= map_UserIdCap.get(strUserId)) {
						continue;
					}
				}

				Decimal intTemp = map_UserRecordCount.get(strUserId);
				if (intLowestCount == null) {
					intLowestCount = intTemp;
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount == intTemp) {
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount > intTemp) {
					intLowestCount = intTemp;
					list_EligibleUsers = new List<String>();
					list_EligibleUsers.add(strUserId);
				}
			}
		}

		return list_EligibleUsers;
	}

	//Advocate Assignment Logic Section======================End=============================

	//Facilitator Assignment Logic Section ==================Start===========================

	//Map contains the key as POD name and values as set of User Ids that belong to that POD
	@TestVisible
	Map<String, Set<String>> map_PODWithUserIds = new Map<String, Set<String>>();
	// Map contains the key as the User Id  and values as a Carrier order count that user already have
	Map<String, Integer> map_UserIdWithCOCount = new Map<String, Integer>();
	// Map contains the key as the User Id  and values as a Document collected
	Map<String, Integer> map_UserIdWithDocCollected = new Map<String, Integer>();
	// Map contains the key as the User Id  and values as a Total Document
	Map<String, Integer> map_UserIdWithTotalDocument = new Map<String, Integer>();
	String CO_BT_RT_ID = Cache.getRecordTypeId('Carrier_Order__c', 'Benefits BoR');
	static String CO_STAGE_COLLECTING_DOCUMENTS = 'Collecting Documents';
	//Set<String> set_ToExcludeCOStatus = new Set<String>{'Canceled','Approved','Closed Admin','Blocked'};
	List<Carrier_Order__c> list_CarrierOrderToUpdate = new List<Carrier_Order__c>();
	Map<Id, Id> map_ParentCarrierOrder = new Map<Id, Id>();

	/*
    This method is called for CO Facilitator 1 assignment from [BenefitOrderHelper] class from "afterUpdate" method
    and From CarrierOrderHelper class from "before insert" method
    */
	public List<Carrier_Order__c> processCOForFacilitator1Assignment(List<Carrier_Order__c> list_CarrierOrder, List<Carrier_Order__c> list_TADACarrierOrders) {
		if (!list_CarrierOrder.isEmpty()) {
			Set<String> strPOD = new Set<String>{ 'POD 1', 'POD 2', 'POD 3' };
			Set<Id> set_ParentId = new Set<Id>();
			Set<ID> set_AlreadyCOId = new Set<Id>();

			for (Carrier_Order__c objCO : list_CarrierOrder) {
				if (objCO.Is_Multi_EIN__c) {
					if (objCO.Parent_Carrier_Order__c != null) {
						set_ParentId.add(objCO.Parent_Carrier_Order__c);
					} else {
						set_ParentId.add(objCO.Id);
					}
				}
				set_AlreadyCOId.add(objCO.Id);
			}

			if (!set_ParentId.isEmpty()) {
				for (Carrier_Order__c objCO : [
					SELECT
						id,
						Benefit_Order__c,
						Benefit_Order__r.RecordTypeId,
						Additional_Details__c,
						Implementation_Stage__c,
						Stage_Detail__c,
						RecordTypeId,
						Open_Enrollment_Start_Date__c,
						Start_Date__c,
						Open_Enrollment_End_Date__c,
						Carrier__r.BT_Facilitator_POD__c,
						Carrier__r.Name,
						Total_Number_Of_Documents__c,
						Number_Of_Collected_Documents__c,
						OwnerId,
						OOO_Timestamp__c,
						Initial_Owner__c,
						Is_Multi_EIN__c,
						TAdA__c,
						Parent_Carrier_Order__c
					FROM Carrier_Order__c
					WHERE
						Is_Multi_EIN__c = TRUE
						AND (ID IN :set_ParentId
						OR Parent_Carrier_Order__c IN :set_ParentId)
						AND Carrier__r.Partner_type__c != :CarrierOrderUtil.PARTNER_TYPE_TADA
						AND Benefit_Order__r.Start_Date__c != NULL
						AND Implementation_Stage__c NOT IN :Utils.setCOExclude
				]) {
					if (objCO.Is_Multi_EIN__c && objCO.Parent_Carrier_Order__c == null && String.valueOf(objCO.OwnerId).startsWith('005')) {
						map_ParentCarrierOrder.put(objCO.Id, objCO.OwnerId);
					} else if (objCO.Is_Multi_EIN__c && objCO.Parent_Carrier_Order__c != null && !String.valueOf(objCO.OwnerId).startsWith('005')) {
						if (!set_AlreadyCOId.contains(objCO.OwnerId)) {
							list_CarrierOrder.add(objCO);
						}
					}
				}
			}

			getUserDataForFAC1(strPOD);
			getUserDataAsPerCOForFAC1();
			assignFacilitator1OwnerCO(list_CarrierOrder, list_TADACarrierOrders);
			return list_CarrierOrderToUpdate;
		}
		return null;
	}

	/** This method is used to get all the User Id as per their pod */
	public void getUserDataForFAC1(Set<String> strPOD) {
		if (!strPOD.isEmpty()) {
			List<User_Skill__c> listUserSkill = [
				SELECT User_Role__r.User__c, Skill__r.POD_Skills__c
				FROM User_Skill__c
				WHERE
					User_Role__r.User__r.isActive = TRUE
					AND User_Role__r.User__r.Out_Of_Office__c = FALSE
					AND User_Skill_Role_Name__c = 'Benefit Transfer Facilitator 1'
					AND Skill__r.POD_Skills__c IN :strPOD
			];
			if (!listUserSkill.isEmpty()) {
				Set<String> set_AllUserIDs = new Set<String>();
				for (User_Skill__c objuserSkill : listUserSkill) {
					Set<String> set_UserIDs = new Set<String>();
					if (!map_PODWithUserIds.isEmpty() && map_PODWithUserIds.containsKey(objuserSkill.Skill__r.POD_Skills__c)) {
						set_UserIDs = map_PODWithUserIds.get(objuserSkill.Skill__r.POD_Skills__c);
					}
					set_UserIDs.add(objuserSkill.User_Role__r.User__c);
					set_AllUserIDs.addAll(set_UserIDs);
					map_PODWithUserIds.put(objuserSkill.Skill__r.POD_Skills__c, set_UserIDs);
				}
				if (!map_PODWithUserIds.isEmpty()) {
					map_PODWithUserIds.put('Unassigned', set_AllUserIDs);
				}
			}
		}
	}
	/** This method is used to get all the User Id with thier Carrier order count */
	public void getUserDataAsPerCOForFAC1() {
		if (!map_PODWithUserIds.isEmpty() && map_PODWithUserIds.containsKey('Unassigned')) {
			//intialize all user with CO count 0 and Percentage of document Collected 0
			for (String strUserId : map_PODWithUserIds.get('Unassigned')) {
				map_UserIdWithCOCount.put(strUserId, 0);
				map_UserIdWithDocCollected.put(strUserId, 0);
				map_UserIdWithTotalDocument.put(strUserId, 0);
			}
			List<AggregateResult> list_AggregateResult = [
				SELECT
					OwnerId,
					COUNT(ID) COCount,
					SUM(Number_Of_Collected_Documents__c) CollectedDocs,
					SUM(Total_Number_Of_Documents__c) TotalDocs,
					SUM(Total_No_Of_Docs_Required_to_Collect__c) LeftDocs
				FROM Carrier_order__c
				WHERE
					RecordTypeID = :CO_BT_RT_ID
					AND OwnerId IN :map_PODWithUserIds.get('Unassigned')
					AND Number_Of_Collected_Documents__c != NULL
					AND Total_No_Of_Docs_Required_to_Collect__c != NULL
					AND Total_Number_Of_Documents__c != NULL
					AND (Implementation_Stage__c = :CO_STAGE_COLLECTING_DOCUMENTS
					OR Implementation_Stage__c NOT IN :Utils.setCOExclude)
					AND Parent_Carrier_Order__c = NULL
				GROUP BY OwnerId
				ORDER BY Count(ID)
			];
			for (AggregateResult objAggregate : list_AggregateResult) {
				map_UserIdWithCOCount.put((String) objAggregate.get('OwnerId'), (Integer) objAggregate.get('COCount'));
				map_UserIdWithDocCollected.put((String) objAggregate.get('OwnerId'), Integer.valueOf(objAggregate.get('CollectedDocs')));
				map_UserIdWithTotalDocument.put((String) objAggregate.get('OwnerId'), Integer.valueOf(objAggregate.get('TotalDocs')));
			}
		}
	}
	/** This method is used to assign CO to Facilitator 1  */
	public void assignFacilitator1OwnerCO(List<Carrier_Order__c> list_CarrierOrder, List<Carrier_Order__c> list_TADACarrierOrders) {
		Map<Id, Carrier_Order__c> map_ChildCOWithParentCO = new Map<Id, Carrier_Order__c>();
		if (list_CarrierOrder != null && list_CarrierOrder.size() > 0) {
			for (Carrier_Order__c objCarrierOrder : list_CarrierOrder) {
				if (objCarrierOrder.Is_Multi_EIN__c) {
					//CO is Child record if parent Carrier Order is not blank
					if (objCarrierOrder.Parent_Carrier_Order__c != null) {
						map_ChildCOWithParentCO.put(objCarrierOrder.Id, objCarrierOrder);
						continue;
					}
				}
				objCarrierOrder.Assignment_Message__c = '';
				Boolean isOwnerAssigned = false;
				String strPODValue = objCarrierOrder.Carrier__r.BT_Facilitator_POD__c;

				if (!map_PODWithUserIds.isEmpty() && (!map_PODWithUserIds.containsKey(strPODValue) || map_PODWithUserIds.get(strPODValue).isEmpty())) {
					strPODValue = 'Unassigned';
				}

				//Get least CO Count
				List<String> list_leastCarrierOrderCountToUser = getEligibleUsersWithLowestCOCount(map_PODWithUserIds.get(strPODValue), map_UserIdWithCOCount);

				if (list_leastCarrierOrderCountToUser != null && list_leastCarrierOrderCountToUser.size() == 1) {
					objCarrierOrder.OwnerId = list_leastCarrierOrderCountToUser[0];
					objCarrierOrder.Assignment_Message__c = 'SUCCESS: Carrier Order Count.';
					isOwnerAssigned = true;
				} else if (list_leastCarrierOrderCountToUser != null && list_leastCarrierOrderCountToUser.size() > 1) {
					//get the Highest Percentage of Document Count
					List<String> list_HighestDocumentPerentageCO = getEligibleUsersWithHighestDocPercentage(
						new Set<String>(list_leastCarrierOrderCountToUser),
						map_UserIdWithDocCollected,
						map_UserIdWithTotalDocument
					);

					if (!list_HighestDocumentPerentageCO.isEmpty()) {
						objCarrierOrder.OwnerId = list_HighestDocumentPerentageCO[0];
						objCarrierOrder.Assignment_Message__c = 'SUCCESS: Carrier Order Highest Collected Doc.';
						isOwnerAssigned = true;
					} else {
						objCarrierOrder.Assignment_Message__c = 'ERROR: Eligible user not found : Carrier Order Highest Collected Doc.';
					}
				} else {
					objCarrierOrder.Assignment_Message__c = 'ERROR: Eligible user not found : Carrier Order Count.';
				}
				//first time User click on Qualify Me
				if (String.isBlank(objCarrierOrder.Initial_Owner__c)) {
					if (objCarrierOrder.Implementation_Stage__c == 'Qualification') {
						objCarrierOrder.Implementation_Stage__c = 'Ready for Document Collection';
					}
					//[DS]24-03-2020 Carrier Order Start Date for Benefits BOR
					if (objCarrierOrder.Start_Date__c == null)
						objCarrierOrder.Start_Date__c = System.today();
				} else {
					//Reassignment
					objCarrierOrder.OOO_Timestamp__c = System.now();
				}

				if (isOwnerAssigned) {
					if (String.isBlank(objCarrierOrder.Initial_Owner__c)) {
						objCarrierOrder.Initial_Owner__c = objCarrierOrder.OwnerId;
					}
					map_UserIdWithCOCount.put((String) objCarrierOrder.OwnerId, map_UserIdWithCOCount.get(objCarrierOrder.OwnerId) + 1);
					map_UserIdWithDocCollected.put(
						(String) objCarrierOrder.OwnerId,
						(Integer) (map_UserIdWithDocCollected.get(objCarrierOrder.OwnerId) + objCarrierOrder.Number_Of_Collected_Documents__c)
					);
					map_UserIdWithTotalDocument.put(
						(String) objCarrierOrder.OwnerId,
						(Integer) (map_UserIdWithTotalDocument.get(objCarrierOrder.OwnerId) + objCarrierOrder.Total_Number_Of_Documents__c)
					);
					list_CarrierOrderToUpdate.add(objCarrierOrder);
					//Assign Parent Co Owner to a map
					if (objCarrierOrder.Is_Multi_EIN__c) {
						//CO is Child record if parent Carrier Order is not blank
						if (objCarrierOrder.Parent_Carrier_Order__c == null) {
							map_ParentCarrierOrder.put(objCarrierOrder.id, objCarrierOrder.OwnerId);
						}
					}
				} else {
					// In case Faciliatator ! is not assisgned
					ExceptionLogUtil.logException('BTAssignmentUtil', 'assignFacilitator1OwnerCO', 'No Facilitor 1 owner is assigned to Carrier Order :- ' + objCarrierOrder.Id, 'Medium');
				}
			}
			//Assign Parent Co Owner to Child Co Owner
			if (!map_ChildCOWithParentCO.isEmpty() && !map_ParentCarrierOrder.isEmpty()) {
				for (Carrier_Order__c objChildCo : map_ChildCOWithParentCO.values()) {
					if (map_ParentCarrierOrder.containsKey(objChildCo.Parent_Carrier_Order__c)) {
						objChildCO.OwnerId = map_ParentCarrierOrder.get(objChildCo.Parent_Carrier_Order__c);
						if (String.isBlank(objChildCO.Initial_Owner__c)) {
							if (objChildCO.Implementation_Stage__c == 'Qualification') {
								objChildCO.Implementation_Stage__c = 'Ready for Document Collection';
							}
							objChildCO.Initial_Owner__c = map_ParentCarrierOrder.get(objChildCo.Parent_Carrier_Order__c);
							//[DS]24-03-2020 Carrier Order Start Date for Benefits BOR
							if (objChildCO.Start_Date__c == null)
								objChildCO.Start_Date__c = System.today();
						} else {
							objChildCO.OOO_Timestamp__c = System.now();
						}

						objChildCO.Assignment_Message__c = 'SUCCESS: Parent CO Owner';
						list_CarrierOrderToUpdate.add(objChildCO);
					}
				}
			}
		}
		if (list_TADACarrierOrders != null && !list_TADACarrierOrders.isEmpty()) {
			//for tada carrier we need to just change the status of the carrier order as "ready for Document collection".
			for (Carrier_Order__c objTADACarrierOrder : list_TADACarrierOrders) {
				if (objTADACarrierOrder.Implementation_Stage__c == 'Qualification') {
					objTADACarrierOrder.Implementation_Stage__c = 'Ready for Document Collection';
					if (objTADACarrierOrder.Start_Date__c == null)
						objTADACarrierOrder.Start_Date__c = System.today();
					list_CarrierOrderToUpdate.add(objTADACarrierOrder);
				}
			}
		}
	}

	//This is util method, this method receive [last criteria eligible user ids] and [next criteria related userId and record count map ]
	public List<String> getEligibleUsersWithHighestDocPercentage(
		Set<String> list_PreviousEligibleUserIds,
		Map<String, Integer> map_UserDocCollectedCount,
		Map<String, Integer> map_UserTotalCollectedCount
	) {
		List<String> list_EligibleUsers = new List<String>();
		if (
			list_PreviousEligibleUserIds != null &&
			map_UserDocCollectedCount != null &&
			map_UserTotalCollectedCount != null &&
			list_PreviousEligibleUserIds.size() > 0 &&
			map_UserDocCollectedCount.size() > 0 &&
			map_UserTotalCollectedCount.size() > 0
		) {
			Integer intHighestCount;
			for (String strUserId : list_PreviousEligibleUserIds) {
				Integer intTemp = 0;
				if (map_UserDocCollectedCount.get(strUserId) != 0 && map_UserTotalCollectedCount.get(strUserId) != 0) {
					intTemp = (map_UserDocCollectedCount.get(strUserId) * 100) / map_UserTotalCollectedCount.get(strUserId);
				}
				if (intHighestCount == null) {
					intHighestCount = intTemp;
					list_EligibleUsers.add(strUserId);
					continue;
				}
				if (intHighestCount == intTemp) {
					list_EligibleUsers.add(strUserId);
					continue;
				}
				if (intHighestCount < intTemp) {
					intHighestCount = intTemp;
					list_EligibleUsers = new List<String>();
					list_EligibleUsers.add(strUserId);
				}
			}
		}
		return list_EligibleUsers;
	}
	//This is util method, this method receive [last criteria eligible user ids] and [next criteria related userId and record count map ]
	public List<String> getEligibleUsersWithLowestCOCount(Set<String> list_PreviousEligibleUserIds, Map<String, Integer> map_UserRecordCount) {
		List<String> list_EligibleUsers = new List<String>();

		if (list_PreviousEligibleUserIds != null && map_UserRecordCount != null && list_PreviousEligibleUserIds.size() > 0 && map_UserRecordCount.size() > 0) {
			Integer intLowestCount;
			for (String strUserId : list_PreviousEligibleUserIds) {
				Integer intTemp = map_UserRecordCount.get(strUserId);
				if (intLowestCount == null) {
					intLowestCount = intTemp;
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount == intTemp) {
					list_EligibleUsers.add(strUserId);
					continue;
				}

				if (intLowestCount > intTemp) {
					intLowestCount = intTemp;
					list_EligibleUsers = new List<String>();
					list_EligibleUsers.add(strUserId);
				}
			}
		}

		return list_EligibleUsers;
	}
	//Facilitator Assignment Logic Section ==================End==============================
}