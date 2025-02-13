/**
 * @name         CampaignToLeadAccuticsDataUpdateBatch
 * @author       Deepak Dhakal
 * @date         06-27-2024
 * @description  Update the lead data if there is an update in accutics campaign object
 * @test classes CampaignToLeadAccuticsBatchTest
 **/

public without sharing class CampaignToLeadAccuticsDataUpdateBatch implements Database.Batchable<sObject>, Database.stateful {
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        List<String> list_campaignFields = new List<String>{'Name','Accutics_AffiliatePlatform__c', 'Accutics_AffiliateType__c', 'Accutics_AffiliatePartner_ID__c', 'Accutics_URL_OfConversion__c', 'Accutics_BDPartner__c','Accutics_ID__c','Accutics_LeadCampaign__c','Accutics_LeadChannel__c','Accutics_LeadFunnelStage__c','Accutics_LeadMedium__c','Accutics_LeadSource__c', 'Accutics_Type__c'};
        // Convert the list of fields into a comma-separated string, properly formatted for SOQL
        String strQuery = 'SELECT Id, ' + String.join(list_campaignFields, ', ') +
            ' FROM Campaign' +
            ' WHERE Accutics_UpdateStatus__c = \'tobeprocessed\' AND LastModifiedDate = LAST_N_DAYS:7';
        
        // Execute the query and return the result
        return Database.getQueryLocator(strQuery);
    }
    
    public static void updateLeadsFromCampaigns(List<Campaign> list_Campaign) {
        try {
            // Define the mapping from Campaign to Lead fields
            Map<String, String> map_CampaignToLeads = new Map<String, String> {
                'Accutics_LeadChannel__c' => 'Lead_Channel__c',
                'Accutics_AffiliatePlatform__c' => 'Accutics_Affiliate_Platform__c',
                'Accutics_LeadMedium__c' => 'Accutics_Lead_Medium__c',
                'Accutics_AffiliateType__c' => 'Accutics_Affiliate_Type__c',
                'Accutics_LeadSource__c' => 'LeadSource',
                'Accutics_BDPartner__c' => 'Accutics_BD_Partner__c',
                'Accutics_LeadFunnelStage__c' => 'Accutics_Lead_Funnel_Stage__c',
                'Accutics_AffiliatePartner_ID__c' => 'Accutics_AffiliatePartner_ID__c',
                'Name' => 'ZP_Lead_Campaign__c'
            };
            
            // Collect Accutics_ID__c values from the Campaign records
            Set<String> set_accuticsIDs = new Set<String>();
            for (Campaign objCampaign : list_Campaign) {
                if (!String.isBlank(objCampaign.Accutics_ID__c)) {
                    set_accuticsIDs.add(objCampaign.Accutics_ID__c);
                }
            }
            
            if (!set_accuticsIDs.isEmpty()) {
                // Query Leads with matching Accutics_ID__c
                // Create a map of Accutics_ID__c to Lead records for quick access
                Map<String, List<Lead>> map_accuticsIdToLeads = new Map<String, List<Lead>>();
                for (Lead lead : [SELECT Id, ZP_Lead_Campaign__c, Accutics_ID__c, Lead_Channel__c, Accutics_Affiliate_Platform__c, Accutics_AffiliatePartner_ID__c,Accutics_Lead_Medium__c, Accutics_Affiliate_Type__c, LeadSource, Accutics_BD_Partner__c, Accutics_Lead_Funnel_Stage__c FROM Lead WHERE Accutics_ID__c IN :set_accuticsIDs]) {
                    List<Lead> list_TempLead = map_accuticsIdToLeads.get(lead.Accutics_ID__c);
                    if (list_TempLead == null) {
                        list_TempLead = new List<Lead>();
                    }
                    list_TempLead.add(lead);
                    map_accuticsIdToLeads.put(lead.Accutics_ID__c, list_TempLead);
                }
                
                List<Lead> list_leadsToUpdate = new List<Lead>();
                
                // Iterate over the Campaign list and update corresponding Lead fields
                for (Campaign objCampaign : list_Campaign) {
                    if (map_accuticsIdToLeads != null && map_accuticsIdToLeads.containsKey(objCampaign.Accutics_ID__c)) {
                        for (Lead objLeadToUpdate : map_accuticsIdToLeads.get(objCampaign.Accutics_ID__c)) {
                            boolean blnEligibleForUpdate = false;
                            for (String strCampaignField : map_CampaignToLeads.keySet()) {
                                String strLeadField = map_CampaignToLeads.get(strCampaignField);
                                if (objCampaign.get(strCampaignField) != objLeadToUpdate.get(strLeadField)) {
                                    objLeadToUpdate.put(strLeadField, objCampaign.get(strCampaignField));
                                    blnEligibleForUpdate = true;
                                }
                            }
                            if (blnEligibleForUpdate){
                                list_leadsToUpdate.add(objLeadToUpdate);
                            }
                        }
                    }
                }
                
                // Update Lead records if there are any changes
                if (!list_leadsToUpdate.isEmpty()) {
                    LeadTriggerHelper.skipTrigger = true;
                    update list_leadsToUpdate;
                }
                // update the campaign to be back to processed
                for (Campaign objCampaign : list_Campaign) {
                    objCampaign.Accutics_UpdateStatus__c ='processed';
                }
                update list_Campaign;
            }
        } catch(Exception objException) {
            ExceptionLogUtil.logException(
                'CampaignToLeadAccuticsDataUpdateBatch',
            'execute',
            'Exception On Line ' +
                objException.getLineNumber() +
                '-' +
                objException.getMessage(),
            objException.getStackTraceString()
                );
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Campaign> list_Campaign) {
        updateLeadsFromCampaigns(list_Campaign);
    }
    
    public void finish(Database.BatchableContext BC) {
        AsyncApexJob objAsyncJob = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        Utils.processBatchFinish(objAsyncJob, 'CampaignToLeadAccuticsDataUpdateBatch', false);
    }
}