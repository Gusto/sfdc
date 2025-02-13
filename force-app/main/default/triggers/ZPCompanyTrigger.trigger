/* @name         ZPCompanyTrigger
 * @author       Praveen Sethu
 * @date         10-18-2021
 * @description  Handles different different DML operations on ZP Company. Delegates tasks to ZP Company Trigger Helper
 * @test classes ZPCompanyTriggerHelperTest
 */
trigger ZPCompanyTrigger on ZP_Company__c(before insert, after insert, before update, after update) {
	if (FeatureManagement.checkPermission('Bypass_Triggers') || ZPCompanyTriggerHelper.skipTrigger) {
		return;
	}
	ZPCompanyTriggerHelper handler = new ZPCompanyTriggerHelper();
	if (ZPCompanyTriggerHelper.skipTrigger == false) {
		if (Trigger.isInsert && Trigger.isBefore) {
			handler.OnBeforeInsert(Trigger.new);
		} else if (Trigger.isInsert && Trigger.isAfter) {
			handler.OnAfterInsert(Trigger.newMap);
		} else if (Trigger.isUpdate && Trigger.isBefore) {
			handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
		} else if (Trigger.isUpdate && Trigger.isAfter) {
			handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
		}
	}
}