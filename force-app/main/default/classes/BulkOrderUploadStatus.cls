public with sharing class BulkOrderUploadStatus {
	public Id bmrId { get; set; }
	public List<Bulk_Order_CSV_Data__c> toBeOrderedLst { get; set; }

	public BulkOrderUploadStatus() {
		toBeOrderedLst = new List<Bulk_Order_CSV_Data__c>();
		bmrId = ApexPages.currentPage().getParameters().get('id');
		if (bmrId != null) {
			toBeOrderedLst = [SELECT Id, Name, Company_ID__c, Message__c, Processing_State__c FROM Bulk_Order_CSV_Data__c WHERE Bulk_Migration_Request__c = :bmrId];
		}
	}
	public void refreshData() {
		toBeOrderedLst = [SELECT Id, Name, Company_ID__c, Message__c, Processing_State__c FROM Bulk_Order_CSV_Data__c WHERE Bulk_Migration_Request__c = :bmrId];
	}

	public pageReference redirectToBMRRecord() {
		bmrId = ApexPages.currentPage().getParameters().get('id');
		PageReference pg = new PageReference('/' + bmrId);
		pg.setRedirect(true);
		return pg;
	}
}