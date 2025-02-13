public with sharing class UR_ViewCalendarCtrl {
	public String currentRecordId { get; set; }
	public Research_Project_Master__c objProject { get; set; }
	public List<calEvent> events { get; set; }
	map<Id, string> mapPartId = new Map<Id, string>();
	public Note objNote { get; set; }
	public boolean addNote { get; set; }
	public boolean isUpdateLastViewDate { get; set; }

	public boolean isEditable { get; set; }
	public UR_ViewCalendarCtrl(ApexPages.StandardController st) {
		isUpdateLastViewDate = true;
		addNote = false;
		currentRecordId = ApexPages.CurrentPage().getparameters().get('projectId');
		isEditable = UR_UtilityCtrl.IsEditAccess(currentRecordId);
		RetriveProjectRecord();
		//Get Notes of project
		RetriveNotes();
	}

	private PageReference RetriveNotes() {
		objNote = new Note();
		List<Note> lstNote = [
			SELECT Body, Id, ParentId, LastModifiedDate, LastModifiedBy.Name, Title
			FROM Note
			WHERE ParentId = :objProject.Id AND (NOT Title LIKE '%-Result')
			LIMIT 1
		];
		if (lstNote != null && lstNote.size() > 0) {
			objNote = lstNote[0];
		}
		return null;
	}

	public void AddNote() {
		addNote = true;
	}
	public void CancelNote() {
		addNote = false;
		RetriveNotes();
	}
	public void SaveNotes() {
		if (objNote.Id == null) {
			objNote.ParentId = objProject.Id;
			objNote.Title = objProject.Name;
		}
		upsert objNote;
		addNote = false;
		RetriveNotes();
	}

	private PageReference RetriveProjectRecord() {
		try {
			objProject = new Research_Project_Master__c();
			objProject = UR_UtilityCtrl.RetriveProjectDetail(currentRecordId);
			if (objProject.Last_View_Calendar_Date__c == null || objProject.Last_View_Calendar_Date__c < System.today()) {
				isUpdateLastViewDate = true;
			} else {
				isUpdateLastViewDate = false;
			}

			if (objProject.Id == null) {
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, Label.UR_InvalidProjectDetail));
				return null;
			}
			for (Research_Project_Detail__c rpd : objProject.Research_Project_Details__r) {
				mapPartId.put(rpd.Id, rpd.Contact__r.Name + '~' + rpd.Contact__c);
				if (rpd.Contact__c != null) {
					mapPartId.put(rpd.Contact__c, rpd.Company_Name__c);
				}
			}
		} // end of try block
		catch (Exception e) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
			return null;
		}
		return null;
	}
	public PageReference eventdata() {
		events = new List<calEvent>();
		if (mapPartId != null && mapPartId.size() > 0) {
			//Get All project participant
			for (Event evnt : [
				SELECT Id, AccountId, ActivityDate, ActivityDateTime, DurationInMinutes, EndDateTime, StartDateTime, Subject, Type, WhatId, WhoId
				FROM Event
				WHERE UR_Meeting_Cancelled__c = FALSE AND WhatId IN :mapPartId.keySet()
			]) {
				DateTime startDT = evnt.StartDateTime;
				DateTime endDT = evnt.EndDateTime;
				calEvent myEvent = new calEvent();
				myEvent.title = evnt.Subject;
				myEvent.startString = startDT.format();
				myEvent.endString = endDT.format();
				list<string> conDetail = mapPartId.get(evnt.WhatId).split('~');
				myEvent.userName = conDetail[0];
				myEvent.url = 'javascript:';
				myEvent.strId = evnt.Id;
				myEvent.className = 'event-personal';
				events.add(myEvent);
			}
		}
		return null;
	}

	public EventWrapper getobjEventWrapper() {
		String currentEventId = ApexPages.currentPage().getParameters().get('currentEventId');
		EventWrapper objEW = new EventWrapper();
		Event eventTemp = new Event();
		if (currentEventId != null) {
			eventTemp = [
				SELECT Id, Subject, WhatId, EndDateTime, StartDateTime
				FROM Event
				WHERE Id = :currentEventId
			];

			objEW.objEvent = eventTemp;
			list<string> conDetail = mapPartId.get(eventTemp.WhatId).split('~');
			objEW.contactName = conDetail[0];
			objEW.contactId = conDetail[1];
			if (mapPartId.containsKey(objEW.contactId)) {
				objEW.companyName = mapPartId.get(objEW.contactId);
			}
		}
		return objEW;
	}

	public PageReference BackToProjectVF() {
		PageReference pageRef = new PageReference('/apex/UR_ManageProject?Id=' + objProject.Id);
		pageRef.setRedirect(true);
		return pageRef;
	}

	public class EventWrapper {
		public string companyName { get; set; }
		public string contactName { get; set; }
		public string contactId { get; set; }
		public Event objEvent { get; set; }
	}
	public class calEvent {
		public String title { get; set; }
		public Boolean allDay { get; set; }
		public String startString { get; set; }
		public String endString { get; set; }
		public String userName { get; set; }
		public String url { get; set; }
		public String className { get; set; }
		public String strId { get; set; }
	}

	public void updateViewCalendarDate() {
		objProject.Last_View_Calendar_Date__c = System.today();
		UR_ProjectMasterTriggerHelper.skipTrigger = true;
		update objProject;
		UR_ProjectMasterTriggerHelper.skipTrigger = false;
		isUpdateLastViewDate = false;
	}
}