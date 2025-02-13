/**
 * @description Trigger handler for ZP_Product_Line__c
 * @author Anurag Gautam
 * @since 2023
 * @group ZP_Product_Line__c
 */
public with sharing class ZPProductLineTriggerHandler extends TriggerHandler {
	private List<ZP_Product_Line__c> list_NewZPProductLine;
	private List<ZP_Product_Line__c> list_OldZPProductLine;
	private Map<Id, ZP_Product_Line__c> map_IdToNewZPProductLine;
	private Map<Id, ZP_Product_Line__c> map_IdToOldZPProductLine;

	/**
	 * @description Constructor
	 */
	public ZPProductLineTriggerHandler() {
		super('ZPProductLineTriggerHandler');
		this.list_NewZPProductLine = (List<ZP_Product_Line__c>) Trigger.new;
		this.list_OldZPProductLine = (List<ZP_Product_Line__c>) Trigger.old;
		this.map_IdToNewZPProductLine = (Map<Id, ZP_Product_Line__c>) Trigger.newMap;
		this.map_IdToOldZPProductLine = (Map<Id, ZP_Product_Line__c>) Trigger.oldMap;
	}
	/**
	 * @description Handles Before Insert Context
	 */
	public override void beforeInsert() {
		ZPProductLineTriggerHelper objHelper = new ZPProductLineTriggerHelper();
		objHelper.processBeforeInsert(list_NewZPProductLine);
	}

	/**
	 * @description Handles After Insert Context
	 */
	public override void afterInsert() {
		ZPProductLineTriggerHelper objHelper = new ZPProductLineTriggerHelper();
		objHelper.processAfterInsert(map_IdToNewZPProductLine);
	}

	/**
	 * @description Handles Before Update Context
	 */
	public override void beforeUpdate() {
		ZPProductLineTriggerHelper objHelper = new ZPProductLineTriggerHelper();
		objHelper.processBeforeUpdate(map_IdToOldZPProductLine, map_IdToNewZPProductLine);
	}

	/**
	 * @description Handles After Update Context
	 */
	public override void afterUpdate() {
		ZPProductLineTriggerHelper objHelper = new ZPProductLineTriggerHelper();
		objHelper.processAfterUpdate(map_IdToOldZPProductLine, map_IdToNewZPProductLine);
	}
}