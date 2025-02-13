/**
 * @description  Handler class to delegate control between ProducerLicensingTrigger & ProducerLicensingTriggerHelper
 * @author       Praveen Sethu
 * @date         03-16-2023
 * @see          ProducerLicensingTriggerHelperTest
 **/
public class ProducerLicensingTriggerHandler extends TriggerHandler {
	private List<agentsync__Producer_Licensing__c> newRecords;
	private List<agentsync__Producer_Licensing__c> oldRecords;
	private Map<Id, agentsync__Producer_Licensing__c> newRecordsMap;
	private Map<Id, agentsync__Producer_Licensing__c> oldRecordsMap;

	public static Boolean blnSkipTrigger = false;

	/**
	 * @description Default class constructor that initializes trigger context variables
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public ProducerLicensingTriggerHandler() {
		super('ProducerLicensingTriggerHandler');
		this.newRecords = (List<agentsync__Producer_Licensing__c>) Trigger.new;
		this.oldRecords = (List<agentsync__Producer_Licensing__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, agentsync__Producer_Licensing__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, agentsync__Producer_Licensing__c>) Trigger.oldMap;
	}

	/**
	 * @description Handles After Insert Context
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public override void afterInsert() {
		try {
			ProducerLicensingTriggerHelper objHelper = new ProducerLicensingTriggerHelper();
			objHelper.processAfterInsert((Map<Id, agentsync__Producer_Licensing__c>) Trigger.newMap);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ProducerLicensingTriggerHandler', 'afterInsert', null, objException);
		}
	}

	/**
	 * @description Handles After Update Context
	 * @author      Praveen Sethu
	 * @param       NA
	 * @return      NA
	 **/
	public override void afterUpdate() {
		try {
			ProducerLicensingTriggerHelper objHelper = new ProducerLicensingTriggerHelper();
			objHelper.processAfterUpdate((Map<Id, agentsync__Producer_Licensing__c>) Trigger.newMap, (Map<Id, agentsync__Producer_Licensing__c>) Trigger.oldMap);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('ProducerLicensingTriggerHandler', 'afterUpdate', null, objException);
		}
	}
}