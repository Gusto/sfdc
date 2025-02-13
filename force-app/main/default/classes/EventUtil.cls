/*
 * @name         EventUtil
 * @author       Sandeep Golla
 * @date         01-31-2022
 * @description  Utility Class for Event Object
 */
public with sharing class EventUtil {
	public final static String LABEL_CHILIPIPER = 'ChiliPiper';

	// Stage Names
	public final static String DEMO_TYPE = 'Demo';
	public final static String PITCH_TYPE = 'Pitch';
	public final static String MEETING_TYPE = 'Schedule-A-Call for Gusto Pro';

	//RecordTypes
	public final static Id AE_DEMO_EVENT_RT_ID = Cache.getRecordTypeId('Event', 'AE Demo');
	public final static Id ARDIUS_TICKET_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Ticket__c', 'Ardius');

	// Meeting types
	public final static String HI_OPPTY_NEW_PLAN = 'HI Opportunity Pass: New Plan';
	public final static String HI_OPPTY_BOR = 'HI Opportunity Pass: BoR';
	public final static String PAYROLL_ONLY_DEMO = 'Payroll Only-Demo';
	public final static String PAYROLL_ONLY_PITCH = 'Payroll Only-Pitch';
	public final static String PAYROLL_BENEFITS_DEMO = 'Payroll Benefits-Demo';
	public final static String PAYROLL_BENEFITS_PATCH = 'Payroll Benefits-Pitch';
	public final static String PARTNER_RESELLER_PASS = 'Partner Reseller Pass';
	public final static String PARTNER_LIVE_TRANSFER_PASS = 'Partner Live Transfer Pass';

	//Object Prefix
	public static final String TICKET_PREFIX = Ticket__c.sObjectType.getDescribe().getKeyPrefix();
	public static final String ACCOUNT_PREFIX = Account.sObjectType.getDescribe().getKeyPrefix();
	public static final String CONTACT_PREFIX = Contact.sObjectType.getDescribe().getKeyPrefix();
	public static final String OPPORTUNITY_PREFIX = Opportunity.sObjectType.getDescribe().getKeyPrefix();
	public static final String LEAD_PREFIX = Lead.sObjectType.getDescribe().getKeyPrefix();

	// Event Status
	public final static String STATUS_ATTEMPT = 'Attempt';
	public final static String STATUS_CONNECT = 'Connect';
	public final static String STATUS_SCHEDULED = 'Scheduled';
	public final static String STATUS_CANCELED = 'Canceled';

	public final static Set<String> set_EventClosureStatus = new Set<String>{ 'Canceled', 'Attempt', 'Connect' };

	//User roles
	public static final String USER_ROLE_SALES = 'Sales';
}