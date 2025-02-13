import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getPermissions from "@salesforce/apex/CareCaseButtons.getPermissions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class SocialEscalationLWC extends NavigationMixin(LightningElement) {
  @api recordId;
  inputVariables = [];
  @track blnIsLoaded = false;
  @track blnShowSocialEscalationFlow;

  connectedCallback() {
    getPermissions()
      .then((result) => {
        this.blnIsLoaded = true;
        if (result.blnSocialEscalationPermission) {
          this.inputVariables = [
            {
              name: "currentCaseId",
              type: "String",
              value: this.recordId
            }
          ];
          this.blnShowSocialEscalationFlow = true;
        } else {
          this.blnShowSocialEscalationFlow = false;
        }
        this.error = undefined;
      })
      .catch((error) => {
        this.blnIsLoaded = true;
        this.error = error;
      });
  }

  handleFlowStatusChange(event) {
    if (event.detail.status === "FINISHED") {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Social & Executive Escalation Details Successfully Saved",
          variant: "success"
        })
      );
      eval("$A.get('e.force:refreshView').fire();");
      this.dispatchEvent(new CloseActionScreenEvent());
    }
  }
}