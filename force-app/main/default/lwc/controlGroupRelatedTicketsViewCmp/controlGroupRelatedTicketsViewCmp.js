/**
 * @description To view all Tickets related by Company Control group
 * @author  Ajay Krishna P U
 * @date    24/05/2023
 */
import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";

import ID from "@salesforce/schema/Ticket__c.Id";
import NAME from "@salesforce/schema/Ticket__c.Name";
import TICKET_NAME from "@salesforce/schema/Ticket__c.Ticket_Name__c";
import ACCOUNT_ID from "@salesforce/schema/Ticket__c.Account__c";
import ACCOUNT_CONTROL_GROUP from "@salesforce/schema/Ticket__c.Account__r.Control_Group__c";
import OWNER_NAME from "@salesforce/schema/Ticket__c.Owner_Full_Name__c";
import STATUS from "@salesforce/schema/Ticket__c.Status__c";
import TAX_YEAR from "@salesforce/schema/Ticket__c.Tax_Year__c";

import getControlGroupRelatedTickets from "@salesforce/apex/ControlGroupRelatedTicketViewController.getControlGroupRelatedTickets";
import { getQueryFields, transformMultiLevelFieldData, transformMultiLevelFieldColumns, RECORD_VIEW_FIELD_NAME } from "./tableUtil";
const COLUMNS = [
	{
		label: "Action Items Name",
		fieldName: RECORD_VIEW_FIELD_NAME,
		type: "url",
		typeAttributes: {
			label: { fieldName: NAME.fieldApiName },
			tooltip: { fieldName: NAME.fieldApiName }
		},
		list_AdditionalFields: [ID.fieldApiName, NAME.fieldApiName]
	},
	{ label: "Ticket Name", fieldName: TICKET_NAME.fieldApiName },
	{ label: "Owner", fieldName: OWNER_NAME.fieldApiName },
	{ label: "Status", fieldName: STATUS.fieldApiName },
	{ label: "Tax Year", fieldName: TAX_YEAR.fieldApiName }
];
export default class ControlGroupRelatedTicketsViewCmp extends LightningElement {
	@api recordId;
	@api intMaxHeight;
	@api strIconName;
	@api strOrderBy;

	blnIsLoading = true;
	strControlGroup;
	list_Records = [];
	list_Columns = [];
	list_QueryFields;

	get strContainerClass() {
		return this.intMaxHeight && this.list_Records?.length > 0 ? `max-height: ${this.intMaxHeight}px;` : "";
	}

	get blnIsHaveRecords() {
		return this.list_Records?.length > 0;
	}

	get blnIsShowComponent() {
		return !!this.strControlGroup;
	}
	get strHeading() {
		return this.strControlGroup ? `Tickets in Control Group, ${this.strControlGroup}` : "";
	}

	/**
	 * Constructor
	 */
	constructor() {
		super();

		this.list_QueryFields = getQueryFields(COLUMNS);
		this.list_Columns = transformMultiLevelFieldColumns(COLUMNS);
	}

	/**
	 * Wire method to fetch current Ticket details.
	 * mainly used to track changes and refresh component data
	 */
	@wire(getRecord, { recordId: "$recordId", fields: [ACCOUNT_ID, ACCOUNT_CONTROL_GROUP] })
	getTicketRecord({ error, data }) {
		if (error) {
			this.handleError(error);
			this.blnIsLoading = false;
		} else if (data) {
			const strControlGroup = getFieldValue(data, ACCOUNT_CONTROL_GROUP);

			if (strControlGroup) {
				this.strControlGroup = strControlGroup;
				this.blnIsLoading = true;
			} else {
				this.strControlGroup = null;
				this.blnIsLoading = false;
				this.list_Records = [];
			}
		}
	}

	/**
	 * Wire method to fetch Control group related Tickets
	 */
	@wire(getControlGroupRelatedTickets, { idTicket: "$recordId", list_Fields: "$list_QueryFields", strControlGroup: "$strControlGroup", strOrderBy: "$strOrderBy" })
	getControlGroupRelatedTicketsFunc({ error, data }) {
		if (error) {
			this.handleError(error);
			this.blnIsLoading = false;
		} else if (data) {
			this.list_Records = transformMultiLevelFieldData(data, this.list_Columns);
			this.blnIsLoading = false;
		}
	}

	/**
	 * Handle error while server call
	 * @param {Error} error
	 */
	handleError(error) {
		console.error("Something went wrong", error);
	}
}