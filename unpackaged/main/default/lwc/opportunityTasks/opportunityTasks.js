/**
 *  @description Handles the fetching, display, and control (expand/collapse) of opportunity tasks related to a specific Ticket__c record
 */
import { LightningElement, wire, api } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getOpportunityTasks from "@salesforce/apex/OpportunityTaskController.getOpportunityTasks";

export default class OpportunityTasks extends LightningElement {
	@api recordId;
	@api strTaskRecordTypes;
	@api strTaskRecordTypeToIconName;
	listTasks = [];
	objWiredTasksResult;
	mapTaskRecordTypeToIcon = new Map();

	/**
	 * Wire method to fetch tasks related to opportunity
	 */
	@wire(getOpportunityTasks, { idTicket: "$recordId", strTaskRecordTypeDevNames: "$strTaskRecordTypes" })
	wiredTasks(result) {
		this.objWiredTasksResult = result;
		if (result.data) {
			this.listTasks = result.data;
		} else if (result.error) {
			console.error("Error: ", result.error);
		}
	}

	/**
	 * Initializes the map by calling the generateTaskRecordTypeToIconNameMap method
	 */
	connectedCallback() {
		this.generateTaskRecordTypeToIconNameMap();
	}

	/**
	 * This function splits a string of record types and icon names,
	 * mapping each record type to its corresponding icon in a Map object
	 */
	generateTaskRecordTypeToIconNameMap() {
		if (this.strTaskRecordTypeToIconName) {
			let listRecordTypeIcons = this.strTaskRecordTypeToIconName.split(",");
			listRecordTypeIcons.forEach((objRecordTypeIcon) => {
				let [key, value] = objRecordTypeIcon.split(";");
				if (key && value) {
					this.mapTaskRecordTypeToIcon.set(key.trim(), value.trim());
				}
			});
		}
	}

	/**
	 * Refreshes the data coming from wire method
	 */
	handleRefresh() {
		refreshApex(this.objWiredTasksResult);
	}

	/**
	 * Handles the expansion of all child task components
	 * by calling the doExpandOrCollapse method with true as an argument
	 */
	handleExpandAll() {
		this.doExpandOrCollapse(true);
	}

	/**
	 * Handles the collapse of all child task components
	 * by calling the doExpandOrCollapse method with false as an argument
	 */
	handleCollapseAll() {
		this.doExpandOrCollapse(false);
	}

	/**
	 * Handles the expansion or collapse of child task components based
	 * on boolean value provided
	 * @param {Boolean} blnIsExpanded
	 */
	doExpandOrCollapse(blnIsExpanded) {
		let listTasks = this.template.querySelectorAll("c-opportunity-task-detail");
		listTasks.forEach((objTask) => {
			objTask.doExpandCollapse(blnIsExpanded);
		});
	}
}