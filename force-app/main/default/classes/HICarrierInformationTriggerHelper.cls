public class HICarrierInformationTriggerHelper extends TriggerHandler {
	public static Boolean skipTrigger = false;
	public static Boolean queue = false;
	private static Map<String, String> statusMap;
	public static Boolean isBOInsert = false;

	public override void beforeInsert() { 
		List<HI_Carrier_Information__c> list_HICarrierInfo = (List<HI_Carrier_Information__c>) Trigger.new;
		if (queue == true) {
			processInformation(list_HICarrierInfo);
		} else {
			for (HI_Carrier_Information__c info : list_HICarrierInfo) {
				info.Processing_State__c = IntegrationUtils.QUEUED_STATE;
			}
		}
	}

	public override void afterInsert() {
		List<HI_Carrier_Information__c> list_HICarrierInfo = (List<HI_Carrier_Information__c>) Trigger.new;
		if (queue == false) {
			HICarrierInformationQueue insertJob = new HICarrierInformationQueue(list_HICarrierInfo, isBOInsert);
			ID jobID = System.enqueueJob(insertJob);
		}
	}

	public override void beforeUpdate() {
		List<HI_Carrier_Information__c> list_HICarrierInfo = (List<HI_Carrier_Information__c>) Trigger.new;
		Map<Id, HI_Carrier_Information__c> map_oldHICarrierInfo = (Map<Id, HI_Carrier_Information__c>) Trigger.oldMap;
		if (queue == true) {
			processInformation(list_HICarrierInfo);
		} else {
			for (HI_Carrier_Information__c info : list_HICarrierInfo) {
				info.Processing_State__c = IntegrationUtils.QUEUED_STATE;
				if (map_oldHICarrierInfo.containsKey(info.Id))
					info.Old_Deleted_At__c = map_oldHICarrierInfo.get(info.Id).Deleted_At__c;
			}
		}
	}

	public override void afterUpdate() {
		List<HI_Carrier_Information__c> list_HICarrierInfo = (List<HI_Carrier_Information__c>) Trigger.new;
		if (queue == false) {
			HICarrierInformationQueue insertJob = new HICarrierInformationQueue(list_HICarrierInfo, isBOInsert);
			ID jobID = System.enqueueJob(insertJob);
		}
	}

	private void processInformation(List<HI_Carrier_Information__c> informations) {
		try {
			CarrierOrderHelperFunctions controller = new CarrierOrderHelperFunctions();
			controller.processHICarrierInformation(informations);
		} catch (exception ex) {
			for (HI_Carrier_Information__c objHIInfo : informations) {
				setProcessingState(IntegrationUtils.ERROR_STATE, ex.getMessage(), objHIInfo);
				continue;
			}
		}
	}

	private HI_Carrier_Information__c setProcessingState(String ProcessingState, String message, HI_Carrier_Information__c carrierInfo) {
		carrierInfo.Processing_State__c = ProcessingState;
		carrierInfo.Message__c = message;
		carrierInfo.Last_Processed__c = System.now();
		return carrierInfo;
	}
}