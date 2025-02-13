public with sharing class HICarrierTriggerHelper extends TriggerHandler {
	
	public static boolean skipTrigger = false;
    public static boolean queue=false;

    public HICarrierTriggerHelper() {
		super('HICarrierTriggerHelper');
	}

	public override void beforeInsert(){ 
    	processInformation((List<HI_Carrier__c>) Trigger.new);
    }

    public override void beforeUpdate(){
		processInformation((List<HI_Carrier__c>) Trigger.new);
    }
    
    private void processInformation(List<HI_Carrier__c> carrierList){
    	list<Carrier_Info__c> toUpsertCarrierList = new list<Carrier_Info__c>();
    	set<String> carrierDetailSet = new set<String>();
        for(HI_Carrier__c hiCarrier : carrierList){
            if(hiCarrier.Carrier_Detail_Id__c!=null && hiCarrier.Carrier_Detail_Id__c!=''){
                carrierDetailSet.add(hiCarrier.Carrier_Detail_Id__c);
            }
    	}
        map<String,HI_Carrier_Detail__c> carrierFieldsMap = new map<String,HI_Carrier_Detail__c>();
        if(carrierDetailSet.size()>0){
            carrierFieldsMap = getCarrierDetailInfo(carrierDetailSet);
        }
        
    	for(HI_Carrier__c hiCarrier : carrierList){
			if(hiCarrier.Processing_State__c==IntegrationUtils.DEAD_STATE){
                continue;
            }
            HI_Carrier_Detail__c carrierDetail = new HI_Carrier_Detail__c();
            if(hiCarrier.Carrier_Detail_Id__c!=null && hiCarrier.Carrier_Detail_Id__c!=''){
                if(!carrierFieldsMap.containsKey(hiCarrier.Carrier_Detail_Id__c) ){
                    setProcessingState(IntegrationUtils.ERROR_STATE,'Carrier detail does not exist',hiCarrier);
                    continue;
                } else {
                    carrierDetail = carrierFieldsMap.get(hiCarrier.Carrier_Detail_Id__c);
                }
            }
            Carrier_Info__c info = mapCarrierFields(hiCarrier,carrierDetail);
            toUpsertCarrierList.add(info);
    	}
    	
    	if(toUpsertCarrierList.size()>0){	
			Map < String, String > dmlUpsertErrorsMap = new Map < String, String >();
	        if(toUpsertCarrierList.size() > 0){
	            List<Database.UpsertResult> saveResult = database.upsert(toUpsertCarrierList,Carrier_Info__c.Fields.Id__c,false);
	            dmlUpsertErrorsMap = Utils.processUpsertResult(saveResult,toUpsertCarrierList,'Id__c',true,'HICarrierTriggerHelper-processInformation');
	            
                for(HI_Carrier__c hiCarrier : carrierList){
                    if(string.isblank(hiCarrier.ID__c)){
                        setProcessingState(IntegrationUtils.ERROR_STATE,'Carrier Id is missing in the record.',hiCarrier);
                        continue;
                    }
                    
                    if (dmlUpsertErrorsMap.containsKey(hiCarrier.ID__c) ){
                        setProcessingState(IntegrationUtils.ERROR_STATE,dmlUpsertErrorsMap.get(hiCarrier.ID__c),hiCarrier);
                    } else {
                        setProcessingState(IntegrationUtils.PROCESSED_STATE,'Processed',hiCarrier);                            
                    }
                }
	        }			 
    	}
    }

    // maping all the related fields
    private Carrier_Info__c mapCarrierFields(HI_Carrier__c hiCarrier, HI_Carrier_Detail__c hiDatail){

        Carrier_Info__c info = new Carrier_Info__c(
            Name = hiDatail.Name__c,
            Id__c = hiCarrier.Id__c,
            Key__c = hiCarrier.key__c,
            External_Key__c = hiCarrier.External_Key__c,
            Carrier_Detail_Id__c = hiCarrier.Carrier_Detail_Id__c,
            Active__c = (hiCarrier.Deleted_At__c==null),
            Address_Addressed_To__c = hiDatail.Address_Addressed_To__c,
            Address_City__c = hiDatail.Address_City__c,
            Address_State__c = hiDatail.Address_State__c,
            Address_Street__c = hiDatail.Address_Street__c,
            Address_Zip__c = hiDatail.Address_Zip__c,
            Customer_Support__c = IntegrationUtils.getJsonParsedMap(hiDatail.Customer_Support__c,'default'),
            Email__c = hiDatail.Email__c,
            Lidi_Census_Email__c = hiDatail.Lidi_Census_Email__c,
            Min_Eligible_Employees_Required__c = hiDatail.Min_Eligible_Employees_Required__c,
            Qualifying_Life_Event_Requirements__c = hiDatail.Qualifying_Life_Event_Requirements__c,
            Sell_Description__c = hiDatail.Sell_Description__c
        );
        return info;
    }
    
    private map<String,HI_Carrier_Detail__c> getCarrierDetailInfo(Set<String> carrierDetailId){
        map<String,HI_Carrier_Detail__c> detailMap = new map<String,HI_Carrier_Detail__c>();
        for(HI_Carrier_Detail__c info : [Select Id,Id__c,Name__c,Address_Addressed_To__c,Address_City__c,Address_State__c,
                Address_Street__c,Address_Zip__c,Customer_Support__c,Email__c,Lidi_Census_Email__c,Min_Eligible_Employees_Required__c,
                Qualifying_Life_Event_Requirements__c,Sell_Description__c from HI_Carrier_Detail__c where id__c in :carrierDetailId]){
            detailMap.put(info.Id__c, info);
        }
        return detailMap;
    }

    private HI_Carrier__c setProcessingState(String ProcessingState, String message, HI_Carrier__c hiCarrier){
        hiCarrier.Processing_State__c = ProcessingState;
        hiCarrier.Message__c = message;
        hiCarrier.Last_Processed__c=System.now();
        return hiCarrier;
    }
}