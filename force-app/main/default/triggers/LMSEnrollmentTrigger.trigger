/*
 * @name         LMSEnrollmentTrigger
 * @author       Prity Kumari
 * @date         2022-07-19
 * @description  Delegates tasks to LMSEnrollmentTriggerHandler
 * @test classes LMSEnrollmentTriggerHelperTest
 */
trigger LMSEnrollmentTrigger on intellumapp__IntellumEnrollment__c (before insert,after insert,before update,after update) {
    // Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to False
    if (FeatureManagement.checkPermission('Bypass_Triggers') || LMSEnrollmentTriggerHelper.blnSkipTrigger) return;
    new LMSEnrollmentTriggerHandler().run();
}