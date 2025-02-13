import { LightningElement, api, track } from "lwc";
import getCategories from "@salesforce/apex/NBACategoryAlignment.getServedCategories";

export default class NbaCategoryAlignmentCmp extends LightningElement {
	// list of all variables
	@api recordId;
	@track blnSpinner = false;
	@track list_rules = [];
	@track strWarningMessage = "";
	@track blnShowWarning = false;
	@track blnOpportunity = false;
	@track list_PrimaryRuleSets = [];
	@track list_SecondaryRuleSets = [];
	@track blnPrimaryAvailable = false;
	@track blnSecondaryAvailable = false;
	@api title;


	get titleLabel() {
		return (this.title) ? this.title : 'NBA Talking Points';
	}

	// on load - get list of primary and secondary category rules
	connectedCallback() {
		this.blnSpinner = true;
		this.blnOpportunity = this.recordId.startsWith("006");
		getCategories({
			recordId: this.recordId
		})
			.then((result) => {
				if (result.blnSuccess) {
					this.list_rules = result.list_RuleSets;
					for (let rule of this.list_rules) {
						// find primary category based on hashtag that was set in Apex Contoller
						if (rule.Rule_Name__c && rule.Rule_Name__c.includes("#Primary")) {
							rule.Rule_Name__c = rule.Rule_Name__c.replace("#Primary", "");
							this.list_PrimaryRuleSets.push(rule);
						} else {
							// if no primary hashtag found, rest all are secondary
							this.list_SecondaryRuleSets.push(rule);
						}
						rule.Talking_Points__c = result.map_TalkingPoints[rule.Id];
					}
					// set flag to show/hide primary category section
					if (this.list_PrimaryRuleSets.length > 0) {
						this.blnPrimaryAvailable = true;
					}

					// set flag to show/hide secondary category section
					if (this.list_SecondaryRuleSets.length > 0) {
						this.blnSecondaryAvailable = true;
					}

					// if no rule sets, show warning message
					if (result.list_RuleSets.length == 0) {
						this.strWarningMessage = "No talking points for this record.";
						this.blnShowWarning = true;
					}
				} else {
					// if exception found, show error message
					this.strWarningMessage = "Unable to load talking points. Reason: " + result.strMessage;
					this.blnShowWarning = true;
				}
				this.blnSpinner = false;
			})
			.catch((error) => {
				// if javascript error, show error message
				this.error = error;
				console.log("error", error);
				this.blnSpinner = false;
				this.strWarningMessage = error?.body?.message;
				this.blnShowWarning = true;
			});
	}
}