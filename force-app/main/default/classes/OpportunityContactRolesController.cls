/*
 * @name         : OpportunityContactRolesController
 * @author       : Debasmita Rawooth
 * @date         : 14-09-2024
 * @description  : Controller for showContactRolesOnOrderCmp
 * @test classes : OpportunityContactRolesControllerTest
 */
public with sharing class OpportunityContactRolesController {
	public static final String CUSTOMER_CONTACT = 'Customer Contact';

	/*
	 * @author      : Debasmita Rawooth
	 * @description : On load of the component show contact roles
	 */
	@AuraEnabled(cacheable=true)
	public static List<OpportunityContactRole> getContactRolesByOrder(Id idOrder) {
		List<String> list_oppContactRoles = System.Label.PT_Opportunity_Contact_Roles_Order.split(',');
		Map<String, Integer> map_roleToRank = new Map<String, Integer>();

		for (Integer i = 0; i < list_oppContactRoles.size(); i++) {
			map_roleToRank.put(list_oppContactRoles[i].trim(), i + 1);
		}

		Order objOrder = [SELECT OpportunityId FROM Order WHERE Id = :idOrder LIMIT 1];
		if (objOrder == null || objOrder.OpportunityId == null) {
			return new List<OpportunityContactRole>(); // Return empty list if no related opportunity
		}

		// Query all OpportunityContactRoles for the Opportunity
		List<OpportunityContactRole> list_allRoles = [
			SELECT Id, ContactId, Contact.Name, Role, IsPrimary, Check_Additional_POC__c
			FROM OpportunityContactRole
			WHERE OpportunityId = :objOrder.OpportunityId
		];

		// Map to store the highest-ranked role for contact
		Map<Id, OpportunityContactRole> map_contactToRole = new Map<Id, OpportunityContactRole>();

		for (OpportunityContactRole objRole : list_allRoles) {
			if (map_roleToRank.containsKey(objRole.Role)) {
				Integer intCurrentRank = map_roleToRank.get(objRole.Role);

				if (!map_contactToRole.containsKey(objRole.ContactId)) {
					map_contactToRole.put(objRole.ContactId, objRole);
				} else {
					OpportunityContactRole objExistingRole = map_contactToRole.get(objRole.ContactId);
					Integer intExistingRank = map_roleToRank.get(objExistingRole.Role);

					if (intCurrentRank < intExistingRank) {
						map_contactToRole.put(objRole.ContactId, objRole);
					}
				}
			}
		}

		// Return the highest-ranked roles for each contact
		return map_contactToRole.values();
	}

	/*
	 * @author      : Debasmita Rawooth
	 * @description : Update Order, Case, CaseMembers and OpportunityContactRoles based on changes to contact roles
	 */
	@AuraEnabled
	public static void updatePrimaryContactOnOrder(Id idOrder, Id idPrimaryContact, List<Id> list_additionalContactIds) {
		try {
			List<OpportunityContactRole> list_contactRoles = new List<OpportunityContactRole>();
			List<OpportunityContactRole> list_contactRolesToUpdate = new List<OpportunityContactRole>();
			List<Case> list_casesToUpdate = new List<Case>();
			List<CaseTeamMember> list_caseTeamMembersToInsert = new List<CaseTeamMember>();
			OrderTriggerHelper.skipTrigger = true;
			AccountTriggerHelper.skipTrigger = true;
			OpportunityTriggerHelper.skipTrigger = true;
			CaseTriggerHelper.skipTrigger = true;

			// Update primary contact on Order
			if (idOrder != null) {
				Order objOrder = [SELECT Id, Primary_Contact__c, Case__c, OpportunityId FROM Order WHERE Id = :idOrder LIMIT 1];
				if (objOrder != null && idPrimaryContact != null) {
					objOrder.Primary_Contact__c = idPrimaryContact;
					update objOrder;
				} else {
					throw new AuraHandledException('Order not found');
				}

				// Query and update Opportunity Contact Roles
				if (objOrder.OpportunityId != null) {
					list_contactRoles = [
						SELECT Id, ContactId, IsPrimary, Check_Additional_POC__c
						FROM OpportunityContactRole
						WHERE OpportunityId = :objOrder.OpportunityId
					];
					for (OpportunityContactRole objContactRole : list_contactRoles) {
						objContactRole.IsPrimary = (objContactRole.ContactId == idPrimaryContact);
						objContactRole.Check_Additional_POC__c = list_additionalContactIds.contains(objContactRole.ContactId);
						list_contactRolesToUpdate.add(objContactRole);
					}
				}

				if (objOrder.Case__c != null) {
					// Query related Cases and update ContactId
					List<Case> list_Cases = [SELECT Id, ContactId FROM Case WHERE Id = :objOrder.Case__c];
					if (!list_Cases.isEmpty()) {
						for (Case objCase : list_Cases) {
							objCase.ContactId = idPrimaryContact; // Set the Case Contact lookup to the new primary contact
							list_casesToUpdate.add(objCase);
						}
					}

					// Handle Case Team Members for additional contacts

					Map<String, CaseTeamRole> map_CaseTeamRole = GlobalQueryHelper.getCaseTeamRole();
					Set<Id> set_existingTeamMembers = new Set<Id>(); // Set to store existing CaseTeamMember IDs
					Id idTeamRole;
					if (map_CaseTeamRole.containsKey(CUSTOMER_CONTACT)) {
						idTeamRole = map_CaseTeamRole.get(CUSTOMER_CONTACT).Id;
					}

					if (!list_Cases.isEmpty() && idTeamRole != null) {
						// Query existing CaseTeamMembers to avoid duplicates
						List<CaseTeamMember> list_existingMembers = [
							SELECT MemberId, ParentId
							FROM CaseTeamMember
							WHERE ParentId = :list_Cases[0].Id AND TeamRoleId = :idTeamRole
						];

						for (CaseTeamMember objMember : list_existingMembers) {
							set_existingTeamMembers.add(objMember.MemberId);
						}
						// Create CaseTeamMembers
						if (!list_additionalContactIds.isEmpty()) {
							for (Id idContact : list_additionalContactIds) {
								if (!set_existingTeamMembers.contains(idContact)) {
									CaseTeamMember teamMember = new CaseTeamMember();
									teamMember.ParentId = list_Cases[0].Id;
									teamMember.MemberId = idContact;
									teamMember.TeamRoleId = idTeamRole;
									list_caseTeamMembersToInsert.add(teamMember);
								}
							}
						}
					}
				}
			}

			// Update Contact Roles
			if (!list_contactRolesToUpdate.isEmpty()) {
				update list_contactRolesToUpdate;
			}
			// Update Case with Contact info
			if (!list_casesToUpdate.isEmpty()) {
				update list_casesToUpdate;
			}
			// Insert new CaseTeamMembers if there are any
			if (!list_caseTeamMembersToInsert.isEmpty()) {
				insert list_caseTeamMembersToInsert;
			}

			OrderTriggerHelper.skipTrigger = false;
			AccountTriggerHelper.skipTrigger = false;
			OpportunityTriggerHelper.skipTrigger = false;
			CaseTriggerHelper.skipTrigger = false;
		} catch (Exception ex) {
			throw new AuraHandledException('Error updating Primary Contact: ' + ex.getMessage());
		}
	}
}