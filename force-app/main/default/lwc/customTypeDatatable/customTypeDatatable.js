import LightningDatatable from "lightning/datatable";
import customColumn from "./customColumn.html";

export default class CustomTypeDatatable extends LightningDatatable {
	static customTypes = {
		customColumn: {
			template: customColumn,
			standardCellLayout: true,
			typeAttributes: ["escalationIcon", "pniIcon", "caseNumber", "caseRecordId"]
		}
	};
}