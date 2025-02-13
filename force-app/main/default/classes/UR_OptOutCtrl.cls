public class UR_OptOutCtrl {
	public String currentEmailCode { get; set; }
	public String conName { get; set; }
	public String comment { get; set; }
	public List<contact> lstCon;
	public contact conObj;
	public boolean showPanel { get; set; }
	public boolean showMessage { get; set; }
	public UR_OptOutCtrl() {
		conObj = new Contact();
		currentEmailCode = ApexPages.CurrentPage().getparameters().get('optoutcode');
		if (String.isNotBlank(currentEmailCode)) {
			currentEmailCode = currentEmailCode.subString(4, 19);
		}
		showPanel = true;
		showMessage = false;
		init();
	}
	public PageReference init() {
		lstCon = [
			SELECT Id, Email, Name, UXResearch_Opt_Out__c, UXResearch_Email_Code__c
			FROM Contact
			WHERE Id = :currentEmailCode
			LIMIT 1
		];

		if (lstCon != null && lstCon.size() > 0) {
			conObj = lstCon[0];
			conName = conObj.Name;
		} else {
			//ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Invalid Detail '));
			return null;
		}
		return null;
	}
	public PageReference UnsubcribeEmail() {
		if (conObj.Id != null) {
			List<Research_Project_Detail__c> lstRpd = new List<Research_Project_Detail__c>();
			for (Research_Project_Detail__c rpd : [
				SELECT Id
				FROM Research_Project_Detail__c
				WHERE Contact__c = :conObj.Id AND Research_Project_Master__r.Project_Status__c != 'Complete'
			]) {
				rpd.Opt_Out__c = true;
				lstRpd.add(rpd);
			}
			if (lstRpd.size() > 0 && lstRpd != null) {
				update lstRpd;
			}
			Contact ct = new Contact(id = conObj.Id);
			ct.UXResearch_Opt_Out__c = true;
			ct.UXResearch_Optout_Comment__c = comment;
			update ct;
			showPanel = false;
			showMessage = true;
			//ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'You have successfully unsubscribed from mailing list'));
			return null;
		}

		return null;
	}
}