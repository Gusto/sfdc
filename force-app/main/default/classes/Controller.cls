public class Controller {
	private ApexPages.StandardController sc;
	public Opportunity opportunity { get; set; }
	private Id accId;
	private static Map<String, String> recordTypeNameIdMap = new Map<String, String>();
	public reasonDescDetail selectedReasonDetail { get; set; }
	Map<String, reasonDescDetail> reasonDetailMap = new Map<String, reasonDescDetail>();
	Boolean saveandFeedback = false;
	Boolean insertAndFeedback = false;

	public Controller(ApexPages.StandardSetController standardSetController) {
		accId = ApexPages.currentPage().getParameters().get('Id');
		setOpportunity(new Opportunity());
		sc = new ApexPages.StandardController(opportunity);
		setOpportunityRecordTypeMap();
		populateReasonDescription();
	}

	public Controller(ApexPages.StandardController standardController) {
		sc = standardController;
		opportunity = (Opportunity) sc.getRecord();
		if (opportunity.id != null) {
			opportunity = [
				SELECT
					Id,
					recordTypeId,
					NumberofEmployees__c,
					amount,
					Opp_Payment_Plan__c,
					Close_Lost_EE_size__c,
					Close_Lost_Amount__c,
					Close_Lost_Payment_Plan__c,
					Name,
					AccountId,
					stagename,
					Stage_Detail__c,
					Stage_Detail_2__c,
					Closed_Details__c,
					Competitor__c,
					Additional_Reasons_Lost__c
				FROM Opportunity
				WHERE id = :opportunity.id
			];
		}

		accId = opportunity.AccountId;
		populateReasonDescription();
	}

	public Opportunity getOpportunity() {
		return opportunity;
	}

	public void setOpportunity(Opportunity opportunity) {
		this.Opportunity = (Opportunity) Schema.Opportunity.SObjectType.newSObject();
	}

	public void setClosedLost() {
		opportunity.AccountId = accId;
		opportunity.StageName = System.Label.OpportunityStage_ClosedLost;
		opportunity.CloseDate = System.today();

		String pageName = ApexPages.CurrentPage().getUrl();
		String strPageNameLow = pageName != null && String.isNotBlank(pageName) ? pageName.toLowerCase() : null;
		if (strPageNameLow != null && strPageNameLow.indexof('closedlostopportunity') > -1) {
			opportunity.Name = getOpportunityName();
			List<User> usrList = [SELECT Id, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
			if (usrList.size() > 0 && usrList.get(0).UserRole.Name != null && (usrList.get(0).UserRole.Name.equalsIgnoreCase('sales_mm_fs_xx'))) {
				opportunity.RecordTypeId = recordTypeNameIdMap.get('Benefits BoR');
			} else if (
				usrList.size() > 0 &&
				usrList.get(0).UserRole.Name != null &&
				(usrList.get(0).UserRole.Name.equalsIgnoreCase('sales_mm_np_xx') ||
				usrList.get(0).UserRole.Name.equalsIgnoreCase('sales_mm_np_xx_mgr') ||
				usrList.get(0).UserRole.Name.equalsIgnoreCase('sales_mm_fs_xx_mgr'))
			) {
				opportunity.RecordTypeId = recordTypeNameIdMap.get('Benefits New Plan');
			}
		}
	}

	public PageReference insertOpportunity() {
		try {
			oppValidation();
			if (apexPages.hasMessages()) {
				return null;
			}
			Database.SaveResult result = Database.insert(opportunity);
			if (!result.isSuccess()) {
				return null;
			} else if (!insertAndFeedback) {
				return getObjectPage();
			}
		} catch (Exception ex) {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, ex.getmessage().substring(ex.getmessage().indexof('_EXCEPTION,') + 12, ex.getmessage().lastIndexOf(':'))));
			return null;
		}
		return null;
	}

	private String getOpportunityName() {
		return [SELECT Name FROM Account WHERE Id = :accId LIMIT 1][0].Name;
	}

	public PageReference getObjectPage() {
		PageReference pageRef = new PageReference('/' + accId);
		pageRef.setRedirect(true);
		return pageRef;
	}

	private void setOpportunityRecordTypeMap() {
		recordTypeNameIdMap = new Map<String, String>();
		for (RecordType recType : [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SobjectType = 'Opportunity']) {
			recordTypeNameIdMap.put(recType.Name, recType.id);
		}
	}

	public pageReference updateOpportunity() {
		try {
			oppValidation();
			if (apexPages.hasMessages()) {
				return null;
			}
			update Opportunity;
		} catch (exception ex) {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.error, ex.getMessage()));
			return null;
		}
		if (saveandFeedback) {
			return null;
		}
		return new pageReference('/' + opportunity.Id);
	}

	public void oppValidation() {
		if (selectedReasonDetail != null && selectedReasonDetail.showCloseDetail == true && string.isblank(Opportunity.Closed_Details__c)) {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Closed Details: field required.'));
		}

		if (Opportunity.Competitor__c == null) {
			apexPages.addMessage(new apexPages.Message(apexPages.severity.error, 'Competitor: field required.'));
		}

		if (apexPages.hasMessages()) {
			return;
		}

		if (opportunity.StageName == 'Closed Lost') {
			if (cache.getRecordTypeId('Opportunity', 'Company Opportunity') == opportunity.RecordTypeId) {
				opportunity.Close_Lost_EE_size__c = opportunity.NumberofEmployees__c;
				opportunity.Close_Lost_Payment_Plan__c = opportunity.Opp_Payment_Plan__c;
				opportunity.Close_Lost_Amount__c = opportunity.Amount;
			} else if (cache.getRecordTypeId('Opportunity', 'Benefits New Plan') == opportunity.RecordTypeId) {
				opportunity.Close_Lost_EE_size__c = opportunity.NumberofEmployees__c;
				opportunity.Close_Lost_Amount__c = opportunity.Amount;
			} else if (cache.getRecordTypeId('Opportunity', 'Benefits BoR') == opportunity.RecordTypeId) {
				opportunity.Close_Lost_EE_size__c = opportunity.NumberofEmployees__c;
				opportunity.Close_Lost_Amount__c = opportunity.Amount;
			}
		}
	}

	public void getReasonDetails() {
		if (reasonDetailMap != null && Opportunity.Stage_Detail_2__c != null && reasonDetailMap.containsKey(Opportunity.Stage_Detail_2__c)) {
			selectedReasonDetail = reasonDetailMap.get(Opportunity.Stage_Detail_2__c);
		} else {
			selectedReasonDetail = new reasonDescDetail('', false);
		}

		if (Opportunity.Stage_Detail__c != null && reasonDetailMap.containsKey(Opportunity.Stage_Detail__c)) {
			selectedReasonDetail = reasonDetailMap.get(Opportunity.Stage_Detail__c);
		}

		if (Opportunity.Competitor__c != null && (Opportunity.Competitor__c == 'Other' || Opportunity.Competitor__c == 'Tech Broker' || Opportunity.Competitor__c == 'Other Competitor')) {
			selectedReasonDetail.showCloseDetail = true;
		}
	}

	public pagereference insertOppOpenFeedback() {
		insertAndFeedback = true;
		insertOpportunity();
		insertAndFeedback = false;
		if (apexPages.hasMessages()) {
			return null;
		}
		pagereference pf = new pagereference('/apex/CustomerFeedbackPage?OppId=' + opportunity.Id + '&accId=' + opportunity.AccountId);

		pf.setRedirect(true);
		return pf;
	}

	public pagereference openFeedback() {
		saveandFeedback = true;
		updateOpportunity();
		saveandFeedback = false;
		if (apexPages.hasMessages()) {
			return null;
		}
		pagereference pf = new pagereference('/apex/CustomerFeedbackPage?OppId=' + opportunity.Id + '&accId=' + opportunity.AccountId);

		pf.setRedirect(true);
		return pf;
	}

	public void populateReasonDescription() {
		selectedReasonDetail = new reasonDescDetail('', false);
		for (Opp_Cosed_Lost_Description__c rec : Opp_Cosed_Lost_Description__c.getall().values()) {
			reasonDetailMap.put(rec.Stage_Name_Value__c, new reasonDescDetail(rec.Description__c, rec.Show_Closed_Detail__c));
		}
		if (Opportunity.Stage_Detail_2__c != null) {
			selectedReasonDetail = reasonDetailMap.get(Opportunity.Stage_Detail_2__c);
		}
		if (Opportunity.Stage_Detail__c != null && reasonDetailMap.containsKey(Opportunity.Stage_Detail__c)) {
			selectedReasonDetail = reasonDetailMap.get(Opportunity.Stage_Detail__c);
		}
	}

	public class reasonDescDetail {
		public String descriptionStr { get; set; }
		public Boolean showCloseDetail { get; set; }

		public reasonDescDetail(String dscStr, Boolean scd) {
			descriptionStr = dscStr;
			showCloseDetail = scd;
		}
	}
}