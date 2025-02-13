import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class CustomTypeCaseColumn extends NavigationMixin(LightningElement) {
	@api caseNumber;
	@api escalationIcon;
	@api pniPartialIcon;
	@api caseId;

	navigateToCaseRecordPage() {
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: this.caseId,
				objectApiName: "Case",
				actionName: "view"
			}
		});
	}
}