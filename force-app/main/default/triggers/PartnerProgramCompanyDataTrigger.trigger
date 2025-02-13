/**
 * @description PartnerProgramCompanyData Trigger
 * @author      Ajay Krishna P U
 * @since       2023-04-17
 * @see         PartnerProgramCompanyTriggerHelperTest
 */
trigger PartnerProgramCompanyDataTrigger on Partner_Program_Company_Data__c (after insert, after update, after delete, after undelete) {
        // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
        if (FeatureManagement.checkPermission('Bypass_Triggers') || PartnerProgramCompanyDataTriggerHelper.blnSkipTrigger) {return;}

        new PartnerProgramCompanyDataTriggerHandler().run();
}