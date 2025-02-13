global class ReassignBenefitOrderOwnerCtrl {
	public static Set<String> set_BOStatus = new Set<String>{ BenefitOrderUtil.STATUS_CANCELLED, BenefitOrderUtil.STATUS_CLOSED_LOST, BenefitOrderUtil.STATUS_CLOSED_ADMIN };
	public static List<Id> set_BOIds = new List<Id>();
	public static String strReturnURL;
	public static String strRoleName;
	public static Boolean blnGroupMember;
	public static Boolean blnOOOLoggedInUser;
	public static set<Id> set_OOOUsers;

	//strRoles
	public static final String IA_OWNER_ASSIGNEMENT = 'Implementation_Advocate_Owner_Assignment';
	public static final String BENEFITS_ONBOARDING_IMPLEMENTATION = 'Benefits Onboarding Implementation';

	//Return Statements
	public static final String MSG_RETURN_FROM_OOO_TO_REASSIGN_BO = 'You must return from OOO to reassign your previously owned Benefit Orders back to your queue.';
	public static final String MSG_BO_NOT_ASSIGN_ONLY_YOUR_ORDER_MOVE = 'This Benefit Order is not assigned to you.Only your orders can be moved.';
	public static final String MSG_TURN_YOUR_OOO_TO_REASSIGN_BO_TO_TEAM = 'You must turn your OOO on to reassign Benefit Orders to the team.';
	public static final String MSG_SELECT_PARENT_CMPNY_CHILD_CMPNY_WILL_REASSIGN = 'Please select the parent company only, and the child company will be reassigned accordingly.';
	public static final String MSG_ORDER_SHOULD_BE_OPEN_STAGE = 'Order should be in open stage';
	public static final String MSG_ORDERS_ALREADY_IN_PROGRESS = 'Some of the Orders are already in OOO Progress';
	public static final String MSG_ASSIGNMENT_UNDER_PROCESS_WAIT_SOMETIME = 'Assignment under Process, wait for some time.';

	//Check logged in user rol
	public static void RetriveRoleName() {
		UserRole objRole = [SELECT Id, Name FROM userRole WHERE id = :UserInfo.getUserRoleId() LIMIT 1];
		strRoleName = objRole.Name;
		blnOOOLoggedInUser = [SELECT Out_Of_Office__c FROM User WHERE id = :UserInfo.getUserId() LIMIT 1].Out_Of_Office__c;
	}

	//There is additional request if user do not have manager role even want to transfer others BO
	public static void ValidateUserAddedInGroup() {
		blnGroupMember = false;
		List<GroupMember> list_GroupMember = [SELECT groupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getuserId() AND group.DeveloperName = :IA_OWNER_ASSIGNEMENT];

		if (list_GroupMember != null && list_GroupMember.size() > 0) {
			blnGroupMember = true;
		}
	}

	webService static String changeOwner(List<Id> list_BOs) {
		for (Id objBO : list_BOs) {
			set_BOIds.add(objBO);
		}
		//Get All active user who is out of office
		set_OOOUsers = new Set<Id>();
		for (User usr : [SELECT Id, Name FROM User WHERE isActive = TRUE AND Out_Of_Office__c = TRUE]) {
			set_OOOUsers.add(usr.id);
		}
		return AssignOwner('2');
	}

	webService static String changeOwnerToSelf(List<Id> list_BOs) {
		set_BOStatus = new Set<String>();
		for (Id objBO : list_BOs) {
			set_BOIds.add(objBO);
		}
		return AssignOwner('1');
	}

	public static String AssignOwner(String strAssignType) {
		Set<Id> set_BOWithoutParentIds = new Set<Id>();
		Set<Id> set_BORecTypeIdsToExclude = new Set<Id>{ BenefitOrderUtil.BoR_BENEFIT_ORDER_RT_ID, BenefitOrderUtil.RENEWAL_ALIGNMENT_BENEFIT_ORDER_RT_ID };

		try {
			if (set_BOIds != null && !set_BOIds.isEmpty()) {
				//If Owner is Manager then can change owner of any benefit order
				//If owner is non manager he can send to assign new owner for his own assigned BO
				Boolean blnRecordExist = false;
				Boolean blnOOOInProgress = false;
				RetriveRoleName();
				ValidateUserAddedInGroup();

				List<Benefit_Order__c> list_BenefitOrders = new List<Benefit_Order__c>();

				for (Benefit_Order__c objBO : [
					SELECT
						Id,
						Parent_Benefit_Order__c,
						Initial_Owner__c,
						Type__c,
						OwnerId,
						Tier__c,
						Account__c,
						RecordTypeId,
						Order_Status__c,
						Partner_Tier__c,
						Assignment_State__c,
						Coverage_Effective_Date__c,
						Opportunity__c,
						Coverage_Effective_Month__c,
						Coverage_Effective_Year__c,
						OOO_In_Progress__c
					FROM Benefit_Order__c
					WHERE RecordTypeId NOT IN :set_BORecTypeIdsToExclude AND Id IN :set_BOIds AND Order_Status__c NOT IN :set_BOStatus
					FOR UPDATE
				]) {
					blnRecordExist = true;

					//Logic will always work on parent Benefit order
					if (objBO.Parent_Benefit_Order__c == null) {
						set_BOWithoutParentIds.add(objBO.id);

						//In case of assign to self(Logged in user)
						if (strAssignType == '1') {
							//In Inital owner is logged user use direct assignement to logged in user
							if (blnOOOLoggedInUser == false && objBO.Initial_Owner__c == UserInfo.getUserId()) {
								objBO.Initial_Owner__c = objBO.OwnerId;
								objBO.OwnerId = UserInfo.getUserId(); //Assign logged in user
								list_BenefitOrders.add(objBO);
							} else {
								return MSG_RETURN_FROM_OOO_TO_REASSIGN_BO;
							}
						}

						//In case of owner assignment
						if (strAssignType == '2') {
							//Check all selected record
							if (set_OOOUsers.contains(objBO.OwnerId) == true) {
								//If Logged in user is non manager and selected others assigned BO then show error.
								if (blnGroupMember == false && strRoleName != BENEFITS_ONBOARDING_IMPLEMENTATION && objBO.OwnerId != UserInfo.getUserId()) {
									return MSG_BO_NOT_ASSIGN_ONLY_YOUR_ORDER_MOVE;
								}

								if (objBO.Initial_Owner__c == null) {
									objBO.Initial_Owner__c = objBO.OwnerId;
								}
								list_BenefitOrders.add(objBO);
							} else {
								return MSG_TURN_YOUR_OOO_TO_REASSIGN_BO_TO_TEAM;
							}

							if (objBO.OOO_In_Progress__c) {
								blnOOOInProgress = true;
							}
						}
					} else {
						return MSG_SELECT_PARENT_CMPNY_CHILD_CMPNY_WILL_REASSIGN;
					}
				}

				if (blnRecordExist == false) {
					return MSG_ORDER_SHOULD_BE_OPEN_STAGE;
				}

				if (blnOOOInProgress) {
					return MSG_ORDERS_ALREADY_IN_PROGRESS;
				}

				if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
					Configuration_Settings__c objConfigrationSettings = Utils.ORG_WIDE_CONFIG_SETTINGS;
					Integer intBatchSize = objConfigrationSettings?.OA_Mass_Email_Batch_Size__c != null ? Integer.valueOf(objConfigrationSettings?.OA_Mass_Email_Batch_Size__c) : 5;

					BenefitOrderAssignOrReassignBatch objBatch;

					if (strAssignType == '2') {
						for (Benefit_Order__c objBO : list_BenefitOrders) {
							objBO.OOO_In_Progress__c = true;
						}

						Utils.skipTrigger(true);
						update list_BenefitOrders;
						Utils.skipTrigger(false);

						objBatch = new BenefitOrderAssignOrReassignBatch(set_BOWithoutParentIds, true);
					} else if (strAssignType == '1') {
						objBatch = new BenefitOrderAssignOrReassignBatch(set_BOWithoutParentIds, false);
					}

					if (objBatch != null) {
						Database.executeBatch(objBatch, intBatchSize);
					}
					return MSG_ASSIGNMENT_UNDER_PROCESS_WAIT_SOMETIME;
				}
			}
		} catch (Exception e) {
			return e.getMessage();
		}
		return null;
	}
}