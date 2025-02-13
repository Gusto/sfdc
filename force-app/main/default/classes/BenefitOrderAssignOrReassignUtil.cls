/**
 * @name          BenefitOrderAssignOrReassignUtil
 * @author        Neha Dabas
 * @date          03-17-2021
 * @description   Sends mass email to cases
 * @see  		  MassEmailUtilTest
 **/
public without sharing class BenefitOrderAssignOrReassignUtil {
	public static final String OA_OOO_MASS_EMAIL_TEMPLATE_NAME = 'OA_Out_of_Office_Notification_for_Customers';
	public static final String OWD_EMAIL_RENEWALS = 'renewals@gusto.com';
	public static final String OWD_EMAIL_NEWPLANS = 'newplans@gusto.com';

	/**
	 * @author       Neha Dabas
	 * @description  Assign BO for OOO Owners and Reassign once they are back in office.
	 * @param        list_BenefitOrders Benefit Orders
	 * @param		 blnOOOAssignment If BOs are being assigned because Owner is OOO
	 * @param		 set_BOIds BO Ids which do not have a parent
	 **/
	public static void assignOrReassignBenefitOrders(Boolean blnOOOAssignment, List<Benefit_Order__c> list_BenefitOrders, Set<Id> set_BOIds) {
		List<Benefit_Order__c> list_ChildBOs = new List<Benefit_Order__c>();
		FWAssignmentUtil objAssignmentUtil = new FWAssignmentUtil();
		List<Benefit_Order__c> list_BOsToUpdate = new List<Benefit_Order__c>();

		if (blnOOOAssignment == true) {
			list_BOsToUpdate = objAssignmentUtil.processAdvocateAssignmentForBO(list_BenefitOrders, true, null, null, null, new Map<Id, Id>());
		} else {
			for (Benefit_Order__c objBenefitOrder : list_BenefitOrders) {
				objBenefitOrder.Initial_Owner__c = objBenefitOrder.OwnerId;
				objBenefitOrder.OwnerId = UserInfo.getUserId();
				list_BOsToUpdate.add(objBenefitOrder);
			}
		}

		try {
			for (Benefit_Order__c objBO : list_BenefitOrders) {
				objBO.OOO_In_Progress__c = false;
			}

			update list_BenefitOrders;
			//get All child and update owner same like parent
			if (set_BOIds != null && !set_BOIds.isEmpty()) {
				for (Benefit_Order__c objBO : [
					SELECT Initial_Owner__c, OwnerId, Parent_Benefit_Order__c, Parent_Benefit_Order__r.OwnerId
					FROM Benefit_Order__c
					WHERE Parent_Benefit_Order__c IN :set_BOIds
				]) {
					if (objBO.Initial_Owner__c == null) {
						objBO.Initial_Owner__c = objBO.OwnerId;
					}
					objBO.OwnerId = objBO.Parent_Benefit_Order__r.OwnerId;
					list_ChildBOs.add(objBO);
				}

				if (!list_ChildBOs.isEmpty()) {
					update list_ChildBOs;
				}
			}
		} catch (Exception objExp) {
			ExceptionLogUtil.logException('BenefitOrderAssignOrReassignUtil', 'assignOrReassignBenefitOrders', objExp.getMessage(), 'Medium');
		}
	}

}