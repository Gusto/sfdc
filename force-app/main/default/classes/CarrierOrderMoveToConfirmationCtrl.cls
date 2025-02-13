/**
 * @author       Deepika Saini
 * @date         22nd June 2024
 * @description  This class is used to validate the Move To Confirmation functionality .
 * @testclass	 CarrierOrderMoveToConfirmationCtrlTest
 **/

public with sharing class CarrierOrderMoveToConfirmationCtrl {
	/**
	 * @author      Deepika Saini
	 * @description This method used to Update Implemetation Stage to Ready For Confirmation
	 * @param       Id - Id of Carrier Order
	 *              String - String of Submission Completion Notes
	 * @return      Boolean - Returns True or false
	 */
	@AuraEnabled
	public static Boolean moveToConfirmation(Id carrierOrderId, String strSubmissionNotes) {
		try {
			List<Carrier_Order__c> list_CarrierOrders = [
				SELECT Id, Name, Implementation_Stage__c, Stage_Detail__c, Order_Type__c, Carrier__c, Effective_Date__c, Submission_Completion_Notes__c
				FROM Carrier_Order__c
				WHERE id = :carrierOrderId
			];

			if (!list_CarrierOrders.isEmpty()) {
				for (Carrier_Order__c objCo : list_CarrierOrders) {
					objCo.Submission_Completion_Notes__c = strSubmissionNotes;
					if (
						objCo.Implementation_Stage__c != CarrierOrderUtil.CO_STATUS_APPROVED ||
						objCo.Implementation_Stage__c != CarrierOrderUtil.STAGE_CANCELLED ||
						objCo.Implementation_Stage__c != BenefitOrderUtil.STATUS_CLOSED_LOST ||
						objCo.Implementation_Stage__c != CarrierOrderUtil.STAGE_CLOSED_ADMIN
					) {
						objCo.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
					}
				}
				OnboardingPlayModeUtility.setFirstPlayDateForCarrierOrders(TicketUtil.STR_ORDER, list_CarrierOrders);
			}

			Map<Id, Carrier_Order__c> map_CarrierOrderToBeUpdated = new Map<Id, Carrier_Order__c>();
			if (list_CarrierOrders != null && list_CarrierOrders.size() > 0) {
				for (Carrier_Order__c objCO : list_CarrierOrders) {
					map_CarrierOrderToBeUpdated.put(objCO.Id, objCO);
				}
				List<Carrier_Order__c> list_ChildCarrierOrder = getChildCarrierOrderStatus(carrierOrderId);
				if (!list_ChildCarrierOrder.isEmpty()) {
					for (Carrier_Order__c objChildCO : list_ChildCarrierOrder) {
						map_CarrierOrderToBeUpdated.put(objChildCO.Id, objChildCO);
					}
				}
				if (!map_CarrierOrderToBeUpdated.isEmpty()) {
					update map_CarrierOrderToBeUpdated.values();
				}
			}
			return true;
		} catch (exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to Update Implemetation Stage to Ready For Confirmation of Child Records
	 * @param       Id - Id of Parent Carrier Order
	 * @return      List of CO
	 */
	public static List<Carrier_Order__c> getChildCarrierOrderStatus(Id parentCarrierId) {
		List<Carrier_Order__c> list_ChildCarrierOrders = new List<Carrier_Order__c>();
		for (Carrier_Order__c co : [SELECT id, name FROM Carrier_Order__c WHERE Parent_Carrier_Order__c = :parentCarrierId]) {
			co.Implementation_Stage__c = CarrierOrderUtil.CO_STATUS_READY_FOR_CONFIRMATION;
			list_ChildCarrierOrders.add(co);
		}
		return list_ChildCarrierOrders;
	}

	@AuraEnabled
	public static List<Carrier_Order__c> getCarrierOrderRecord(Id idCarrierOrder){
		return [SELECT Id, Submission_Completion_Notes__c, Implementation_Stage__c, OwnerId, Confirmation_Owner__c FROM Carrier_Order__c WHERE Id = :idCarrierOrder];
	}
}