import { LightningElement } from "lwc";
import fetchCarriers from "@salesforce/apex/UpdateCarrierPlayInfoCtrl.fetchCarriers";
import fetchCarrierPlayInfo from "@salesforce/apex/UpdateCarrierPlayInfoCtrl.fetchCarrierPlayInfo";
import saveCarrierPlayInfo from "@salesforce/apex/UpdateCarrierPlayInfoCtrl.saveCarrierPlayInfo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const columns = [
	{ label: "Event Type", fieldName: "eventType", type: "text", editable: false },
	{ label: "Play Mode Type", fieldName: "playMode", type: "text", editable: false },
	{ label: "From (Day of Month)", fieldName: "from", type: "number", editable: false },
	{ label: "To (Day of Month)", fieldName: "to", type: "number", editable: false },
	{ label: "Before/After Effective Date", fieldName: "before", type: "text", editable: false },
	{ label: "Number of Days", fieldName: "nDays", type: "number", editable: true }
];

export default class CarrierUpdatePlayInfoCmp extends LightningElement {
	columns = columns;
	list_carriers = [];
	list_carriers_master = [];
	map_carriers = [];
	selected_carrier = null;
	selected_states = [];
	list_states = [];
	draftValues = [];
	error;
	carrierPlayInfo = [];
	blnAllStates = false;
	blnIsLoading = false;
	map_CarrierPlayInfo = null;
	map_AllCarrierPlayInfo = null;

	connectedCallback() {
		this.fetchCarriersMethod();
	}

	async fetchCarriersMethod() {
		try {
			this.blnIsLoading = true;
			let result = await fetchCarriers();
			this.list_carriers = result.carriers;
			this.list_carriers_master = result.carriers;
			this.map_carriers = result.map_CarrierUniqueName;
			this.error = undefined;
		} catch (error) {
			console.log("error", error);
			this.error = error;
			this.carriers = [];
		}
		this.blnIsLoading = false;
	}

	async fetchPlayInfo(carrierIds) {
		try {
			this.blnIsLoading = true;
			let result = await fetchCarrierPlayInfo({ list_CarrierIds: carrierIds });
			let carrierPlayInfo = [];
			for (const [key, value] of Object.entries(result.map_CarrierPlayInfo)) {
				carrierPlayInfo.push({
					Id: value.Id,
					key: key,
					eventType: value.Event_Type__c,
					playMode: value.Play_Mode_Type__c,
					from: value.From__c,
					to: value.To__c,
					before: value.Before_After__c,
					nDays: value.Number_of_Days__c
				});
			}
			this.carrierPlayInfo = carrierPlayInfo;
			this.map_AllCarrierPlayInfo = result.map_AllCarrierPlayInfo;
			this.map_CarrierPlayInfo = result.map_CarrierPlayInfo;
			this.error = undefined;
		} catch (error) {
			console.log("error", error);
			this.error = error;
			this.carriers = [];
		}
		this.blnIsLoading = false;
	}

	// used when users enter a value in the auto complete field
	handleFilterList(event) {
		// variable declaration
		let value = event.detail ? event.detail : "";
		let list_filterFields = [];
		let list_toSearch = this.list_carriers_master;
		if (value) {
			// not searching for every character. search only for every 3rd character
			if (value.length % 3 === 0) {
				let counter = 0;
				list_toSearch.forEach((detail) => {
					if (detail.toLowerCase().includes(value.toLowerCase())) {
						if (counter < 10) {
							list_filterFields.push(detail);
							counter = counter + 1;
						}
					}
				});
				this.list_carriers = list_filterFields;
			}
		} else {
			this.list_carriers = this.list_carriers_master;
		}
	}

	//method that handle when the field changes from the dropdown
	handleChangeCarrier(event) {
		let str_label = event.detail ? event.detail : "";
		this.selected_carrier = str_label;
		this.populateStates();
	}

	populateStates() {
		this.blnAllStates = false;
		this.selected_states = [];
		this.carrierPlayInfo = [];
		if (this.selected_carrier !== null && this.selected_carrier !== "") {
			this.list_states = [];
			let list_states = [];
			let set_uniqueStates = new Set();
			this.map_carriers[this.selected_carrier].forEach((carrier) => {
				let set_carrierStates = new Set(carrier.State__c.split(";"));
				set_uniqueStates = [...set_uniqueStates, ...set_carrierStates];
			});
			set_uniqueStates.forEach((state) => {
				list_states.push({ label: state, value: state });
			});
			this.list_states = list_states;
			this.template.querySelector("c-multi-select-pick-list-cmp").refreshSelectedValues(this.selected_states);
			this.template.querySelector("c-multi-select-pick-list-cmp").refreshOptions(this.list_states);
		}
	}

	handleSelectStates(event) {
		let list_SelectedUserLookups = JSON.parse(JSON.stringify(event.detail));
		this.selected_states = list_SelectedUserLookups;
		this.handleFetchPlayInfo();
	}

	handleFetchPlayInfo() {
		let carrierIds = [];
		this.map_carriers[this.selected_carrier].forEach((carrier) => {
			this.selected_states.forEach((state) => {
				if (carrier.State__c.includes(state)) {
					carrierIds.push(carrier.Id);
				}
			});
		});
		this.fetchPlayInfo(carrierIds);
	}

	get isDisabled() {
		return this.selected_carrier === null || this.selected_carrier === "" || this.blnAllStates;
	}

	get hasData() {
		return this.carrierPlayInfo.length > 0;
	}

	get blnShowAllStates() {
		return this.selected_carrier === null || this.selected_carrier === "";
	}

	async handleSave(event) {
		this.blnIsLoading = true;
		try {
			let newCarrierInfo = [];
			event.detail.draftValues.forEach((draft) => {
				let index = Number(draft.id.split("-")[1]);
				newCarrierInfo.push({
					Number_of_Days__c: draft.nDays,
					key: this.carrierPlayInfo[index].key
				});
			});
			let updatedCarriers = [];
			newCarrierInfo.forEach((updatedCarrier) => {
				let carriers = this.map_AllCarrierPlayInfo[updatedCarrier.key];
				carriers.forEach((carrier) => {
					carrier.Number_of_Days__c = updatedCarrier.Number_of_Days__c;
					updatedCarriers.push(carrier);
				});
			});
			await saveCarrierPlayInfo({ list_CarrierPlayInfoToUpdate: updatedCarriers });
			const evt = new ShowToastEvent({ title: "Success", message: "Carrier Play Info Updated", variant: "success" });
			this.blnIsLoading = false;
			this.dispatchEvent(evt);
			this.handleFetchPlayInfo();
			this.template.querySelector("lightning-datatable").draftValues = [];
		} catch (error) {
			console.log("error", error);
			this.blnIsLoading = false;
			const evt = new ShowToastEvent({ title: "Error", message: "Error Updating Carrier Play Info:" + error.body.message, variant: "error" });
			this.dispatchEvent(evt);
		}
	}

	handleAllStates(event) {
		this.blnAllStates = event.target.checked;
		if (this.blnAllStates) {
			this.selected_states = this.list_states.map((state) => state.value);
			this.template.querySelector("c-multi-select-pick-list-cmp").refreshSelectedValues(this.selected_states);
			this.handleFetchPlayInfo();
		} else {
			this.selected_states = [];
			this.template.querySelector("c-multi-select-pick-list-cmp").refreshSelectedValues(this.selected_states);
			this.carrierPlayInfo = [];
		}
	}
}