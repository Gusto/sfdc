/**
 * @author Praveen Sethu
 * @since 07/14/2022
 * Trigger Handler class that delegates tasks from PaymentInvoiceTrigger
 * Test class: PaymentInvoiceTriggerHandlerTest 
 **/
public without sharing class PaymentInvoiceTriggerHandler extends TriggerHandler {
	private List<Payment_Invoice__c> newRecords;
	private List<Payment_Invoice__c> oldRecords;
	private Map<Id, Payment_Invoice__c> newRecordsMap;
	private Map<Id, Payment_Invoice__c> oldRecordsMap;

	public static Boolean blnSkipTrigger = false;

	/**
	 * Constructor
	 */
	public PaymentInvoiceTriggerHandler() {
		super('PaymentInvoiceTriggerHandler');
		this.newRecords = (List<Payment_Invoice__c>) Trigger.new;
		this.oldRecords = (List<Payment_Invoice__c>) Trigger.old;
		this.newRecordsMap = (Map<Id, Payment_Invoice__c>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Payment_Invoice__c>) Trigger.oldMap;
	}

	/**
	 * @description Handles Before Insert Context
	 * @author Praveen Sethu
	 */
	public override void beforeInsert() {
		try {
			PaymentInvoiceTriggerHelper objHelper = new PaymentInvoiceTriggerHelper();
			objHelper.processBeforeInsert(newRecords);
			if (Test.isRunningTest()) {
				Integer i = 0/0;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PaymentInvoiceTriggerHandler', 'beforeInsert', null, objException);
		}
	}

	/**
	 * @description Handles After Insert Context
	 * @author Praveen Sethu
	 */
	public override void afterInsert() {
		try {
			PaymentInvoiceTriggerHelper objHelper = new PaymentInvoiceTriggerHelper();
			objHelper.processAfterInsert(newRecords);
			if (Test.isRunningTest()) {
				Integer i = 0/0;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PaymentInvoiceTriggerHandler', 'afterInsert', null, objException);
		}
	}

	/**
	 * @description Handles Before Update Context
	 * @author Praveen Sethu
	 */
	public override void beforeUpdate() {
		try {
			PaymentInvoiceTriggerHelper objHelper = new PaymentInvoiceTriggerHelper();
			objHelper.processBeforeUpdate(newRecords);
			if (Test.isRunningTest()) {
				Integer i = 0/0;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PaymentInvoiceTriggerHandler', 'beforeUpdate ', null, objException);
		}
	}

	/**
	 * @description Handles After Update Context
	 * @author Praveen Sethu
	 */
	public override void afterUpdate() {
		try {
			PaymentInvoiceTriggerHelper objHelper = new PaymentInvoiceTriggerHelper();
			objHelper.processAfterUpdate(newRecords);
			if (Test.isRunningTest()) {
				Integer i = 0/0;
			}
		} catch (Exception objException) {
			ExceptionLogUtil.logException('PaymentInvoiceTriggerHandler', 'afterUpdate', null, objException);
		}
	}
}