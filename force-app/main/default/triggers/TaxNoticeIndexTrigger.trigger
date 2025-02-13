/* @author       Elavarasan Nagarathinam
 * @date         07/20/2023
 * @description  Trigger executed on DML operation of TNDC records
 **/

trigger TaxNoticeIndexTrigger on Tax_Notice_Index__c (before insert, after insert, after update) {
	// Check if Logged In User has custom permissions to by pass trigger or If Skip Trigger is set to True
	if (!FeatureManagement.checkPermission('Bypass_Triggers') && !TaxNoticeIndexTriggerHelper.skipTrigger) {
		new TaxNoticeIndexTriggerHandler().run();
	}
}