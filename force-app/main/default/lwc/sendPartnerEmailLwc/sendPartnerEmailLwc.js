import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
export default class SendPartnerEmailLwc extends NavigationMixin(LightningElement) {
    @api recordId;
    @api invoke() {
        var pageRef = {
            type: "standard__quickAction",
            attributes: {
                apiName:"Global.SendEmail"
            },
            state: {
                recordId: this.recordId,
                defaultFieldValues:
                    encodeDefaultFieldValues({
                        HtmlBody: "Hi there....This is a POC ",
                        Subject:"Greetings"
                    })
            }
        };
        this[NavigationMixin.Navigate](pageRef);
    }
}