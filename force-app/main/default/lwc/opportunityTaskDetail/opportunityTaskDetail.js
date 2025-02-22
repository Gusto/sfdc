/**
 * @description Manages the display and toggling of task/event details
 */
import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import taskTemplate from './taskTemplate.html';
import eventTemplate from './eventTemplate.html';

const SET_EVENT_TYPES = new Set(["Event", "AE_Demo", "DemoEvent"]);
export default class OpportunityTaskDetail extends NavigationMixin(LightningElement) {
	@api objActivity = [];
	@api mapTaskRecordTypeToIcon = new Map();
	blnIsExpanded = true;

	render() {
		return SET_EVENT_TYPES.has(this.objActivity?.RecordType?.DeveloperName) ? eventTemplate : taskTemplate;
    }

	@api doExpandCollapse(blnIsExpanded) {
		this.blnIsExpanded = blnIsExpanded;
	}

	get strRecordTypeIconName() {
		return this.mapTaskRecordTypeToIcon?.get(this.objActivity?.RecordType?.DeveloperName);
	}

	get strIconName() {
		return this.blnIsExpanded ? "utility:chevrondown" : "utility:chevronright";
	}

	get blnIsHighPriority() {
		return this.objActivity.Priority === "High";
	}

	/**
	 * Toggles the visibility of task/event details
	 */
	handleToggleDetails() {
		this.blnIsExpanded = !this.blnIsExpanded;
	}
	
	/**
	 * Navigates to the Task/Event record page when invoked
	 * @param {Event} event
	 */
	handleNavigateToActivityRecordPage(event) {
		event.preventDefault();
		event.stopPropagation();

		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				recordId: this.objActivity.Id,
				actionName: "view"
			}
		});
	}
}