/**
 * @description  Delegates control between CampaignTrigger and CampaignTriggerHelper
 * @author       Veeresh Kumar
 * @date         04-18-2022
 * @see          CampaignTriggerHelperTest
 **/
public with sharing class CampaignTriggerHandler extends TriggerHandler {
	private List<Campaign> list_NewRecords;
	private List<Campaign> list_OldRecords;
	private Map<Id, Campaign> map_NewRecords;
	private Map<Id, Campaign> map_OldRecords;

	public CampaignTriggerHandler() {
		super('CampaignTriggerHandler');
		this.list_NewRecords = (List<Campaign>) Trigger.new;
		this.list_OldRecords = (List<Campaign>) Trigger.old;
		this.map_NewRecords = (Map<Id, Campaign>) Trigger.newMap;
		this.map_OldRecords = (Map<Id, Campaign>) Trigger.oldMap;
	}

	/**
	 * @description Handles before update context. Overridden method from TriggerHandler
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeUpdate() {
		try {
			CampaignTriggerHelper.updateAccuticsStatusIfFieldsChanged(map_OldRecords, list_NewRecords);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CampaignTriggerHandler', 'beforeUpdate', null, objException);
		}
	}
	/**
	 * @description Handles before insert context. Overridden method from TriggerHandler
	 * @author      Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeInsert() {
		try {
			CampaignTriggerHelper objHelper = new CampaignTriggerHelper();
			objHelper.BeforeInsert(list_NewRecords);
		} catch (Exception objException) {
			ExceptionLogUtil.logException('CampaignTriggerHandler', 'beforeInsert', null, objException);
		}
	}
}