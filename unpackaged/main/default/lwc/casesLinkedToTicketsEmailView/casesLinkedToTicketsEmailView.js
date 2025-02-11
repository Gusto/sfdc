/**
 * @description To view all Tickets related by Company Control group
 * @author  Ajay Krishna P U
 * @date    24/05/2023
 */
import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import ID from "@salesforce/schema/Case.Id";
import CASE_NAME from "@salesforce/schema/Case.CaseNumber";
import STATUS from "@salesforce/schema/Case.Status";
import CREATED_DATE from "@salesforce/schema/Case.CreatedDate";
import CASE_OWNER from "@salesforce/schema/Case.Case_Owner_Name__c";
import TIME_ZONE from "@salesforce/i18n/timeZone";

import getCasesLinkedToEmail from "@salesforce/apex/ControlGroupRelatedTicketViewController.getCasesLinkedToEmail";
import { getQueryFields, transformMultiLevelFieldData, transformMultiLevelFieldColumns, RECORD_VIEW_FIELD_NAME } from "./TableUtil";
const COLUMNS = [
	{
		label: "Case Number",
		fieldName: RECORD_VIEW_FIELD_NAME,
		type: "url",
		typeAttributes: {
			label: { fieldName: CASE_NAME.fieldApiName },
			tooltip: { fieldName: CASE_NAME.fieldApiName }
		},
		list_AdditionalFields: [ID.fieldApiName, CASE_NAME.fieldApiName]
	},
	{ label: "Status", fieldName: STATUS.fieldApiName },
	{ label: "Created Date", fieldName: CREATED_DATE.fieldApiName },
	{ label: "Case Owner", fieldName: CASE_OWNER.fieldApiName }
];

export default class CasesLinkedToTicketsEmailView extends LightningElement {
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

	get blnIsShowComponent() {
		return this.list_Records?.length > 0;
	}
	get strHeading() {
		return "Linked Cases";
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
	 * Wire method to fetch Control group related Tickets
	 */
	@wire(getCasesLinkedToEmail, { idTicket: "$recordId", list_Fields: "$list_QueryFields", strOrderBy: "$strOrderBy" })
	getCasesLinkedToEmailFunc({ error, data }) {
		if (error) {
			this.handleError(error);
			this.blnIsLoading = false;
		} else if (data) {
			let rows = JSON.parse(JSON.stringify(data));
			if (rows) {
				for (let i = 0; i < rows.length; i++) {
					let dataParse = rows[i];
					if (dataParse.CreatedDate) {
						let dt = new Date(dataParse.CreatedDate);
						dataParse.CreatedDate = dt.toLocaleString("en-US", { timeZone: TIME_ZONE });
					}
				}
				this.list_Records = transformMultiLevelFieldData(rows, this.list_Columns);
				this.blnIsLoading = false;
			}
		}
	}

	/**
	 * Handle error while server call
	 * @param {Error} error
	 */
	handleError(error) {
		const event = new ShowToastEvent({
			title: "Error",
			message: error,
			variant: "Error",
			mode: "dismissable"
		});
		this.dispatchEvent(event);
	}
}