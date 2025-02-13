/*
    Name : UpateOpportunityToClosedWonController    
    Date : Nov 09, 2017
    By : PR
    Description : 
*/
public class UpateOpportunityToClosedWonController {
	public Opportunity opportunityRec { get; set; }

	//constructor
	public UpateOpportunityToClosedWonController(ApexPages.StandardController sc) {
		opportunityRec = new Opportunity();
		queryOpportunityRecord();
	}
	public static void updateOpportunity() {
		string opportunityId = apexPages.currentPage().getParameters().get('id');
		updateOpportunityInfo(opportunityId);
	}

	@future
	public static void updateOpportunityInfo(String opportunityId) {
		if (opportunityId != null && opportunityId.length() > 0) {
			opportunity oppRec = new Opportunity(id = opportunityId, StageName = 'Closed Won');
			try {
				update oppRec;
			} catch (exception ex) {
				apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, ex.getMessage()));
			}
		}
	}

	// using method to get the update opportunity details.
	public void queryOpportunityRecord() {
		string opportunityId = apexPages.currentPage().getParameters().get('id');
		if (opportunityId != null && opportunityId.length() > 0) {
			list<Opportunity> oppList = [SELECT id, Name, StageName FROM Opportunity WHERE id = :opportunityId LIMIT 1];

			if (oppList.size() > 0) {
				opportunityRec = oppList.get(0);
			}
		} else {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, 'Not able to query the Opportunity record. Page not loaded properly.'));
		}
	}

	// mehtod used to redirect user back to opportunity record.
	public pagereference backToOpportunity() {
		if (opportunityRec != null && opportunityRec.id != null) {
			return new pageReference('/' + opportunityRec.id);
		} else {
			apexPages.addMessage(new apexPages.Message(apexPages.Severity.Error, 'Not able to redirect the user back to the Opportunity record. Page not loaded properly.'));
		}

		return null;
	}
}