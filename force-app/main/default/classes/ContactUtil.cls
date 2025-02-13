public class ContactUtil {
	// All Record Type Final Strings
	public final static String COMPANY_RT_NAME = 'Company';
	public final static String RESELLER_RT_NAME = 'Reseller';
	public final static String EMBEDDED_COMPANY_RT_NAME = 'Embedded Company';

	public final static Id COMPANY_CONTACT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Contact', COMPANY_RT_NAME);
	public final static Id RESELLER_CONTACT_RT_ID = RecordTypes.getRecordTypeIdFromDeveloperName('Contact', RESELLER_RT_NAME);
	public final static Id EMBEDDED_COMPANY_CONTACT_RT_ID = RecordTypes.getRecordTypeIdFromName('Contact', EMBEDDED_COMPANY_RT_NAME);
	
	public final static String PHONE_PREFIX = '+1';

	public static final String CAMPAIGN_TYPE_WEBINAR = 'Webinar';
	public static final String CAMPAIGN_TYPE_EVENT = 'Event';
	public static final String CAMPAIGN_TYPE_GATED_CONTENT = 'Gated Content';
	public static final String CAMPAIGN_TYPE_3RD_PARTY_WEBINAR = '3rd Party Webinar';
	public static final String CAMPAIGN_TYPE_TRAINING = 'Training';
	public static final String CAMPAIGN_TYPE_WEBSITE = 'Website';
	public static final String CAMPAIGN_TYPE_SUBSCRIPTION = 'Subscription';

	public static final Set<String> set_RecentSourceCampaignTypes = new Set<String>{
		CAMPAIGN_TYPE_WEBINAR,
		CAMPAIGN_TYPE_EVENT,
		CAMPAIGN_TYPE_GATED_CONTENT,
		CAMPAIGN_TYPE_3RD_PARTY_WEBINAR,
		CAMPAIGN_TYPE_TRAINING,
		CAMPAIGN_TYPE_WEBSITE,
		CAMPAIGN_TYPE_SUBSCRIPTION
	};
	//Intellum Enrollments static values
	public final static String LT_PAYROLL_ESSENTIAL = 'Payroll Essentials';
	public final static String LT_PEOPLE_ADVISORY = 'People Advisory';
	public final static String LT_PRACTICE_MANAGEMENT = 'Practice Management';
	public final static String PROGRAM_TYPE_CERTIFICATION = 'Certification';

	public static Map<String, Integer> map_Status = new Map<String, Integer>{
		'' => 0,
		'no-show' => 1,
		'incomplete' => 2,
		'dropped' => 3,
		'in-progress' => 4,
		'failed' => 5,
		'assessment-completed' => 6,
		'passed' => 6
	};
}