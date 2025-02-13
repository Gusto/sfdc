/**
 * @description       : Platform event (HI Event) Trigger Handler
 * @author            : Nigam Goyal
 * @last modified on  : 07-12-2024
 * @last modified by  : Nigam Goyal
**/
public with sharing class HIEventTriggerHandler {

	/**
	* @description Build the map of Event Processor to Payloads and process the payloads
	* @author Nigam Goyal | 07-12-2024 
	* @param list_HIEvents 
	**/
	public static void processHIEvents(List<HI_Event__e> list_HIEvents) {
        Map<String, List<String>> map_EventProcessorToPayloadsMap = new Map<String, List<String>>();
        for (HI_Event__e objHIEvent : list_HIEvents) {
            if (map_EventProcessorToPayloadsMap.containsKey(objHIEvent.BT_Event_Processor__c)) {
                map_EventProcessorToPayloadsMap.get(objHIEvent.BT_Event_Processor__c).add(objHIEvent.Payload__c);
            } else {
                map_EventProcessorToPayloadsMap.put(objHIEvent.BT_Event_Processor__c, new List<String>{ objHIEvent.Payload__c });
            }
        }

        for (String strEventProcessor : map_EventProcessorToPayloadsMap.keySet()) {
            Type objPlatformEventType = Type.forName(strEventProcessor);
            PlatformEventAbstract objPlatformEventAbstract = (PlatformEventAbstract) objPlatformEventType.newInstance();
            List<String> list_Payloads = map_EventProcessorToPayloadsMap.get(strEventProcessor);
            objPlatformEventAbstract.processPayloads(list_Payloads);
        }
    }
}