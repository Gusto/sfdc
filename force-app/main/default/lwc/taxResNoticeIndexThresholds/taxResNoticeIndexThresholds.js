import { LightningElement, wire } from "lwc";
import getBelowToleranceThreshold from "@salesforce/apex/TaxResNoticeIndexThresholdsCntrl.getBelowToleranceThreshold";
import updateThresholdValue from "@salesforce/apex/TaxResNoticeIndexThresholdsCntrl.updateThresholdValue";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class TaxResNoticeIndexThresholds extends LightningElement {
	originalValue;
	belowToleranceThresholdValue;
	disabled = true;

	@wire(getBelowToleranceThreshold)
	belowToleranceThreshold({ error, data }) {
		if (data) {
			console.log(data);
			this.customSettingRecord = data;
			this.belowToleranceThresholdValue = data.Value_Decimal__c;
			this.originalValue = data.Value_Decimal__c;
		} else if (error) {
			console.error(error);
		}
	}

	handleChange(event) {
		this.belowToleranceThresholdValue = event.target.value;
		console.log(this.belowToleranceThresholdValue);
	}

	handleClick(event) {
		if (event.target.label === "Save") {
			console.log(String.valueOf(this.belowToleranceThresholdvalue));
			updateThresholdValue({ thresholdValue: this.belowToleranceThresholdValue.toString() })
				.then((result) => {
					this.dispatchEvent(
						new ShowToastEvent({
							title: "Success",
							message: "Record Saved Successfully",
							variant: "Success"
						})
					);
                    this.originalValue = this.belowToleranceThresholdValue;
					this.disabled = true;
				})
				.catch((error) => {
					console.log(error);
				});
		} else if (event.target.label === "Edit") {
			this.disabled = false;
		} else if (event.target.label === "Cancel") {
			this.disabled = true;
			this.belowToleranceThresholdValue = this.originalValue;
		}
	}
}