trigger BTRetryProcessorTrigger on BT_Retry_Processor__c (after insert, after update) {
    
    Map<String, List<String>> map_EventProcessorToPayloadsMap = new Map<String, List<String>>();
    for (BT_Retry_Processor__c objretryProcessor : Trigger.new) {
        if(objretryProcessor.Status__c == HIEventUtil.ERROR || objretryProcessor.Status__c == HIEventUtil.QUEUED) {
            if (map_EventProcessorToPayloadsMap.containsKey(objretryProcessor.BT_Event_Processor__c)) {
                map_EventProcessorToPayloadsMap.get(objretryProcessor.BT_Event_Processor__c).add(objretryProcessor.Payload__c);
            } else {
                map_EventProcessorToPayloadsMap.put(objretryProcessor.BT_Event_Processor__c, new List<String>{ objretryProcessor.Payload__c });
            }
        }
    }

    for (String strEventProcessor : map_EventProcessorToPayloadsMap.keySet()) {
        Type objPlatformEventType = Type.forName(strEventProcessor);
        PlatformEventAbstract.blnIsFromBTRetry = true;
        PlatformEventAbstract objPlatformEventAbstract = (PlatformEventAbstract) objPlatformEventType.newInstance();
        List<String> list_Payloads = map_EventProcessorToPayloadsMap.get(strEventProcessor);
        objPlatformEventAbstract.processPayloads(list_Payloads);
    }
}