/**
 * @description  Trigger helper of Campaign Member. Updates Unique Accounts Campaign Field
 * @author       Praveen Sethu
 * @date         03-30-2022
 * @see          CampaignMemberTriggerHelperTest
 **/
public class CampaignMemberTriggerHelper {
	public static Boolean skipTrigger = false;

	public static final String CAMPAIGN_TYPE_WEBINAR = 'Webinar';
	public static final String CAMPAIGN_TYPE_EVENT = 'Event';
	public static final String CAMPAIGN_TYPE_GATED_CONTENT = 'Gated Content';
	public static final String CAMPAIGN_TYPE_3RD_PARTY_WEBINAR = '3rd Party Webinar';
	public static final String CAMPAIGN_TYPE_TRAINING = 'Training';
	public static final String CAMPAIGN_TYPE_WEBSITE = 'Website';
	public static final String CAMPAIGN_TYPE_SUBSCRIPTION = 'Subscription';

	public static final Set<String> set_RecentSourceCampaignTypes = new Set<String>{
		CAMPAIGN_TYPE_WEBINAR,
		CAMPAIGN_TYPE_EVENT,
		CAMPAIGN_TYPE_GATED_CONTENT,
		CAMPAIGN_TYPE_3RD_PARTY_WEBINAR,
		CAMPAIGN_TYPE_TRAINING,
		CAMPAIGN_TYPE_WEBSITE,
		CAMPAIGN_TYPE_SUBSCRIPTION
	};

	/**
	 * @description Processes before update context
	 * @author      Praveen Sethu
	 * @param       list_NewMembers - list of campaign members from trigger context
	 * @return      NA
	 **/
	public void OnBeforeInsert(List<CampaignMember> list_NewMembers) {
		updateCampaignMemberFields(list_NewMembers);
	}

	/**
	 * @description Processes after insert context
	 * @author      Rushi R
	 * @param       list_NewMembers - list of campaign members from trigger context
	 * @return      NA
	 **/
	public void OnAfterInsert(List<CampaignMember> list_NewMembers) {
		updateMemberFirstRespondedDate(list_NewMembers);
	}

	/**
	 * @description Processes before update context
	 * @author      Praveen Sethu
	 * @param       map_NewMembers - map of campaign members from trigger context
	 * @param       map_OldMembers - map of  old campaign members from trigger context (Trigger.oldMap)
	 * @return      NA
	 **/
	public void OnBeforeUpdate(Map<Id, CampaignMember> map_OldMembers, Map<Id, CampaignMember> map_NewMembers) {
		updateCampaignMemberFields(map_NewMembers.values());
	}

	/**
	 * @description Processes after update context
	 * @author      Rushi R
	 * @param       map_NewMembers - map of campaign members from trigger context
	 * @param       map_OldMembers - map of  old campaign members from trigger context (Trigger.oldMap)
	 * @return      NA
	 **/
	public void OnAfterUpdate(Map<Id, CampaignMember> map_OldMembers, Map<Id, CampaignMember> map_NewMembers) {
		updateMemberFirstRespondedDate(map_NewMembers.values());
	}

