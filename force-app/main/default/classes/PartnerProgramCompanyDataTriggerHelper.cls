/**
 * @description PartnerProgramCompanyData Trigger Helper
 * @author      Ajay Krishna P U
 * @since       2023-04-17
 * @see 		PartnerProgramCompanyTriggerHelperTest
 */
public without sharing class PartnerProgramCompanyDataTriggerHelper {
	public static Boolean blnSkipTrigger = false;
	//Recalculate metric Tracker
	public static final String TRACKER_FIRM_MRR = 'Firm MRR';

	/**
	 * @description                  After Insert Handler
	 * @param map_NewPartnerPrograms New Version of PartnerProgram
	 */
	public void processAfterInsert(Map<Id, Partner_Program_Company_Data__c> map_NewPartnerPrograms) {
		//add account ids to the tracker only if the partner program does not already have a deleted at date
		Set<Id> set_AccountsToUpdate = new Set<Id>();
		for (Partner_Program_Company_Data__c objPartnerProgram : map_NewPartnerPrograms.values()) {
			if (objPartnerProgram.Deleted_At__c == null && objPartnerProgram.Managing_Accounting_Firm__c != null) {
				set_AccountsToUpdate.add(objPartnerProgram.Managing_Accounting_Firm__c);
			}
		}
		if (System.IsBatch() == false && System.isFuture() == false) {
			identifyAndTrackFirmMRRRecalculateChangesFuture(set_AccountsToUpdate);
		} else {
			identifyAndTrackFirmMRRRecalculateChanges(set_AccountsToUpdate);
		}
	}

	/**
	 * @description                  After Update Handler
	 * @param map_OldPartnerPrograms Old Version of PartnerProgram
	 * @param map_NewPartnerPrograms New Version of PartnerProgram
	 */
	public void processAfterUpdate(Map<Id, Partner_Program_Company_Data__c> map_OldPartnerPrograms, Map<Id, Partner_Program_Company_Data__c> map_NewPartnerPrograms) {
		//add managing account firm ids if deleted at is changed or managing account firm is changed or account is changed
		Set<Id> set_AccountsToUpdate = new Set<Id>();
		for (Partner_Program_Company_Data__c objPartnerProgram : map_NewPartnerPrograms.values()) {
			Partner_Program_Company_Data__c oldPartnerProgram = map_OldPartnerPrograms.get(objPartnerProgram.Id);
			if (objPartnerProgram.Managing_Accounting_Firm__c != oldPartnerProgram.Managing_Accounting_Firm__c || objPartnerProgram.Account__c != oldPartnerProgram.Account__c) {
				if (objPartnerProgram.Managing_Accounting_Firm__c != null && objPartnerProgram.Deleted_At__c == null) {
					set_AccountsToUpdate.add(objPartnerProgram.Managing_Accounting_Firm__c);
				}
				if (objPartnerProgram.Managing_Accounting_Firm__c != oldPartnerProgram.Managing_Accounting_Firm__c && oldPartnerProgram.Managing_Accounting_Firm__c != null) {
					set_AccountsToUpdate.add(oldPartnerProgram.Managing_Accounting_Firm__c);
				}
			} else if (objPartnerProgram.Deleted_At__c != oldPartnerProgram.Deleted_At__c && objPartnerProgram.Managing_Accounting_Firm__c != null) {
				set_AccountsToUpdate.add(objPartnerProgram.Managing_Accounting_Firm__c);
			}
		}
		if (System.IsBatch() == false && System.isFuture() == false) {
			identifyAndTrackFirmMRRRecalculateChangesFuture(set_AccountsToUpdate);
		} else {
			identifyAndTrackFirmMRRRecalculateChanges(set_AccountsToUpdate);
		}
	}

	/**
	 * @description                  After Delete Handler
	 * @param map_NewPartnerPrograms Old Version of PartnerProgram
	 */
	public void processAfterDelete(Map<Id, Partner_Program_Company_Data__c> map_OldPartnerPrograms) {
		//add account ids to the tracker only if the partner program does not already have a deleted at date
		Set<Id> set_AccountsToUpdate = new Set<Id>();
		for (Partner_Program_Company_Data__c objPartnerProgram : map_OldPartnerPrograms.values()) {
			if (objPartnerProgram.Managing_Accounting_Firm__c != null && objPartnerProgram.Deleted_At__c == null) {
				set_AccountsToUpdate.add(objPartnerProgram.Managing_Accounting_Firm__c);
			}
		}
		if (System.IsBatch() == false && System.isFuture() == false) {
			identifyAndTrackFirmMRRRecalculateChangesFuture(set_AccountsToUpdate);
		} else {
			identifyAndTrackFirmMRRRecalculateChanges(set_AccountsToUpdate);
		}
	}

	/**
	 * @description                  After Un-delete Handler
	 * @param map_NewPartnerPrograms New Version of PartnerProgram
	 */
	public void processAfterUnDelete(Map<Id, Partner_Program_Company_Data__c> map_NewPartnerPrograms) {
		//add account ids to the tracker only if the partner program does not already have a deleted at date
		Set<Id> set_AccountsToUpdate = new Set<Id>();
		for (Partner_Program_Company_Data__c objPartnerProgram : map_NewPartnerPrograms.values()) {
			if (objPartnerProgram.Managing_Accounting_Firm__c != null && objPartnerProgram.Deleted_At__c == null) {
				set_AccountsToUpdate.add(objPartnerProgram.Managing_Accounting_Firm__c);
			}
		}

		if (System.IsBatch() == false && System.isFuture() == false) {
			identifyAndTrackFirmMRRRecalculateChangesFuture(set_AccountsToUpdate);
		} else {
			identifyAndTrackFirmMRRRecalculateChanges(set_AccountsToUpdate);
		}
	}

	/**
	 * @description         Future method for identify Accounts needs Firm MRR recalculation.
	 * @param set_AccountsToUpdate   Set of Account Ids for which Firm MRR recalculation needs to be done.
	 */
	@future
	public static void identifyAndTrackFirmMRRRecalculateChangesFuture(Set<Id> set_AccountsToUpdate) {
		identifyAndTrackFirmMRRRecalculateChanges(set_AccountsToUpdate);
	}

	/**
	 * @description                   Identify Accounts needs Firm MRR recalculation.
	 * @param set_AccountsToUpdate   Set of Account Ids for which Firm MRR recalculation needs to be done.
	 */
	public static void identifyAndTrackFirmMRRRecalculateChanges(Set<Id> set_AccountsToUpdate) {
		List<Account> list_AccountsToUpdate = new List<Account>();
		for (Account objAccount : [SELECT Id, Recalculate_Metrics_Tracker__c FROM Account WHERE Id IN :set_AccountsToUpdate]) {
			if (!Utils.isMultiPicklistContains(objAccount.Recalculate_Metrics_Tracker__c, TRACKER_FIRM_MRR)) {
				objAccount.Recalculate_Metrics_Tracker__c = Utils.addToMultiPicklistValue(objAccount.Recalculate_Metrics_Tracker__c, TRACKER_FIRM_MRR);
				list_AccountsToUpdate.add(objAccount);
			}
		}

		AccountTriggerHelper.skipTrigger = true;
		update list_AccountsToUpdate;
		AccountTriggerHelper.skipTrigger = false;
	}
}