/*
    BY: PR
    Date: Sep 26,2019
    Desc: Helper class code Order_BOA_Relationship__c trigger.
*/

public class OrderBOARelationshipTriggerHelper {
	public static boolean skiptrigger = false;
	public static String strAdvocate = 'Advocate';
	public static String strOrderStatusOpen = 'Open';
	public static String strOrderStatusClosed = 'Closed';
	public static Map<String, String> map_AdvocateOrderStatus = new Map<String, String>{
		'Closed: Payroll Run' => 'Closed',
		'Closed: Canceled' => 'Closed',
		'Blocked' => 'Closed',
		'Rejected' => 'Closed'
	};
	public static Map<String, String> map_OtherOrderStatus = new Map<String, String>{
		'Drafted' => 'Open',
		'Sales Submitted' => 'Open',
		'Sales Follow-up' => 'Open',
		'Collecting Documents' => 'Open',
		'Onboarding Steps 1 - 6' => 'Open',
		'Onboarding Step 7' => 'Open'
	};

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Before insert of Order_BOA_Relationship__c this method will execute.
	 * @Parm        : List of Order_BOA_Relationship__c records
	 * @Return      : NA
	 */
	public void onBeforeInsert(List<Order_BOA_Relationship__c> list_OrderBOARelationShip) {
		setDefaultFieldValues(list_OrderBOARelationShip, null);
	}

	public void onAfterInsert(List<Order_BOA_Relationship__c> list_OrderBOARelationShip) {
		updateUniqueStatesOnBOA(list_OrderBOARelationShip);
	}

	public void onBeforeDelete(List<Order_BOA_Relationship__c> list_OrderBOARelationShip) {
		updateUniqueStatesOnBOA(list_OrderBOARelationShip);
	}

