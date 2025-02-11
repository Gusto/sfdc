import { LightningElement, api, track, wire  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import convertURL from "@salesforce/apex/RelatedRecordsCtrl.convertURL";
export default class ConvertUrlCmp extends LightningElement {
    @track blnIsLoading = false
    @track strInputURL = "";
    @track strOutputURL = "";
    @track strMessage = "";
    @track strVariant = "Failed";
    @track blnValidUrl = false;
    @track strIconName = 'utility:copy';
    @track strAltText = 'Copy Text';

    convertCurrentPageURL (){
        this.strInputURL = window.location.href + '';
        this.convertUrlHandler();
    }

    convertCopyPasteURL (){
        var listOfInputText = this.template.querySelectorAll("lightning-input");
        listOfInputText.forEach(function(objElement){
            if(objElement.name=="inputurl")
                this.strInputURL = objElement.value;
        },this);
        this.convertUrlHandler();
    }

    convertUrlHandler (){
        this.blnValidUrl = false;
        this.strOutputURL = "";
        this.blnIsLoading = true;
		this.strAltText = 'Copy Text';

        convertURL({
			strInputUrl: this.strInputURL,
            strBaseURL : window.location.origin
		}).then((result) => {
			this.strOutputURL = result.strOutputUrl;
			this.strMessage = result.strMessage;
            this.blnValidUrl = result.blnValidUrl;
            this.strIconName = 'utility:copy';

            if (result.blnValidUrl) {
                this.strVariant = "Success";
            } else {
                this.strVariant = "Error";
            }

            const event = new ShowToastEvent({
                "title": this.strVariant,
                "variant": this.strVariant,
                "message": this.strMessage
            });
            this.dispatchEvent(event);
            this.blnIsLoading = false;
		});
    }

    copyClipBoard() {
        this.strIconName = 'utility:check';
		this.strAltText = 'Text Copied';
        const objElement = document.createElement("textarea");
		objElement.value = this.strOutputURL;
		document.body.appendChild(objElement);
		objElement.select();
		document.execCommand("copy");
		document.body.removeChild(objElement);

        const event = new ShowToastEvent({
            "title": "Success",
            "variant": "success",
            "message": "URL copied to clipboard!"
        });
        this.dispatchEvent(event);
	}
}