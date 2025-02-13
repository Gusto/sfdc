/**
    Created by : Praveen Sethu
    Created Date : 10/05/2020
    Description: New Refactored ContactTriggerHelper Class
**/

public class ContactTriggerHelper {
	// ------------ EXISTING STATIC VARIABLES STARTS HERE ----------

	// Developer Notes - Not renaming static variable names as these could be used in so many places
	// Static Variable used to Contact Skip Triggers
	public static Boolean skipTrigger = false;
	public static String forceRollup = 'EmailDomain;';
	public static Boolean processContactMerge = false;
	public static NormalizationUtil objNormalization = new NormalizationUtil();
	public static List<Contact> list_contactsToCallout = new List<Contact>();
	public static final List<String> LIST_ADMIN_ROLES = new List<String>{ 'Primary Payroll Admin', 'Payroll Admin', 'Accountant' };
	// ------------ EXISTING STATIC VARIABLES END HERE ----------

	// Map of Account Id to Account Object
	public Map<Id, Account> map_AccountIdToObjAccount;
	// Set of Email Address to be Normalized
	public Set<String> set_emailsToNormalize;
	public Set<String> set_referredTokens;
	public Map<Id, List<CampaignMember>> map_ContactIdToCampaignMembers;
	Map<String, Contact> map_ContactEmailToObjContact;
	List<String> list_allContactFields;
	public Set<String> set_ConvertedLeadIds;

	// List of sObjects To Update
	Map<Id, Account> map_AccountsToUpdate;
	Map<Id, Contact> map_ContactToListOfEnrollments;
	Map<String, Lead> map_ContactEmailsToLeads;
	Map<Id, CampaignMember> map_CampaignMembersToUpdate;
	public static String strSubscriptionFeatureFlag = System.Label.Subscription_Feature_Flag;

	/*** Constructor  ***/
	public ContactTriggerHelper() {
		map_AccountIdToObjAccount = new Map<Id, Account>();
		set_emailsToNormalize = new Set<String>();
		set_referredTokens = new Set<String>();
		map_ContactIdToCampaignMembers = new Map<Id, List<CampaignMember>>();
		map_ContactEmailToObjContact = new Map<String, Contact>();
		list_allContactFields = new List<String>();
		map_AccountsToUpdate = new Map<Id, Account>();
		map_ContactToListOfEnrollments = new Map<Id, Contact>();
		map_ContactEmailsToLeads = new Map<String, Lead>();
		set_ConvertedLeadIds = new Set<String>();
		map_CampaignMembersToUpdate = new Map<Id, CampaignMember>();
	}

	/*** Process Before Insert  ***/
	public void processBeforeInsert(List<Contact> list_Contacts) {
		List<Opportunity> list_PayRollOpportunities = new List<Opportunity>();

		Map<String, String> map_EmailToNormalizedValue = new Map<String, String>();
		// Iteration #1 - Getting a Map of Account Id to Account
		// SOQL #1 - Querying Account and It's Related Contacts
		setAccountMapAndEmailSet(list_Contacts, null);
		// Check if list of emails to normalize is not empty.
		if (!set_emailsToNormalize.isEmpty()) {
			// If not empty, get list of normalized email address and store them in a map
			map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(set_emailsToNormalize);
		}

		// Iteration #2 - Iterating over list of new contacts that are inserted
		for (Contact objContact : list_Contacts) {
			// Opt out Zenefits contacts
			optOutZenefits(objContact, null);

			// Update Contact Phone With ZP_Phone__c
			updatePhoneWithZPPhone(objContact, null);

			// Update Contact Unique Email With Email
			updateEmailWithUniqueEmail(objContact, null);

			// Update First Session id on Contact with Session_Id__c
			updateFirstSessionId(objContact);

			// Set Referral User and Referral Date Time If not already Set
			setReferralUserInfo(objContact, null, false);

			// Normalize Email Domain
			normalizeEmailDomains(map_EmailToNormalizedValue, objContact);

			// Normalization of Phone Fields (Phone, MobilePhone and OtherPhone)
			normalizeContactPhoneFields(objContact, null);

			// Set Contact Record Type to Company or Reseller If Parent Account's Record Type is Company or Reseller
			setRecordTypeOnInsert(objContact);

			// Send notification to Slack about a new contact that is inserted
			sendNotificationToSlack(objContact);

			// Sets if any ABC resller lead is associated with contact
			setHasResellerLead(objContact);

			// set contact owner the same as account owner
			setContactOwnerOnInsert(objContact);

			// Set subscriptions based on dependencies
			setSubscriptionPreferencesOnContact(objContact, null, true);

			// Set Legacy Subscription fields based on Subscription Preferences field
			setLegacySubscriptionFields(objContact, null);
			setOutreachEmailOptOut(objContact, null);
		}
	}

	/*** Process After Insert Context  ***/
	public void processAfterInsert(Map<Id, Contact> map_NewContacts) {
		// List of new tasks to be created
		List<Task> list_Tasks = new List<Task>();
		// Set of Account Id
		Set<Id> set_AccountIdForDomainRollup = new Set<Id>();
		// List of Account Email Domain records to be created
		List<Account_Email_Domain__c> list_AccountEmailDomains = new List<Account_Email_Domain__c>();

		// Preparing Data
		// Iteration #1 - Querying Contact's Accounts
		// SOQL #1 - Getting Contact's Account
		// SOQL #2 - Getting Contact's ZP User Roles
		setAccountAndCampaignInformation(map_NewContacts.values(), null);
		// Data Processing
		// Iteration #2 - Iterating over list of new contacts that are inserted

		// Map to store contact fields
		Map<String, SObjectField> map_ContactFields = Contact.SObjectType.getDescribe().fields.getMap();
		// Build a map of editable contact fields
		Map<String, Boolean> map_EditableContactFields = contactEditableFields(map_ContactFields);

		for (Contact objContact : map_NewContacts.values()) {
			// Merge Contacts with Duplicate Email Address
			if (map_ContactEmailToObjContact.containsKey(objContact.Email)) {
				// Already existing duplicate contact
				Contact objDuplicateContact = map_ContactEmailToObjContact.get(objContact.Email);
				Contact objContactToMerge = new Contact(Id = objContact.Id);
				Boolean blnMerge = false;
				for (String strContactField : list_allContactFields) {
					// Update blank values child records to parent
					// Check if Contact has blank value and duplicate value has value and check if the field is editable
					if (
						objContact.get(strContactField) == null &&
						objDuplicateContact.get(strContactField) != null &&
						map_EditableContactFields.containsKey(strContactField) &&
						map_EditableContactFields.get(strContactField)
					) {
						Schema.SobjectField objField = map_ContactFields.get(strContactField);
						objContactToMerge.put(objField, objDuplicateContact.get(strContactField));
						blnMerge = true;
					}
				}

				if (blnMerge) {
					Database.merge(objContactToMerge, objDuplicateContact);
				}
			}
			// Create new task if Contact is Added by Client
			if (objContact.ABC_Lead_Match__c && objContact.OwnerId != null) {
				list_Tasks.add(createTaskIfAddedByClient(objContact));
			}

			// Create new task for Reseller Contacts
			Task objResellerTask;
			objResellerTask = createTaskForResllerContact(objContact);
			if (objResellerTask != null && objResellerTask.OwnerId != null) {
				list_Tasks.add(objResellerTask);
			}

			// Set Random Cohort on Account
			setRandomCohortonAccount(objContact);

			// Set Normalized Email Domain on Account
			setNormalizedEmailDomainOnParentAccount(objContact, null);

			if (objContact.AccountId != null && (String.isNotBlank(objContact.Normalized_Email_Domain__c) || String.isNotBlank(objContact.Normalized_Alternate_Email_Domain__c))) {
				set_AccountIdForDomainRollup.add(objContact.AccountId);
			}

			// Set Subscription Preferences on Account
			setSubscriptionPreferencesOnParentAccount(objContact, null, true);
		}

		if (!set_AccountIdForDomainRollup.isEmpty()) {
			// DML #1 - rollUpUniqueContactDomainToAccount Contains - Deleting Existing Account Email Domain Mapping
			list_AccountEmailDomains = rollUpUniqueContactDomainToAccount(set_AccountIdForDomainRollup, map_NewContacts);
		}

		{
			if (!list_Tasks.isEmpty()) {
				// Skip Task Trigger
				TaskTriggerHelper.skipTrigger = true;
				// Create new tasks
				insert list_Tasks;
				// Reset Skip Trigger after Task is inserted
				TaskTriggerHelper.skipTrigger = false;
			}

			if (!list_AccountEmailDomains.isEmpty()) {
				insert list_AccountEmailDomains;
			}

			if (!map_AccountsToUpdate.values().isEmpty()) {
				Map<String, String> dmlUpdateErrorsMap = new Map<String, String>();
				List<Database.SaveResult> result = Database.update(map_AccountsToUpdate.values(), false);
				dmlUpdateErrorsMap = Utils.processSaveResult(result, map_AccountsToUpdate.values(), 'Id', true, 'ContactTriggerHelper-processAfterInsert-updateAccount');
			}

			if (!list_contactsToCallout.isEmpty() && !Test.isRunningTest()) {
				SubscriptionCenterUtil.calloutSubscription(list_contactsToCallout, Contact.SObjectType);
			}
		}
	}