	/**
	 * @Author      : Bhagat Singh
	 * @Description : Set default fields value, with respect to their related object.
	 * @Parm        : List of new Order_BOA_Relationship__c records
	 * 				: Map of old Order_BOA_Relationship__c records
	 * @Return      : NA
	 */
	public void setDefaultFieldValues(list<Order_BOA_Relationship__c> list_OrderBOARelationShip, Map<Id, Order_BOA_Relationship__c> map_OldOrderBOARelationShip) {
		try {
			Map<Id, Benefit_Order_Allocation__c> map_BOAllocations = new Map<Id, Benefit_Order_Allocation__c>();
			Set<Id> set_BOAllocations = new Set<Id>();
			for (Order_BOA_Relationship__c objRelation : list_OrderBOARelationShip) {
				if (objRelation.Benefit_Order_Allocation__c != null) {
					set_BOAllocations.add(objRelation.Benefit_Order_Allocation__c);
				}
			}

			if (set_BOAllocations.size() > 0) {
				for (Benefit_Order_Allocation__c objBOAllocation : [
					SELECT Id, Payroll_Transfer_FBOS_Forecast__c, Payroll_Transfer_FBOS_Forecast__r.RecordType.Name
					FROM Benefit_Order_Allocation__c
					WHERE Id IN :set_BOAllocations
				]) {
					map_BOAllocations.put(objBOAllocation.Id, objBOAllocation);
				}
			}

			for (Order_BOA_Relationship__c objRelation : list_OrderBOARelationShip) {
				Order_BOA_Relationship__c objOldRelation;
				if (objRelation.Id != null) {
					objOldRelation = map_OldOrderBOARelationShip?.containsKey(objRelation.Id) ? map_OldOrderBOARelationShip.get(objRelation.Id) : null;
				}

				Boolean blnIsNew = objOldRelation == null ? true : false;

				if (blnIsNew || objRelation.Inactive_Employee_Count__c != objRelation.Order_Inactive_Employee_Count_Formula__c) {
					objRelation.Inactive_Employee_Count__c = objRelation.Order_Inactive_Employee_Count_Formula__c != null ? objRelation.Order_Inactive_Employee_Count_Formula__c : 0;
				}

				if (blnIsNew || objRelation.Contractor_Count__c != objRelation.Order_Contractor_Count_Formula__c) {
					objRelation.Contractor_Count__c = objRelation.Order_Contractor_Count_Formula__c != null ? objRelation.Order_Contractor_Count_Formula__c : 0;
				}

				if (blnIsNew || objRelation.Order_Employee_Count__c != objRelation.Order_Employee_Count_Formula__c) {
					objRelation.Order_Employee_Count__c = objRelation.Order_Employee_Count_Formula__c != null ? objRelation.Order_Employee_Count_Formula__c : 0;
				}

				if (objRelation.Benefit_Order_Allocation__c != null && map_BOAllocations.containsKey(objRelation.Benefit_Order_Allocation__c)) {
					String strOrderStatus = strOrderStatusClosed;
					Benefit_Order_Allocation__c objBOAllocation = map_BOAllocations.get(objRelation.Benefit_Order_Allocation__c);
					if (objBOAllocation.Payroll_Transfer_FBOS_Forecast__c != null && objBOAllocation.Payroll_Transfer_FBOS_Forecast__r.RecordType.Name == strAdvocate) {
						strOrderStatus = strOrderStatusOpen;
						if (map_AdvocateOrderStatus.containsKey(objRelation.Order_Status_Formula__c)) {
							strOrderStatus = map_AdvocateOrderStatus.get(objRelation.Order_Status_Formula__c);
						}
					} else {
						if (map_OtherOrderStatus.containsKey(objRelation.Order_Status_Formula__c)) {
							strOrderStatus = map_OtherOrderStatus.get(objRelation.Order_Status_Formula__c);
						}
					}
					objRelation.Order_Status__c = strOrderStatus;
				}
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('OrderBOARelationshipTriggerHelper', 'setDefaultFieldValues', objExp.getMessage(), objExp.getStackTraceString());
		}
	}

	//Desc: on creation or deletion of the relationship object, we want to udpate the unique states on the related BOA
	public void updateUniqueStatesOnBOA(list<Order_BOA_Relationship__c> list_OrderBOARelationShip) {
		if (list_OrderBOARelationShip == null || list_OrderBOARelationShip.size() == 0) {
			return;
		}

		Map<Id, Benefit_Order_Allocation__c> map_toUpdateBOAs = new Map<Id, Benefit_Order_Allocation__c>();
		Set<Id> set_OrderIds = new Set<Id>();

		for (Order_BOA_Relationship__c objRelation : list_OrderBOARelationShip) {
			set_OrderIds.add(objRelation.orders__c);
		}

		Map<Id, Order> map_OrderIdRec = new Map<Id, Order>([SELECT Id, States__c FROM Order WHERE Id IN :set_OrderIds]);

		for (Order_BOA_Relationship__c objRelation : list_OrderBOARelationShip) {
			Benefit_Order_Allocation__c tempBOAObj = new Benefit_Order_Allocation__c(id = objRelation.Benefit_Order_Allocation__c);
			Set<String> set_uniqueStates = new Set<String>();

			if (map_OrderIdRec.get(objRelation.orders__c).States__c != null && map_OrderIdRec.get(objRelation.orders__c).States__c.length() > 0) {
				set_uniqueStates.addAll(map_OrderIdRec.get(objRelation.orders__c).States__c.Split(';'));
			}

			if (
				map_toUpdateBOAs.containsKey(objRelation.Benefit_Order_Allocation__c) &&
				map_toUpdateBOAs.get(objRelation.Benefit_Order_Allocation__c).Unique_States__c != null &&
				map_toUpdateBOAs.get(objRelation.Benefit_Order_Allocation__c).Unique_States__c.length() > 0
			) {
				set_uniqueStates.addAll(map_toUpdateBOAs.get(objRelation.Benefit_Order_Allocation__c).Unique_States__c.Split(';'));
			}

			if (set_uniqueStates.size() > 0) {
				list<String> lst_temp = new List<string>();
				lst_temp.addAll(set_uniqueStates);
				tempBOAObj.Unique_States__c = string.join(lst_temp, ';');
			}

			map_toUpdateBOAs.put(objRelation.Benefit_Order_Allocation__c, tempBOAObj);
		}

		if (map_toUpdateBOAs.size() > 0) {
			try {
				update map_toUpdateBOAs.values();
			} catch (exception ex) {
			}
		}
	}
}