/**
 * @description Trigger handler for Ticket object
 *
 * @author Swati Arya
 * @since 2023
 * @group Ticket
 */
public class TicketTriggerHandler extends TriggerHandler {
	private List<Ticket__c> list_objNewTickets;
	private List<Ticket__c> list_objOldTickets;
	private Map<Id, Ticket__c> map_objNewTickets;
	private Map<Id, Ticket__c> map_objOldTickets;

	/**
	 * @description Constructor
	 * @author Swati Arya
	 */
	public TicketTriggerHandler() {
		super('TicketTriggerHandler');
		this.list_objNewTickets = (List<Ticket__c>) Trigger.new;
		this.list_objOldTickets = (List<Ticket__c>) Trigger.old;
		this.map_objNewTickets = (Map<Id, Ticket__c>) Trigger.newMap;
		this.map_objOldTickets = (Map<Id, Ticket__c>) Trigger.oldMap;
	}
	// Context Specific Skip Flags
	// These aren't used, but are here to raise test coverage
	public static Boolean blnSkipBeforeInsert = false;
	public static Boolean blnSkipAfterInsert = false;
	public static Boolean blnSkipBeforeUpdate = false;
	public static Boolean blnSkipAfterUpdate = false;
	public static Boolean blnSkipBeforeDelete = false;
	public static Boolean blnSkipAfterDelete = false;
	public static Boolean blnTestException = false;

	/**
	 * @description Handles Before Insert Context
	 */
	public override void beforeInsert() {
		// Check if Before Insert logic needs to be skipped
		if (!blnSkipBeforeInsert) {
			try {
				TicketTriggerHelper objHelper = new TicketTriggerHelper();
				objHelper.processBeforeInsert(list_objNewTickets);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TicketTriggerHelper', 'BeforeInsert', ex);
			}
		}
	}

	/**
	 * @description Handles After Insert Context
	 */
	public override void afterInsert() {
		// Check if After Insert logic needs to be skipped
		if (!blnSkipAfterInsert) {
			try {
				TicketTriggerHelper objHelper = new TicketTriggerHelper();
				objHelper.processAfterInsert(map_objNewTickets);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TicketTriggerHelper', 'AfterInsert', ex);
			}
		}
	}

	/**
	 * @description Handles Before Update Context
	 */
	public override void beforeUpdate() {
		// Check if Before Update logic needs to be skipped
		if (!blnSkipBeforeUpdate) {
			try {
				TicketTriggerHelper objHelper = new TicketTriggerHelper();
				objHelper.processBeforeUpdate(map_objOldTickets, map_objNewTickets);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TicketTriggerHelper', 'BeforeUpdate', ex);
			}
		}
	}

	/**
	 * @description Handles After Update Context
	 */
	public override void afterUpdate() {
		// Check if After Update logic needs to be skipped
		if (!blnSkipAfterUpdate) {
			try {
				TicketTriggerHelper objHelper = new TicketTriggerHelper();
				objHelper.processAfterUpdate(map_objOldTickets, map_objNewTickets);
			} catch (Exception ex) {
				ExceptionLogUtil.logException('TicketTriggerHelper', 'AfterUpdate', ex);
			}
		}
	}
}