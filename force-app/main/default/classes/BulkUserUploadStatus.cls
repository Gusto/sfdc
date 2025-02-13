public with sharing class BulkUserUploadStatus {
	public String csvId { get; set; }
	public List<Bulk_User_CSV_Data__c> bulkUserCsvList { get; set; }

	public BulkUserUploadStatus() {
		bulkUserCsvList = new List<Bulk_User_CSV_Data__c>();
		csvId = ApexPages.currentPage().getParameters().get('csvid');
		if (csvId != null) {
			bulkUserCsvList = [SELECT Name, csv_id__c, First_Name__c, Last_Name__c, Message__c, Processing_State__c FROM Bulk_User_CSV_Data__c WHERE csv_id__c = :csvid];
		}
	}
	public void refreshData() {
		bulkUserCsvList = [SELECT Name, csv_id__c, First_Name__c, Last_Name__c, Message__c, Processing_State__c FROM Bulk_User_CSV_Data__c WHERE csv_id__c = :csvid];
	}
}