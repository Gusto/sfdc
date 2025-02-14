import { LightningElement, track } from "lwc";
import getBanner from "@salesforce/apex/AlertBannerCtrl.getBanner";

export default class BannerAlert extends LightningElement {
	@track strMessage;

	connectedCallback() {
		getBanner()
			.then((result) => {
				if (result) {
					this.strMessage = result;
				}
			})
			.catch((error) => {
				console.log(JSON.stringify(error));
			});
	}
}