	/***  Run Before Update Context ***/
	public void processBeforeUpdate(List<Contact> list_NewContacts, Map<Id, Contact> map_OldContacts) {
		Set<string> set_ExcludedEmailDomains = new Set<string>();
		Map<String, Integer> map_leadCountByReferrerTokens = new Map<String, Integer>();
		Map<String, String> map_EmailToNormalizedValue = new Map<String, String>();

		// Flag to indicate if user can skip validation rule
		// SOQL #1
		Boolean blnSkipValidationRule = UserUtils.returnLoggedInUser().Exempt_from_Validation_Rules__c;
		// Iteration #1 - Getting a Map of Account Id to Account
		// SOQL #2 - Querying Account and It's Related Contacts
		setAccountMapAndEmailSet(list_NewContacts, map_OldContacts);

		if (!set_emailsToNormalize.isEmpty()) {
			// If not empty, get list of normalized email address and store them in a map
			map_EmailToNormalizedValue = objNormalization.normaliseDomainFieldBulkified(set_emailsToNormalize);
		}

		for (UR_Excluded_Contact_Domain__c objExcludeEmail : UR_Excluded_Contact_Domain__c.getall().values()) {
			set_ExcludedEmailDomains.add(objExcludeEmail.Name);
		}

		/*if(!set_referredTokens.isEmpty()) {
            map_leadCountByReferrerTokens = LeadQueryHelper.getTotalReferrelLeadCountPerToken(set_referredTokens);
        }
		*/

		// Data Processing
		// Iteration #2 - Iterating over contacts to set data
		for (Contact objNewContact : list_NewContacts) {
			// Get Old Contact Map
			Contact objOldContact = map_OldContacts.get(objNewContact.Id);

			// Opt out Zenefits contacts
			optOutZenefits(objNewContact, objOldContact);

			// Update Contact Phone With ZP_Phone__c
			updatePhoneWithZPPhone(objNewContact, objOldContact);

			// Update Contact Unique Email With Email
			updateEmailWithUniqueEmail(objNewContact, objOldContact);

			// Update First Session id on Contact with Session_Id__c
			updateFirstSessionId(objNewContact);

			// Normalization of Phone Fields (Phone, MobilePhone and OtherPhone)
			normalizeContactPhoneFields(objNewContact, objOldContact);

			// Normalize Email Domain
			normalizeEmailDomains(map_EmailToNormalizedValue, objNewContact);

			// Set Referral User and Referral Date Time If not already Set
			setReferralUserInfo(objNewContact, objOldContact, blnSkipValidationRule);

			//sync "ZP_User_Role_Text__c" with "ZP_User_Role__c" field value
			objNewContact.ZP_User_Role_Text__c = objNewContact.ZP_User_Role__c;

			// Mark Excluded Domain for UX Research
			markExcludedDomainForUXResearch(objNewContact, set_ExcludedEmailDomains);

			// Sets if any ABC resller lead is associated with contact
			setHasResellerLead(objNewContact);

			// Set subscriptions based on dependencies
			setSubscriptionPreferencesOnContact(objNewContact, objOldContact, false);

			// Set Legacy Subscription fields based on Subscription Preferences field
			setLegacySubscriptionFields(objNewContact, objOldContact);
			setOutreachEmailOptOut(objNewContact, objOldContact);
			setSyncToMarketo(objNewContact, objOldContact);
		}
	}

	/***  Run After Update Context ***/
	public void processAfterUpdate(Map<Id, Contact> map_NewContacts, Map<Id, Contact> map_OldContacts) {
		// List of Account Email Domain records to be created
		List<Account_Email_Domain__c> list_AccountEmailDomains = new List<Account_Email_Domain__c>();
		// Set of Account Id
		Set<Id> set_AccountIdForDomainRollup = new Set<Id>();
		// Filtered Database Results
		List<Database.SaveResult> list_FilteredResult = new List<Database.SaveResult>();

		// Preparing Data
		setAccountAndCampaignInformation(map_NewContacts.values(), map_OldContacts);

		// Data Processing
		// Iteration #2 - Iterating over list of new contacts that are inserted
		for (Contact objNewContact : map_NewContacts.values()) {
			Contact objOldContact = map_OldContacts.get(objNewContact.Id);

			updateCampaignMember(objNewContact);

			// Set Random Cohort on Account
			setRandomCohortonAccount(objNewContact);

			// Set Normalized Email Domain on Account
			setNormalizedEmailDomainOnParentAccount(objNewContact, objOldContact);

			if (
				objNewContact.AccountId != null &&
				(objNewContact.Normalized_Email_Domain__c != objOldContact.Normalized_Email_Domain__c ||
				objNewContact.Normalized_Alternate_Email_Domain__c != objOldContact.Normalized_Alternate_Email_Domain__c)
			) {
				set_AccountIdForDomainRollup.add(objNewContact.AccountId);
			}

			// Set Subscription Preferences on Account
			setSubscriptionPreferencesOnParentAccount(objNewContact, objOldContact, false);
			//Callout subscription preferences if updated
			if (objNewContact.Customer_Subscriptions__c != objOldContact.Customer_Subscriptions__c) {
				calloutSubscriptionPreferencesIfUpdated(objNewContact);
			}
		}

		if (!set_AccountIdForDomainRollup.isEmpty()) {
			// DML #1 - rollUpUniqueContactDomainToAccount Contains - Deleting Existing Account Email Domain Mapping
			list_AccountEmailDomains = rollUpUniqueContactDomainToAccount(set_AccountIdForDomainRollup, map_NewContacts);
		}
		// Upsert Out Reach Engagment Records
		List<Outreach_Engagement__c> list_OutReachEngagments = updateOutreachEngagementFields(map_newContacts, map_oldContacts);

		{
			// Insert New Account to Email Domain Records
			if (!list_AccountEmailDomains.isEmpty()) {
				insert list_AccountEmailDomains;
			}

			// Upsert Outreach Engagment Records
			if (!list_OutReachEngagments.isEmpty()) {
				upsert list_OutReachEngagments;
			}

			if (!map_AccountsToUpdate.values().isEmpty()) {
				Map<String, String> map_DmlUpdateErrors = new Map<String, String>();
				TriggerHandler.bypass('AccountTriggerHandler');
				List<Database.SaveResult> result = Database.update(map_AccountsToUpdate.values(), false);
				//filter results to exclude records that would trigger Validation Rule - Direct_Require_Competitor on Account to prevent logging exceptions
				list_FilteredResult = Utils.filterAccounts(result);
				map_DmlUpdateErrors = Utils.processSaveResult(list_FilteredResult, map_AccountsToUpdate.values(), 'Id', true, 'ContactTriggerHelper-processAfterUpdate-updateAccount');
				AccountTriggerHelper.skipTrigger = false;
				TriggerHandler.clearBypass('AccountTriggerHandler');
			}

			if (!map_CampaignMembersToUpdate.isEmpty()) {
				CampaignMemberTriggerHelper.skipTrigger = true;
				update map_CampaignMembersToUpdate.values();
				CampaignMemberTriggerHelper.skipTrigger = false;
			}

			if (!list_contactsToCallout.isEmpty() && !Test.isRunningTest()) {
				SubscriptionCenterUtil.calloutSubscription(list_contactsToCallout, Contact.SObjectType);
			}
		}
	}

