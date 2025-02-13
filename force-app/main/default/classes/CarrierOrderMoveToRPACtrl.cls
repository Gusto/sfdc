/**
 * @author       Deepika Saini
 * @date         15th June 2022
 * @description  This class is used to validate the Move To RPA functionality for the button.
 * @testclass	 CarrierOrderMoveToRPACtrlTest
 **/
global with sharing class CarrierOrderMoveToRPACtrl {
	static Set<String> set_ImplementationStages = new Set<String>{ CarrierOrderUtil.CO_STATUS_READY_FOR_SUBMISSION_PREP, CarrierOrderUtil.STAGE_SUBMISSION_PREP };
	public static final String STR_AUTOMATION_QUEUE = 'Automation Queue';
	public static final String STR_ERROR1_MESSAGE = 'Carrier Order cannot be routed to the Automation Queue because it does\'t meet the correct criteria. (i.e. Open Ticket, Incorrect Stage, wrong Order Type, not eligible for retry).';
	public static final String STR_ERROR2_MESSAGE = 'RPA automation is not valid for MULTI EIN records.';
	public static final String STR_SUCCESS_MESSAGE = 'Carrier Order routed to the Automation Queue Successfully.';
	public static final String STR_ASSIGNMENT_MESSAGE = 'Carrier Order already routed to the Automation Queue.';
	String strCarrierOrderId;
	static Boolean blnError;
	/**
	 * @author      Omar Benitez
	 * @description This method used to call assign the queue to owner from lwc
	 * @param       NA
	 * @return      result message
	 */
	@AuraEnabled
	public static string assignAutomationQueueWrapper(String strCarrierOrderId) {
		try {
			return assignAutomationQueue(strCarrierOrderId);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @author      Deepika Saini
	 * @description This method used assign the queue to owner
	 * @param       NA
	 * @return      page reference of CO
	 */
	webService static String assignAutomationQueue(String strCarrierOrderId) {
		Set<Id> set_CarrierOrderIds = new Set<Id>();
		set_CarrierOrderIds.add(strCarrierOrderId);
		List<Carrier_Order__c> list_CarrierOrders = CarrierOrderUtil.getCarrierOrders(set_CarrierOrderIds);
		blnError = false;

		if (list_CarrierOrders[0].Parent_Carrier_Order__c == null && list_CarrierOrders[0].Is_Multi_EIN__c == false) {
			if (list_CarrierOrders[0].OwnerId == GlobalQueryHelper.getQueueIdByName(STR_AUTOMATION_QUEUE)) {
				return STR_ASSIGNMENT_MESSAGE;
			} else {
				Boolean blnEligibleforRetry = false;
				if (list_CarrierOrders[0].Carrier__c != null && String.isNotBlank(list_CarrierOrders[0].Carrier__r.Carrier_Id__c)) {
					for (RPA_Submission_Automation_rules__mdt objSubmissionRules : RPA_Submission_Automation_rules__mdt.getAll().values()) {
						if (objSubmissionRules.Active__c && objSubmissionRules.Submission_Eligible_for_Retry__c && list_CarrierOrders[0].Carrier__r.Carrier_Id__c == objSubmissionRules.Carrier_Id__c) {
							blnEligibleforRetry = true;
						}
					}
				}

				if (!blnEligibleforRetry) {
					return STR_ERROR1_MESSAGE;
				}
				
				Id idOwnerId = list_CarrierOrders[0].OwnerId;
				list_CarrierOrders[0].Is_Order_Eligible_For_Sub_Automation__c = true;
				List<Carrier_Order__c> list_UpdatedCOs = SubmissionAutomationHelper.routeSubmissionCOToAutomation(list_CarrierOrders);

				if (idOwnerId == list_UpdatedCOs[0].OwnerId || !set_ImplementationStages.contains(list_UpdatedCOs[0].Implementation_Stage__c) || !list_UpdatedCOs[0].Tickets__r.isEmpty()) {
					blnError = true;
				}

				if (blnError) {
					return STR_ERROR1_MESSAGE;
				} else {

					try {
						update list_UpdatedCOs;
					} catch (exception objExp) {
						return objExp.getMessage();
					}
					return STR_SUCCESS_MESSAGE;
				}
			}
		} else {
			return STR_ERROR2_MESSAGE;
		}
	}

	/**
	 * @author      Deepika Saini
	 * @description This method used to return to the CO record
	 * @param       NA
	 * @return      List of carrier orders
	 */
	public PageReference discard() {
		PageReference objPageRef = new PageReference('/' + strCarrierOrderId);
		return objPageRef;
	}
}