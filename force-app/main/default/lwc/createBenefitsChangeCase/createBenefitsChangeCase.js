import { LightningElement, api, wire } from "lwc";
import { IsConsoleNavigation, openSubtab, getTabInfo, getFocusedTabInfo } from "lightning/platformWorkspaceApi";
import { CurrentPageReference } from "lightning/navigation";
/* Import Apex Methods */
import getFulfilmentCaseWithTicket from "@salesforce/apex/TicketBenefitChangeCasePageCtrl.getFulfilmentCaseWithTicket";
import saveFulfillmentCase from "@salesforce/apex/TicketBenefitChangeCasePageCtrl.saveFulfillmentCase";
import { displayToast } from "c/utilityService";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class CreateBenefitsChangeCase extends LightningElement {
    @api recordId;
    isLoading = false;
    @wire(IsConsoleNavigation) blnConsoleNavigation;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        this.isLoading = true;
        getFocusedTabInfo()
            .then((tabInfo) => {
                this.idParentTab = tabInfo.tabId;
            })
            .catch((error) => console.error("Error fetching focused tab info:", error));

        /* Check if an open ticket exists with a carrier order */
        getFulfilmentCaseWithTicket({
            idTicketRecord: this.recordId
        }).then((result) => {
            console.log("result----->" + JSON.stringify(result));
            if (result.Fulfillment_Case__c != null) {
                this.strOpenCaseId = result.Fulfillment_Case__c;
                this.strOpenCaseName = result.Fulfillment_Case__r.CaseNumber;
                this.openCase();
            } else {
                saveFulfillmentCase({
                    objTicket: result
                })
                    .then((result) => {
                        console.log("result at 41----->" + JSON.stringify(result));
                        if (result.blnIsSuccess) {
                            const caseUrl = "/lightning/r/Case/" + result.objTicket.Fulfillment_Case__c + "/view";
                            const event = new ShowToastEvent({
                                title: "Case Created!",
                                variant: "success",
                                message: "{1} created successfully!",
                                mode: "sticky",
                                messageData: [
                                    result.objTicket.Fulfillment_Case__r.CaseNumber,
                                    {
                                        url: caseUrl,
                                        label: result.objTicket.Fulfillment_Case__r.CaseNumber
                                    }
                                ]
                            });
                            this.dispatchEvent(event);
                            this.strOpenCaseId = result.objTicket.Fulfillment_Case__c;
                            this.strOpenCaseName = result.objTicket.Fulfillment_Case__r.CaseNumber;
                            this.openCase();
                        } else {
                            displayToast(this, result.strMessage, "", "error", "sticky");
                        }
                    })
                    .catch((error) => {
                        console.log("Error in createBenefitsChangeCase LWC Component----->" + error);
                    });
            }

            this.isLoading = false;
        });
    }

    /* Open Case record as a subtab */
    async openCase() {
        if (!this.idParentTab) {
            return;
        }
        const objTabInfo = await getTabInfo(this.idParentTab);
        const idPrimaryTab = objTabInfo.isSubtab ? objTabInfo.parentTabId : this.idParentTab;

        if (this.blnConsoleNavigation) {
            if (this.strOpenCaseId) {
                await openSubtab(idPrimaryTab, {
                    url: "/lightning/r/Case/" + this.strOpenCaseId + "/view",
                    label: this.strOpenCaseName,
                    focus: true
                }).catch((error) => {
                    console.log("Error in openTicketCmp LWC Component----->" + error);
                });
            }
        }
    }
}