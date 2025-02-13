global with sharing class ConciergeAccountScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new BatchToUpdateConciergeAccount(), 150);
		PrivacyRequestsUtil.updateCookieKey();
		Database.executeBatch(new CloseOutAbandonedCasesBatch(), 50);
	}
}