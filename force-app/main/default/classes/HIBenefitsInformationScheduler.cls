global with sharing class HIBenefitsInformationScheduler implements Schedulable {
    public static final String HIFULFILLMENT_EVENT_BATCH_CLASS_NAME = 'HIFulfillmentEventBatch';
    public static final String FILTER_TYPE_BATCH_SIZE = 'Batch Size';
    
    global void execute(SchedulableContext sc) {
        database.executeBatch(new HINewPlansApplicationBatch(), 10);
        // get batch size from HI_Configuration__mdt setting for HIFulfillmentEventBatch class
        Map<String, HI_Configuration__mdt> map_HIConfigurations = HIBatchUtil.fetchHIConfigurations(HIFULFILLMENT_EVENT_BATCH_CLASS_NAME);
        Integer intBatchSize = 1;
        if (map_HIConfigurations != null && map_HIConfigurations.containsKey(FILTER_TYPE_BATCH_SIZE) && map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c != null) {
            intBatchSize = Integer.valueOf(map_HIConfigurations.get(FILTER_TYPE_BATCH_SIZE).Value__c);
        }
        database.executeBatch(new HIFulfillmentEventBatch(), intBatchSize);
    }
}