public with sharing class HIBenefitsAdminTriggerHelper extends TriggerHandler {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;
	public static final String CUSTOMER_CONTACT = 'Customer Contact';
	public static final Set<String> set_BOStatus = new Set<String>{ 'Fulfilled', 'Closed Admin', 'Canceled', 'Closed Lost' };

	public HIBenefitsAdminTriggerHelper() {
		super('HIBenefitsAdminTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_Benefits_Admin__c> list_HIBenefitsAdmin = (List<HI_Benefits_Admin__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_HIBenefitsAdmin);
		} else {
			for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
				objHIAdmin.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Benefits_Admin__c> list_HIBenefitsAdmin = (List<HI_Benefits_Admin__c>) Trigger.new;
		if (queue == false && !Test.isRunningTest()) {
			HIBenefitsAdminQueue objUpdateJob = new HIBenefitsAdminQueue(list_HIBenefitsAdmin);
			ID idJob = System.enqueueJob(objUpdateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_Benefits_Admin__c> list_HIBenefitsAdmin = (List<HI_Benefits_Admin__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_HIBenefitsAdmin);
		} else {
			for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
				objHIAdmin.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Benefits_Admin__c> list_HIBenefitsAdmin = (List<HI_Benefits_Admin__c>) Trigger.new;
		if (queue == false && !Test.isRunningTest()) {
			HIBenefitsAdminQueue objUpdateJob = new HIBenefitsAdminQueue(list_HIBenefitsAdmin);
			ID idJob = System.enqueueJob(objUpdateJob);
		}
	}

	public void processInformation(List<HI_Benefits_Admin__c> list_HIBenefitsAdmin) {
		Set<String> set_CompanyId = new Set<String>();
		Set<String> set_UserId = new Set<String>();
		Set<String> set_EmailId = new Set<String>();
		List<Contact> list_ContactCreation = new List<Contact>();
		String strEmailId = '';

		for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
			if (objHIAdmin.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (String.isNotBlank(objHIAdmin.Company_Id__c)) {
				set_CompanyId.add(objHIAdmin.Company_Id__c);
			}
			if (String.isNotBlank(objHIAdmin.ZP_User_Id__c)) {
				set_UserId.add(objHIAdmin.ZP_User_Id__c);
			}
		}

		Set<Opportunity> set_Opportunity = new Set<Opportunity>();
		map<String, Account> map_Account = HIBenefitsUtil.getAccountInformation(set_CompanyId);
		Map<Id, List<Opportunity>> map_AccountOpportunities = HIBenefitsUtil.getOpportunityIds(set_CompanyId);
		map<String, ZP_User__c> map_ZPUser = HIBenefitsUtil.getZPUsers(set_UserId);
		map<String, ZP_User_Role__c> map_ZPUserRole = HIBenefitsUtil.getZPUserRoles(set_UserId);
		if (!map_ZPUser.isEmpty()) {
			for (ZP_User__c objZPUser : map_ZPUser.values()) {
				if (String.isNotBlank(objZPUser.email__c)) {
					set_EmailId.add(objZPUser.email__c);
				}
			}
		}
		map<String, Contact> map_Contact = new Map<String, Contact>();
		if (!set_EmailId.isEmpty() || !set_UserId.isEmpty()) {
			map_Contact = HIBenefitsUtil.getContacts(set_EmailId, set_UserId);
		}
		for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
			if (objHIAdmin.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (String.isBlank(objHIAdmin.Company_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.COMPANY_ID_NULL, objHIAdmin);
				continue;
			}
			if (!map_Account.containsKey(objHIAdmin.Company_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.COMPANY_DOES_NOT_EXIST, objHIAdmin);
				continue;
			}
			if (String.isBlank(objHIAdmin.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.USER_ID_NULL, objHIAdmin);
				continue;
			}
			if (!map_ZPUser.containsKey(objHIAdmin.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.ZPUSER_DOES_NOT_EXIST, objHIAdmin);
				continue;
			}

			//we have already checked map_ZPUser containkey with ZP User Id above
			ZP_User__c objZPUser = map_ZPUser.get(objHIAdmin.ZP_User_Id__c);
			//In ZP_User__c object, Email__c is a text field that's why we need to convert into lower case then search in Map.
			strEmailId = objZPUser.Email__c;
			if (String.isNotBlank(strEmailId)) {
				strEmailId = strEmailId.toLowerCase();
			}

			if (!map_ZPUserRole.containsKey(objHIAdmin.ZP_User_Id__c)) {
				String strErrorMessage = HIBenefitsUtil.ZPUSERROLE_DOES_NOT_EXIST;
				//DS[12-Nov-2020] added the check for Gusto email address
				if (String.isNotBlank(strEmailId) && strEmailId.indexOf('@gusto.com') != -1) {
					strErrorMessage = HIBenefitsUtil.ZPUSERROLE_GUSTO_DOES_NOT_EXIST;
				}
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, strErrorMessage, objHIAdmin);
				continue;
			}
			//we have already checked map_ZPUserRole containkey with ZP User Id above
			ZP_User_Role__c objZPUserRole = map_ZPUserRole.get(objHIAdmin.ZP_User_Id__c);

			if (String.isBlank(strEmailId)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.ZPUSER_DOES_NOT_HAVE_EMAIL, objHIAdmin);
				continue;
			}
			//we have already checked map_Account containkey with Company Id above
			Account objAcc = map_Account.get(objHIAdmin.Company_Id__c);
			if (!map_Contact.containsKey(strEmailId) && !map_Contact.containsKey(objZPUser.Id__c) && objHIAdmin.Deleted_At__c == null) {
				Contact objContact = new Contact();
				objContact.Email = strEmailId;
				objContact.FirstName = objZPUserRole.First_Name__c;
				objContact.LastName = objZPUserRole.Last_Name__c;
				objContact.AccountId = objAcc.Id;
				objContact.ZP_User_Id__c = objZPUser.Id__c;
				list_ContactCreation.add(objContact);
			}
		}

		Map<String, String> map_DMLContactInsertErrors = new Map<String, String>();
		if (!list_ContactCreation.isEmpty()) {
			List<Database.SaveResult> list_SaveResult = database.insert(list_ContactCreation, false);
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResult, list_ContactCreation, 'ZP_User_Id__c', true, 'ZPBenefitsAdminTriggerHepler-processInformation');
			for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
				if (map_DMLContactInsertErrors.containsKey(objHIAdmin.ZP_User_Id__c)) {
					setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHIAdmin.ZP_User_Id__c), objHIAdmin);
				}
			}
			//if contact is created during HI benefits admin record.
			//then we have to refresh the contact map again.
			if (!set_EmailId.isEmpty()) {
				map_Contact = HIBenefitsUtil.getContacts(set_EmailId, new Set<String>());
			}
		}

		Map<String, OpportunityContactRole> map_OppContactRelation = HIBenefitsUtil.getOpportunityContactRelations(set_EmailId, map_AccountOpportunities, HIBenefitsUtil.BENEFIT_ADMIN);
		List<OpportunityContactRole> list_ContactRoleToBeUpsert = new List<OpportunityContactRole>();
		List<OpportunityContactRole> list_ContactRoleToBeDeleted = new List<OpportunityContactRole>();
		Map<Id, Set<Id>> map_OppIdsContactIds = new Map<Id, Set<Id>>();
		Map<String, Id> map_ZPUserIdContactId = new Map<String, Id>();
		Set<String> set_CompanyIds = new Set<String>();
		for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
			if (objHIAdmin.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIAdmin.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			ZP_User__c objZPUser = map_ZPUser.get(objHIAdmin.ZP_User_Id__c);
			Account objAcc = map_Account.get(objHIAdmin.Company_Id__c);
			//In ZP_User__c object, Email__c is a text field that's why we need to convert into lower case then search in Map
			strEmailId = objZPUser.Email__c;
			if (String.isNotBlank(strEmailId)) {
				strEmailId = strEmailId.toLowerCase();
			}
			Contact objContact = map_Contact.get(strEmailId);
			if (!map_AccountOpportunities.isEmpty() && map_AccountOpportunities.containsKey(objAcc.Id) && objContact != null) {
				for (Opportunity objOpportunity : map_AccountOpportunities.get(objAcc.Id)) {
					if (objOpportunity.IsClosed == false) {
						if (!map_OppContactRelation.isEmpty() && map_OppContactRelation.containsKey(objOpportunity.Id + '-' + objContact.Id)) {
							OpportunityContactRole objContactRole = map_OppContactRelation.get(objOpportunity.Id + '-' + objContact.Id);
							if (objHIAdmin.Deleted_At__c != null) {
								list_ContactRoleToBeDeleted.add(objContactRole);
							} else {
								objContactRole.Role = HIBenefitsUtil.BENEFIT_ADMIN;
								objContactRole.ContactId = objContact.Id;
								list_ContactRoleToBeUpsert.add(objContactRole);
							}
						} else if (objHIAdmin.Deleted_At__c == null) {
							OpportunityContactRole objContactRole = new OpportunityContactRole();
							objContactRole.OpportunityId = objOpportunity.Id;
							objContactRole.ContactId = objContact.Id;
							objContactRole.Role = HIBenefitsUtil.BENEFIT_ADMIN;
							list_ContactRoleToBeUpsert.add(objContactRole);
						}
					}
					if (objHIAdmin.Deleted_At__c == null) {
						if (map_OppIdsContactIds?.containsKey(objOpportunity.Id)) {
							map_OppIdsContactIds.get(objOpportunity.Id).add(objContact.Id);
						} else {
							map_OppIdsContactIds.put(objOpportunity.Id, new Set<Id>{ objContact.Id });
						}
					} else if (objHIAdmin.Deleted_At__c != null) {
						map_ZPUserIdContactId.put(objHIAdmin.ZP_User_Id__c, objContact.Id);
						set_CompanyIds.add(objHIAdmin.Company_Id__c);
					}
				}
			}
		}

		Map<String, String> map_DmlRelationUpsertErrors = new Map<String, String>();
		Map<String, String> map_DmlRelationDeleteErrors = new Map<String, String>();
		if (!list_ContactRoleToBeUpsert.isEmpty()) {
			List<Database.UpsertResult> list_UpsertResult = database.upsert(list_ContactRoleToBeUpsert, false);
			map_DmlRelationUpsertErrors = Utils.processUpsertResult(list_UpsertResult, list_ContactRoleToBeUpsert, 'ZP_User_Id__c', true, 'ZPBenefitsAdminTriggerHepler-processInformation');
		}
		if (!list_ContactRoleToBeDeleted.isEmpty()) {
			List<Database.DeleteResult> list_DeleteResult = database.delete(list_ContactRoleToBeDeleted, false);
			map_DmlRelationDeleteErrors = Utils.processDeleteResult(list_DeleteResult, list_ContactRoleToBeDeleted, 'ZP_User_Id__c', true, 'ZPBenefitsAdminTriggerHepler-processInformation');
		}

		if (!map_OppIdsContactIds.isEmpty()) {
			createCaseTeamMembersForExistingCase(map_OppIdsContactIds);
		}
		if (!map_ZPUserIdContactId?.isEmpty()) {
			deleteCaseTeamMemberForExistingCase(map_ZPUserIdContactId, set_CompanyIds, true);
		}

		for (HI_Benefits_Admin__c objHIAdmin : list_HIBenefitsAdmin) {
			if (objHIAdmin.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIAdmin.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_DmlRelationUpsertErrors.containsKey(objHIAdmin.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DmlRelationUpsertErrors.get(objHIAdmin.ZP_User_Id__c), objHIAdmin);
				continue;
			}
			if (map_DmlRelationDeleteErrors.containsKey(objHIAdmin.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DmlRelationDeleteErrors.get(objHIAdmin.ZP_User_Id__c), objHIAdmin);
				continue;
			}
			setProcessingStateCarrier(IntegrationUtils.PROCESSED_STATE, HIBenefitsUtil.PROCESSED_MESSAGE, objHIAdmin);
		}
	}

	// populating HI_State_carrier__c object fields
	private HI_Benefits_Admin__c setProcessingStateCarrier(String ProcessingState, String message, HI_Benefits_Admin__c objHIAdmin) {
		objHIAdmin.Processing_State__c = ProcessingState;
		objHIAdmin.Message__c = message;
		objHIAdmin.Last_Processed__c = System.now();
		return objHIAdmin;
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to Update Case Team on Existing Onboarding Cases
	 * @param       map_OppIdsContactIds
	 * @return      NA
	 */
	public static void createCaseTeamMembersForExistingCase(Map<Id, Set<Id>> map_OppIdsContactIds) {
		List<CaseTeamMember> list_CaseTeamMembers = new List<CaseTeamMember>();
		Map<String, CaseTeamRole> map_CaseTeamRole = GlobalQueryHelper.getCaseTeamRole();
		if (map_CaseTeamRole?.containsKey(CUSTOMER_CONTACT)) {
			map<Id, Case> map_CaseIdCase = new Map<Id, Case>(
				[
					SELECT Id, Opportunity__c, Integration_Id__c, ContactId
					FROM Case
					WHERE
						Opportunity__c = :map_OppIdsContactIds.keySet()
						AND ContactId != NULL
						AND Integration_Id__c LIKE 'hippo%'
						AND (Benefit_Order__c = NULL
						OR (Benefit_Order__c != NULL
						AND Benefit_Order__r.Order_Status__c NOT IN :set_BOStatus))
				]
			);
			Set<Id> set_contactAlreadyMember = new Set<Id>();
			for (CaseTeamMember objCaseTeamMember : [SELECT Id, MemberId FROM CaseTeamMember WHERE ParentId IN :map_CaseIdCase.keySet() AND TeamRoleId = :map_CaseTeamRole.get(CUSTOMER_CONTACT).Id]) {
				set_contactAlreadyMember.add(objCaseTeamMember.MemberId);
			}
			for (Case objCase : map_CaseIdCase.values()) {
				if (map_OppIdsContactIds.containsKey(objCase.Opportunity__c)) {
					for (Id contactId : map_OppIdsContactIds.get(objCase.Opportunity__c)) {
						if (!set_contactAlreadyMember?.contains(contactId)) {
							CaseTeamMember objCaseTeam = new CaseTeamMember(MemberId = contactId, ParentId = objCase.Id, TeamRoleId = map_CaseTeamRole.get(CUSTOMER_CONTACT).Id);
							list_CaseTeamMembers.add(objCaseTeam);
						}
					}
				}
			}
		}

		if (!list_CaseTeamMembers.isEmpty()) {
			insert list_CaseTeamMembers;
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to Update Case Team on Existing Onboarding Cases
	 * @param       map_ZPUserIdContactId,
	 *              blnIsBenefitAdmin
	 * @return      NA
	 */
	public static void deleteCaseTeamMemberForExistingCase(map<String, Id> map_ZPUserIdContactId, Set<String> set_CompanyIds, Boolean blnIsBenefitAdmin) {
		List<CaseTeamMember> list_caseTeamMember = new List<CaseTeamMember>();
		if (blnIsBenefitAdmin) {
			for (HI_Benefits_Signatory__c objHiBenefitSignatory : [
				SELECT Id, ZP_User_Id__c, Company_Id__c
				FROM HI_Benefits_Signatory__c
				WHERE Deleted_At__c = NULL AND ZP_User_Id__c IN :map_ZPUserIdContactId.keySet() AND Company_Id__c IN :set_CompanyIds
			]) {
				map_ZPUserIdContactId.remove(objHiBenefitSignatory.ZP_User_Id__c);
			}
		} else {
			for (HI_Benefits_Admin__c objHiBenefitAdmin : [
				SELECT Id, ZP_User_Id__c
				FROM HI_Benefits_Admin__c
				WHERE Deleted_At__c = NULL AND ZP_User_Id__c IN :map_ZPUserIdContactId.keySet() AND Company_Id__c IN :set_CompanyIds
			]) {
				map_ZPUserIdContactId.remove(objHiBenefitAdmin.ZP_User_Id__c);
			}
		}
		if (!map_ZPUserIdContactId.isEmpty()) {
			for (CaseTeamMember objCaseTeam : [SELECT Id, MemberId, ParentId FROM CaseTeamMember WHERE MemberId IN :map_ZPUserIdContactId.values()]) {
				list_caseTeamMember.add(objCaseTeam);
			}
		}
		if (!list_caseTeamMember.isEmpty()) {
			delete list_caseTeamMember;
		}
	}
}