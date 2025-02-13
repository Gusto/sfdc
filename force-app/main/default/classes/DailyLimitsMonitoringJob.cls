/**
 * @name         DailyLimitsMonitoringJob
 * @author       Sanjay Paryani
 * @date         03-30-2020
 * @author       David Schach
 * @updated      11-16-2021
 * @description
 * @testClasses	DailyLimitsMonitoringTest
 **/
public class DailyLimitsMonitoringJob implements Schedulable {
	public static final String DAILY_ASYNC_API_THRESHOLD = 'DailyAsyncApexExecutions_Threshold';
	public static final String DAILY_API_REQUESTS_THRESHOLD = 'DailyAPIRequests_Threshold';
	public static final String DAILY_BULK_API_THRESHOLD = 'DailyBulkApiBatches_Threshold';
	public static final String DAILY_ASYNC_APEX_EXECUTIONS = 'DailyAsyncApexExecutions';
	public static final String DAILY_API_REQUESTS = 'DailyApiRequests';
	public static final String DAILY_BULK_API_BATCHES = 'DailyBulkApiBatches';
	public static final String API_HEROKU = 'API Heroku';
	public static final String BODY_FOOTER_1 = '\n\r Please get in touch with the Developer team to temporarily turn off any async jobs.';
	public static final String BODY_FOOTER_2 = '\n\r Link to Salesforce Limits Manager:' + OrganizationUtilities.getBaseURL() + '/apex/DailyLimitsMonitoringPage';

	public static final String STR_TO_ADDRESSES = System.Label.Daily_Limit_Notification_Email_List;

	public void execute(SchedulableContext SC) {
		// Call method to get all limits for our org and sends an email if the async limits have exceeded the set threshold value.

		String strEmailSubject = ''; 
		String strEmailBody = '';
		Decimal decAsyncApexThreshold;
		Decimal decApiRequestThreshold;
		Decimal decBulkApiBatchesThreshold;

		Map<String, OrgConfig__mdt> map_OrgConfig = OrgConfig__mdt.getAll();
		Map<String, System.OrgLimit> map_limitsMap = OrgLimits.getMap();

		// Calling method to check if async limits has exceeded the set threshold
		// and sends an email to all addresses mentioned in the configuration setting Daily_Limit_Notification_Email_List__c.

		if (map_OrgConfig.containsKey(DAILY_ASYNC_API_THRESHOLD) && map_OrgConfig.get(DAILY_ASYNC_API_THRESHOLD) != null) {
			decAsyncApexThreshold = map_OrgConfig.get(DAILY_ASYNC_API_THRESHOLD).PercentValue__c;
			System.OrgLimit objAsyncOrgLimit = map_limitsMap.get(DAILY_ASYNC_APEX_EXECUTIONS);
			if (isThresholdExceeded(objAsyncOrgLimit.getValue(), objAsyncOrgLimit.getLimit(), decAsyncApexThreshold)) {
				strEmailSubject = 'Daily Async Limit has exceeded the threshold limit';
				strEmailBody = 'Daily Async Limit has exceeded the given threshold limit of: ' + decAsyncApexThreshold + '% of capacity';
				strEmailBody += BODY_FOOTER_1 + BODY_FOOTER_2;
				Utils.sendEmail(STR_TO_ADDRESSES, API_HEROKU, strEmailSubject, strEmailBody);
			}
		}

		if (map_OrgConfig.containsKey(DAILY_API_REQUESTS_THRESHOLD) && map_OrgConfig.get(DAILY_API_REQUESTS_THRESHOLD) != null) {
			decApiRequestThreshold = map_OrgConfig.get(DAILY_API_REQUESTS_THRESHOLD).PercentValue__c;
			System.OrgLimit objApiReqOrgLimit = map_limitsMap.get(DAILY_API_REQUESTS);
			if (isThresholdExceeded(objApiReqOrgLimit.getValue(), objApiReqOrgLimit.getLimit(), decApiRequestThreshold)) {
				strEmailSubject = 'Daily API Requests Limit has exceeded the threshold limit';
				strEmailBody = 'Daily API Requests Limit has exceeded the given threshold limit of: ' + decApiRequestThreshold + '% of capacity';
				strEmailBody += BODY_FOOTER_1 + BODY_FOOTER_2;
				Utils.sendEmail(STR_TO_ADDRESSES, API_HEROKU, strEmailSubject, strEmailBody);
			}
		}

		if (map_OrgConfig.containsKey(DAILY_BULK_API_THRESHOLD) && map_OrgConfig.get(DAILY_BULK_API_THRESHOLD) != null) {
			decBulkApiBatchesThreshold = map_OrgConfig.get(DAILY_BULK_API_THRESHOLD).PercentValue__c;
			System.OrgLimit objBulkApiOrgLimit = map_limitsMap.get(DAILY_BULK_API_BATCHES);
			if (isThresholdExceeded(objBulkApiOrgLimit.getValue(), objBulkApiOrgLimit.getLimit(), decBulkApiBatchesThreshold)) {
				strEmailSubject = 'Daily Bulk API Requests Limit has exceeded the threshold limit';
				strEmailBody = 'Daily Bulk API Requests Limit has exceeded the given threshold limit of: ' + decBulkApiBatchesThreshold + '% of capacity';
				strEmailBody += BODY_FOOTER_1 + BODY_FOOTER_2;
				Utils.sendEmail(STR_TO_ADDRESSES, API_HEROKU, strEmailSubject, strEmailBody);
			}
		}
	}
	// this method will check if the daily threshold limits has been exceeded or not
	private Boolean isThresholdExceeded(Decimal decConsumedVal, Decimal decTotalDailyLimit, Decimal decDailyThreshold) {
		if (Test.isRunningTest()) {
			return true;
		} else {
			return ((decConsumedVal / decTotalDailyLimit) >= decDailyThreshold);
		}
	}
}