	/***  Run After Delete Context ***/
	public void processAfterDelete(List<Contact> list_OldContacts, Map<Id, Contact> map_OldContacts) {
		Set<Id> set_AccountIds = new Set<Id>();
		List<Account_Email_Domain__c> list_AccountEmailDomainsToDelete = new List<Account_Email_Domain__c>();
		Set<String> set_EmailDomainsToDelete = new Set<String>();
		// Data Prep
		for (Contact objDeletedContact : list_OldContacts) {
			if (objDeletedContact.AccountId != null && (String.isNotBlank(objDeletedContact.Normalized_Email_Domain__c) || String.isNotBlank(objDeletedContact.Normalized_Alternate_Email_Domain__c))) {
				set_AccountIds.add(objDeletedContact.AccountId);

				if (String.isNotBlank(objDeletedContact.Normalized_Email_Domain__c)) {
					set_EmailDomainsToDelete.add(objDeletedContact.Normalized_Email_Domain__c);
				}

				if (String.isNotBlank(objDeletedContact.Normalized_Alternate_Email_Domain__c)) {
					set_EmailDomainsToDelete.add(objDeletedContact.Normalized_Alternate_Email_Domain__c);
				}
			}
		}

		List<Account_Email_Domain__c> list_AccountEmailDomains = queryAccountEmailDomains(set_AccountIds);

		for (Account_Email_Domain__c objEmailDomain : list_AccountEmailDomains) {
			if (set_AccountIds.contains(objEmailDomain.Account__c) && set_EmailDomainsToDelete.contains(objEmailDomain.Name)) {
				list_AccountEmailDomainsToDelete.add(objEmailDomain);
			}
		}

		if (!list_AccountEmailDomainsToDelete.isEmpty()) {
			delete list_AccountEmailDomainsToDelete;
		}
	}

	/**
	 * @description Update CampaignMember Info from Contact.
	 * @author      Veeresh Kumar
	 * @param       objContact - New Contact
	 * @return      NA
	 **/
	public void updateCampaignMember(Contact objContact) {
		if (map_ContactIdToCampaignMembers.containsKey(objContact.Id)) {
			for (CampaignMember objMember : map_ContactIdToCampaignMembers.get(objContact.Id)) {
				CampaignMember objMemberToUpdate = map_CampaignMembersToUpdate.containsKey(objMember.Id) ? map_CampaignMembersToUpdate.get(objMember.Id) : objMember;
				Boolean blnIsUpdated = false;

				if (objMemberToUpdate.HasResponded && String.isNotBlank(objMemberToUpdate.Campaign.Type) && ContactUtil.set_RecentSourceCampaignTypes.contains(objMemberToUpdate.Campaign.Type)) {
					if (String.isNotBlank(objContact.Recent_Source__c) && String.isBlank(objMemberToUpdate.Recent_Source__c)) {
						objMemberToUpdate.Recent_Source__c = objContact.Recent_Source__c;
						blnIsUpdated = true;
					}

					if (String.isNotBlank(objContact.Recent_Campaign__c) && String.isBlank(objMemberToUpdate.Recent_Campaign__c)) {
						objMemberToUpdate.Recent_Campaign__c = objContact.Recent_Campaign__c;
						blnIsUpdated = true;
					}

					if (String.isNotBlank(objContact.Recent_Content__c) && String.isBlank(objMemberToUpdate.Recent_Content__c)) {
						objMemberToUpdate.Recent_Content__c = objContact.Recent_Content__c;
						blnIsUpdated = true;
					}
				}

				if (blnIsUpdated) {
					map_CampaignMembersToUpdate.put(objMemberToUpdate.Id, objMemberToUpdate);
				}
			}
		}
	}
	/*** Update Phone With ZP_Phone__c ***/
	public void updateEmailWithUniqueEmail(Contact objNewContact, Contact objOldContact) {
		if (objOldContact == null || objOldContact.Email != objNewContact.Email) {
			objNewContact.Unique_Email_Address_Contact__c = objNewContact.Email;
		}
	}
	/*** Mark UXResearch_Exclude_Domain__c on Contact ***/
	public void markExcludedDomainForUXResearch(Contact objContact, Set<String> set_ExcludedEmailDomains) {
		// Initially set default value as false
		objContact.UXResearch_Exclude_Domain__c = false;

		if (!set_ExcludedEmailDomains.isEmpty() && String.isNotBlank(objContact.Email)) {
			String strEmail = objContact.Email;
			String strDomain = strEmail.substring(strEmail.indexOf('@') + 1, strEmail.length()).trim();
			//Check if theis domain exits in exluded list or not
			objContact.UXResearch_Exclude_Domain__c = set_ExcludedEmailDomains.contains(strDomain);
		}
	}

	/**** Opt out Zenefits users from receiving email ****/
	public void optOutZenefits(Contact objNewContact, Contact objOldContact) {
		// Check if Contact Email is not null
		if (String.isNotBlank(objNewContact.Email) && objNewContact.Email.endsWithIgnoreCase('zenefits.com')) {
			objNewContact.HasOptedOutOfEmail = true;
		}
	}

	/*** Update Phone With ZP_Phone__c ***/
	public void updatePhoneWithZPPhone(Contact objNewContact, Contact objOldContact) {
		// If Contact Phone is empty and Contact has ZP Phone, Update Phone with ZP Phone
		if (String.isBlank(objNewContact.Phone) && String.isNotBlank(objNewContact.ZP_Phone__c)) {
			if (objOldContact == null || (objOldContact != null && objOldContact.ZP_Phone__c != objNewContact.ZP_Phone__c)) {
				objNewContact.Phone = objNewContact.ZP_Phone__c;
			}
		}
	}

	/*** Update First Sesssion Id, if not already set ***/
	public void updateFirstSessionId(Contact objContact) {
		// Connecting visitor ID/Session ID to Campaign Member
		if (String.isBlank(objContact.Session_ID_First__c) && String.isNotBlank(objContact.Session_Id__c)) {
			objContact.Session_ID_First__c = objContact.Session_Id__c;
		}
	}

	/*** Set Referral User and Date Time, if not already set ***/
	public void setReferralUserInfo(Contact objNewContact, Contact objOldContact, Boolean blnSkipValidationRule) {
		// If Contact's Referral_Sent__c is True, Set Referral User as Logged In User and Referral Date Time as Current Time Stamp
		if ((objOldContact == null && objNewContact.Referral_Sent__c) || (objOldContact != null && !objOldContact.Referral_Sent__c && objNewContact.Referral_Sent__c)) {
			if (objNewContact.Referral_User__c == null) {
				objNewContact.Referral_User__c = UserInfo.getUserId();
			}

			if (objNewContact.Referral_Date_Time__c == null) {
				objNewContact.Referral_Date_Time__c = DateTime.now();
			}
		}

		if (objOldContact != null) {
			if (!objNewContact.Referral_Sent__c && objOldContact.Referral_Sent__c && !blnSkipValidationRule) {
				objNewContact.Referral_Sent__c = true;
			}

			if (objOldContact.Referral_User__c != null && objNewContact.Referral_User__c != objOldContact.Referral_User__c && !blnSkipValidationRule) {
				objNewContact.Referral_User__c = objOldContact.Referral_User__c;
			}

			if (objOldContact.Referral_Date_Time__c != null && objNewContact.Referral_Date_Time__c != objOldContact.Referral_Date_Time__c && !blnSkipValidationRule) {
				objNewContact.Referral_Date_Time__c = objOldContact.Referral_Date_Time__c;
			}
		}
	}

	/*** Normalize Email and Alernate Email Fields and Set them on their respective Normalized fields ***/
	public void normalizeEmailDomains(Map<String, String> map_EmailToNormalizedValue, Contact objContact) {
		if (!map_EmailToNormalizedValue.isEmpty()) {
			if (map_EmailToNormalizedValue.containsKey(objContact.Email)) {
				objContact.Normalized_Email_Domain__c = map_EmailToNormalizedValue.get(objContact.Email);
			}

			if (map_EmailToNormalizedValue.containsKey(objContact.Alternate_Email__c)) {
				objContact.Normalized_Alternate_Email_Domain__c = map_EmailToNormalizedValue.get(objContact.Alternate_Email__c);
			}
		}
	}

