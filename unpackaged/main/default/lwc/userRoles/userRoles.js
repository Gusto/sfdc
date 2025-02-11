import { LightningElement,api } from 'lwc';
import queryRoles from '@salesforce/apex/AdminPermissions.queryUserRoles';
export default class UserRoles extends LightningElement {
    blnShow = false;
    strRoles = '';
    @api recordid;

    connectedCallback() {
        this.doInit();
    }
    
    /**
     * Author: Alex
     * Date: 9/11/2020
     * Desc: query Case's Contact's user roles from ZP User.
     * If there are any, fire custom event to parent component to display the info.
     */
    doInit() {
        queryRoles({
            idCase: this.recordid
        })
        .then(result => {
            if(result) {
                console.log('result',  result);
                this.strRoles = result;

                if(result.length > 0) {
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