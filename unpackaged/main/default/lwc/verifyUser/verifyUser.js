import { LightningElement,api } from 'lwc';
import {
    FlowAttributeChangeEvent,
    FlowNavigationNextEvent,
} from 'lightning/flowSupport';

export default class VerifyUser extends LightningElement {
    @api displayAuthenticated = false;
    @api displayTokenMatch = false;
    @api displayUnauthenticated = false;
    @api
    availableActions = [];
    //Logic to call the First And Last Invoice Button and open a new screen on Engagement case record page when clicked on it.
    handleAuthenticated(){      
        this.displayAuthenticated = true;
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'Authenticated',
            this.displayAuthenticated
        );
        this.dispatchEvent(attributeChangeEvent);
         // check if NEXT is allowed on this screen
         if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
          
    }

    //Logic to call the View Invoice in Panda Button and open a new screen on Engagement case record page when clicked on it.
    handleTokenMatch(){
        this.displayTokenMatch = true;
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'TokenMatch',
            this.displayTokenMatch
        );
        this.dispatchEvent(attributeChangeEvent);
         // check if NEXT is allowed on this screen
         if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }

    //Logic to call the Discount And Refund Button and open a new screen on Engagement case record page when clicked on it.
    handleUnauthenticated(){
        this.displayUnauthenticated = true;  
        const attributeChangeEvent = new FlowAttributeChangeEvent(
            'UnAuthenticated',
            this.displayUnauthenticated
        );
        this.dispatchEvent(attributeChangeEvent);   
        // check if NEXT is allowed on this screen
         if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        
        
    }
}