	/**** Creates a new map of Account Id to Account Object. ****/
	public void setAccountMapAndEmailSet(List<Contact> list_Contacts, Map<Id, Contact> map_OldContacts) {
		if (map_AccountIdToObjAccount.isEmpty()) {
			// Create a new set of Account Ids
			Set<Id> set_AccountIds = new Set<Id>();
			Set<Id> set_ContactIds = new Set<Id>();
			Set<String> set_Emails = new Set<String>();
			// Iterate over list of contacts and update set with Account Ids
			for (Contact objContact : list_Contacts) {
				set_AccountIds.add(objContact.AccountId);
				set_ContactIds.add(objContact.Id);
				// Add Contact's Email and Alternate Email Addresses to a Set
				if (String.isNotBlank(objContact.Email)) {
					set_emailsToNormalize.add(objContact.Email);
					set_Emails.add(objContact.Email);
				}

				if (String.isNotBlank(objContact.Alternate_Email__c)) {
					set_emailsToNormalize.add(objContact.Alternate_Email__c);
				}

				if (map_OldContacts != null) {
					if (String.isNotBlank(objContact.Referral_Token__c) && map_OldContacts.containsKey(objContact.Id) && String.isBlank(map_OldContacts.get(objContact.Id).Referral_Token__c)) {
						set_referredTokens.add(objContact.Referral_Token__c);
					}
				}

				if (String.isNotBlank(objContact.Lead_ID__c)) {
					set_ConvertedLeadIds.add(objContact.Lead_ID__c);
				}
			}
			// Check if set of Account Id is not Empty
			if (!set_AccountIds.isEmpty()) {
				// Instantiate a new static variable that stores a map of Account Id and Account - Indexed Query
				map_AccountIdToObjAccount = new Map<Id, Account>([SELECT Id, RecordTypeId, RecordType.Name, Website, OwnerId FROM Account WHERE Id IN :set_AccountIds]);
			}

			if (!set_Emails.isEmpty()) {
				for (Lead objLead : [SELECT Id, LeadSource, RecordTypeId, Email FROM Lead WHERE Email IN :set_Emails AND RecordTypeId = :LeadUtil.RESELLER_LEAD_RT_ID]) {
					map_ContactEmailsToLeads.put(objLead.Email, objLead);
				}
			}
		}
	}

	/**** Set Contact Record Type to Company or Reseller If Parent Account's Record Type is Company or Reseller ****/
	public void setRecordTypeOnInsert(Contact objContact) {
		if (objContact.AccountId != null && map_AccountIdToObjAccount.containsKey(objContact.AccountId)) {
			// Set record type on contact based on account record type
			if (map_AccountIdToObjAccount.get(objContact.AccountId).RecordType.Name == ContactUtil.COMPANY_RT_NAME) {
				objContact.RecordTypeId = ContactUtil.COMPANY_CONTACT_RT_ID;
			} else if (map_AccountIdToObjAccount.get(objContact.AccountId).RecordType.Name == ContactUtil.RESELLER_RT_NAME) {
				objContact.RecordTypeId = ContactUtil.RESELLER_CONTACT_RT_ID;
			} else if (map_AccountIdToObjAccount.get(objContact.AccountId).RecordType.Name == ContactUtil.EMBEDDED_COMPANY_RT_NAME) {
				objContact.RecordTypeId = ContactUtil.EMBEDDED_COMPANY_CONTACT_RT_ID;
			}
		}
	}

	/**** Normalize Phone Fields (Phone, MobilePhone and OtherPhone) ****/
	public void normalizeContactPhoneFields(Contact objNewContact, Contact objOldContact) {
		// Normalization of Phone Fields (Phone, MobilePhone and OtherPhone)
		if (objOldContact == null || (objOldContact != null && objOldContact.Phone != objNewContact.Phone)) {
			objNewContact.Normalized_Phone__c = objNormalization.normalisePhoneField(objNewContact.Phone);
		}

		if (objOldContact == null || (objOldContact != null && objOldContact.MobilePhone != objNewContact.MobilePhone)) {
			objNewContact.Normalized_Mobile_Phone__c = objNormalization.normalisePhoneField(objNewContact.MobilePhone);
		}

		if (objOldContact == null || (objOldContact != null && objOldContact.OtherPhone != objNewContact.OtherPhone)) {
			objNewContact.Normalized_Other_Phone__c = objNormalization.normalisePhoneField(objNewContact.OtherPhone);
		}

		// Set Phone number Exceptions if Phone fields are not normalized properly
		if (String.isBlank(objNewContact.Normalized_Phone__c) || String.isBlank(objNewContact.Normalized_Mobile_Phone__c) || String.isBlank(objNewContact.Normalized_Other_Phone__c)) {
			objNewContact.Invalid_Field_Exceptions__c = 'Invalid Phone Number Exception';
		}
	}

	/*** Sets if any ABC resller lead is associated with contact ***/
	public void setHasResellerLead(Contact objNewContact) {
		if (
			objNewContact.RecordTypeId == ContactUtil.COMPANY_CONTACT_RT_ID &&
			String.isNotBlank(objNewContact.Email) &&
			map_ContactEmailsToLeads != null &&
			map_ContactEmailsToLeads.containsKey(objNewContact.Email)
		) {
			Lead objLead = map_ContactEmailsToLeads.get(objNewContact.Email);
			if (objLead != null && objLead.RecordTypeId == LeadUtil.RESELLER_LEAD_RT_ID && objLead.LeadSource == LeadUtil.LEADSOURCE_ABC) {
				objNewContact.ABC_Reseller_Lead__c = objLead.Id;
			}
		}
	}

	/*** Set Contact Owner the same as Account Owner ***/
	public void setContactOwnerOnInsert(Contact objNewContact) {
		if (map_AccountIdToObjAccount.containsKey(objNewContact.AccountId)) {
			objNewContact.OwnerId = map_AccountIdToObjAccount.get(objNewContact.AccountId).OwnerId;
		}
	}

