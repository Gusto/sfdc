/**
 * @name         HIFulfillmentEventOpenEnrollment
 * @author       Gireesh
 * @date         11 June 2020
 * @description  Helper class to execute HI Fullfillment open enrollment events
 * @test class   HIFulfillmentEventOpenEnrollmentTest
 * @revisions    Date ------------ Name ------------ Comments
 */
public with sharing class HIFulfillmentEventOpenEnrollment {
	private static final string HIOESTATUS_OE = 'not_started';
	private static final string HIOESTATUS_EXTENDED = 'extended';
	private static final string HIOESTATUS_COMPLETED = 'completed';
	private static final string BENEFITSTATUS_OE = 'OE';
	private static final string BENEFITSTATUS_EXTENDED = 'OE Extended';
	private static final string BENEFITSTATUS_COMPLETED = 'OE Verification/Checking Participation';
	private static final String DEAD_UNPROCESSED_EVENT = 'Relevant Benefit Order was not found.';
	public static Boolean blnTestException = false;


	private static Map<String, String> map_HiFulfillMent_BoRecordType = new Map<String, String>{ 'Renewal' => 'Renewal', 'NewPlansApplication' => 'New_Plan', 'BenefitChangeApplication' => 'Change' };

	/*
	 * Author       :   Gireesh, 11 June 2020
	 * Description  :   Inner class to map the HIFullfillment open enrollment event JSON String
	 */
	public class HIFulfillmentEventOpenEntrollmentJSON {
		public string fulfillment_id;
		public string oe_status;
		public string company_id;
	}

	/*
	 * Author       :   Gireesh, 11 June 2020
	 * Description  :   Method to process HIFullfillment open enrollment and update the Benefit order.
	 * 					Hippo Status --> SFDC Status
	 *        			in_progress --> OE
	 *       			extended --> OE Extended
	 *      			completed--> OE Verification/Checking Participation
	 */
	public void processInformation(List<HI_Fulfillment_Event__c> list_FulfillmentList) {
		List<HIFullfillmentEventWrapper> list_HiWrapper = UtilitiesFactory.getDecryptedHIEventStr(list_FulfillmentList);
		map<String, HI_Fulfillment_Event__c> map_HiFulfillEvent = new Map<String, HI_Fulfillment_Event__c>();
		map<String, HIFulfillmentEventOpenEntrollmentJSON> map_HIFulfillOEJSON = new Map<String, HIFulfillmentEventOpenEntrollmentJSON>();
		System.debug('list_HiWrapper' + JSON.serializePretty(list_HiWrapper));
        if (!list_HiWrapper.isEmpty()) {
			for (HIFullfillmentEventWrapper objHiWrapper : list_HiWrapper) {
				try {
					HIFulfillmentEventOpenEntrollmentJSON objOpenEntrollmentJSON = (HIFulfillmentEventOpenEntrollmentJSON) JSON.deserialize(
						objHiWrapper.jsonString,
						HIFulfillmentEventOpenEntrollmentJSON.class
					);
                    
                    System.debug('objOpenEntrollmentJSON' + JSON.serializePretty(objOpenEntrollmentJSON));

					if (objOpenEntrollmentJSON.fulfillment_id == null) {
						map_HIFulfillOEJSON.put(objOpenEntrollmentJSON.company_id, objOpenEntrollmentJSON);
						map_HIFulfillEvent.put(objHiWrapper.objHiFulFillmentEvent.Id__c, objHiWrapper.objHiFulFillmentEvent);
					} else {
						map_HIFulfillOEJSON.put(objOpenEntrollmentJSON.fulfillment_id, objOpenEntrollmentJSON);
						map_HIFulfillEvent.put(objOpenEntrollmentJSON.fulfillment_id, objHiWrapper.objHiFulFillmentEvent);
					}

					//test exception
					if (Test.isRunningTest() && blnTestException) {
						Integer i = 1 / 0;
					}
				} catch (Exception e) {
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Something went wrong while deserializing JSON string.', objHiWrapper.objHiFulFillmentEvent);
					continue;
				}
			}
			Map<String, HI_Fulfillment__c> map_HIFulfillment = new Map<String, HI_Fulfillment__c>();
			for (HI_Fulfillment__c objHIFulfillment : [SELECT Id__c, Fulfillable_Id__c, Fulfillable_Type__c FROM HI_Fulfillment__c WHERE Id__c IN :map_HIFulfillOEJSON.keySet()]) {
				map_HIFulfillment.put(objHIFulfillment.Fulfillable_Id__c, objHIFulfillment);
			}
			if (map_HIFulfillOEJSON.isEmpty() && map_HIFulfillment.isEmpty()) {
				return;
			}

			Configuration_Settings__c objConfigSettings = Configuration_Settings__c.getOrgDefaults();
			List<String> list_doNotUpdateBenefitOrder;
			if (String.isNotBlank(objConfigSettings.BO_Do_Not_Update_Staus_on_HI_OE_event__c)) {
				list_doNotUpdateBenefitOrder = objConfigSettings.BO_Do_Not_Update_Staus_on_HI_OE_event__c.split(';');
			}
			System.debug('map_HIFulfillment' + JSON.serializePretty(map_HIFulfillment));
            System.debug('map_HIFulfillOEJSON' + JSON.serializePretty(map_HIFulfillOEJSON));
            System.debug('map_HIFulfillEvent' + JSON.serializePretty(map_HIFulfillEvent));
			List<Benefit_Order__c> list_BenefitOrders = [
				SELECT RecordType.DeveloperName, Application_Id__c, Opportunity_Type__c, Order_Status__c, ZP_Company_ID__c
				FROM Benefit_Order__c
				WHERE (Application_Id__c IN :map_HIFulfillment.keySet() OR (ZP_Company_Id__c IN :map_HIFulfillOEJSON.keySet() AND RecordTypeId = :BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID AND Order_Status__c = 'OE'))
				AND Order_Status__c <> null AND Order_Status__c  NOT IN :list_doNotUpdateBenefitOrder
			];
            /*List<Benefit_Order__c> list_BenefitOrders = [
				SELECT RecordType.DeveloperName, Application_Id__c, Opportunity_Type__c, Order_Status__c, ZP_Company_ID__c
				FROM Benefit_Order__c
				WHERE (Application_Id__c IN :map_HIFulfillment.keySet())
			];*/
			if (list_BenefitOrders != null && list_BenefitOrders.size() > 0) {
				List<Benefit_Order__c> list_UpdateBenefitOrders = new List<Benefit_Order__c>();
				/*building the benefitorder list for updating the order status*/
				try {
					for (Benefit_Order__c objBenefitOrder : list_BenefitOrders) {
						Boolean blnIsBYB = (objBenefitOrder.RecordTypeId == BenefitOrderUtil.BYB_BENEFIT_ORDER_RT_ID);

						if (blnIsBYB && !objBenefitOrder.Order_Status__c.equals('OE')) {
							continue;
						}

						String strMapKey = '';
						if (blnIsBYB && map_HIFulfillOEJSON.containsKey(objBenefitOrder.ZP_Company_Id__c)) {
							strMapKey = objBenefitOrder.ZP_Company_Id__c;
						} else if (map_HIFulfillment.containsKey(objBenefitOrder.Application_Id__c)) {
							strMapKey = map_HIFulfillment.get(objBenefitOrder.Application_Id__c).Id__c;
						}

						if (String.isBlank(strMapKey) || !map_HIFulfillOEJSON.containsKey(strMapKey)) {
							continue;
						}

						HIFulfillmentEventOpenEntrollmentJSON oHIFulfillment = map_HIFulfillOEJSON.get(strMapKey);
						if (oHIFulfillment == null) {
							continue;
						}

						if (!blnIsBYB) {
							String strFullfillmentType = (String) map_HIFulfillment.get(objBenefitOrder.Application_Id__c).Fulfillable_Type__c;
							if (objBenefitOrder.ZP_Company_ID__c != oHIFulfillment.company_id || map_HiFulfillMent_BoRecordType.get(strFullfillmentType) != objBenefitOrder.recordtype.developername) {
								continue;
							}
						}

						if (
							oHIFulfillment.oe_status == HIOESTATUS_EXTENDED && (objBenefitOrder.Order_Status__c != BENEFITSTATUS_EXTENDED && objBenefitOrder.Order_Status__c != BENEFITSTATUS_COMPLETED)
						) {
							objBenefitOrder.Order_Status__c = BENEFITSTATUS_EXTENDED;
							list_UpdateBenefitOrders.add(objBenefitOrder);
						} else if (oHIFulfillment.oe_status == HIOESTATUS_COMPLETED && (objBenefitOrder.Order_Status__c != BENEFITSTATUS_COMPLETED || blnIsBYB)) {
							objBenefitOrder.Order_Status__c = BENEFITSTATUS_COMPLETED;
							list_UpdateBenefitOrders.add(objBenefitOrder);
						}
					}
					if (!list_UpdateBenefitOrders.isEmpty()) {
						update list_UpdateBenefitOrders;
					}

					//updating the HI Fullfillevent status.
					for (String fullfillId : map_HIFulfillEvent.keySet()) {
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.PROCESSED_STATE, 'HI Open enrollment processed sucessfully', map_HIFulfillEvent.get(fullfillId));
					}

					//test exception
					if (Test.isRunningTest() && blnTestException) {
						Integer i = 1 / 0;
					}
				} catch (Exception e) {
					for (String fullfillId : map_HIFulfillEvent.keySet()) {
						if (map_HIFulfillment.containsKey(fullfillId) == false) {
							continue;
						}
						HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.ERROR_STATE, 'Benefit order process failed', map_HIFulfillEvent.get(fullfillId));
					}
				}
			} else {
				for (String strFulfillableId : map_HIFulfillEvent.keySet()) {
					if (map_HIFulfillment.containsKey(strFulfillableId) == false) {
						continue;
					}
					HIFulfillmentEventTriggerHelper.setProcessingState(IntegrationUtils.DEAD_STATE, DEAD_UNPROCESSED_EVENT, map_HIFulfillEvent.get(strFulfillableId));
				}
			}
		}
	}
}