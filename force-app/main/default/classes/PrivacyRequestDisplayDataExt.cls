public with sharing class PrivacyRequestDisplayDataExt {
	private ApexPages.StandardController stdCtrl;
	private Case c;
	public String redirectUrl { public get; private set; }
	public Boolean shouldRedirect { public get; private set; }

	public PrivacyRequestDisplayDataExt(ApexPages.StandardController ctrl) {
		this.stdCtrl = ctrl;
		if (!Test.isRunningTest())
			ctrl.addFields(new List<String>{ 'Privacy_Requester_First_Name__c', 'Privacy_Requester_Last_Name__c', 'Privacy_Requester_Data__c' });
		this.c = (Case) ctrl.getRecord();
		shouldRedirect = false;
	}

	public PageReference displayData() {
		List<String> list_DetailsSplitByNewLine = new List<String>();
		redirectUrl = '/console?tsid=' + c.Id;
		shouldRedirect = true;

		List<Data_Collection__c> list_dataCollection = [SELECT Details__c FROM Data_Collection__c WHERE Case__c = :c.Id AND Exclude_From_Disclosure__c = FALSE];
		for (Data_Collection__c dc : list_dataCollection) {
			if (!String.isBlank(dc.Details__c)) {
				list_DetailsSplitByNewLine.addAll(dc.Details__c.split('\n'));
				list_DetailsSplitByNewLine.add(' ');
			}
		}

		c.Privacy_Requester_Data__c = '';
		for (String str_data : list_DetailsSplitByNewLine) {
			c.Privacy_Requester_Data__c += str_data + '<br/>';
		}
		update c;

		return null;
	}
}