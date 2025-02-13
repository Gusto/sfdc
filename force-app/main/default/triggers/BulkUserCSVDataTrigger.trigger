/*
 * @name         BulkUserCSVDataTrigger
 * @author       Gaurav Khare
 * @date         4/23/2019
 * @description  Creates or updates users in bulk
 * @test classes BulkUserUploadControllerTest
 */
trigger BulkUserCSVDataTrigger on Bulk_User_CSV_Data__c(before insert, after insert) {
	BulkUserCSVDataTriggerHelper handler = new BulkUserCSVDataTriggerHelper();
	if (BulkUserCSVDataTriggerHelper.skipTrigger == false) {
		if (Trigger.isInsert && Trigger.isBefore) {
			handler.OnBeforeInsert(Trigger.new);
		} else if (Trigger.isInsert && Trigger.isAfter) {
			handler.OnAfterInsert(Trigger.newMap);
		}
	}
}