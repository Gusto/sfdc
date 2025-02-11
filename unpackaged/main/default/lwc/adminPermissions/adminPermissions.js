import { LightningElement, track, api } from 'lwc';
import queryPerms from '@salesforce/apex/AdminPermissions.queryAdminPerms';
export default class AdminPermissions extends LightningElement {
    //the case we're on
    @api currentCase;
    @api recordid;
    strPerms = '';
    blnShow = false;
    connectedCallback() {
        this.doInit();
    }
    /**
     * Author: Alex
     * Date: 9/11/2020
     * Desc: query for the Case's Contact's admin permissions.
     * if there are any, fire a custom event to parent component to display the info
     */
    @api doInit() {
        queryPerms({
            idCase: this.recordid
        })
        .then(result => {
            if(result) {
                console.log('result',  result);
                this.strPerms = result;
                
                if(result.length === 0) {
                    console.log('blank ',  result);
                    this.blnShow = false;
                }
                else {
                    this.blnShow = true;
                    const moreDetailsEvent = new CustomEvent('showmoredetails', {
                        detail: {},
                    });
                    // Fire the custom event
                    this.dispatchEvent(moreDetailsEvent);
                }
            }
            else {
                console.log('null',  result);
                this.blnShow = false;
            }
       })
       .catch(error => {
            console.log('!!! error', error);
       });
    }
}