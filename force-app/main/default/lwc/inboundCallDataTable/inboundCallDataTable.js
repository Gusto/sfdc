import LightningDatatable from "lightning/datatable";
import toggleButtonColumnTemplate from "./inboundCallColumnButtonTemplate.html";

export default class InboundCallDataTable extends LightningDatatable {
	static customTypes = {
		clickButton: {
			template: toggleButtonColumnTemplate,
			standardCellLayout: true,
			typeAttributes: ["objRecordId", "objRecordName", "rowRecordId"]
		},
		openSubTab: {
			template: toggleButtonColumnTemplate,
			standardCellLayout: true,
			typeAttributes: ["objRecordId", "objRecordName", "rowRecordId"]
		}
	};
}