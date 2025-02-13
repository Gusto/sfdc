/**
* Author: Midhuna KB
* Date: 02/02/2021
* Desc: scheduled class that runs NPSSurveyBatch batch class         
**/
global class NPSSurveyJob implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
        Integer intBatch = 20;
        if(objConfigSettings != null && objConfigSettings.NPS_Batch_Size__c != null) {          
            intBatch = (Integer) objConfigSettings.NPS_Batch_Size__c; 
        }
        NPSSurveyBatch objNPSSurveyBatch = new NPSSurveyBatch(); 
        database.executebatch(objNPSSurveyBatch, intBatch);
    }
}