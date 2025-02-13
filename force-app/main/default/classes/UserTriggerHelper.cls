/**
 * @name         : UserTriggerHelper
 * @author       : PR
 * @date         : 08-02-2019
 * @description  : This class is used as a helper class for the User trigger
 * @test classes : UserTriggerHelperTest
 **/
public with sharing class UserTriggerHelper {
	public static boolean skipTrigger = false;
	public static integer counter = 0;
	public static String strResellerOwnerId = Label.Reseller_Inactive_Owner;
	public static Map<String, Inactive_Case_Routing__mdt> map_InactiveTaxResCaseRoutingMdt = CaseQueryHelper.getInactiveCaseRoutingMetaDataForTaxRes();
	public static Map<String, Group> map_AllQueuesByDevName = GlobalQueryHelper.getAllQueuesByDevNameMap();
	public static Set<Id> BENEFIT_OPP_REC_TYPE_IDS = new Set<Id>{
		Cache.getRecordTypeId('Opportunity', 'Benefits New Plan'),
		Cache.getRecordTypeId('Opportunity', 'Benefits BYOB'),
		Cache.getRecordTypeId('Opportunity', 'Benefits BoR')
	};
	public static final String SUBMISSION_ADVOCATE = 'Submission Advocate';
	public static final String FULFILLMENT = 'Fulfillment';
	public static Set<string> set_ImpStage = new Set<String>{ 'Approved', 'Canceled', 'Closed Admin' };

	public void OnBeforeUpdate(Map<ID, User> oldUserMap, Map<ID, User> newUserMap) {
		//BY:Bhagat Singh, Date:Dec-3-2020, desc: PT OOO enhancement
		User objOldUser = null;
		for (User objNewUser : newUserMap.values()) {
			objOldUser = oldUserMap.get(objNewUser.Id);

			//[BS: 25 Nov 2020]Track Last OOO Timestamp
			if (objNewUser.Out_Of_Office__c != objOldUser.Out_Of_Office__c) {
				objNewUser.Last_OOO_Modified_Timestamp__c = Datetime.now();
			}

			if (objNewUser.IsActive != objOldUser.IsActive) {
				if (!objNewUser.IsActive) {
					objNewUser.Inactive_User_Date_Time__c = Datetime.now();
					objNewUser.Inactive__c = true;
					objNewUser.Active_License__c = null;
				} else {
					objNewUser.Inactive_User_Date_Time__c = null;
					objNewUser.Inactive__c = false;
				}
			}
		}
	}

	public void OnAfterUpdate(Map<Id, User> oldUserMap, Map<Id, User> newUserMap) {
		counter++;
		//for checking any user feature(UserRoleId,ProfileId,Class_Queue__c,Benefits_Class__c,Name,ManagerId) changed then call trackUserFeatureChanges this method
		List<String> lst_wrapperClass = new List<String>();
		set<string> set_ReturnToOfficeUserIds = new Set<string>();
		Set<Id> set_InactiveUserIds = new Set<Id>();
		Set<Id> set_UserId = new Set<Id>();
		Map<String, UserRole> map_UserRolesByName = GlobalQueryHelper.getNameUserRoleMap();
		UserRole objSubmissionUserRole = map_UserRolesByName.get(SUBMISSION_ADVOCATE);
		UserRole objFulfillmentUserRole = map_UserRolesByName.get(FULFILLMENT);
		for (User objUser : newUserMap.values()) {
			if (objUser.IsActive) {
				User oldUserObj = oldUserMap.get(objUser.Id);
				if (objUser.Out_Of_Office__c == false && oldUserObj.Out_Of_Office__c == true) {
					set_ReturnToOfficeUserIds.add(objUser.Id);
				}

				if (objUser.UserRoleId != oldUserObj.UserRoleId) {
					if (
						(objUser.UserRoleId != objSubmissionUserRole?.id || objUser.UserRoleId != objFulfillmentUserRole?.Id) &&
						(oldUserObj.UserRoleId == objSubmissionUserRole?.id ||
						oldUserObj.UserRoleId == objFulfillmentUserRole?.Id)
					) {
						set_UserId.add(objUser.Id);
					}
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.UserRoleId;
					tempCtrl.oldValue = oldUserObj.UserRoleId;
					tempCtrl.changedFieldStr = 'Role';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
				if (objUser.ProfileId != null && objUser.ProfileId != oldUserObj.ProfileId) {
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.ProfileId;
					tempCtrl.oldValue = oldUserObj.ProfileId;
					tempCtrl.changedFieldStr = 'Profile';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
				if (objUser.Class_Queue__c != oldUserObj.Class_Queue__c) {
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.Class_Queue__c;
					tempCtrl.oldValue = oldUserObj.Class_Queue__c;
					tempCtrl.changedFieldStr = 'Class/Queue';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
				if (objUser.Benefits_Class__c != oldUserObj.Benefits_Class__c) {
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.Benefits_Class__c;
					tempCtrl.oldValue = oldUserObj.Benefits_Class__c;
					tempCtrl.changedFieldStr = 'Benefits Class';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
				if (objUser.FirstName != oldUserObj.FirstName || objUser.LastName != oldUserObj.LastName) {
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.FirstName + ' ' + objUser.LastName;
					tempCtrl.oldValue = oldUserObj.FirstName + ' ' + oldUserObj.LastName;
					tempCtrl.changedFieldStr = 'Name';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
				if (objUser.ManagerId != oldUserObj.ManagerId) {
					userWrapper tempCtrl = new userWrapper();
					tempCtrl.newValue = objUser.ManagerId;
					tempCtrl.oldValue = oldUserObj.ManagerId;
					tempCtrl.changedFieldStr = 'Manager';
					tempCtrl.userId = objUser.Id;
					lst_wrapperClass.add(json.serialize(tempCtrl));
				}
			} else if (!objUser.IsActive) {
				set_InactiveUserIds.add(objUser.Id);
			}
		}
		if (lst_wrapperClass.size() > 0) {
			saveUserRecordIntoAuditHistory(lst_wrapperClass);
		}

		if (!set_UserId.isEmpty()) {
			setReRoutingToTrueOnCarrierOrder(set_UserId);
		}

		//BY: PR, Date: Feb 18 - 2020, Desc: To handle user coming back to office.
		if (set_ReturnToOfficeUserIds.size() > 0) {
			Set<String> set_BTRoleNames = new Set<String>{ 'Benefit Transfer Advocate', 'Benefit Transfer Facilitator 1', 'Benefit Transfer Facilitator 2' };
			Set<string> set_AdvocateIds = new Set<string>();
			Set<string> set_Facilitator1Ids = new Set<string>();

			for (User_Skill__c objUserSkill : [
				SELECT Id, User_Role__r.User__c, Skill__c, Skill__r.Role__c, Skill__r.Role__r.Name
				FROM User_Skill__c
				WHERE User_Role__r.User__c IN :set_ReturnToOfficeUserIds AND Skill__r.Role__r.Name IN :set_BTRoleNames
			]) {
				if ('Benefit Transfer Advocate'.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
					set_AdvocateIds.add(objUserSkill.User_Role__r.User__c);
				}
				if ('Benefit Transfer Facilitator 1'.equalsIgnoreCase(objUserSkill.Skill__r.Role__r.Name)) {
					set_Facilitator1Ids.add(objUserSkill.User_Role__r.User__c);
				}
			}

			if (!set_AdvocateIds.isEmpty()) {
				Cache.displayErrorMessage('In progress... Please wait 2-3 minutes and refresh the page.', ApexPages.Severity.INFO);
				reAssignBOAsync(set_AdvocateIds);
			}

			if (!set_Facilitator1Ids.isEmpty()) {
				CarrierOrderHelperFunctions.reAssignCOtoInitialFacilitator1OnReturnToOffice(set_Facilitator1Ids);
			}
		}

		// Calling method to route inactive cases to correct owners.
		// BBO-630 - Added Empty check, and if running in Future or Batch Context
		if (!set_InactiveUserIds?.isEmpty()) {
			if (!System.isFuture() && !System.isBatch()) {
				inactiveCaseRouting(set_InactiveUserIds);
			}
		}
	}

	@future
	public static void reAssignBOAsync(Set<string> set_AdvocateIds) {
		BenefitOrderHelperFunctions.reAssignBOtoInitialAdvocateOnReturnToOffice(set_AdvocateIds);
	}

	/*
    BY: PR, Date:8/2/19
    Desc: This method receives set of User Id and Type of Update as a string. We are creating User Audit history records.
    */
	@future
	public static void saveUserRecordIntoAuditHistory(List<String> lst_wrapperClass) {
		List<User_Audit_History__c> userAuditHistoryList = new List<User_Audit_History__c>();
		if (lst_wrapperClass != null && lst_wrapperClass.size() > 0) {
			for (String serialisedStr : lst_wrapperClass) {
				userWrapper wrapperRec = (userWrapper) JSON.deserialize(serialisedStr, userWrapper.class);
				User_Audit_History__c userAuditObj = new User_Audit_History__c();
				userAuditObj.User__c = wrapperRec.UserId;
				userAuditObj.Field_Name__c = wrapperRec.changedFieldStr;
				userAuditObj.From_Value__c = wrapperRec.oldValue;
				userAuditObj.To_Value__c = wrapperRec.newValue;
				userAuditHistoryList.add(userAuditObj);
			}

			if (userAuditHistoryList.size() > 0) {
				try {
					insert userAuditHistoryList;
				} catch (Exception objEx) {
					ExceptionLogUtil.logException(
						'UserTriggerHandler',
						'saveUserRecordIntoAuditHistory',
						'Exception On Line ' + objEx.getLineNumber() + '-' + objEx.getMessage(),
						objEx.getStackTraceString()
					);
				}
			}
		}
	}

	/**
	 * @Author          : Sanjay Paryani
	 * @Description     : If Case Owner is Inactive, reassign Case to the appropriate owner
	 * @Parm            : Set<Id> passed with Ids of all users that went inactive
	 * @Return          : N/A
	 */
	@future
	public static void inactiveCaseRouting(Set<Id> set_InactiveUserIds) {
		List<Case> list_CasesForSpecialistAssignment = new List<Case>();
		List<Case> list_CasesForRoutingUpdate = new List<Case>();
		Set<Id> set_SpecialistAssigmentCaseIds = new Set<Id>();
		Map<Id, Case> map_TaxResCasesToRoute = new Map<Id, Case>();

		// Creating a tax res only cases where these cases belong to inactive users so they can be rerouted to the correct owner.
		if (set_InactiveUserIds?.size() > 0) {
			for (Case objCase : [
				SELECT Id, RecordTypeId, Status, Account_Specialist__c, OwnerId, Agency_Information__c, Error_Message__c
				FROM Case
				WHERE OwnerId IN :set_InactiveUserIds AND RecordTypeId = :CaseUtils.RECTYPE_TAXRES AND Status NOT IN (:UserUtils.STATUS_CLOSED, :UserUtils.STATUS_SOLVED)
			]) {
				map_TaxResCasesToRoute.put(objCase.Id, objCase);
			}
		}

		// Handling inactive routing for Tax Res cases
		if (map_TaxResCasesToRoute?.size() > 0) {
			for (Case objCase : map_TaxResCasesToRoute.values()) {
				// This part takes care if we have rules defined for a case status
				if (map_InactiveTaxResCaseRoutingMdt.containsKey(objCase.Status)) {
					if (
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status) != null &&
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status)?.Target_Owner__c != null &&
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status)?.Target_Owner__c != CaseUtils.TEXT_ROUND_ROBIN
					) {
						String strTargetOwner = map_InactiveTaxResCaseRoutingMdt.get(objCase.Status).Target_Owner__c;
						Id idCaseOwnerFromMap = map_AllQueuesByDevName?.get(strTargetOwner).Id;
						if (idCaseOwnerFromMap != null) {
							objCase.OwnerId = idCaseOwnerFromMap;
						}
					} else {
						//Collect case for Round-Robin assignment
						objCase.Account_Specialist__c = null;
						list_CasesForSpecialistAssignment.add(objCase);
						set_SpecialistAssigmentCaseIds.add(objCase.Id);
					}

					if (
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status) != null &&
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status).Target_Status__c != null &&
						map_InactiveTaxResCaseRoutingMdt?.get(objCase.Status)?.Target_Status__c != CaseUtils.CASE_STATUS_BLANK_STATUS
					) {
						objCase.Status = map_InactiveTaxResCaseRoutingMdt.get(objCase.Status).Target_Status__c;
					}

					// This part takes care if we dont have any rules defined for a case status
				} else if (map_InactiveTaxResCaseRoutingMdt?.containsKey(CaseUtils.CASE_STATUS_BLANK_STATUS)) {
					if (map_InactiveTaxResCaseRoutingMdt?.get(CaseUtils.CASE_STATUS_BLANK_STATUS)?.Target_Owner__c != CaseUtils.TEXT_ROUND_ROBIN) {
						Id idCaseOwnerFromMap = map_AllQueuesByDevName?.get(map_InactiveTaxResCaseRoutingMdt.get(CaseUtils.CASE_STATUS_BLANK_STATUS).Target_Owner__c)?.Id;
						if (idCaseOwnerFromMap != null) {
							objCase.OwnerId = idCaseOwnerFromMap;
						}
					} else {
						//Collect case for Round robin assignment
						objCase.Account_Specialist__c = null;
						list_CasesForSpecialistAssignment.add(objCase);
						set_SpecialistAssigmentCaseIds.add(objCase.Id);
					}

					if (map_InactiveTaxResCaseRoutingMdt?.get(CaseUtils.CASE_STATUS_BLANK_STATUS)?.Target_Status__c != CaseUtils.CASE_STATUS_BLANK_STATUS) {
						objCase.Status = map_InactiveTaxResCaseRoutingMdt.get(CaseUtils.CASE_STATUS_BLANK_STATUS).Target_Status__c;
					}
				}

				if (!set_SpecialistAssigmentCaseIds?.contains(objCase.Id)) {
					list_CasesForRoutingUpdate.add(objCase);
				}
			}

			if (list_CasesForSpecialistAssignment?.size() > 0) {
				// Calling Tax Res Specialist case assignment
				CaseTriggerHelper.taxResSpecialistCaseAssignment(list_CasesForSpecialistAssignment, null, true);
			}

			if (list_CasesForRoutingUpdate?.size() > 0) {
				CaseTriggerHelper.skipTrigger = true;
				List<Database.SaveResult> list_SaveResult = Database.update(list_CasesForRoutingUpdate, false);
				Utils.processSaveResult(list_SaveResult, list_CasesForRoutingUpdate, 'Id', true, 'UserTriggerHelper-inactiveCaseRouting');
				CaseTriggerHelper.skipTrigger = false;
			}
		}
	}

	/**
	 * @author       Deepika Saini
	 * @description  update the Requires rerouting to True om Carrier Order
	 * @param        Set<Id> - set of User id
	 * @return       N/A
	 **/
	@future
	public static void setReRoutingToTrueOnCarrierOrder(Set<Id> set_UserId) {
		List<Carrier_Order__c> list_CarrierOrder = new List<Carrier_Order__c>();
		for (Carrier_Order__c objCarrierOrder : [SELECT Id, OwnerId, Requires_Routing__c FROM Carrier_Order__c WHERE OwnerId IN :set_UserId AND Implementation_Stage__c NOT IN :set_ImpStage]) {
			objCarrierOrder.Requires_Routing__c = true;
			list_CarrierOrder.add(objCarrierOrder);
		}
		if (!list_CarrierOrder.isEmpty()) {
			CarrierOrderTriggerHelper.skipTrigger = true;
			update list_CarrierOrder;
		}
	}

	public class UserWrapper {
		public String oldValue;
		public String newValue;
		public String userId;
		public String changedFieldStr;

		public UserWrapper() {
		}
	}
}