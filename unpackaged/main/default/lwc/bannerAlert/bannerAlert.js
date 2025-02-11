import { LightningElement, track } from "lwc";
import getBanner from "@salesforce/apex/AlertBannerCtrl.getHighlightBanner";

export default class BannerAlert extends LightningElement {
	@track list_Messages = [];

	connectedCallback() {
		getBanner()
			.then((result) => {
				if (result && result.length) {
					this.list_Messages = result;
				}
			})
			.catch((error) => {
				console.log(JSON.stringify(error));
			});
	}
}