	/**** Send notifications to Slack when a new reseller contact is added or updated ****/
	public void sendNotificationToSlack(Contact objNewContact) {
		// Check if the Contact has Parent Account Id
		// Check if the Contact is a Reseller Contact
		// Check if Contact does not contain an associated Lead
		// Check if Contact's Parent Account is a Reseller Account
		// If all the above conditions match, set Send_To_Partner_Slack_New_Add__c as True
		if (
			objNewContact.AccountId != null &&
			objNewContact.RecordTypeId == ContactUtil.RESELLER_CONTACT_RT_ID &&
			(String.isBlank(objNewContact.Lead_Id__c)) &&
			map_AccountIdToObjAccount.containsKey(objNewContact.AccountId)
		) {
			Account objAccount = map_AccountIdToObjAccount.get(objNewContact.AccountId);
			if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				if (!objNewContact.Send_To_Partner_Slack_New_Add__c) {
					objNewContact.Send_To_Partner_Slack_New_Add__c = true;
				}
			}
		}
	}

	/**** Create new task if contact is added by client ****/
	public Task createTaskIfAddedByClient(Contact objContact) {
		return new Task(
			Subject = 'New Contact from ABC',
			Type = 'Email',
			Priority = 'Low',
			Description = 'Please connect the lead to the firm in Panda',
			Status = 'Open',
			ActivityDate = System.Today(),
			OwnerId = objContact.OwnerId,
			RecordTypeId = TaskUtil.TASK_EMAIL_RT_ID,
			WhoId = objContact.Id
		);
	}

	/***  Create Task for Resller Contact  ****/
	public Task createTaskForResllerContact(Contact objContact) {
		Task objTask;
		// Check if Contact has an Account and ZP User Role contains Accountant
		if (
			objContact.AccountId != null &&
			String.isNotBlank(objContact.ZP_User_Role__c) &&
			objContact.ZP_User_Role__c.contains('Accountant') &&
			map_AccountIdToObjAccount.containsKey(objContact.AccountId)
		) {
			Id idTaskOwner;
			// Get Account object from Map
			Account objAccount = map_AccountIdToObjAccount.get(objContact.AccountId);
			// Check if Account is Company Record Type then check if Account has Referred By or Sold By
			if (objAccount.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
				if (objAccount.Referred_By__c != null) {
					idTaskOwner = objAccount.Referred_By__r.OwnerId;
				}
				if (objAccount.Sold_by__c != null) {
					idTaskOwner = objAccount.Sold_By__r.OwnerId;
				}
			} else if (objAccount.RecordTypeId == AccountUtil.RESELLER_ACCOUNT_RT_ID) {
				idTaskOwner = objAccount.OwnerId;
			}
			objTask = new Task(
				Subject = 'New Accountant Added',
				Type = 'Follow Up',
				Priority = 'Low',
				Description = 'New Accountant Added',
				Status = 'Open',
				ActivityDate = System.today(),
				RecordTypeId = TaskUtil.TASK_STANDARD_RT_ID,
				WhatId = objAccount.Id,
				OwnerId = idTaskOwner
			);
		}
		return objTask;
	}

	/***  Query Contact's Account and ZP User Role Records  ****/
	public void setAccountAndCampaignInformation(List<Contact> list_Contacts, Map<Id, Contact> map_OldContacts) {
		// Create a new set of Account Ids
		Set<Id> set_AccountIds = new Set<Id>();
		// Create a new set of Contact Ids
		Set<Id> set_ContactIds = new Set<Id>();
		// Set of Contact Emails
		Set<String> set_ContactEmails = new Set<String>();
		// Iterate over list of contacts and update set with Account Ids
		for (Contact objContact : list_Contacts) {
			// Get Old Contact from Trigger.oldMap
			Contact objOldContact;
			if (map_OldContacts != null && map_OldContacts.containsKey(objContact.Id)) {
				objOldContact = map_OldContacts.get(objContact.Id);
			}

			if (objContact.AccountId != null) {
				set_AccountIds.add(objContact.AccountId);
			}

			// Add Old Account to set of Account Ids when Account Id changes
			if (objOldContact != null && objContact.AccountId != objOldContact.AccountId) {
				set_AccountIds.add(objOldContact.AccountId);
			}

			set_ContactIds.add(objContact.Id);
			if (String.isNotBlank(objContact.Email)) {
				set_ContactEmails.add(objContact.Email);
			}
		}
		// If set of Account Ids is not Empty, Query Account Ids - Indexed Query
		if (!set_AccountIds.isEmpty()) {
			map_AccountIdToObjAccount = new Map<Id, Account>(
				[
					SELECT
						Id,
						RecordTypeId,
						RecordType.Name,
						Referred_By__c,
						Referred_By__r.OwnerId,
						Sold_By__c,
						Sold_By__r.OwnerId,
						Num_Accountants_At_Firm__c,
						Random_Cohort__c,
						Normalized_Email_Domain__c,
						Website,
						(SELECT Id, ZP_User_Id__c, Inactive_ZP_User__c, Normalized_Email_Domain__c FROM Contacts ORDER BY CreatedDate ASC),
						OwnerId
					FROM Account
					WHERE Id IN :set_AccountIds
				]
			);
		}

		DateTime dtLastHour = System.now().addHours(-1);
		// Indexed Query
		for (CampaignMember objMember : [
			SELECT Id, ContactId, CampaignId, Campaign.IsActive, Campaign.Type, HasResponded, Recent_Source__c, Recent_Campaign__c, Recent_Content__c
			FROM CampaignMember
			WHERE ContactId IN :set_ContactIds AND CreatedDate >= :dtLastHour
		]) {
			if (map_ContactIdToCampaignMembers.containsKey(objMember.ContactId)) {
				map_ContactIdToCampaignMembers.get(objMember.ContactId).add(objMember);
			} else {
				map_ContactIdToCampaignMembers.put(objMember.ContactId, new List<CampaignMember>{ objMember });
			}
		}

		if (!set_ContactEmails.isEmpty()) {
			getContactsWithSameEmail(set_ContactEmails);
		}
	}

	public void setRandomCohortonAccount(Contact objContact) {
		// Check if Account Map has Contact's Account Id
		if (map_AccountIdToObjAccount.containsKey(objContact.AccountId)) {
			// Fetch the Account
			Account objAccount = map_AccountIdToObjAccount.get(objContact.AccountId);
			// Check if Random Cohort is already populated, if not set random number b/w 1 and 10
			if (objAccount.Random_Cohort__c == null || objAccount.Random_Cohort__c == 0) {
				Account objAccountToUpdate = map_AccountsToUpdate.containsKey(objAccount.Id) ? map_AccountsToUpdate.get(objAccount.Id) : new Account(Id = objAccount.Id);
				objAccountToUpdate.Random_Cohort__c = RandomNumberGenerator.generateRandomNumber(1, 10);

				map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
			}
		}
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Set Normalized Email Domain on Account, when parent AccountId is remapped on Contact
	 * @Parm        : Contact - Trigger new
	 * @Parm        : Contact - Trigger old
	 * @Return      : N/A
	 **/
	public void setNormalizedEmailDomainOnParentAccount(Contact objNewContact, Contact objOldContact) {
		// Get Old and New Account
		Account objOldAccount;
		if (objOldContact != null) {
			objOldAccount = map_AccountIdToObjAccount.containsKey(objOldContact.AccountId) ? map_AccountIdToObjAccount.get(objOldContact.AccountId) : null;
		}
		Account objNewAccount = map_AccountIdToObjAccount.containsKey(objNewContact.AccountId) ? map_AccountIdToObjAccount.get(objNewContact.AccountId) : null;

		// Check if Account Id changes or Normalized Email Domain on Account is Blank
		if ((objOldContact != null && objNewContact.AccountId != objOldContact.AccountId) || (objNewAccount != null && String.isBlank(objNewAccount.Normalized_Email_Domain__c))) {
			// Normalize New Account
			if (objNewContact.AccountId != null && objNewAccount != null) {
				normalizeAccount(objNewAccount);
			}

			// Normalize Old Account
			if (objOldContact != null && objNewContact.AccountId != objOldContact.AccountId && objOldAccount != null) {
				normalizeAccount(objOldAccount);
			}
		}
	}

	/**
	 * @Author      : Praveen Sethu
	 * @Description : Set Normalized Email Domain on Account by iterating over Contacts (Ordered by ascending order of Created Date)
	 * @Parm        : Account - Account to be Normalized
	 * @Return      : N/A
	 **/
	public void normalizeAccount(Account objAccount) {
		// Reset Normalized Email Domain
		String strEmailDomain = '';
		String strWebsite = objAccount.Website;
		for (Contact objAcctContact : objAccount.Contacts) {
			if (String.isNotBlank(objAcctContact.Normalized_Email_Domain__c)) {
				strEmailDomain = objAcctContact.Normalized_Email_Domain__c;
				break;
			}
		}

		if (objAccount.Normalized_Email_Domain__c != strEmailDomain) {
			Account objAccountToUpdate = map_AccountsToUpdate.containsKey(objAccount.Id) ? map_AccountsToUpdate.get(objAccount.Id) : new Account(Id = objAccount.Id);
			objAccountToUpdate.Normalized_Email_Domain__c = strEmailDomain;
			// Only update Website if Account website is null
			if ((String.isBlank(strWebsite) || strWebsite.contains(AccountUtil.ACCOUNT_OBJ_PREFIX)) && String.isNotBlank(objAccountToUpdate.Normalized_Email_Domain__c)) {
				objAccountToUpdate.Website = 'www.' + objAccountToUpdate.Normalized_Email_Domain__c;
			}
			map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
		}
	}

	/** Deleting existing domain entries for account and creates a new map of account and domain records ***/
	public List<Account_Email_Domain__c> rollUpUniqueContactDomainToAccount(Set<Id> set_AccountIdForDomainRollup, Map<Id, Contact> map_NewContacts) {
		List<Account_Email_Domain__c> list_AccountEmailDomains = new List<Account_Email_Domain__c>();
		Map<String, Set<String>> map_AccountIdToDomainSet = new Map<String, Set<String>>();

		List<Account_Email_Domain__c> list_EmailDomainsToDelete = [SELECT Id FROM Account_Email_Domain__c WHERE Account__c IN :set_AccountIdForDomainRollup];
		Database.delete(list_EmailDomainsToDelete, false);

		if (set_AccountIdForDomainRollup.size() > 0) {
			// Indexed Query
			List<Contact> list_Contacts = queryContacts(set_AccountIdForDomainRollup);

			if (list_Contacts.size() > 0) {
				for (Contact objContact : list_Contacts) {
					if (map_NewContacts != null) {
						objContact = map_NewContacts.containsKey(objContact.Id) ? map_NewContacts.get(objContact.Id) : objContact;
					}
					Set<String> set_Domains = new Set<String>();
					if (map_AccountIdToDomainSet.containsKey(objContact.AccountId)) {
						set_Domains.addAll(map_AccountIdToDomainSet.get(objContact.AccountId));
					}
					if (String.isNotBlank(objContact.Normalized_Email_Domain__c)) {
						set_Domains.add(objContact.Normalized_Email_Domain__c);
					}
					if (String.isNotBlank(objContact.Normalized_Alternate_Email_Domain__c)) {
						set_Domains.add(objContact.Normalized_Alternate_Email_Domain__c);
					}
					if (!set_Domains.isEmpty()) {
						map_AccountIdToDomainSet.put(objContact.AccountId, set_Domains);
					}
				}
			}

			for (Id idAccount : set_AccountIdForDomainRollup) {
				if (map_AccountIdToDomainSet.containsKey(idAccount) && map_AccountIdToDomainSet.get(idAccount).size() > 0) {
					for (String strDomain : map_AccountIdToDomainSet.get(idAccount)) {
						list_AccountEmailDomains.add(new Account_Email_Domain__c(Name = strDomain, Account__c = idAccount));
					}
				}
			}
		}
		return list_AccountEmailDomains;
	}

	/*** Get All Data related to Contacts with Same Email Address ***/
	public void getContactsWithSameEmail(Set<String> set_ContactEmails) {
		// Get all fields from contact
		list_allContactFields = new List<String>(Contact.SObjectType.getDescribe().fields.getMap().keySet());
		// Form a Dynamic SOQL- Indexed Query
		String strContactSOQL = 'SELECT ' + String.join(list_allContactFields, ',') + ' FROM Contact WHERE Email IN :set_ContactEmails';
		// Query List of Contacts
		List<Contact> list_Contacts = Database.query(strContactSOQL);
		// Iterate over list of contacts - Update Map
		for (Contact objContact : list_Contacts) {
			map_ContactEmailToObjContact.put(objContact.Email, objContact);
		}
	}

	/*** Build a map of Contact field and boolean flag to indicate if it is editable or not ***/
	public Map<String, Boolean> contactEditableFields(Map<String, SObjectField> map_ContactFields) {
		Map<String, Boolean> map_EditableContactFields = new Map<String, Boolean>();

		// Iterate over map's key set - and update if the field is editable or not
		for (String strContactField : map_ContactFields.keySet()) {
			map_EditableContactFields.put(strContactField, map_ContactFields.get(strContactField).getDescribe().isUpdateable());
		}

		return map_EditableContactFields;
	}

	/*** Update and Insert New Outreach Engagement Records  ****/
	public List<Outreach_Engagement__c> updateOutreachEngagementFields(Map<Id, Contact> map_newContact, Map<Id, Contact> map_oldContact) {
		Set<Id> set_ContactIds = new Set<Id>();
		Set<Id> set_ContIdtoUpdateOutreach = new Set<Id>();
		Map<Id, Contact> map_AccIdWithConId = new Map<Id, Contact>();
		List<Outreach_Engagement__c> list_OutreachEngmntToUpsert = new List<Outreach_Engagement__c>();
		Map<Id, Map<String, Id>> map_AccWIthOutreachValues = new Map<Id, Map<String, Id>>();
		List<Id> list_SortedHIOpps = new List<Id>();
		Map<Id, User> map_AllActiveUsers = GlobalQueryHelper.queryActiveUsers();

		for (Contact objNewContact : map_newContact.values()) {
			Contact objOldContact = map_oldContact.get(objNewContact.Id);
			//if only Id of currently Active sequence updated create a new record otherwise insert it.
			if (objNewContact.ID_of_Currently_Active_Sequence__c != null && objOldContact.ID_of_Currently_Active_Sequence__c != objNewContact.ID_of_Currently_Active_Sequence__c) {
				set_ContactIds.add(objNewContact.Id);
				map_AccIdWithConId.put(objNewContact.AccountId, objNewContact);
			} else if (
				objOldContact.Actively_being_Sequenced__c != objNewContact.Actively_being_Sequenced__c ||
				(objNewContact.Current_Sequence_ID__c != null &&
				objOldContact.Current_Sequence_ID__c != objNewContact.Current_Sequence_ID__c) ||
				(objNewContact.Current_Sequence_Name__c != null &&
				objOldContact.Current_Sequence_Name__c != objNewContact.Current_Sequence_Name__c) ||
				(objNewContact.Current_Sequence_Status__c != null &&
				objOldContact.Current_Sequence_Status__c != objNewContact.Current_Sequence_Status__c) ||
				(objNewContact.Current_Sequence_Step_Number__c != null &&
				objOldContact.Current_Sequence_Step_Number__c != objNewContact.Current_Sequence_Step_Number__c) ||
				(objNewContact.Current_Sequence_Step_Type__c != null &&
				objOldContact.Current_Sequence_Step_Type__c != objNewContact.Current_Sequence_Step_Type__c) ||
				(objNewContact.Current_Sequence_Task_Due_Date__c != null &&
				objOldContact.Current_Sequence_Task_Due_Date__c != objNewContact.Current_Sequence_Task_Due_Date__c) ||
				(objNewContact.Current_Sequence_User_Name__c != null &&
				objOldContact.Current_Sequence_User_Name__c != objNewContact.Current_Sequence_User_Name__c) ||
				(objNewContact.Current_Sequence_User_Integration_ID__c != null &&
				objOldContact.Current_Sequence_User_Integration_ID__c != objNewContact.Current_Sequence_User_Integration_ID__c) ||
				(objNewContact.Number_of_Active_Sequences__c != null &&
				objOldContact.Number_of_Active_Sequences__c != objNewContact.Number_of_Active_Sequences__c) ||
				(objNewContact.Number_of_Active_Sequence_Tasks__c != null &&
				objOldContact.Number_of_Active_Sequence_Tasks__c != objNewContact.Number_of_Active_Sequence_Tasks__c) ||
				(objNewContact.Finished_Sequence__c != null &&
				objOldContact.Finished_Sequence__c != objNewContact.Finished_Sequence__c)
			) {
				set_ContIdtoUpdateOutreach.add(objNewContact.Id);
				map_AccIdWithConId.put(objNewContact.AccountId, objNewContact);
			}
		}

		if (map_AccIdWithConId.size() > 0) {
			//query over Contact Accounts to get related Account and assosciated Opps(Desc order by createddate) - Indexed Query
			List<Account> list_AssociatedAccWithOpps = queryAccounts(map_AccIdWithConId.keySet());

			for (Account objAcc : list_AssociatedAccWithOpps) {
				if (objAcc.RecordTypeId == AccountUtil.COMPANY_ACCOUNT_RT_ID) {
					if (!map_AccWIthOutreachValues.containsKey(objAcc.Id)) {
						map_AccWIthOutreachValues.put(objAcc.Id, new Map<String, Id>());
					}
					for (Opportunity objOpp : objAcc.Opportunities) {
						if (objOpp.RecordTypeId == OpportunityUtil.COMPANY_OPPTY_RT_ID) {
							//set oppId of opportunity is payroll opps
							map_AccWIthOutreachValues.get(objAcc.Id).put('OppId', objOpp.Id);
							//set soldBYreferredby for payroll ops
							if (objOpp.Sold_By__c != null) {
								map_AccWIthOutreachValues.get(objAcc.Id).put('SoldRefBy', objOpp.Sold_By__c);
							} else if (objOpp.Referred_By__c != null) {
								map_AccWIthOutreachValues.get(objAcc.Id).put('SoldRefBy', objOpp.Referred_By__c);
							} else {
								map_AccWIthOutreachValues.get(objAcc.Id).put('SoldRefBy', null);
							}
							//For HI Oppties get all the list of Opps
						} else if (OpportunityUtil.getBenefitRecordTypeIds().contains(objOpp.RecordTypeId)) {
							list_SortedHIOpps.add(objOpp.Id);
						} else {
							map_AccWIthOutreachValues.get(objAcc.Id).put('OppId', null);
						}
					}
				}
				//Since List already has sorted opps by created date .first opp should be the latest one.
				if (list_SortedHIOpps.size() > 0 && map_AccWIthOutreachValues.containsKey(objAcc.Id)) {
					map_AccWIthOutreachValues.get(objAcc.Id).put('HIOpp', list_SortedHIOpps[0]);
				} else if (map_AccWIthOutreachValues.containsKey(objAcc.Id)) {
					map_AccWIthOutreachValues.get(objAcc.Id).put('HIOpp', null);
				}
			}
		}
		if (set_ContIdtoUpdateOutreach.size() > 0) {
			//update outreach Engagement
			List<Outreach_Engagement__c> list_OutreachEngmnt = queryOutReachEngagements(set_ContIdtoUpdateOutreach);
			if (list_OutreachEngmnt.size() > 0) {
				for (Outreach_Engagement__c objOutreachEng : list_OutreachEngmnt) {
					//update only those Outreach record where Id of current Sequence matches
					if (
						map_newContact.containsKey(objOutreachEng.Contact__c) &&
						objOutreachEng.ID_of_Currently_Active_Sequence__c == map_newContact.get(objOutreachEng.Contact__c).ID_of_Currently_Active_Sequence__c
					) {
						objOutreachEng.Current_Sequence_ID__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_ID__c;
						objOutreachEng.Current_Sequence_User_Name__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_User_Name__c;
						objOutreachEng.Actively_being_Sequenced__c = map_newContact.get(objOutreachEng.Contact__c).Actively_being_Sequenced__c;
						objOutreachEng.Current_Sequence_Name__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_Name__c;
						objOutreachEng.Current_Sequence_Status__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_Status__c;
						objOutreachEng.Current_Sequence_Step_Number__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_Step_Number__c;
						objOutreachEng.Current_Sequence_Step_Type__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_Step_Type__c;
						objOutreachEng.Current_Sequence_Task_Due_Date__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_Task_Due_Date__c;
						objOutreachEng.Current_Sequence_User_Integration_ID__c = map_newContact.get(objOutreachEng.Contact__c).Current_Sequence_User_Integration_ID__c;
						objOutreachEng.Number_of_Active_Sequences__c = map_newContact.get(objOutreachEng.Contact__c).Number_of_Active_Sequences__c;
						objOutreachEng.Number_of_Active_Sequence_Tasks__c = map_newContact.get(objOutreachEng.Contact__c).Number_of_Active_Sequence_Tasks__c;
						objOutreachEng.Finished_Sequence__c = map_newContact.get(objOutreachEng.Contact__c).Finished_Sequence__c;
						objOutreachEng.Account__c = map_newContact.get(objOutreachEng.Contact__c).AccountId;

						if (map_AccWIthOutreachValues.containsKey(map_newContact.get(objOutreachEng.Contact__c).AccountId)) {
							Id idAccount = map_newContact.get(objOutreachEng.Contact__c).AccountId;
							objOutreachEng.Payroll_Opportunity__c = map_AccWIthOutreachValues.get(idAccount).get('OppId');
							objOutreachEng.Sold_By_Referred_By_Account__c = map_AccWIthOutreachValues.get(idAccount).get('SoldRefBy');
							objOutreachEng.HI_Opportunity__c = map_AccWIthOutreachValues.get(idAccount).get('HIOpp');
						}

						//update record owner based on Current Sequence User Itegration Id (actual user id)
						if (!String.isBlank(objOutreachEng.Current_Sequence_User_Integration_ID__c) && map_AllActiveUsers.containsKey(objOutreachEng.Current_Sequence_User_Integration_ID__c)) {
							objOutreachEng.OwnerId = objOutreachEng.Current_Sequence_User_Integration_ID__c;
						}

						list_OutreachEngmntToUpsert.add(objOutreachEng);
					}
				}
			}
		}
		if (set_ContactIds.size() > 0) {
			// Create new Outreach engagement record
			for (Id idContact : set_ContactIds) {
				Outreach_Engagement__c objOutreachEng = new Outreach_Engagement__c();
				if (map_newContact.containsKey(idContact)) {
					objOutreachEng.Current_Sequence_ID__c = map_newContact.get(idContact).Current_Sequence_ID__c;
					objOutreachEng.Current_Sequence_User_Name__c = map_newContact.get(idContact).Current_Sequence_User_Name__c;
					objOutreachEng.Actively_being_Sequenced__c = map_newContact.get(idContact).Actively_being_Sequenced__c;
					objOutreachEng.Current_Sequence_Name__c = map_newContact.get(idContact).Current_Sequence_Name__c;
					objOutreachEng.Current_Sequence_Status__c = map_newContact.get(idContact).Current_Sequence_Status__c;
					objOutreachEng.Current_Sequence_Step_Number__c = map_newContact.get(idContact).Current_Sequence_Step_Number__c;
					objOutreachEng.Current_Sequence_Step_Type__c = map_newContact.get(idContact).Current_Sequence_Step_Type__c;
					objOutreachEng.Current_Sequence_Task_Due_Date__c = map_newContact.get(idContact).Current_Sequence_Task_Due_Date__c;
					objOutreachEng.Current_Sequence_User_Integration_ID__c = map_newContact.get(idContact).Current_Sequence_User_Integration_ID__c;
					objOutreachEng.ID_of_Currently_Active_Sequence__c = map_newContact.get(idContact).ID_of_Currently_Active_Sequence__c;
					objOutreachEng.Number_of_Active_Sequences__c = map_newContact.get(idContact).Number_of_Active_Sequences__c;
					objOutreachEng.Number_of_Active_Sequence_Tasks__c = map_newContact.get(idContact).Number_of_Active_Sequence_Tasks__c;
					objOutreachEng.Finished_Sequence__c = map_newContact.get(idContact).Finished_Sequence__c;
					objOutreachEng.Contact__c = map_newContact.get(idContact).Id;
					objOutreachEng.Account__c = map_newContact.get(idContact).AccountId;

					if (map_AccWIthOutreachValues.containsKey(map_newContact.get(idContact).AccountId)) {
						Id idAccount = map_newContact.get(idContact).AccountId;
						objOutreachEng.Payroll_Opportunity__c = map_AccWIthOutreachValues.get(idAccount).get('OppId');
						objOutreachEng.Sold_By_Referred_By_Account__c = map_AccWIthOutreachValues.get(idAccount).get('SoldRefBy');
						objOutreachEng.HI_Opportunity__c = map_AccWIthOutreachValues.get(idAccount).get('HIOpp');
					}

					//update record owner based on Current Sequence User Itegration Id (actual user id)
					if (!String.isBlank(objOutreachEng.Current_Sequence_User_Integration_ID__c) && map_AllActiveUsers.containsKey(objOutreachEng.Current_Sequence_User_Integration_ID__c)) {
						objOutreachEng.OwnerId = objOutreachEng.Current_Sequence_User_Integration_ID__c;
					}
					list_OutreachEngmntToUpsert.add(objOutreachEng);
				}
			}
		}
		return list_OutreachEngmntToUpsert;
	}

	/*** Query Account Email Domain Records ***/
	public List<Account_Email_Domain__c> queryAccountEmailDomains(Set<Id> idAccount) {
		return [SELECT Id, Name, Account__c FROM Account_Email_Domain__c WHERE Account__c IN :idAccount];
	}

	/*** Query List of Contacts Linked to Account */
	public static List<Contact> queryContacts(Set<Id> set_AccountIds) {
		return [SELECT Normalized_Email_Domain__c, Normalized_Alternate_Email_Domain__c, AccountId FROM Contact WHERE AccountId IN :set_AccountIds];
	}

	/*** Query Accounts ***/
	public static List<Account> queryAccounts(Set<Id> set_AccountIds) {
		return [SELECT Id, RecordTypeId, (SELECT Id, RecordTypeId, Sold_By__c, Referred_By__c FROM Opportunities ORDER BY CreatedDate DESC) FROM Account WHERE Id = :set_AccountIds];
	}

	/*** Query Outreach Engagements ***/
	public static List<Outreach_Engagement__c> queryOutReachEngagements(Set<Id> set_ContactIds) {
		return [
			SELECT
				Id,
				Account__c,
				Actively_being_Sequenced__c,
				Contact__c,
				Current_Sequence_Name__c,
				Current_Sequence_Status__c,
				Current_Sequence_Step_Number__c,
				Current_Sequence_Step_Type__c,
				Current_Sequence_Task_Due_Date__c,
				Current_Sequence_User_Integration_ID__c,
				Current_Sequence_User_Name__c,
				Finished_Sequence__c,
				HI_Opportunity__c,
				ID_of_Currently_Active_Sequence__c,
				Number_of_Active_Sequences__c,
				Number_of_Active_Sequence_Tasks__c,
				Payroll_Opportunity__c,
				Sold_By_Referred_By_Account__c
			FROM Outreach_Engagement__c
			WHERE Contact__c = :set_ContactIds
		];
	}

	/**
	 * @Description : Set Subscription Preferences on Contact based on dependencies. Common method for before insert and update
	 * @Param        : Contact - Trigger new
	 * @Param        : Contact - Trigger old (if before update)
	 * @Return      : void
	 **/
	public void setSubscriptionPreferencesOnContact(Contact objNewContact, Contact objOldContact, Boolean blnIsInsert) {
		Set<String> set_newSubscriptionValues = new Set<String>();
		Set<String> set_oldSubscriptionValues = new Set<String>();
		Set<String> set_finalSubscriptionValues = new Set<String>();
		if (String.isNotBlank(objNewContact.Customer_Subscriptions__c)) {
			set_newSubscriptionValues.addAll(objNewContact.Customer_Subscriptions__c.split(';'));
		}
		//If new populate subscriptions factoring dependencies
		if (blnIsInsert) {
			objNewContact.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, true);
		} else if (objOldContact != null && objNewContact.Customer_Subscriptions__c != objOldContact.Customer_Subscriptions__c) {
			// Check if Subscription Preferences are modified on Contact
			if (String.isNotBlank(objOldContact.Customer_Subscriptions__c)) {
				set_oldSubscriptionValues.addAll(objOldContact.Customer_Subscriptions__c.split(';'));
			}
			objNewContact.Customer_Subscriptions__c = SubscriptionCenterUtil.getApplicableSubscriptionPreferences(set_newSubscriptionValues, set_oldSubscriptionValues, false);
		} else if (objOldContact != null && objNewContact.Salesloft_Email_Opt_Out__c && !objOldContact.Salesloft_Email_Opt_Out__c) {
			// Check if Email Op Out - Outreach is being checked
			if (objNewContact.Customer_Subscriptions__c != null) {
				set_finalSubscriptionValues.addAll(objNewContact.Customer_Subscriptions__c.split(';'));
			}
			if (set_finalSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) {
				set_finalSubscriptionValues.remove(SubscriptionCenterUtil.OUTREACH);
			}
			objNewContact.Customer_Subscriptions__c = String.join(new List<String>(set_finalSubscriptionValues), ';');
		}
	}

	/**
	 * @Description : add contacts for callout to mulesoft endpoint for updating Iterable/Sendgrid on update of admin preferences
	 * @Param        : Contact - triggerNew
	 * @Return      : void
	 **/
	public void calloutSubscriptionPreferencesIfUpdated(Contact objNewContact) {
		if (!objNewContact.Inactive_ZP_User__c) {
			list_contactsToCallout.add(objNewContact);
		}
	}

	/**
	 * @Description : Set Subscription Preferences on Account, on update of Preferences on Contact, common method for insert/update
	 * @Parm        : Contact - triggerNew, Contact - triggerOld, Boolean isInsert - true if called from after insert
	 * @Return      : N/A
	 **/
	public void setSubscriptionPreferencesOnParentAccount(Contact objNewContact, Contact objOldContact, Boolean blnIsInsert) {
		if (String.isBlank(objNewContact.ZP_User_Role__c)) {
			return;
		}
		Boolean blnIsAdmin = false;
		Set<String> set_UserRoles = new Set<String>(objNewContact.ZP_User_Role__c.split(';'));
		for (String strUserRole : set_UserRoles) {
			if (LIST_ADMIN_ROLES.contains(strUserRole)) {
				blnIsAdmin = true;
				break;
			}
		}
		if (blnIsAdmin && objNewContact.AccountId != null && (blnIsInsert || objNewContact.Customer_Subscriptions__c != objOldContact.Customer_Subscriptions__c)) {
			Account objAccountToUpdate = map_AccountsToUpdate.containsKey(objNewContact.AccountId) ? map_AccountsToUpdate.get(objNewContact.AccountId) : new Account(Id = objNewContact.AccountId);
			objAccountToUpdate.Customer_Subscriptions__c = objNewContact.Customer_Subscriptions__c;
			map_AccountsToUpdate.put(objAccountToUpdate.Id, objAccountToUpdate);
		}
	}

	/**
	 * @Description : Set Legacy Subscription fields based on Subscription Preferences field
	 * @Param        : Contact - Trigger new
	 * @Param        : Contact - Trigger old
	 * @Return      : void
	 **/
	public void setLegacySubscriptionFields(Contact objNewContact, Contact objOldContact) {
		// If feature flag is set to false, do not fire automation to set subscription checkbox fields
		if (String.isNotBlank(strSubscriptionFeatureFlag) && strSubscriptionFeatureFlag.equals('false')) {
			return;
		}

		if (objOldContact == null || objNewContact.Customer_Subscriptions__c != objOldContact.Customer_Subscriptions__c) {
			objNewContact.Subscription_Center_Small_Biz_Newslet__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BIZ_NEWSLETTER);
			objNewContact.Subscription_Center_Feature_Announce__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FEATURE_ANNOUNCEMENTS);
			objNewContact.Subscription_Center_Benefits_Announcem__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.BENEFIT_ANNOUNCEMENTS);
			objNewContact.Subscription_Center_Deals_and_Promos__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.DEALS_PROMOS);
			objNewContact.Subscription_Center_Financial_Products__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.FINANCIAL_PRODUCTS);
			objNewContact.Subscription_Center_Acct_Partner_Newsl__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.ACCOUNT_PARTNER_NEWS);
			objNewContact.Marketing_Email_Opt_Out__c =
				String.isNotBlank(objNewContact.Customer_Subscriptions__c) && objNewContact.Customer_Subscriptions__c.containsIgnoreCase(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT);
		}
	}

	/**
	 * @Description : Set Email Opt Out - Outreach Contact based on criteria. Common method for before insert and update
	 * @Param        : Contact - Trigger new
	 * @Param        : Contact - Trigger old (if before update)
	 * @Return      : void
	 **/
	public void setOutreachEmailOptOut(Contact objNewContact, Contact objOldContact) {
		Set<String> set_newSubscriptionValues = new Set<String>();
		Set<String> set_oldSubscriptionValues = new Set<String>();

		if (String.isNotBlank(objNewContact.Customer_Subscriptions__c)) {
			set_newSubscriptionValues.addAll(objNewContact.Customer_Subscriptions__c.split(';'));
		}
		if (objOldContact != null && String.isNotBlank(objOldContact.Customer_Subscriptions__c)) {
			set_oldSubscriptionValues.addAll(objOldContact.Customer_Subscriptions__c.split(';'));
		}
		if (
			objOldContact != null &&
			((!set_newSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH) && set_oldSubscriptionValues.contains(SubscriptionCenterUtil.OUTREACH)) ||
			(set_newSubscriptionValues.contains(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT) && !set_oldSubscriptionValues.contains(SubscriptionCenterUtil.MARKETING_EMAIL_OPT_OUT)))
		) {
			objNewContact.Salesloft_Email_Opt_Out__c = true;
		}
	}

	/**
	 * @Description : Set sync to marketo fields if contact role changes (indicated by marketo sync formula)
	 * @Param        : Contact - Trigger new
	 * @Param        : Contact - Trigger old
	 * @Return      : void
	 **/
	public void setSyncToMarketo(Contact objNewContact, Contact objOldContact) {
		if (objNewContact.Marketo_Sync__c == false && objNewContact.Marketo_Sync__c != objOldContact.Marketo_Sync__c) {
			objNewContact.Sync_To_Marketo__c = true;
			objNewContact.Sync_To_Marketo_Request_Time__c = System.now();
		} else if (objNewContact.Marketo_Sync__c == true && objNewContact.Marketo_Sync__c != objOldContact.Marketo_Sync__c) {
			objNewContact.Sync_To_Marketo__c = false;
		}
	}
}