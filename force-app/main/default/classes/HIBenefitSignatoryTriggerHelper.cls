public with sharing class HIBenefitSignatoryTriggerHelper extends TriggerHandler {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;

	public HIBenefitSignatoryTriggerHelper() {
		super('HIBenefitSignatoryTriggerHelper');
	}

	public override void beforeInsert() {
		List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory = (List<HI_Benefits_Signatory__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_HIBenefitsSignatory);
		} else {
			for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
				objHIBenefitSignatory.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory = (List<HI_Benefits_Signatory__c>) Trigger.new;
		if (queue == false && !Test.isRunningTest()) {
			HIBenefitSignatoryQueue objUpdateJob = new HIBenefitSignatoryQueue(list_HIBenefitsSignatory);
			ID idJob = System.enqueueJob(objUpdateJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory = (List<HI_Benefits_Signatory__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_HIBenefitsSignatory);
		} else {
			for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
				objHIBenefitSignatory.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory = (List<HI_Benefits_Signatory__c>) Trigger.new;
		if (queue == false && !Test.isRunningTest()) {
			HIBenefitSignatoryQueue objUpdateJob = new HIBenefitSignatoryQueue(list_HIBenefitsSignatory);
			ID idJob = System.enqueueJob(objUpdateJob);
		}
	}

	private void processInformation(List<HI_Benefits_Signatory__c> list_HIBenefitsSignatory) {
		Set<String> set_CompanyId = new Set<String>();
		Set<String> set_UserId = new Set<String>();
		Set<String> set_EmailId = new Set<String>();
		List<Contact> list_ContactCreation = new List<Contact>();
		Set<String> set_ZPUserId = new Set<String>();
		String strEmailId = '';

		for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
			if (objHIBenefitSignatory.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (String.isNotBlank(objHIBenefitSignatory.Company_Id__c)) {
				set_CompanyId.add(objHIBenefitSignatory.Company_Id__c);
			}
			if (String.isNotBlank(objHIBenefitSignatory.ZP_User_Id__c)) {
				set_UserId.add(objHIBenefitSignatory.ZP_User_Id__c);
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

				if (String.isNotBlank(objZPUser.Id__c)) {
					set_ZPUserId.add(objZPUser.Id__c);
				}
			}
		}

		map<String, Contact> map_Contact = new Map<String, Contact>();
		if (!set_EmailId.isEmpty() || !set_ZPUserId.isEmpty()) {
			map_Contact = HIBenefitsUtil.getContacts(set_EmailId, set_ZPUserId);
		}

		for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
			if (objHIBenefitSignatory.Processing_State__c == IntegrationUtils.DEAD_STATE) {
				continue;
			}
			if (String.isBlank(objHIBenefitSignatory.Company_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.COMPANY_ID_NULL, objHIBenefitSignatory);
				continue;
			}
			if (!map_Account.containsKey(objHIBenefitSignatory.Company_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.COMPANY_DOES_NOT_EXIST, objHIBenefitSignatory);
				continue;
			}
			if (String.isBlank(objHIBenefitSignatory.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.USER_ID_NULL, objHIBenefitSignatory);
				continue;
			}
			if (!map_ZPUser.containsKey(objHIBenefitSignatory.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.ZPUSER_DOES_NOT_EXIST, objHIBenefitSignatory);
				continue;
			}

			//DS[12-Nov-2020] make the ZP_User__c object above the user Role Map
			ZP_User__c objZPUser = map_ZPUser.get(objHIBenefitSignatory.ZP_User_Id__c);
			//In ZP_User__c object, Email__c is a text field that's why we need to convert into lower case then search in Map.
			strEmailId = objZPUser.Email__c;
			if (String.isNotBlank(strEmailId)) {
				strEmailId = strEmailId.toLowerCase();
			}

			if (!map_ZPUserRole.containsKey(objHIBenefitSignatory.ZP_User_Id__c)) {
				String strErrorMessage = HIBenefitsUtil.ZPUSERROLE_DOES_NOT_EXIST;
				//DS[12-Nov-2020] added the check for Gusto email address
				if (String.isNotBlank(strEmailId) && strEmailId.indexOf('@gusto.com') != -1) {
					strErrorMessage = HIBenefitsUtil.ZPUSERROLE_GUSTO_DOES_NOT_EXIST;
				}
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, strErrorMessage, objHIBenefitSignatory);
				continue;
			}

			//ZP_User__c objZPUser = map_ZPUser.get(objHIBenefitSignatory.ZP_User_Id__c);
			ZP_User_Role__c objZPUserRole = map_ZPUserRole.get(objHIBenefitSignatory.ZP_User_Id__c);
			if (String.isBlank(strEmailId)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, HIBenefitsUtil.ZPUSER_DOES_NOT_HAVE_EMAIL, objHIBenefitSignatory);
				continue;
			}
			Account objAcc = map_Account.get(objHIBenefitSignatory.Company_Id__c);
			if (!map_Contact.containsKey(strEmailId) && !map_Contact.containsKey(objZPUser.Id__c) && objHIBenefitSignatory.Deleted_At__c == null) {
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
			map_DMLContactInsertErrors = Utils.processSaveResult(list_SaveResult, list_ContactCreation, 'ZP_User_Id__c', true, 'ZPBenefitsSignatoryTriggerHepler-processInformation');
			for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
				if (map_DMLContactInsertErrors.containsKey(objHIBenefitSignatory.ZP_User_Id__c)) {
					setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DMLContactInsertErrors.get(objHIBenefitSignatory.ZP_User_Id__c), objHIBenefitSignatory);
				}
			}
			//if contact is created during HI benefits Signatory record.
			//then we have to refresh the contact map again.
			if (!set_EmailId.isEmpty()) {
				map_Contact = HIBenefitsUtil.getContacts(set_EmailId, new Set<String>());
			}
		}

		Map<String, OpportunityContactRole> map_OppContactRelation = HIBenefitsUtil.getOpportunityContactRelations(set_EmailId, map_AccountOpportunities, HIBenefitsUtil.BENEFIT_SIGNATORY);
		List<OpportunityContactRole> list_ContactRoleToBeUpsert = new List<OpportunityContactRole>();
		List<OpportunityContactRole> list_ContactRoleToBeDeleted = new List<OpportunityContactRole>();
		Map<Id, Set<Id>> map_OppIdsContactIds = new Map<Id, Set<Id>>();
		Map<String, Id> map_ZPUserIdContactId = new Map<String, Id>();
		Set<String> set_CompanyIds = new Set<String>();
		for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
			if (objHIBenefitSignatory.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIBenefitSignatory.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}

			ZP_User__c objZPUser = map_ZPUser.get(objHIBenefitSignatory.ZP_User_Id__c);
			Account objAcc = map_Account.get(objHIBenefitSignatory.Company_Id__c);
			//In ZP_User__c object, Email__c is a text field that's why we need to convert into lower case then search in Map.
			strEmailId = objZPUser.Email__c;
			if (String.isNotBlank(strEmailId)) {
				strEmailId = strEmailId.toLowerCase();
			}
			Contact objContact = map_Contact.get(strEmailId);

			//DS[12-Nov-2020]
			if (!map_AccountOpportunities.isEmpty() && map_AccountOpportunities.containsKey(objAcc.Id) && objContact != null) {
				for (Opportunity objOpportunity : map_AccountOpportunities.get(objAcc.Id)) {
					if (objOpportunity.IsClosed == false) {
						if (!map_OppContactRelation.isEmpty() && map_OppContactRelation.containsKey(objOpportunity.Id + '-' + objContact.Id)) {
							OpportunityContactRole objContactRole = map_OppContactRelation.get(objOpportunity.Id + '-' + objContact.Id);
							if (objHIBenefitSignatory.Deleted_At__c != null) {
								list_ContactRoleToBeDeleted.add(objContactRole);
							} else {
								objContactRole.Role = HIBenefitsUtil.BENEFIT_SIGNATORY;
								objContactRole.ContactId = objContact.Id;
								list_ContactRoleToBeUpsert.add(objContactRole);
							}
						} else if (objHIBenefitSignatory.Deleted_At__c == null) {
							OpportunityContactRole objContactRole = new OpportunityContactRole();
							objContactRole.OpportunityId = objOpportunity.Id;
							objContactRole.ContactId = objContact.Id;
							objContactRole.Role = HIBenefitsUtil.BENEFIT_SIGNATORY;
							list_ContactRoleToBeUpsert.add(objContactRole);
						}
					}
					if (objHIBenefitSignatory.Deleted_At__c == null) {
						if (map_OppIdsContactIds?.containsKey(objOpportunity.Id)) {
							map_OppIdsContactIds.get(objOpportunity.Id).add(objContact.Id);
						} else {
							map_OppIdsContactIds.put(objOpportunity.Id, new Set<Id>{ objContact.Id });
						}
					} else if (objHIBenefitSignatory.Deleted_At__c != null) {
						map_ZPUserIdContactId.put(objHIBenefitSignatory.ZP_User_Id__c, objContact.Id);
						set_CompanyIds.add(objHIBenefitSignatory.Company_Id__c);
					}
				}
			}
		}

		Map<String, String> map_DmlRelationUpsertErrors = new Map<String, String>();
		Map<String, String> map_DmlRelationDeleteErrors = new Map<String, String>();
		if (!list_ContactRoleToBeUpsert.isEmpty()) {
			List<Database.UpsertResult> list_UpsertResult = database.upsert(list_ContactRoleToBeUpsert, false);
			map_DmlRelationUpsertErrors = Utils.processUpsertResult(list_UpsertResult, list_ContactRoleToBeUpsert, 'ZP_User_Id__c', true, 'ZPBenefitsSignatoryTriggerHepler-processInformation');
		}

		if (!list_ContactRoleToBeDeleted.isEmpty()) {
			List<Database.DeleteResult> list_DeleteResult = database.delete(list_ContactRoleToBeDeleted, false);
			map_DmlRelationDeleteErrors = Utils.processDeleteResult(list_DeleteResult, list_ContactRoleToBeDeleted, 'ZP_User_Id__c', true, 'ZPBenefitsSignatoryTriggerHepler-processInformation');
		}

		if (!map_OppIdsContactIds.isEmpty()) {
			HIBenefitsAdminTriggerHelper.createCaseTeamMembersForExistingCase(map_OppIdsContactIds);
		}

		if (!map_ZPUserIdContactId?.isEmpty()) {
			HIBenefitsAdminTriggerHelper.deleteCaseTeamMemberForExistingCase(map_ZPUserIdContactId, set_CompanyIds, false);
		}

		for (HI_Benefits_Signatory__c objHIBenefitSignatory : list_HIBenefitsSignatory) {
			if (objHIBenefitSignatory.Processing_State__c == IntegrationUtils.DEAD_STATE || objHIBenefitSignatory.Processing_State__c == IntegrationUtils.ERROR_STATE) {
				continue;
			}
			if (map_DmlRelationUpsertErrors.containsKey(objHIBenefitSignatory.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DmlRelationUpsertErrors.get(objHIBenefitSignatory.ZP_User_Id__c), objHIBenefitSignatory);
				continue;
			}
			if (map_DmlRelationDeleteErrors.containsKey(objHIBenefitSignatory.ZP_User_Id__c)) {
				setProcessingStateCarrier(IntegrationUtils.ERROR_STATE, map_DmlRelationDeleteErrors.get(objHIBenefitSignatory.ZP_User_Id__c), objHIBenefitSignatory);
				continue;
			}
			setProcessingStateCarrier(IntegrationUtils.PROCESSED_STATE, 'Processed', objHIBenefitSignatory);
		}
	}

	// populating HI_State_carrier__c object fields
	private HI_Benefits_Signatory__c setProcessingStateCarrier(String ProcessingState, String message, HI_Benefits_Signatory__c objHIBenefitSignatory) {
		objHIBenefitSignatory.Processing_State__c = ProcessingState;
		objHIBenefitSignatory.Message__c = message;
		objHIBenefitSignatory.Last_Processed__c = System.now();
		return objHIBenefitSignatory;
	}
}