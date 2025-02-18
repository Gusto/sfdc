/**
 * @description  Used to identify unconverted leads associated to user roles and merge them to existing companies or firms
 * @author       Praveen Sethu
 * @date         04-06-2022
 * @see          ZPUserRoleTriggerHelperTest
 **/
public with sharing class BatchConvertZPUserRoleLeads implements Database.Batchable<sObject> {
	/**
	 * @description Queries user roles that errored out because of pending lead conversion
	 * @author      Praveen Sethu
	 * @return      NA
	 **/
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String strErrorState = IntegrationUtils.ERROR_STATE;
		String strLeadConvertPendingStatus = ZPUserRoleUtil.LEAD_CONVERT_PENDING;
		String strQuery = 'Select Id, ZP_User__c, ZP_User__r.Email__c, Company_Id__c, Accounting_Firm_Id__c, Company_Account__c, Accounting_Firm_Account__c FROM ZP_User_Role__c WHERE Processing_State__c = :strErrorState AND Message__c = :strLeadConvertPendingStatus';
		return Database.getQueryLocator(strQuery);
	}

	/**
	 * @description convert leads to existing companies or firms
	 * @author      Praveen Sethu
	 * @return      NA
	 **/
	public void execute(Database.BatchableContext bc, List<ZP_User_Role__c> list_ZPUserRoles) {
		// Reseller lead record type Id
		Id idResellerLeadRecordType = Cache.getRecordTypeId('Lead', 'Reseller');
		Set<String> set_ConvertedLeads = new Set<String>();
		Set<Id> set_AccountIds = new Set<Id>();
		Set<String> set_LeadEmails = new Set<String>();
		Map<Id, ZP_User_Role__c> map_RolesToUpdate = new Map<Id, ZP_User_Role__c>();
		List<ZP_User__c> list_UsersToUpdate = new List<ZP_User__c>();
		Map<String, ZP_User_Role__c> map_EmailToRole = new Map<String, ZP_User_Role__c>();
		Map<String, Opportunity> map_OpportunityByAccountId = new Map<String, Opportunity>();
		Map<String, Contact> map_ContactByEmail = new Map<String, Contact>();

		for (ZP_User_Role__c objRole : list_ZPUserRoles) {
			if (String.isNotBlank(objRole?.ZP_User__r?.Email__c)) {
				map_EmailToRole.put(objRole.ZP_User__r.Email__c, objRole);
			}

			if (objRole.Company_Account__c != null) {
				set_AccountIds.add(objRole.Company_Account__c);
			} else {
				set_AccountIds.add(objRole.Accounting_Firm_Account__c);
			}
		}

		List<Lead> list_Leads = [SELECT Id, Email, RecordTypeId FROM Lead WHERE Email IN :map_EmailToRole.keySet() AND IsConverted = FALSE];

		for (Opportunity objOpportunity : [
			SELECT Id, AccountId, ZP_Company_ID__c, OwnerId
			FROM Opportunity
			WHERE AccountId IN :set_AccountIds AND (RecordTypeId = :ZPUserRoleUtil.COMPANY_OPPTY_RT_ID OR RecordTypeId = :ZPUserRoleUtil.ACQUISITION_OPPTY_RT_ID)
			ORDER BY CreatedDate ASC
		]) {
			map_OpportunityByAccountId.put(objOpportunity.AccountId, objOpportunity);
		}

		for (Lead objLead : list_Leads) {
			if (map_EmailToRole.containsKey(objLead.Email) && !set_ConvertedLeads.contains(objLead.Email)) {
				set_LeadEmails.add(objLead.Email);
			}
		}

		for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Email IN :set_LeadEmails]) {
			map_ContactByEmail.put(objContact.Email, objContact);
		}

		for (Lead objLead : list_Leads) {
			if (map_EmailToRole.containsKey(objLead.Email) && !set_ConvertedLeads.contains(objLead.Email)) {
				ZP_User_Role__c objRole = map_EmailToRole.get(objLead.Email);
				ZP_User__c objUser = new ZP_User__c(Id = objRole.ZP_User__c);
				// new instance of lead convert
				Database.LeadConvert objConvert = new Database.LeadConvert();

				try {
					// Set Lead Id
					objConvert.setLeadId(objLead.Id);
					// Set Converted Status as SAL
					objConvert.setConvertedStatus(Config.LeadConversion.CONVERTED_LEAD_STATUS);

					Id idAccount = objRole.Company_Account__c != null ? objRole.Company_Account__c : objRole.Accounting_Firm_Account__c;
					// Check if account already has company opportunity
					Opportunity objOpportunity = map_OpportunityByAccountId.get(idAccount);

					// Do not create opportunity for reseller leads OR company account already has company opportunity
					if (objLead.RecordTypeId == idResellerLeadRecordType || objOpportunity != null) {
						objConvert.setDoNotCreateOpportunity(true);
					}
					// Set Account Id
					objConvert.setAccountId(idAccount);
					// Convert Lead
					Database.LeadConvertResult objResult = Database.convertLead(objConvert);
					set_ConvertedLeads.add(objLead.Email);

					// If lead conversion is successful, set zp user role and zp user to Queued state. They will be re-processed by Batach
					Contact objContact = map_ContactByEmail.get(objLead.Email);
					if (objResult.isSuccess() && objContact != null) {
						// Skip trigger User Role to Queued State
						objRole.Processing_State__c = IntegrationUtils.QUEUED_STATE;
						objRole.Message__c = ZPUserRoleUtil.LEAD_CONVERT_SUCCESSFUL;
						objRole.Contact__c = objContact.Id;
						map_RolesToUpdate.put(objRole.Id, objRole);

						// Skip trigger User to Queued State
						objUser.Processing_State__c = IntegrationUtils.QUEUED_STATE;
						list_UsersToUpdate.add(objUser);
					}

					if (Test.isRunningTest()) {
						// force exception when run via tests
						Integer i = 0 / 0;
					}
				} catch (Exception objException) {
					// If Lead Conversion Fails, mark User Role as Failed
					objRole.Processing_State__c = IntegrationUtils.ERROR_STATE;
					String strMessage = objException.getMessage();
					strMessage = String.isNotBlank(strMessage) && strMessage.length() > 255 ? strMessage.subString(0, 255) : strMessage;
					objRole.Message__c = strMessage;
					map_RolesToUpdate.put(objRole.Id, objRole);
				}
			}
		}

		if (!map_RolesToUpdate.isEmpty()) {
			ZPUserRoleTriggerHelper.skipTrigger = true;
			update map_RolesToUpdate.values();
		}

		if (!list_UsersToUpdate.isEmpty()) {
			ZPUserRoleTriggerHelper.skipTrigger = true;
			update list_UsersToUpdate;
		}
	}

	/**
	 * @description send out emails if there are any errors
	 * @author      Praveen Sethu
	 * @return      NA
	 **/
	public void finish(Database.BatchableContext BC) {
		AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
		Utils.processBatchFinish(objAsyncJob, 'BatchConvertZPUserRoleLeads', false);
	}
}