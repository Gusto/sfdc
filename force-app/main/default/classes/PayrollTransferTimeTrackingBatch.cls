/*
 * Created By ND, 3rd Dec 2019
 * Process order records in batches, which were either updated, or their related cheklists were updated to keep track of different time metrics for Payroll Transfer Analytics
 */
global class PayrollTransferTimeTrackingBatch implements Database.Batchable<sObject> {
	global Database.QueryLocator start(Database.BatchableContext bContext) {
		List<Order> lstOrders = new List<Order>();

		//Get order ids of orders for which checklists were either created yesterday or later or deleted on yesterday or later
		Set<Id> setOrderIdWithUpdatedChecklists = new Set<Id>();
		List<Order_Facilitator_Checklist__c> lstUpdatedChecklistOrders = new List<Order_Facilitator_Checklist__c>();
		lstUpdatedChecklistOrders = [SELECT Order__c, IsDeleted FROM Order_Facilitator_Checklist__c WHERE CreatedDate >= YESTERDAY OR (IsDeleted = TRUE AND LastModifiedDate >= YESTERDAY) ALL ROWS];

		if (null != lstUpdatedChecklistOrders && lstUpdatedChecklistOrders.size() > 0) {
			for (Order_Facilitator_Checklist__c chk : lstUpdatedChecklistOrders) {
				setOrderIdWithUpdatedChecklists.add(chk.Order__c);
			}
		}

		//Contruct Order query
		String strOrderQuery = 'SELECT Id, Facilitator_Assigned_DateTime__c,Facilitator_Work_Start_DateTime__c,Status,Bulk_Migration__c,Previous_Payroll_Provider__c, ';
		strOrderQuery += '(SELECT Id, CreatedDate, Completed_Timestamp__c FROM Order_Facilitator_Checklists__r),';
		strOrderQuery += '(SELECT Id,From_Status__c,To_Status__c,Start_Time__c,End_Time__c FROM Order_Status_Change_History__r)';
		strOrderQuery += ' FROM Order WHERE RecordType.Name = \'Company Migration\' AND (LastmodifiedDate >= YESTERDAY OR Id IN :setOrderIdWithUpdatedChecklists)';
		//strOrderQuery +=' FROM Order WHERE RecordType.Name = \'Company Migration\' AND Payroll_Run_Date__c > 2019-11-10 '; //delete this line and uncomment the above line after first sucessfullrun of the batch

		return Database.getQueryLocator(strOrderQuery);
	}
	global void execute(Database.batchableContext bc, List<Order> lstOrders) {
		try {
			PayrollTransferTimeTrackingUtil ptAnalyticsUtil = new PayrollTransferTimeTrackingUtil();

			ptAnalyticsUtil.syncTimeTrackingDetails(lstOrders);
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('PayrollTransferTimeTrackingBatch', 'execute', objExp.getMessage(), objExp.getStackTraceString());
		}
	}

	global void finish(Database.BatchableContext bc) {
	}
}