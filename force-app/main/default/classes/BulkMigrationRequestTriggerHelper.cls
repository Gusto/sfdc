/**
    Created by : Gaurav Khare
    Created Date : 5/06/2019
**/
public class BulkMigrationRequestTriggerHelper {
	public static boolean skipTrigger = false;
	private static integer counter = 0;
	private static Map<Id, Bulk_Migration_Request__c> map_ReslAccIdBMRs = new Map<Id, Bulk_Migration_Request__c>(); //By :Prashant 23-04-2020
	private static List<Bulk_Migration_Request__c> list_BulkMRWithTTFs = new List<Bulk_Migration_Request__c>();
	private static Set<Id> set_BulkMReqIds = new Set<Id>(); // To store list of Bulk Mig Req  Id
	private static Set<Id> set_caseIds = new Set<Id>(); //to update case Status on BMR completion

	@InvocableMethod(label='Skip BMR Trigger' description='Sets the skipTrigger flag to true.')
	public static void skipBMRTrigger(List<boolean> booleanList) {
		if (booleanList.size() > 0) {
			skipTrigger = booleanList[0];
		}
	}
	public void processBeforeInsert(List<Bulk_Migration_Request__c> list_BulkMRs) {
		counter++;
	}

	public void processAfterInsert(Map<ID, Bulk_Migration_Request__c> map_BulkMRs) {
		counter++;
		processBMRInfo(map_BulkMRs.values(), null);
		updateBMRonRelatedTTFOrder();
	}

	public void processBeforeUpdate(Map<Id, Bulk_Migration_Request__c> map_OldBMRs, Map<Id, Bulk_Migration_Request__c> map_NewBMRs) {
		counter++;
	}

	public void processAfterUpdate(Map<Id, Bulk_Migration_Request__c> map_OldBMRs, Map<Id, Bulk_Migration_Request__c> map_NewBMRs) {
		counter++;
		processBMRInfo(map_NewBMRs.values(), map_OldBMRs);
		updateOrders();
		updateBMRonRelatedTTFOrder();
		updateRelatedCaseStatus(set_caseIds); //Reference in Order TriggreHelper
	}

	/*
	By : AKS prepare all the data before sending to perform operation
	*/
	public void processBMRInfo(List<Bulk_Migration_Request__c> list_BMRs, Map<Id, Bulk_Migration_Request__c> map_OldBMR) {
		for (Bulk_Migration_Request__c objBMR : list_BMRs) {
			//Get Old BMR
			Bulk_Migration_Request__c objOLDBMR = null;
			if (map_OldBMR?.size() > 0) {
				objOLDBMR = map_OldBMR.get(objBMR.Id);
			}
			if (objBMR.Transition_To_Fulfillment__c != null && (objOLDBMR == null || (objOLDBMR != null && objOLDBMR.Transition_To_Fulfillment__c != objBMR.Transition_To_Fulfillment__c))) {
				list_BulkMRWithTTFs.add(objBMR);
			}

			if (objBMR.Reseller_Account__c != null && (objOLDBMR == null || (objOLDBMR != null && objOLDBMR.Reseller_Account__c != objBMR.Reseller_Account__c))) {
				map_ReslAccIdBMRs.put(objBMR.Reseller_Account__c, objBMR);
			}

			if (
				objOLDBMR != null &&
				objOLDBMR.Bulk_Migration_Status__c != objBMR.Bulk_Migration_Status__c &&
				objBMR.Bulk_Migration_Status__c == BulkMigrationRequestUtil.BULK_MIGRATION_STATUS_COMPLETED
			) {
				set_BulkMReqIds.add(objBMR.Id);
				if (objBMR.Bulk_Case__c != null) {
					set_caseIds.add(objBMR.Bulk_Case__c);
				}
			}
		}
	}
	/*
        By: PR, Date: Oct 11 2019, Desc: On BMR creation or TTF field update, we want to update the BMR lookup
        on order related with TTF.
    */
	public void updateBMRonRelatedTTFOrder() {
		if (list_BulkMRWithTTFs == null || list_BulkMRWithTTFs.size() == 0) {
			return;
		}

		List<Order> list_toUpdateOrderRecords = new List<Order>();
		Map<Id, Bulk_Migration_Request__c> map_TTFIdBMRIds = new Map<Id, Bulk_Migration_Request__c>();

		for (Bulk_Migration_Request__c objBMR : list_BulkMRWithTTFs) {
			map_TTFIdBMRIds.put(objBMR.Transition_To_Fulfillment__c, objBMR);
		}

		if (map_TTFIdBMRIds.keySet().size() > 0) {
			for (Order orderObj : [SELECT Id, Transition_to_Fulfillment__c, Bulk_Migration__c, Bulk_Case__c FROM Order WHERE Transition_to_Fulfillment__c IN :map_TTFIdBMRIds.keyset()]) {
				orderObj.Bulk_Migration__c = map_TTFIdBMRIds.get(orderObj.Transition_to_Fulfillment__c).id;
				orderObj.Bulk_Case__c = map_TTFIdBMRIds.get(orderObj.Transition_to_Fulfillment__c).Bulk_Case__c;
				list_toUpdateOrderRecords.add(orderObj);
			}

			if (list_toUpdateOrderRecords.size() > 0) {
				try {
					update list_toUpdateOrderRecords;
				} catch (exception objException) {
					list_BulkMRWithTTFs.get(0).addError('Error occured while updating the Order with new BMR record. ' + objException.getMessage());
				}
			}
		}
	}

	// If status is changed to Completed the Update all related Orders to closed
	public void updateOrders() {
		if (set_BulkMReqIds == null || set_BulkMReqIds.size() == 0) {
			return;
		}

		List<Order> list_OrdersToUpdate = new List<Order>();
		List<Order> list_Orders = [
			SELECT Id, status
			FROM Order
			WHERE Bulk_Migration__c IN :set_BulkMReqIds AND status != :BulkMigrationRequestUtil.STATUS_CLOSED_PAYROLL_RUN AND status != :BulkMigrationRequestUtil.STATUS_CLOSED_CANCELED
		]; // Query open Orders
		for (Order objOrder : list_Orders) {
			objOrder.status = BulkMigrationRequestUtil.STATUS_CLOSED_PAYROLL_RUN;
			list_OrdersToUpdate.add(objOrder);
		}

		if (list_OrdersToUpdate.size() > 0) {
			OrderTriggerHelper.skipTrigger = true;
			update list_OrdersToUpdate;
			OrderTriggerHelper.skipTrigger = false;
		}
	}

	//BY: PR, Date: Oct-22-2019, Desc: If the BMR status goes "Completed" we want to close the related Case record.
	public void updateRelatedCaseStatus(Set<Id> set_caseIdsTemp) {
		if (set_caseIdsTemp == null || set_caseIdsTemp.size() == 0) {
			return;
		}
		List<Case> list_toUpdateCases = new List<Case>();

		for (Id caseIds : set_caseIdsTemp) {
			list_toUpdateCases.add(new Case(Id = caseIds, Status = BulkMigrationRequestUtil.STATUS_CLOSED, Send_Survey__c = true));
		}

		if (list_toUpdateCases.size() > 0) {
			try {
				boolean previousVal = CaseTriggerHelper.skipTrigger;
				CaseTriggerHelper.skipTrigger = true;
				update list_toUpdateCases;
				CaseTriggerHelper.skipTrigger = previousVal;
			} catch (exception ex) {
				ExceptionLogUtil.logException('BulkMigrationRequestTriggerHelper', 'updateRelatedCaseStatus', ex.getMessage(), ex.getStackTraceString());
			}
		}
	}
}