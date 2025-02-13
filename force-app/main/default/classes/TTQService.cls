/**
* @name         TTQService
* @author       Gireesh
* @date         10 August 2020
* @description  REST API class to get the TTQ data
* @test class   TTQServiceTest
* @revisions    Date ------------ Name ------------ Comments  
*               Sep/31/2020        PR               Passing new field values for BCA and Renewal applications
*/
@RestResource(urlMapping='/TTQService/*')
global with sharing class TTQService {
    static final String INTERNAL_ERROR='Salesforce internal error ';
    static final String RECORD_ERROR='Salesforce record is not found';
    static final String RECORDID_ERROR='Salesforce record Id is missing';
    global class TTQServiceException extends Exception{}
    class TTQWrapper{
        String sf_record_id;
        String application_id;
        String company_id;
        String application_type;
        String  number_hours_for_ee_to_be_eligible;
        Boolean fake_ee_data;
        Boolean special_enrollment;
        String important_note;
        Boolean has_affiliates;
        String owner_names_and_percentage_of_ownership;
        String contribution_details_from_ba;
        String rating_structure;
        String contribution_scheme_changes;
        String new_contribution_scheme;
        String tada_contribution_notes;
        Boolean waiving_initial_waiting_period;
        String prior_coverage_notes;
        String peo_switcher;
        String peo_notes_ee_on_cobra;
        String er_communication;
        String adding_tada;
        String [] type_of_tada_s;
        String renewing_tada;	
        string full_two_percent_shareholder_contributions_enabled;
        string part_time_ees_eligible;
        string address_notes;
        string add_scorp_contribution_description;
        boolean escalated_customer; 
    }
    /*
     * getTTQ - to get the TTQ data by recordId/applicationID and application type.
     * */
    @HttpGet
    global static String getTTQ() {
        String strTTQ;
        RestRequest objRequest = RestContext.request;
        Id objRecordId = RestContext.request.params.get('sf_record_id'); 
        String strApplicationId = RestContext.request.params.get('application_id'); 
        String strApplicationType = RestContext.request.params.get('application_type');
        if(String.isBlank(objRecordId)&&(String.isBlank(strApplicationId)||String.isBlank(strApplicationType)))
        {
            throw new TTQServiceException(RECORDID_ERROR);
        }
        List<Transition_to_Fulfillment__c>list_TTQ=new List<Transition_to_Fulfillment__c>();
        String strSoql='SELECT Opportunity__c, Opportunity__r.ZP_Company_ID_from_Account__c, application_id__c, RecordType.Name,Of_hours_for_EE_to_be_eligible__c,'+
            ' Special_Enrollment__c,Do_they_have_affiliates__c, '+
            ' PEO__c,Adding_TADA__c, '+
            ' Priority__c,Renewing_TAdA_s__c,Type_of_TADA_s__c FROM Transition_to_Fulfillment__c WHERE ';

        if(!String.isBlank(objRecordId)){
            list_TTQ=Database.query(strSoql+' Id=:objRecordId');
        }
        if(list_TTQ.isEmpty()){
            list_TTQ=Database.query(strSoql+' application_id__c =:strApplicationId and RecordType.Name=:strApplicationType ORDER BY createddate desc LIMIT 1');
        }
        if(list_TTQ.isEmpty()){
            throw new TTQServiceException(RECORD_ERROR);
        }
        try{
            Transition_to_Fulfillment__c objTTQ=list_TTQ.get(0);
            TTQWrapper objTTQWrapper=new TTQWrapper();
            objTTQWrapper.number_hours_for_ee_to_be_eligible=objTTQ.Of_hours_for_EE_to_be_eligible__c;
            objTTQWrapper.special_enrollment=objTTQ.Special_Enrollment__c;
            objTTQWrapper.has_affiliates=objTTQ.Do_they_have_affiliates__c;
            objTTQWrapper.peo_switcher=objTTQ.PEO__c;
            objTTQWrapper.adding_tada=objTTQ.Adding_TADA__c;
            objTTQWrapper.type_of_tada_s=getMultiPicklistValue(objTTQ.Type_of_TADA_s__c);//String [] 
            objTTQWrapper.renewing_tada=objTTQ.Renewing_TAdA_s__c;
            objTTQWrapper.sf_record_id=objTTQ.Id;
            objTTQWrapper.application_id=objTTQ.application_id__c;
            objTTQWrapper.company_id=objTTQ.Opportunity__r.ZP_Company_ID_from_Account__c;
            objTTQWrapper.application_type=objTTQ.RecordType.Name;
            objTTQWrapper.escalated_customer = 'Y' == objTTQ.Priority__c ? true : false;

            strTTQ=JSON.serialize(objTTQWrapper);
        }
        Catch(Exception objException){
            throw new TTQServiceException(INTERNAL_ERROR+' '+objException.getMessage());
        }
        return strTTQ;
    }
    private static String[] getMultiPicklistValue(String strValue){
        if(String.isNotBlank(strValue)){
            return strValue.split(';');
        }
        return null;
    }
}