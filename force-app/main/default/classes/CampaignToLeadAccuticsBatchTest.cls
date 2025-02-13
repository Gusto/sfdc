/**
 * @name         CampaignToLeadAccuticsBatchTest
 * @author       Deepak Dhakal
 * @date         06-27-2024
 * @description  Update the lead data if there is an update in accutics campaign object Test the data
 **/

@isTest
private class CampaignToLeadAccuticsBatchTest {
    
    /**
     * @description Test the batch job CampaignToLeadAccuticsDataUpdateBatch to update the lead with campaign record
     * @author      Deepak Dhakal
     * @param       NA
     * @return      NA
     **/
    @isTest
    static void testBatchExecution() {
        // Create test Campaigns
        List<Campaign> list_campaigns = new List<Campaign>();
        for (Integer i = 0; i < 1; i++) {
            list_campaigns.add(new Campaign(
                Name = 'Test Campaign ' + i,
            Accutics_ID__c = 'ACCID' + i,
            Accutics_LeadChannel__c ='Lead Channel'
                ));
        }
        insert list_campaigns;
        
        // Create test Leads
        List<Lead> list_Leads = new List<Lead>();
        for (Campaign objCampaign : list_campaigns) {
            TestDataFactory.LeadBuilder objBuilder = new TestDataFactory.LeadBuilder()
                .setRecordTypeId(LeadUtil.COMPANY_LEAD_RT_ID)
                .setFirstName('FName')
                .setLastName('LName')
                .setEmail('email@xeropartner.com')
                .setPhone('123456789')
                .setCompany('Xero Partner')
                .setLeadSource(LeadUtil.LEADSOURCE_XERO_MIGRATION_PARTNER)
                .setStatus(LeadUtil.LEAD_STATUS_AQL)
                .setAccuticsId(objCampaign.Accutics_ID__c);
            list_Leads.add(objBuilder.build());
        }
        insert list_Leads;
        
        // Execute the batch job
        Test.startTest();
        for (Campaign objCampaign : list_campaigns) {
            objCampaign.Accutics_BDPartner__c = 'testBD';
            objCampaign.Accutics_AffiliatePartner_ID__c = 'Test AffiliatePartner';
        }
        update list_campaigns;
        
        String strCronExp = '0 0 * * * ?';
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = 20;
        
        if (objConfigSettings != null && objConfigSettings.Accutics_Batch_Size__c != null) {
            intBatch = (Integer) objConfigSettings.Accutics_Batch_Size__c;
        } else {
            objConfigSettings.Accutics_Batch_Size__c = intBatch;
            insert objConfigSettings;
        }
        CampaignToLeadAccuticsScheduler objScheduler = new CampaignToLeadAccuticsScheduler();
        String strJobId = System.schedule('Data mapping scheduler', strCronExp, objScheduler);
        CampaignToLeadAccuticsDataUpdateBatch batch = new CampaignToLeadAccuticsDataUpdateBatch();
        Database.executeBatch(batch);
        batch.execute(null, list_campaigns);
        Test.stopTest();
        
        // Verify that Leads have been updated
        List<Lead> list_updatedLeads = [SELECT Id, Lead_Channel__c, Accutics_BD_Partner__c, Accutics_AffiliatePartner_ID__c FROM Lead];
        for (Lead objlead : list_updatedLeads) {
            System.assertEquals('Lead Channel', objlead.Lead_Channel__c, 'Lead_Channel__c was not updated correctly.');
            System.assertEquals('testBD', objlead.Accutics_BD_Partner__c, 'Accutics_BD_Partner__c was not updated correctly');
            System.assertEquals('Test AffiliatePartner', objlead.Accutics_AffiliatePartner_ID__c, 'Accutics_AffiliatePartner_ID__c was not updated correctly');
            
        }
    }
}