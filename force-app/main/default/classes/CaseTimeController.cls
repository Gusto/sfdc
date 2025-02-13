global with sharing class CaseTimeController {
	public String recordId { get; set; }
	public String duration { get; set; }
	public String comments { get; set; }

	public Decimal cumulativeTime {
		get {
			Case currentCase = [SELECT Id, Cumulative_Time__c FROM Case WHERE Id = :recordId LIMIT 1];
			return currentCase.Cumulative_Time__c;
		}
		set;
	}

	public List<Session_Time__c> sessions {
		get {
			sessions = [SELECT Id, Agent__r.Name, Date__c, Duration__c FROM Session_Time__c WHERE Case__r.Id = :recordId AND Type__c = 'Automatic' ORDER BY Date__c DESC];
			return sessions;
		}
		set;
	}

	public List<Session_Time__c> manualSessions {
		get {
			manualSessions = [SELECT Id, Agent__r.Name, Date__c, Duration__c FROM Session_Time__c WHERE Case__r.Id = :recordId AND Type__c = 'Manual' ORDER BY Date__c DESC];
			return manualSessions;
		}
		set;
	}

	public CaseTimeController(ApexPages.StandardController stdController) {
		recordId = (String) stdController.getRecord().Id;
	}

	@RemoteAction
	global static String recordSession(String caseId, String duration) {
		Session_Time__c session = new Session_Time__c();
		session.Case__c = caseId;
		session.Date__c = System.now();
		session.Duration__c = Integer.valueOf(duration);
		session.Agent__c = UserINFO.getUserId();
		session.Type__c = 'Automatic';
		insert session;
		return session.Id;
	}

	public PageReference recordManualSession() {
		Session_Time__c session = new Session_Time__c();
		session.Case__c = recordId;
		session.Date__c = System.now();
		session.Duration__c = Integer.valueOf(duration);
		session.Agent__c = UserINFO.getUserId();
		session.Type__c = 'Manual';
		session.Comments__c = comments;
		insert session;
		return null;
	}
}