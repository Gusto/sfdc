/**
 * @description  Automates functionalities on Campaign
 * @author       Veeresh Kumar
 * @date         04-18-2022
 * @see          CampaignTriggerHelperTest
 **/
public with sharing class CampaignTriggerHelper {
	// Static Variable used to Contact Skip Triggers
	public static Boolean blnSkipTrigger = false;

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Handles Before Insert Context
	 * @Parm        : list_Campaigns - List of Campaigns from Trigger.new
	 * @Return      : N/A
	 **/
	public void beforeInsert(List<Campaign> list_Campaigns) {
		for (Campaign objCampaign : list_Campaigns) {
			setDefaultsOnCreate(objCampaign);
		}
	}

	/**
	 * @Author      : Veeresh Kumar
	 * @Description : Sets Default Values when Campaign is Inserted
	 * @Parm        : objCampaign - New Campaign
	 * @Return      : N/A
	 **/
	private void setDefaultsOnCreate(Campaign objCampaign) {
		// if StartDate is blank, set it with CreatedDate
		if (objCampaign.StartDate == null) {
			objCampaign.StartDate = Date.today();
		}
	}

	public static void updateAccuticsStatusIfFieldsChanged(Map<Id, Campaign> oldMap, List<Campaign> newList) {
        // List of fields to check for changes
        Set<String> set_fieldsToCheck = new Set<String>{
            'Accutics_AffiliatePlatform__c', 
            'Accutics_AffiliateType__c',
            'Accutics_URL_OfConversion__c', 
            'Accutics_BDPartner__c',
            'Accutics_ID__c',
            'Accutics_LeadCampaign__c',
            'Accutics_LeadChannel__c',
            'Accutics_LeadFunnelStage__c',
            'Accutics_LeadMedium__c',
            'Accutics_LeadSource__c', 
            'Accutics_Type__c',
            'Accutics_AffiliatePartner_ID__c'
        };

        for (Campaign objNewCampaign : newList) {
            // Get the old version of the campaign record
            Campaign objOldCampaign = oldMap.get(objNewCampaign.Id);

            // Flag to check if any specified field has changed
            Boolean blnFieldChanged = false;

            // Iterate through the list of fields and check for changes
            for (String strField : set_fieldsToCheck) {
                if (objNewCampaign.get(strField) != objOldCampaign.get(strField)) {
                    blnFieldChanged = true;
                    break;
                }
            }

            // If any field has changed, update the status field
            if (blnFieldChanged) {
                objNewCampaign.put('Accutics_UpdateStatus__c', 'tobeprocessed');
            }
        }
    }
}