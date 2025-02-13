/**
 * @name         GFLeadTriggerHandler
 * @author       Veeresh Kumar
 * @date         04/13/2022
 * @description  Trigger Handler class that delegates tasks between GFLeadTrigger and GFLeadTriggerHelper
 * @see          GFLeadTriggerHelperTest
 **/
public class GFLeadTriggerHandler extends TriggerHandler {
	// Static Variables:
	public static Boolean blnTestException = false;

	// Instance Variables:
	private List<GF_Lead__c> list_NewRecords;
	private List<GF_Lead__c> list_OldRecords;
	private Map<Id, GF_Lead__c> map_NewRecords;
	private Map<Id, GF_Lead__c> map_OldRecords;

	/**
	 * @description Constructor
	 * @author     	Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public GFLeadTriggerHandler() {
		super('GFLeadTriggerHandler');
		list_NewRecords = (List<GF_Lead__c>) Trigger.new;
		list_OldRecords = (List<GF_Lead__c>) Trigger.old;
		map_NewRecords = (Map<Id, GF_Lead__c>) Trigger.newMap;
		map_OldRecords = (Map<Id, GF_Lead__c>) Trigger.oldMap;
	}

	/**
	 * @description Overridden method from TriggerHandler - Handles Task Before Insert Context
	 * @author     	Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeInsert() {
		try {
			GFLeadTriggerHelper objHelper = new GFLeadTriggerHelper();
			objHelper.processBeforeInsert(list_NewRecords);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHandler', 'beforeInsert', objEx);
		}
	}

	/**
	 * @description Overridden method from TriggerHandler - Handles Task After Insert Context
	 * @author     	Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void afterInsert() {
		try {
			GFLeadTriggerHelper objHelper = new GFLeadTriggerHelper();
			objHelper.processAfterInsert(map_NewRecords);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHandler', 'afterInsert', objEx);
		}
	}

	/**
	 * @description Overridden method from TriggerHandler - Handles Task Before Update Context
	 * @author     	Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void beforeUpdate() {
		try {
			GFLeadTriggerHelper objHelper = new GFLeadTriggerHelper();
			objHelper.processBeforeUpdate(map_OldRecords, map_NewRecords);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHandler', 'beforeUpdate', objEx);
		}
	}

	/**
	 * @description Overridden method from TriggerHandler - Handles Task After Update Context
	 * @author     	Veeresh Kumar
	 * @param       NA
	 * @return      NA
	 **/
	public override void afterUpdate() {
		try {
			GFLeadTriggerHelper objHelper = new GFLeadTriggerHelper();
			objHelper.processAfterUpdate(map_OldRecords, map_NewRecords);

			if (blnTestException) {
				Integer intException = 0 / 0;
			}
		} catch (Exception objEx) {
			ExceptionLogUtil.logException('GFLeadTriggerHandler', 'afterUpdate', objEx);
		}
	}
}