/**
 * Description     :   On Benefit order,for creating/updating transition to fulfillment records based on record types-
 *                     Submission New Plan,Submission Renewal/Change,Care New Plan,Care Renewal/Change with respective page layout
 *                     Buttons:Transition to Submission, transition to Care.
 *
 * Visualforce page:   NPRU_CreateTransitionToSubmission,NPRU_CreateTransitionToCare
 * Created By      :   Syam Nukilla
 *
 * Created Date    :   06/03/2019
 **/

public class CreateTransitionToSubmissionExt {
	public String currentRecordId;
	public Transition_to_Fulfillment__c ttfObj;
	public Benefit_Order__c boObj;
	public List<Transition_to_Fulfillment__c> lstTtfRec;
	public String contRoleName;
	public String contRoleId;
	public string accname;
	public string accid;
	public id newrecordtypeid;
	public id renewalrecordtypeid;
	public String urlStr;
	public OpportunityContactRole oppConRole;
	public List<Transition_to_Fulfillment__c> ttfRecCon;
	public id benfitnewrectypeid;
	public id fullfillrecordtypeid;
	public String contactId;
	public String ContactName;
	public CreateTransitionToSubmissionExt(ApexPages.StandardController standardController) {
		lstTtfRec = new List<Transition_to_Fulfillment__c>();
		ttfObj = new Transition_to_Fulfillment__c();
		currentRecordId = ApexPages.CurrentPage().getparameters().get('id');
		urlStr = null;
		benfitnewrectypeid = cache.getRecordTypeId('Benefit_Order__c', 'New Plan');
	}
	// transition to Submision
	public PageReference initSubmission() {
		newrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission New Plan');
		renewalrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Submission Renewal/Change');
		lstTtfRec = [
			SELECT id, name, Opportunity__c, Benefit_Order__c
			FROM Transition_to_Fulfillment__c
			WHERE Benefit_Order__c = :currentRecordId AND (recordtypeid = :newrecordtypeid OR recordtypeid = :renewalrecordtypeid)
		];
		List<Benefit_Order__c> boList = [
			SELECT id, name, Opportunity__c, Opportunity__r.name, Opportunity__r.Account.id, Opportunity__r.Account.name, recordtypeid
			FROM Benefit_Order__c
			WHERE id = :currentRecordId
			LIMIT 1
		];
		oppConRole = new OpportunityContactRole();
		if (boList != null) {
			boObj = boList[0];
			ttfRecCon = [SELECT Id, Contact__r.id, Contact__r.name FROM Transition_to_Fulfillment__c WHERE Opportunity__c = :boObj.Opportunity__c];
			if (ttfRecCon.size() > 0 && ttfRecCon != null) {
				ContactName = ttfRecCon[0].Contact__r.name;
				ContactId = ttfRecCon[0].Contact__r.id;
			}
			if (boObj.Opportunity__r.Account.id != null) {
				accname = boObj.Opportunity__r.Account.name;
				accid = boObj.Opportunity__r.Account.id;
			} else {
				accname = '';
				accid = '';
			}
			if (boObj.recordtypeid == benfitnewrectypeid) {
				fullfillrecordtypeid = newrecordtypeid;
			} else {
				fullfillrecordtypeid = renewalrecordtypeid;
			}
		}
		if (lstTtfRec.size() == 0) {
			urlStr =
				'/' +
				Transition_to_Fulfillment__c.sobjectType.getDescribe().getkeyPrefix() +
				'/e?retURL=%2F' +
				boObj.id +
				'&RecordType=' +
				fullfillrecordtypeid +
				'&ent=Transition_to_Fulfillment__c&CF00N1M00000FE19l=' +
				boObj.name +
				'&CF00N1600000FDl7b=' +
				boObj.Opportunity__r.Name +
				'&CF00N1600000FDl7b_lkid=' +
				boObj.Opportunity__c +
				'&CF00N1600000FDl7J=' +
				accname +
				'&CF00N1600000FDl7J_lkid=' +
				accid +
				'&CF00N3D000004jtw5_lkid=' +
				ContactId +
				'&CF00N3D000004jtw5=' +
				ContactName +
				'&nooverride=1';
		} else {
			urlStr = '/' + lstTtfRec[0].id + '/e?retURL=%2F' + boObj.id + '&RecordType=' + fullfillrecordtypeid + '&ent=Transition_to_Fulfillment__c&nooverride=1';
		}
		PageReference pg = new PageReference(urlStr);
		pg.setRedirect(true);
		return pg;
	}
	// end of transition to submission

	// create transition to Care
	public PageReference initCare() {
		newrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Care New Plan');
		renewalrecordtypeid = cache.getRecordTypeId('Transition_to_Fulfillment__c', 'Care Renewal/Change');
		lstTtfRec = [
			SELECT id, name, Opportunity__c, Benefit_Order__c, RecordTypeId
			FROM Transition_to_Fulfillment__c
			WHERE Benefit_Order__c = :currentRecordId AND (recordtypeid = :newrecordtypeid OR recordtypeid = :renewalrecordtypeid)
		];

		List<Benefit_Order__c> boList = [
			SELECT id, name, Opportunity__c, Opportunity__r.name, Opportunity__r.Account.id, Opportunity__r.Account.name, recordtypeid
			FROM Benefit_Order__c
			WHERE id = :currentRecordId
			LIMIT 1
		];
		oppConRole = new OpportunityContactRole();
		if (boList != null) {
			boObj = boList[0];
			ttfRecCon = [SELECT Id, Contact__r.id, Contact__r.name FROM Transition_to_Fulfillment__c WHERE Opportunity__c = :boObj.Opportunity__c];
			if (ttfRecCon.size() > 0 && ttfRecCon != null) {
				ContactName = ttfRecCon[0].Contact__r.name;
				ContactId = ttfRecCon[0].Contact__r.id;
			}
			if (boObj.Opportunity__r.Account.id != null) {
				accname = boObj.Opportunity__r.Account.name;
				accid = boObj.Opportunity__r.Account.id;
			} else {
				accname = '';
				accid = '';
			}
			if (boObj.recordtypeid == benfitnewrectypeid) {
				fullfillrecordtypeid = newrecordtypeid;
			} else {
				fullfillrecordtypeid = renewalrecordtypeid;
			}
		}
		if (lstTtfRec.size() == 0) {
			urlStr =
				'/' +
				Transition_to_Fulfillment__c.sobjectType.getDescribe().getkeyPrefix() +
				'/e?retURL=%2F' +
				boObj.id +
				'&RecordType=' +
				fullfillrecordtypeid +
				'&ent=Transition_to_Fulfillment__c&CF00N1M00000FE19l=' +
				boObj.name +
				'&CF00N1600000FDl7b=' +
				boObj.Opportunity__r.Name +
				'&CF00N1600000FDl7b_lkid=' +
				boObj.Opportunity__c +
				'&CF00N1600000FDl7J=' +
				accname +
				'&CF00N1600000FDl7J_lkid=' +
				accid +
				'&CF00N3D000004jtw5_lkid=' +
				ContactId +
				'&CF00N3D000004jtw5=' +
				ContactName +
				'&nooverride=1';
		} else {
			urlStr = '/' + lstTtfRec[0].id + '/e?retURL=%2F' + boObj.id + '&RecordType=' + fullfillrecordtypeid + '&ent=Transition_to_Fulfillment__c&nooverride=1';
		}
		PageReference pg = new PageReference(urlStr);
		pg.setRedirect(true);
		return pg;
	}
}