/**
 * @description       : PlatformEventAbstract designed to be extended by all Platform Event Processors
 * @author            : Nigam Goyal
 * @last modified on  : 07-14-2024
 * @last modified by  : Nigam Goyal
 **/
public abstract class PlatformEventAbstract {
	public static Boolean blnIsFromBTRetry = false;
	public final Integer NUMBER_OF_RETRY_ATTEMPT = 4;
	/**
	 * @description processs the payloads of the event
	 * @author Nigam Goyal | 07-14-2024
	 * @param list_Payloads
	 * @return void
	 **/
	public abstract void processPayloads(List<String> list_Payloads);
	/**
	 * @description Retry standard platform exception upto 5 times and then create a record in BT_Retry_Processor__c object
	 * @author Nigam Goyal | 07-14-2024
	 * @param ex
	 * @return void
	 **/
	// exeption null means it was a global error for the complete transaction, it will retry all the payloads, else it will retry only the failed payloads
	public virtual void onError(Exception ex, List<String> list_Payloads, Set<String> set_IDs, String strBTEventProcessorName, List<String> list_errorMessages) {
		List<String> list_IDs = new List<String>(set_IDs);
		Map<String, Double> map_RetryProcessorCount = getRetryProcessorCountMap(set_IDs);
		if (!blnIsFromBTRetry && EventBus.TriggerContext.currentContext().retries < 2 && !Test.isRunningTest()) {
			throw new EventBus.RetryableException(ex.getMessage());
		} else if (set_IDs != null && !set_IDs.isEmpty()) {
			List<BT_Retry_Processor__c> list_BTRetryProcessores = new List<BT_Retry_Processor__c>();
			for (Integer index = 0; index < list_Payloads.size(); index++) {
				//in case error was before we get the proper id, it will put it as index + date time
				if ((index + 1) > list_IDs.size()) {
					list_IDs.add('index-' + index + DateTime.now().format('yyyy-MM-dd HH:mm:ss'));
				}
				BT_Retry_Processor__c objretryProcessor = new BT_Retry_Processor__c();
				objretryProcessor.BT_Event_Processor__c = strBTEventProcessorName;
				objretryProcessor.Error__c = ex == null ? list_errorMessages[index] : ex.getMessage();
				objretryProcessor.Payload__c = list_Payloads[index];
				objretryProcessor.Retry_Attempt__c = map_RetryProcessorCount.containsKey(list_IDs[index]) ? map_RetryProcessorCount.get(list_IDs[index]) + 1 : 1;
				objretryProcessor.UUID__c = list_IDs[index];
				objretryProcessor.Status__c = HIEventUtil.ERROR;
				// System will send slack message on 4th retry attempt and stop further retry attempts
				if (objretryProcessor.Retry_Attempt__c == NUMBER_OF_RETRY_ATTEMPT) {
					objretryProcessor.Send_Slack_Message__c = true;
				}
				if (objretryProcessor.Retry_Attempt__c <= NUMBER_OF_RETRY_ATTEMPT) {
					list_BTRetryProcessores.add(objretryProcessor);
				}
			}
			upsert list_BTRetryProcessores UUID__c;
		}
	}

	/**
	 * @description On success of transaction of failed record, system will auto delete the errored record
	 * @author Nigam Goyal | 09-23-2024
	 * @param set_IDs
	 * @return virtual
	 **/
	public virtual void onSuccessDeleteErrorBTRetryRecords(Set<String> set_IDs) {
		if (set_IDs != null && !set_IDs.isEmpty()) {
			String strUUIDs = String.join(new List<String>(set_IDs), ',').left(255);
			List<BT_Retry_Processor__c> list_BTRetryProcessores = [SELECT Id, Status__c FROM BT_Retry_Processor__c WHERE UUID__c = :strUUIDs];
			delete list_BTRetryProcessores;
		}
	}

	/**
	 * @description handle the upsert of the records based on the UUIDs
	 * @author Nigam Goyal | 12-09-2024
	 * @param set_IDs
	 * @return virtual
	 **/
	public virtual void handleUpsertBTRetry(List<Database.UpsertResult> list_UpsertResults, List<SObject> list_objs, String strField, List<String> list_Payloads) {
		Set<String> set_BrokerageToRemove = new Set<String>();
		Set<String> set_IdsToRetry = new Set<String>();
		List<String> list_errorMessages = new List<String>();
		List<String> list_PayloadsToRetry = new List<String>();
		for (Integer index = 0; index < list_UpsertResults.size(); index++) {
			String strId = strField.contains('.') ? (String) list_objs[index].getSobject(strField.split('\\.')[0]).get(strField.split('\\.')[1]) : (String) list_objs[index].get(strField);
			if (!list_UpsertResults[index].isSuccess()) {
				list_PayloadsToRetry.add(list_Payloads[index]);
				set_IdsToRetry.add(strId);
				list_errorMessages.add(list_UpsertResults[index].getErrors()[0].getMessage());
			} else {
				set_BrokerageToRemove.add(strId);
			}
		}
		// Delete the success errors records
		onSuccessDeleteErrorBTRetryRecords(set_BrokerageToRemove);
		// Retry the failed records
		PlatformEventAbstract.blnIsFromBTRetry = true;
		if (!list_PayloadsToRetry.isEmpty()) {
			onError(null, list_PayloadsToRetry, set_IdsToRetry, HIEventUtil.HI_BROKERAGE_UPSERT_EVENT, list_errorMessages);
		}
	}

	/**
	 * @description Count of Retry of failed records based on UUIDs
	 * @author Nigam Goyal | 09-23-2024
	 * @param strUUIDs
	 * @return Map<String, Double>
	 **/
	private static Map<String, Double> getRetryProcessorCountMap(Set<String> set_strUUIDs) {
		Map<String, Double> map_RetryProcessorCount = new Map<String, Double>();
		for (BT_Retry_Processor__c objRetryProcessor : [SELECT Id, UUID__c, Retry_Attempt__c FROM BT_Retry_Processor__c WHERE UUID__c IN :set_strUUIDs]) {
			Double retryAttempt = objRetryProcessor.Retry_Attempt__c == null ? 0 : objRetryProcessor.Retry_Attempt__c;
			map_RetryProcessorCount.put(objRetryProcessor.UUID__c, retryAttempt);
		}
		return map_RetryProcessorCount;
	}
}