	/**
	 * @description Updates campaign member fields from Lead or Contact
	 * @author      Praveen Sethu
	 * @param       list_NewMembers - list of campaign members from trigger context
	 * @return      NA
	 **/
	public void updateCampaignMemberFields(List<CampaignMember> list_NewMembers) {
		Set<Id> set_LeadIds = new Set<Id>();
		Set<Id> set_ContactIds = new Set<Id>();
		Set<Id> set_CampaignIds = new Set<Id>();

		Map<Id, Lead> map_Leads = new Map<Id, Lead>();
		Map<Id, Contact> map_Contacts = new Map<Id, Contact>();
		Map<Id, Campaign> map_Campaigns = new Map<Id, Campaign>();

		for (CampaignMember objMember : list_NewMembers) {
			if (objMember.LeadId != null) {
				set_LeadIds.add(objMember.LeadId);
			}

			if (objMember.ContactId != null) {
				set_ContactIds.add(objMember.ContactId);
			}

			set_CampaignIds.add(objMember.CampaignId);
		}

		map_Campaigns = queryCampaigns(set_CampaignIds);

		if (set_LeadIds != null && set_LeadIds.size() > 0) {
			map_Leads = new Map<Id, Lead>(
				[
					SELECT
						Id,
						Session_ID_First__c,
						Held_out_of_Upsell_Communications__c,
						Session_ID__c,
						Visitor_ID__c,
						Status,
						Recent_Source__c,
						Recent_Campaign__c,
						Recent_Content__c
					FROM Lead
					WHERE Id IN :set_LeadIds
				]
			);
		}

		if (set_ContactIds != null && set_ContactIds.size() > 0) {
			map_Contacts = new Map<Id, Contact>(
				[
					SELECT
						Id,
						Session_ID_First__c,
						Held_out_of_Upsell_Communications__c,
						Session_ID__c,
						Visitor_ID__c,
						Recent_Source__c,
						Recent_Campaign__c,
						Recent_Content__c
					FROM Contact
					WHERE Id IN :set_ContactIds
				]
			);
		}

		for (CampaignMember objMember : list_NewMembers) {
			Lead objLead = objMember.LeadId != null && map_Leads.containsKey(objMember.LeadId) ? map_Leads.get(objMember.LeadId) : null;
			Contact objContact = objMember.ContactId != null && map_Contacts.containsKey(objMember.ContactId) ? map_Contacts.get(objMember.ContactId) : null;
			Campaign objCampaign = map_Campaigns.containsKey(objMember.CampaignId) ? map_Campaigns.get(objMember.CampaignId) : new Campaign();

			if (objLead != null) {
				objMember.Visitor_ID__c = objLead.Visitor_ID__c;
				objMember.Session_ID__c = objLead.Session_ID__c;

				if (Trigger.isInsert) {
					if (String.isNotBlank(objLead.Status)) {
						objMember.On_Campaign_Member_Create_Lead_Status__c = objLead.Status;
					}
				}

				if (String.isNotBlank(objLead.Session_ID_First__c) && String.isBlank(objMember.Session_ID_First__c)) {
					objMember.Session_ID_First__c = objLead.Session_ID_First__c;
				} else if (String.isNotBlank(objLead.Session_ID__c) && String.isBlank(objMember.Session_ID_First__c)) {
					objMember.Session_ID_First__c = objLead.Session_ID__c;
				}
			} else if (objContact != null) {
				objMember.Visitor_ID__c = objContact.Visitor_ID__c;
				objMember.Session_ID__c = objContact.Session_ID__c;

				if (String.isNotBlank(objContact.Session_ID_First__c) && String.isBlank(objMember.Session_ID_First__c)) {
					objMember.Session_ID_First__c = objContact.Session_ID_First__c;
				} else if (String.isNotBlank(objContact.Session_ID__c) && String.isBlank(objMember.Session_ID_First__c)) {
					objMember.Session_ID_First__c = objContact.Session_ID__c;
				}
			}

			if (objMember.HasResponded && String.isNotBlank(objCampaign.Type) && set_RecentSourceCampaignTypes.contains(objCampaign.Type)) {
				if (objContact != null) {
					if (String.isNotBlank(objContact.Recent_Source__c) && String.isBlank(objMember.Recent_Source__c)) {
						objMember.Recent_Source__c = objContact.Recent_Source__c;
					}

					if (String.isNotBlank(objContact.Recent_Campaign__c) && String.isBlank(objMember.Recent_Campaign__c)) {
						objMember.Recent_Campaign__c = objContact.Recent_Campaign__c;
					}

					if (String.isNotBlank(objContact.Recent_Content__c) && String.isBlank(objMember.Recent_Content__c)) {
						objMember.Recent_Content__c = objContact.Recent_Content__c;
					}
				} else if (objLead != null) {
					if (String.isNotBlank(objLead.Recent_Source__c) && String.isBlank(objMember.Recent_Source__c)) {
						objMember.Recent_Source__c = objLead.Recent_Source__c;
					}

					if (String.isNotBlank(objLead.Recent_Campaign__c) && String.isBlank(objMember.Recent_Campaign__c)) {
						objMember.Recent_Campaign__c = objLead.Recent_Campaign__c;
					}

					if (String.isNotBlank(objLead.Recent_Content__c) && String.isBlank(objMember.Recent_Content__c)) {
						objMember.Recent_Content__c = objLead.Recent_Content__c;
					}
				}
			}
		}
	}

	/**
	 * @description Fetch Parent Campaigns based on CampaignIds
	 * @author      Veeresh Kumar
	 * @param       set_CampaignIds - set of Campaign Ids
	 * @return      NA
	 **/
	public Map<Id, Campaign> queryCampaigns(Set<Id> set_CampaignIds) {
		return new Map<Id, Campaign>([SELECT Id, Type FROM Campaign WHERE Id IN :set_CampaignIds]);
	}

	/**
	 * @description Updates First Responded Date (WFR Migration)
	 * @author      Rushi R
	 * @param       list_NewMembers - list of campaign members from trigger context
	 * @return      NA
	 **/
	public void updateMemberFirstRespondedDate(List<CampaignMember> list_NewMembers) {
		List<CampaignMember> list_campaignMemberToUpdate = new List<CampaignMember>();
		for (CampaignMember objMember : list_NewMembers) {
			if (objMember.FirstRespondedDate != null && objMember.Member_First_Responded_Date__c == null) {
				list_campaignMemberToUpdate.add(new CampaignMember(Id = objMember.Id, Member_First_Responded_Date__c = objMember.FirstRespondedDate));
			}
		}

		if (!list_campaignMemberToUpdate.isEmpty()) {
			update list_campaignMemberToUpdate;
		}
	}
}