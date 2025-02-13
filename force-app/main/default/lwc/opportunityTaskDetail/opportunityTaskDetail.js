/**
 * @description Manages the display and toggling of task details
 */
import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class OpportunityTaskDetail extends NavigationMixin(LightningElement) {
	@api objTask = [];
	@api mapTaskRecordTypeToIcon = new Map();
	blnIsExpanded = true;

	@api doExpandCollapse(blnIsExpanded) {
		this.blnIsExpanded = blnIsExpanded;
	}

	get strRecordTypeIconName() {
		return this.mapTaskRecordTypeToIcon?.get(this.objTask?.RecordType?.DeveloperName);
	}

	get strIconName() {
		return this.blnIsExpanded ? "utility:chevrondown" : "utility:chevronright";
	}

	get blnIsHighPriority() {
		return this.objTask.Priority === "High";
	}

	/**
	 * Toggles the visibility of task details
	 */
	handleToggleDetails() {
		this.blnIsExpanded = !this.blnIsExpanded;
	}

	/**
	 * Navigates to the Task record page when invoked
	 * @param {Event} event
	 */
	handleNavigateToTaskRecordPage(event) {
		event.preventDefault();
		event.stopPropagation();

		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: this.objTask.Id,
				actionName: "view"
			}
		});
	}
}