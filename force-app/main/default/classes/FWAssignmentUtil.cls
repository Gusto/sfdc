/**
 * @name         FWAssignmentUtil
 * @author       Deepika
 * @date         16-06-2020
 * @description
 * @test class   FWAssignmentUtilTest, NPRU_TicketButtonOnCODetailExtTest
 **/
public with sharing class FWAssignmentUtil {
	public FWAssignmentUtil() {
	}
	//Advocate Assignment Logic Section======================Start=============================

	//this map contains BO Id with Skill Hash
	Map<String, Map<String, Decimal>> map_BOWithCOAndTADACount = new Map<String, Map<String, Decimal>>();
	//this map contains User id with Skill Hash
	Set<String> set_UserWithHashOfSkill = new Set<String>();
	//this map contains User id with Skill Hash
	Map<String, Set<String>> map_HashOfSkillWithUser = new Map<String, Set<String>>();
	//this map contains User id with Skill Hash
	Map<String, Set<String>> map_PartnerTierWithUser = new Map<String, Set<String>>();
	//this map contains User id with Assigned State
	Map<String, Set<String>> map_StateWithUser = new Map<String, Set<String>>();
	//this map contains BOR user and Current Month Cap
	Map<String, Decimal> map_UserIdCap = new Map<String, Decimal>();
	//this set contains User id that has Maestro Skills
	Set<String> set_UserWithMaestro = new Set<String>();
	Set<String> set_SkillHash = new Set<String>();
	Set<String> set_OrderType = new Set<String>();
	Set<String> set_PartnerTier = new Set<String>();
	Set<String> set_MonthYear = new Set<String>();
	Set<Decimal> set_Month = new Set<Decimal>();
	Set<Decimal> set_Year = new Set<Decimal>();
	Map<String, Decimal> map_UserIdActiveBOCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdTadaCOCount = new Map<String, Decimal>();
	Map<String, Decimal> map_UserIdCOCount = new Map<String, Decimal>();
	Map<String, Set<Id>> map_EffectiveDateWithUser = new Map<String, Set<Id>>();
	Set<String> set_ToExcludeOrderStatus = UtilitiesFactory.set_FWExcludeCOBO;
	String BO_NEW_PLAN_ID = Cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	String BO_CHANGE_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Change');
	String BO_RENEWAL_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
	String BO_RENEWAL_ALIGNMENT_ID = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal Alignment');
	Set<String> set_RecordType = new Set<String>{ BO_NEW_PLAN_ID, BO_CHANGE_ID, BO_RENEWAL_ID, BO_RENEWAL_ALIGNMENT_ID };
	List<Carrier_Order__c> list_CarrierOrdersRec = new List<Carrier_Order__c>();
	List<Benefit_Order__c> list_BOToBeUpdated = new List<Benefit_Order__c>();
	public static final String TRUE_VALUE = 'true';
	public static final String FALSE_VALUE = 'false';

	public List<Benefit_Order__c> processAdvocateAssignmentForBO(
		list<Benefit_Order__c> list_BenefitOrders,
		boolean blnIsOOOAssignment,
		map<id, Account> map_Account,
		set<String> setOppRecordType,
		Map<Id, Benefit_Order__c> map_AcctIdBO,
		Map<Id, Id> map_RenewalSpecialistOpps
	) {
		if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
			if (!blnIsOOOAssignment) {
				updateChildBOOwner(map_Account, setOppRecordType, map_AcctIdBO);
			}
			getSkillsAsPerBO(list_BenefitOrders, blnIsOOOAssignment);
			getAdvocateUserDataAsPerBO();
			getCapDetailsForRamping();
			getUserBasedBOData();
			assignOwnerToBO(list_BenefitOrders, blnIsOOOAssignment, map_RenewalSpecialistOpps);
		}
		return list_BOToBeUpdated;
	}

	public void updateChildBOOwner(map<id, Account> map_Account, set<String> setOppRecordType, map<Id, Benefit_Order__c> map_AcctIdBO) {
		Map<Id, Id> map_ChildAccWithParentAcc = new Map<Id, Id>();
		Set<Id> set_ParentAcc = new Set<Id>();
		for (Account a : map_Account.values()) {
			if (a.parentId != null) {
				map_ChildAccWithParentAcc.put(a.id, a.parentId);
				set_ParentAcc.add(a.parentId);
			}
		}

		if (!set_ParentAcc.isEmpty()) {
			Map<String, Benefit_Order__c> map_AccountIdWithBOOwner = new Map<String, Benefit_Order__c>();
			for (Benefit_Order__c objBO : [
				SELECT id, OwnerId, UW_Owner__c, Order_Status__c, Opportunity__r.AccountId
				FROM Benefit_Order__c
				WHERE
					Order_Status__c != 'Canceled'
					AND Order_Status__c != 'Fulfilled'
					AND Order_Status__c != 'Closed Lost'
					AND Opportunity__r.AccountId IN :set_ParentAcc
					AND Opportunity__r.StageName IN ('Closed Won', 'Pending PR')
					AND Opportunity__r.RecordType.Name IN :setOppRecordType
				ORDER BY Createddate DESC
			]) {
				if (!map_AccountIdWithBOOwner.isEmpty() && map_AccountIdWithBOOwner.containsKey(objBO.Opportunity__r.AccountId)) {
					continue;
				}
				map_AccountIdWithBOOwner.put(objBO.Opportunity__r.AccountId, objBO);
			}

			for (Id objAccountId : map_AcctIdBO.keySet()) {
				Benefit_Order__c objParentBO = new Benefit_Order__c();
				Id idParentAccountId;
				if (!map_ChildAccWithParentAcc.isEmpty() && map_ChildAccWithParentAcc.containsKey(objAccountId)) {
					idParentAccountId = map_ChildAccWithParentAcc.get(objAccountId);
				}
				//Get the parent BO
				if (idParentAccountId != null && !map_AccountIdWithBOOwner.isEmpty() && map_AccountIdWithBOOwner.containsKey(idParentAccountId)) {
					objParentBO = map_AccountIdWithBOOwner.get(idParentAccountId);
					Benefit_Order__c objChildBO = map_AcctIdBO.get(objAccountId);
					objChildBO.OwnerId = objParentBO.OwnerId;
					objChildBO.Parent_Benefit_Order__c = objParentBO.Id;
					objChildBO.UW_Owner__c = objParentBO.UW_Owner__c;
					objChildBO.Order_Status__c = objParentBO.Order_Status__c;

					if (objChildBO.OwnerId == null) {
						objChildBO.OwnerId = UserInfo.getUserId();
					}
					list_BOToBeUpdated.add(objChildBO);
				}
			}
		}
	}

	private Set<String> getEligibleUserIdAsPerSkills(Benefit_Order__c objBO, Boolean blnBigDeskAccount, Boolean blnIgnoreMaestro) {
		Set<String> set_EligibleUserIds = new Set<String>();
		Set<String> set_TempEligibleUserIds = new Set<String>();
		Set<String> set_PartnerTierEligibleUserIds = new Set<String>();
		Set<String> set_OtherParmeterEligibleUserIds = new Set<String>();
		Set<String> set_NewSkillHash = new Set<String>();
		String strHashSkills;

		Boolean blnPrioritySupport = (BenefitOrderHelper.map_accounts != null && BenefitOrderHelper.map_accounts.ContainsKey(objBO.Account__c)
			? BenefitOrderHelper.map_accounts.get(objBO.Account__c).Priority_Support__c
			: objBO.Account__r.Priority_Support__c);

		String strAssignmentState;
		if (String.isBlank(objBO.Assignment_State__c)) {
			if (
				BenefitOrderHelper.map_OpportunityRecords != null &&
				BenefitOrderHelper.map_OpportunityRecords.containsKey(objBO.Opportunity__c) &&
				BenefitOrderHelper.map_OpportunityRecords.get(objBO.Opportunity__c).UW_state__c != null
			) {
				strAssignmentState = BenefitOrderHelper.map_OpportunityRecords.get(objBO.Opportunity__c).UW_state__c;
			} else if (
				BenefitOrderHelper.map_accounts != null &&
				BenefitOrderHelper.map_accounts.containsKey(objBO.Account__c) &&
				BenefitOrderHelper.map_accounts.get(objBO.Account__c).BillingState != null
			) {
				strAssignmentState = BenefitOrderHelper.map_accounts.get(objBO.Account__c).BillingState;
			}
		} else {
			strAssignmentState = objBO.Assignment_State__c;
		}

		if (String.isNotBlank(objBO.Type__c) && String.isNotBlank(strAssignmentState)) {
			strHashSkills = '';
			strHashSkills += '#' + objBO.Type__c + '#' + strAssignmentState + '#false'+'#';
			if(objBO.Maestro__c){
				strHashSkills += TRUE_VALUE;
			}else{
				strHashSkills += FALSE_VALUE;
			}
			set_NewSkillHash.add(strHashSkills);
			

			if (blnBigDeskAccount) {
				Set<String> set_BigDeskHashSkills = getBigDeskHashSkills(objBO, strAssignmentState);
				if (!set_BigDeskHashSkills.isEmpty()) {
					set_NewSkillHash.addAll(set_BigDeskHashSkills);
				}
			}
		}

		//User having the same Skill(Order type, tier, state)
		for (String strTierHash : set_NewSkillHash) {
			if (!map_HashOfSkillWithUser.isEmpty() && map_HashOfSkillWithUser.containsKey(strTierHash)) {
				set_OtherParmeterEligibleUserIds = map_HashOfSkillWithUser.get(strTierHash);
				set_TempEligibleUserIds.addAll(set_OtherParmeterEligibleUserIds);
			}
		}

		//User having the same Skill(partner)
		if (String.isNotBlank(objBO.Partner_Tier__c) && !map_PartnerTierWithUser.isEmpty() && map_PartnerTierWithUser.containsKey(objBO.Partner_Tier__c)) {
			set_PartnerTierEligibleUserIds = map_PartnerTierWithUser.get(objBO.Partner_Tier__c);
			set_TempEligibleUserIds.addAll(set_PartnerTierEligibleUserIds);
		}

		if (!set_PartnerTierEligibleUserIds.isEmpty() && !set_OtherParmeterEligibleUserIds.isEmpty()) {
			//Comon User having the same Skill(partner) &&  Skill(Order type, tier, state)
			for (String objUserID : set_TempEligibleUserIds) {
				if (set_PartnerTierEligibleUserIds.contains(objUserID) && set_OtherParmeterEligibleUserIds.contains(objUserID)) {
					set_EligibleUserIds.add(objUserID);
				}
			}
		} else if (set_PartnerTierEligibleUserIds.isEmpty() && !set_OtherParmeterEligibleUserIds.isEmpty()) {
			set_EligibleUserIds.addAll(set_TempEligibleUserIds);
		}

		if (set_EligibleUserIds.size() == 0 && map_StateWithUser.size() > 0) {
			if (map_StateWithUser.containsKey(objBO.Assignment_State__c)) {
				set_EligibleUserIds = map_StateWithUser.get(objBO.Assignment_State__c);
			}
		}

		// If BO has Maestro, only User with Maestro skill should be set as IA
		// If BO does not have Maestro, User with Maestro skill should not be set as IA
		if (!blnIgnoreMaestro) {
			Set<String> set_TempUserIds = new Set<String> (set_EligibleUserIds);
			for(String objUserID : set_TempUserIds) {
				if (
					(objBO.Maestro__c && !set_UserWithMaestro.contains(objUserID)) ||
					(!objBO.Maestro__c && set_UserWithMaestro.contains(objUserID))
				) {
					set_TempUserIds.remove(objUserID);
				}
			}

			if(!objBO.Maestro__c || !set_TempUserIds.isEmpty()) {
				set_EligibleUserIds = set_TempUserIds;
			}
		}
		return set_EligibleUserIds;
	}

	public void assignOwnerToBO(List<Benefit_Order__c> list_BenefitOrders, Boolean blnIsOOOAssignment, Map<Id, Id> map_RenewalSpecialistOpps) {
		if (!list_BenefitOrders.isEmpty()) {
			Set<String> set_EligibleUserIds = new Set<String>();

			for (Benefit_Order__c objBO : list_BenefitOrders) {
				Boolean blnIsRenewalSpecialistAssigned = false;
				objBO.Assignment_Message__c = '';
				Boolean blnIsUserAssigned = false;
				Boolean blnIsAssignmentMsg = false;

				if (objBO.Parent_Benefit_Order__c != null) {
					continue;
				}

				if (objBO.Opportunity__c != null && map_RenewalSpecialistOpps != null && !map_RenewalSpecialistOpps.isEmpty() && map_RenewalSpecialistOpps.containsKey(objBO.Opportunity__c)) {
					objBO.OwnerId = map_RenewalSpecialistOpps.get(objBO.Opportunity__c);
					if (objBO.Initial_Owner__c == null) {
						objBO.Initial_Owner__c = objBO.OwnerId;
					}
					objBO.Assignment_Message__c = 'SUCCESS: Assigned Renewal Specialist User';
					blnIsAssignmentMsg = true;
					blnIsRenewalSpecialistAssigned = true;
					blnIsUserAssigned = true;
				}

				String strKey = objBO.Coverage_Effective_Month__c?.intValue() + '~' + objBO.Coverage_Effective_Year__c?.intValue();

				Boolean blnBigDeskAccount = (BenefitOrderHelper.map_accounts != null && BenefitOrderHelper.map_accounts.ContainsKey(objBO.Account__c)
					? BenefitOrderHelper.map_accounts.get(objBO.Account__c).Big_Desk_Sandbox_BenOps__c
					: false);

				// Get all Eligible Users per the Skills, enforcing Big Desk and Maestro skills
				set_EligibleUserIds = getEligibleUserIdAsPerSkills(objBO, blnBigDeskAccount, false);

				// If there are no BigDesk skills found and BO is for BigDesk, find Eligible users ignoring BigDesk skill
				if (blnBigDeskAccount && set_EligibleUserIds.isEmpty()) {
					set_EligibleUserIds = getEligibleUserIdAsPerSkills(objBO, false, false);
					blnBigDeskAccount = false;
				}

				// Assuming Maestro has removed all of the Users from Elibility, fetch list again ignoring Maestro
				Boolean blnMaestroIgnored = false;
				if (set_EligibleUserIds.isEmpty()) {
					set_EligibleUserIds = getEligibleUserIdAsPerSkills(objBO, false, true);
					blnMaestroIgnored = true;
				}

				//level 1 qualification [how many in-process (active) Bos do they currently own? ]
				if (!set_EligibleUserIds.isEmpty() && !blnIsUserAssigned) {
					list<String> list_LowestActiveBOCountUsers = getEligibleUsersWithLowestCount(set_EligibleUserIds, strKey, map_UserIdActiveBOCount);

					// Consider Maestro skilling, if there are no Eligible Users with any capacity, fetch the list ignoring Maestro
					if ((list_LowestActiveBOCountUsers == null || list_LowestActiveBOCountUsers.size() == 0) && !blnMaestroIgnored) {
						set_EligibleUserIds = getEligibleUserIdAsPerSkills(objBO, false, true);
						if (!set_EligibleUserIds.isEmpty()) {
							list_LowestActiveBOCountUsers = getEligibleUsersWithLowestCount(set_EligibleUserIds, strKey, map_UserIdActiveBOCount);
						}
					}

					// If all users with the 'Big Desk' skill are currently full to capacity, ignore big desk skill when assigning order.
					if ((list_LowestActiveBOCountUsers == null || list_LowestActiveBOCountUsers.size() == 0) && blnBigDeskAccount) {
						set_EligibleUserIds = getEligibleUserIdAsPerSkills(objBO, false, false);
						if (!set_EligibleUserIds.isEmpty()) {
							list_LowestActiveBOCountUsers = getEligibleUsersWithLowestCount(set_EligibleUserIds, strKey, map_UserIdActiveBOCount);
						}
					}
					
					if (list_LowestActiveBOCountUsers != null && list_LowestActiveBOCountUsers.size() == 1) {
						objBO.OwnerId = list_LowestActiveBOCountUsers.get(0);
						objBO.Assignment_Message__c = 'SUCCESS: Active Benefit Order Count~' + strKey;
						blnIsAssignmentMsg = true;
						if (objBO.Initial_Owner__c == null) {
							objBO.Initial_Owner__c = objBO.OwnerId;
						}
						blnIsUserAssigned = true;
					} else if ((list_LowestActiveBOCountUsers != null && list_LowestActiveBOCountUsers.size() > 1)) {
						//level 2 qualification [Whoever has the lower amount of open carrier orders]
						list<String> list_EligibleUsersWithLowestCOCount = getEligibleUsersWithLowestCount(new Set<String>(list_LowestActiveBOCountUsers), strKey, map_UserIdCOCount);

						if (list_EligibleUsersWithLowestCOCount != null && list_EligibleUsersWithLowestCOCount.size() == 1) {
							objBO.OwnerId = list_EligibleUsersWithLowestCOCount.get(0);
							objBO.Assignment_Message__c = 'SUCCESS: Lowest Carrier Order Count~' + strKey;
							blnIsAssignmentMsg = true;
							if (objBO.Initial_Owner__c == null) {
								objBO.Initial_Owner__c = objBO.OwnerId;
							}
							blnIsUserAssigned = true;
						} else if (list_EligibleUsersWithLowestCOCount != null && list_EligibleUsersWithLowestCOCount.size() > 1) {
							//level 3 qualification [Whoever has the lower amount of open TADA carrier orders]
							list<String> list_EligibleUsersWithLowestTadaCOCount = getEligibleUsersWithLowestCount(new Set<String>(list_EligibleUsersWithLowestCOCount), strKey, map_UserIdTadaCOCount);

							if (list_EligibleUsersWithLowestTadaCOCount != null) {
								objBO.OwnerId = list_EligibleUsersWithLowestTadaCOCount.get(0);
								if (objBO.Initial_Owner__c == null) {
									objBO.Initial_Owner__c = objBO.OwnerId;
								}
								blnIsUserAssigned = true;
								if (list_EligibleUsersWithLowestTadaCOCount.size() > 1) {
									objBO.Assignment_Message__c = 'SUCCESS: Randomly Assigned~' + strKey;
									blnIsAssignmentMsg = true;
								} else {
									objBO.Assignment_Message__c = 'SUCCESS: Lowest TAda Carrier Order Count~' + strKey;
									blnIsAssignmentMsg = true;
								}
							} else {
								objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Lowest TAda Carrier Order Count.';
								blnIsAssignmentMsg = true;
							}
						} else {
							objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Lowest Carrier Order Count.';
							blnIsAssignmentMsg = true;
						}
					} else {
						objBO.Assignment_Message__c = 'ERROR: Eligible user not found : Active Benefit Order Count.';
						blnIsAssignmentMsg = true;
					}
				}

				if (blnIsUserAssigned && blnIsOOOAssignment && !blnIsRenewalSpecialistAssigned) {
					String strMapKey = objBO.OwnerId + '~' + strKey;

					if (!map_BOWithCOAndTADACount.isEmpty() && map_BOWithCOAndTADACount.containsKey(objBO.id)) {
						Map<String, Decimal> map_TempCoAndTAdaCount = map_BOWithCOAndTADACount.get(objBO.id);
						//add CO Count
						if (!map_TempCoAndTAdaCount.isEmpty() && map_TempCoAndTAdaCount.containsKey('COCount'))
							map_UserIdCOCount.put(strMapKey, map_UserIdCOCount.get(strMapKey) + map_TempCoAndTAdaCount.get('COCount'));
						//Add Tada Count
						if (!map_TempCoAndTAdaCount.isEmpty() && map_TempCoAndTAdaCount.containsKey('Tada'))
							map_UserIdTadaCOCount.put(strMapKey, map_UserIdTadaCOCount.get(strMapKey) + map_TempCoAndTAdaCount.get('Tada'));
						//Add Benefit Count
						if (!map_TempCoAndTAdaCount.isEmpty() && map_TempCoAndTAdaCount.containsKey('BOCount'))
							map_UserIdActiveBOCount.put(strMapKey, map_UserIdActiveBOCount.get(strMapKey) + map_TempCoAndTAdaCount.get('BOCount'));
					}
					list_BOToBeUpdated.add(objBO);
				}

				if (!blnIsUserAssigned) {
					if (!blnIsOOOAssignment) {
						objBO.OwnerId = UserInfo.getUserId(); //Assign logged in user
					}
					if (!blnIsAssignmentMsg) {
						objBO.Assignment_Message__c = 'ERROR: Skills Does not matched';
					}
				}

				//BY:PR, Date:Aug/21/2020, Desc: This to keep track of manual/automated user assignment
				if (blnIsUserAssigned) {
					BenefitOrderHelperFunctions.blnIsPlayModeAssigned = true;
				}
			}
		}
	}

	//this method uses [map_UserIdCount] map to get the user/users with lowest Count
	public list<String> getEligibleUsersWithLowestCount(Set<String> set_BOEligibleUserIds, String strkey, Map<String, Decimal> map_UserIdCount) {
		list<String> list_EligibleUsers = new List<String>();

		if (map_UserIdCount.size() > 0) {
			Decimal intLowestCount;

			for (String objUserID : set_BOEligibleUserIds) {
				if (map_UserIdCap.containsKey(objUserID + '~' + strKey) && map_UserIdActiveBOCount.get(objUserID + '~' + strKey) >= map_UserIdCap.get(objUserID + '~' + strKey)) {
					continue;
				}
				if (!map_UserIdCount.isEmpty() && map_UserIdCount.containsKey(objUserID + '~' + strKey)) {
					Decimal intTemp = map_UserIdCount.get(objUserID + '~' + strKey);
					if (intLowestCount == null) {
						intLowestCount = intTemp;
						list_EligibleUsers.add(objUserID);
						continue;
					}

					if (intLowestCount == intTemp) {
						list_EligibleUsers.add(objUserID);
						continue;
					}

					if (intLowestCount > intTemp) {
						intLowestCount = intTemp;
						list_EligibleUsers = new List<String>();
						list_EligibleUsers.add(objUserID);
					}
				}
			}
		}

		return list_EligibleUsers;
	}

	public void getSkillsAsPerBO(list<Benefit_Order__c> list_BenefitOrders, boolean blnIsOOOAssignment) {
		String strHashSkills;
		Set<String> set_BOIds = new Set<String>();
		List<Carrier_Order__c> list_TempCO = new List<Carrier_Order__c>();
		for (Benefit_Order__c objBO : list_BenefitOrders) {
			if (objBO.Parent_Benefit_Order__c != null) {
				continue;
			}

			if (objBO.Coverage_Effective_Date__c != null) {
				set_Month.add(objBO.Coverage_Effective_Date__c.Month());
				set_Year.add(objBO.Coverage_Effective_Date__c.Year());
				set_MonthYear.add(objBO.Coverage_Effective_Date__c.Month() + '~' + objBO.Coverage_Effective_Date__c.Year());
			}
			strHashSkills = '';

			if (String.isNotBlank(objBO.Partner_Tier__c)) {
				set_PartnerTier.add(objBO.Partner_Tier__c);
			}

			Boolean blnPrioritySupport = (BenefitOrderHelper.map_accounts != null && BenefitOrderHelper.map_accounts.ContainsKey(objBO.Account__c)
				? BenefitOrderHelper.map_accounts.get(objBO.Account__c).Priority_Support__c
				: objBO.Account__r.Priority_Support__c);

			String strAssignmentState;
			if (String.isBlank(objBO.Assignment_State__c)) {
				if (
					BenefitOrderHelper.map_OpportunityRecords != null &&
					BenefitOrderHelper.map_OpportunityRecords.containsKey(objBO.Opportunity__c) &&
					BenefitOrderHelper.map_OpportunityRecords.get(objBO.Opportunity__c).UW_state__c != null
				) {
					strAssignmentState = BenefitOrderHelper.map_OpportunityRecords.get(objBO.Opportunity__c).UW_state__c;
				} else if (
					BenefitOrderHelper.map_accounts != null &&
					BenefitOrderHelper.map_accounts.containsKey(objBO.Account__c) &&
					BenefitOrderHelper.map_accounts.get(objBO.Account__c).BillingState != null
				) {
					strAssignmentState = BenefitOrderHelper.map_accounts.get(objBO.Account__c).BillingState;
				}
			} else {
				strAssignmentState = objBO.Assignment_State__c;
			}

			set_OrderType.add(objBO.Type__c);
			strHashSkills = '';
			strHashSkills += '#' + objBO.Type__c + '#' + strAssignmentState + '#false'+'#';
			if(objBO.Maestro__c){
				strHashSkills += 'true';
			}else{
				strHashSkills += 'false';
			}
			set_SkillHash.add(strHashSkills);

			Set<String> set_BigDeskHashSkills = getBigDeskHashSkills(objBO, strAssignmentState);
			if (!set_BigDeskHashSkills.isEmpty()) {
				set_SkillHash.addAll(set_BigDeskHashSkills);
			}

			if (blnIsOOOAssignment) {
				set_BOIds.add(objBO.Id);
			}
		}

		if (blnIsOOOAssignment) {
			//Count the child records also when ever parent is Assigned to the IA user
			for (Benefit_Order__c objBO : [
				SELECT Id, Has_TADA__c, Coverage_Effective_Month__c, Coverage_Effective_Year__c, OwnerId, No_of_Carrier_Order__c, No_Of_TADA_Carrier_Order__c, Parent_Benefit_Order__c
				FROM Benefit_Order__c
				WHERE Coverage_Effective_Date__c != NULL AND (Id IN :set_BOIds OR Parent_Benefit_Order__c IN :set_BOIds) AND Order_Status__c NOT IN :set_ToExcludeOrderStatus
				ORDER BY OwnerId
			]) {
				String strBOId = objBO.Id;
				if (!set_BOIds.contains(objBO.Id)) {
					strBOId = objBO.Parent_Benefit_Order__c;
				}

				Map<String, Decimal> map_tempCOCount = new Map<String, Decimal>();
				map_tempCOCount.put('COCount', 0);
				map_tempCOCount.put('Tada', 0);
				map_tempCOCount.put('BOCount', 0);

				if (!map_BOWithCOAndTADACount.isEmpty() && map_BOWithCOAndTADACount.containsKey(strBOId)) {
					map_tempCOCount = map_BOWithCOAndTADACount.get(strBOId);
				}

				Decimal intCOCount = 0;
				if (objBO.No_of_Carrier_Order__c != null) {
					intCOCount = objBO.No_of_Carrier_Order__c;
				}

				Decimal intTADACOCount = 0;
				if (objBO.No_Of_TADA_Carrier_Order__c != null) {
					intTADACOCount = objBO.No_Of_TADA_Carrier_Order__c;
				}

				Decimal intBOCount = 1;
				if (!map_tempCOCount.isEmpty()) {
					if (map_tempCOCount.containsKey('COCount')) {
						intCOCount += map_tempCOCount.get('COCount');
					}

					if (map_tempCOCount.containsKey('Tada')) {
						intTADACOCount += map_tempCOCount.get('Tada');
					}

					if (map_tempCOCount.containsKey('BOCount')) {
						intBOCount += map_tempCOCount.get('BOCount');
					}
					map_tempCOCount.put('COCount', intCOCount);
					map_tempCOCount.put('Tada', intTADACOCount);
					map_tempCOCount.put('BOCount', intBOCount);
				}
				map_BOWithCOAndTADACount.put(strBOId, map_tempCOCount);
			}
		}
	}

	/**get the Advocate Using the skills selected/newly created */
	public void getAdvocateUserDataAsPerBO() {
		Set<String> set_UserIds = new Set<String>();
		Set<String> set_AssignedState = new Set<String>();

		if (!set_SkillHash.isEmpty()) {
			list<User_Skill__c> list_UserSkillTemp = [
				SELECT
					Id,
					User_Name__c,
					User_Role__c,
					User_Role__r.User__c,
					Skill_TADA_Check__c,
					User_Role__r.User__r.Out_Of_Office__c,
					Skill_Order_type__c,
					Skill_Partner_Tier__c,
					State_Group__c,
					IA_Skill_Hash__c,
					Maestro__c
				FROM User_Skill__c
				WHERE
					Skill_Role_Name__c = 'Implementation Advocate'
					AND IA_Skill_Hash__c IN :set_SkillHash
					AND User_Role__r.User__r.IsActive = TRUE
					AND User_Role__r.User__r.Out_Of_Office__c = FALSE
					AND Active__c = TRUE
			];

			if (list_UserSkillTemp.size() == 0) {
				for (String strHash : set_SkillHash) {
					list<String> list_strState = strHash.split('#');
					if (list_strState != null && list_strState.size() >= 4) {
						set_AssignedState.add(list_strState.get(3).trim());
					}
				}

				list_UserSkillTemp = [
					SELECT
						Id,
						User_Name__c,
						User_Role__c,
						User_Role__r.User__c,
						Skill_TADA_Check__c,
						User_Role__r.User__r.Out_Of_Office__c,
						Skill_Order_type__c,
						Skill_Partner_Tier__c,
						State_Group__c,
						IA_Skill_Hash__c,
						Maestro__c
					FROM User_Skill__c
					WHERE
						Skill_Role_Name__c = 'Implementation Advocate'
						AND State_Group__c IN :set_AssignedState
						AND Skill_Order_type__c IN :set_OrderType
						AND User_Role__r.User__r.IsActive = TRUE
						AND User_Role__r.User__r.Out_Of_Office__c = FALSE
						AND Active__c = TRUE
				];
			}

			for (User_Skill__c objSkillRec : list_UserSkillTemp) {
				set_UserWithHashOfSkill.add(objSkillRec.User_Role__r.User__c);
				if (set_AssignedState.size() == 0) {
					if (String.isNotBlank(objSkillRec.IA_Skill_Hash__c)) {
						//Add user ids in a set as per skills(Order type, tier, state)
						set_UserIds = new Set<String>();
						if (!map_HashOfSkillWithUser.isEmpty() && map_HashOfSkillWithUser.containsKey(objSkillRec.IA_Skill_Hash__c)) {
							set_UserIds = map_HashOfSkillWithUser.get(objSkillRec.IA_Skill_Hash__c);
						}
						set_UserIds.add(objSkillRec.User_Role__r.User__c);
						map_HashOfSkillWithUser.put(objSkillRec.IA_Skill_Hash__c, set_UserIds);
					}

					if (String.isNotBlank(objSkillRec.Skill_Partner_Tier__c)) {
						//Add user ids in a set as per skills(partner Tier)
						set_UserIds = new Set<String>();
						if (!map_PartnerTierWithUser.isEmpty() && map_PartnerTierWithUser.containsKey(objSkillRec.Skill_Partner_Tier__c)) {
							set_UserIds = map_PartnerTierWithUser.get(objSkillRec.Skill_Partner_Tier__c);
						}
						set_UserIds.add(objSkillRec.User_Role__r.User__c);
						map_PartnerTierWithUser.put(objSkillRec.Skill_Partner_Tier__c, set_UserIds);
					}
				} else {
					set_UserIds = new Set<String>();
					if (!map_StateWithUser.isEmpty() && map_StateWithUser.containsKey(objSkillRec.State_Group__c)) {
						set_UserIds = map_StateWithUser.get(objSkillRec.State_Group__c);
					}
					set_UserIds.add(objSkillRec.User_Role__r.User__c);
					map_StateWithUser.put(objSkillRec.State_Group__c, set_UserIds);
				}

				if(objSkillRec.Maestro__c) {
					set_UserWithMaestro.add(objSkillRec.User_Role__r.User__c);
				}
			}
		}
	}

	public void getCapDetailsForRamping() {
		if (!set_UserWithHashOfSkill.isEmpty()) {
			for (Benefit_Order_Allocation__c objBOA : [
				SELECT User__c, Month__c, Year__c, Max_BO__c, id
				FROM Benefit_Order_Allocation__c
				WHERE Month__c IN :set_Month AND Year__c IN :set_Year AND RecordType.Name = 'Benefits'
			]) {
				String strkey = objBOA.User__c + '~' + objBOA.Month__c + '~' + objBOA.Year__c;
				map_UserIdCap.put(strkey, objBOA.Max_BO__c);
			}
		}
	}

	/**Using this method we query out the current open BO records owned by the eligible Users queried in [getUserData] method*/
	public void getUserBasedBOData() {
		List<Benefit_Order__c> list_ExistingBenefitOrder = new List<Benefit_Order__c>();
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		map_UserIdActiveBOCount = new Map<String, Decimal>();
		map_UserIdCOCount = new Map<String, Decimal>();
		map_UserIdTadaCOCount = new Map<String, Decimal>();

		if (!set_UserWithHashOfSkill.isEmpty()) {
			for (String strkey : set_UserWithHashOfSkill) {
				for (String objMonthYear : set_MonthYear) {
					map_UserIdCOCount.put(strkey + '~' + objMonthYear, 0);
					map_UserIdActiveBOCount.put(strkey + '~' + objMonthYear, 0);
					map_UserIdTadaCOCount.put(strkey + '~' + objMonthYear, 0);
				}
			}

			list_ExistingBenefitOrder = [
				SELECT Id, Has_TADA__c, Coverage_Effective_Month__c, Coverage_Effective_Year__c, OwnerId, No_of_Carrier_Order__c, No_Of_TADA_Carrier_Order__c
				FROM Benefit_Order__c
				WHERE
					OwnerId IN :set_UserWithHashOfSkill
					AND Coverage_Effective_Date__c != NULL
					AND Coverage_Effective_Month__c IN :set_Month
					AND Coverage_Effective_Year__c IN :set_Year
					AND Order_Status__c NOT IN :set_ToExcludeOrderStatus
					AND RecordTypeId IN :set_RecordType
				ORDER BY OwnerId
			];
		}

		if (!list_ExistingBenefitOrder.isEmpty()) {
			for (Benefit_Order__c objBO : list_ExistingBenefitOrder) {
				String strKey = objBO.OwnerId + '~' + objBO.Coverage_Effective_Month__c + '~' + objBO.Coverage_Effective_Year__c;
				Set<Id> set_UserIds = new Set<Id>();

				if (!map_EffectiveDateWithUser.isEmpty() && map_EffectiveDateWithUser.containsKey(strKey)) {
					set_UserIds = map_EffectiveDateWithUser.get(strKey);
				}
				set_UserIds.add(objBO.Id);
				map_EffectiveDateWithUser.put(strKey, set_UserIds);

				//For Active BO Count
				Decimal intBOCount = 0;
				if (!map_UserIdActiveBOCount.isEmpty() && map_UserIdActiveBOCount.containsKey(strKey)) {
					intBOCount = map_UserIdActiveBOCount.get(strKey);
				}
				map_UserIdActiveBOCount.put(strKey, intBOCount + 1);

				//For Co Count
				Decimal intCOCount = 0;
				if (!map_UserIdCOCount.isEmpty() && map_UserIdCOCount.containsKey(strKey)) {
					intCOCount = map_UserIdCOCount.get(strKey);
				}

				if (objBO.No_of_Carrier_Order__c != null) {
					intCOCount = intCOCount + objBO.No_of_Carrier_Order__c;
				}
				map_UserIdCOCount.put(strKey, intCOCount);

				//For All the Alegeus Carrier Orders
				Decimal intTADACOCount = 0;
				if (!map_UserIdTadaCOCount.isEmpty() && map_UserIdTadaCOCount.containsKey(strKey)) {
					intTADACOCount = map_UserIdTadaCOCount.get(strKey);
				}

				if (objBO.No_Of_TADA_Carrier_Order__c != null) {
					intTADACOCount = intTADACOCount + objBO.No_Of_TADA_Carrier_Order__c;
				}
				map_UserIdTadaCOCount.put(strKey, intTADACOCount);
			}
		}
	}

	public Set<String> getBigDeskHashSkills(Benefit_Order__c objBO, String strAssignmentState) {
		Set<String> set_UserHashSkills = new Set<String>();
		String strUserHashSkills;
		if (
			BenefitOrderHelper.map_accounts != null &&
			objBO.RecordTypeId == BenefitOrderUtil.RENEWAL_BENEFIT_ORDER_RT_ID &&
			BenefitOrderHelper.map_accounts.containsKey(objBO.Account__c) &&
			BenefitOrderHelper.map_accounts.get(objBO.Account__c).Big_Desk_Sandbox_BenOps__c
		) {
			strUserHashSkills = '';
			strUserHashSkills += '#' + objBO.Type__c + '#' + strAssignmentState + '#true'+'#';
			if(objBO.Maestro__c){
				strUserHashSkills += 'true';
			}else{
				strUserHashSkills += 'false';
			}
			set_UserHashSkills.add(strUserHashSkills);
		}

		return set_UserHashSkills;
	}
}