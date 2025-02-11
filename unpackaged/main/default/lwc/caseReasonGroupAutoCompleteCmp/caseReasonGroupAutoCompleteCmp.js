import { LightningElement, track, api } from 'lwc';

import { fireCustomEvent } from 'c/utilityService';

export default class CaseReasonGroupAutoComplete extends LightningElement {

    /* all @api variables grouped together */
    /* map of case record type and its corresponding case reason classification */
    @api mapcasereason = [];
    /* flag to indicate if case reason choices can be shown on auto complete */
    @api blncasereasonfound;
    /* default confirm case reason if it already exists on case */
    @api strcasereason = '';
    /* Label of the field showed in front end */
    @api strlabel;
    @api blnisdisabled = false;

    /* all @track variables grouped together */
    /* flag to indicate if case reason choices can be shown on auto complete */
    @track blnIsVisible = false;
    
    /* Focussed element on auto complete options */
    focusedElement = {};
    /* corresponding index on which row is highlighted */
    intHighlightCounter = 0;
    /* highlighed case reason, this changes as users press up and down arrow */
    strFocusedReason = '';
    strFocusedRecordType = '';

    renderedCallback() {
        if(!this.strlabel) {
            this.template.querySelector('.slds-form-element__label').classList.add("hide");
        }
    }

    // This method handles when user types in any value on auto complete textbox
    handleChange(event) {
        // Check if it is not disabled
        if(!this.blnisdisabled) {
            // Set highlight counter to 0
            this.intHighlightCounter = 0;
            // Remove if there are any elements that are already focussed
            this.removeFocus();
            // set visible to true
            this.blnIsVisible = true;
            // event has value, then send it to the parent component
            if(event.detail) {
                this.strcasereason = event.detail.value;
                fireCustomEvent(this, event.detail.value , 'filtercasereason');
            } else {
                fireCustomEvent(this, this.strcasereason , 'filtercasereason');
            }
        }
    }

    // This method handles when users select a choice on list of auto complete options
    handleSelected(event) {
        // after selected, set isvisible to false
        this.blnIsVisible = false;
        // set case reason and default them on textbox
        this.strcasereason = event.target.dataset.api;
        // fire custom event to send selected case reason to parent component
        fireCustomEvent(this, {
            reason: event.target.dataset.api,
            type: event.target.dataset.type,
            id:event.target.dataset.id
        } , 'selectcasereason');
    }
    
    // when component loads, add keyup listeners
    connectedCallback() {
        // Adding event listeners for onkeyp
        this.addEventListener('keyup', this.handleKeyPress.bind(this));
        this.strcasereason = this.strcasereason ? this.strcasereason : '';
    }

    // This method is used for users to navigate auto complete list using arrow keys (up and down) and 
    // to be able to select a case reason using enter key.
    handleKeyPress({code}) {
        // get a list of selectable choices
        let lst_choices = [...this.template.querySelectorAll('li.selectable-option')];
        if(code === 'ArrowDown') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.intHighlightCounter) {
                    let strChoiceToRemoveFocus = lst_choices[i-1];
                    let strChoiceToAddFocus = lst_choices[i];
                    if(strChoiceToRemoveFocus) {
                        strChoiceToRemoveFocus.classList.remove('list-highlighted');
                    }
                    if(strChoiceToAddFocus) {
                        lst_choices[i].classList.add('list-highlighted');
                        this.focusedElement = strChoiceToAddFocus;
                        this.strFocusedReason = strChoiceToAddFocus.dataset.api;
                        this.strFocusedRecordType = strChoiceToAddFocus.dataset.type;
                    }
                    if(this.intHighlightCounter !== lst_choices.length -1 )
                        this.intHighlightCounter = this.intHighlightCounter + 1;
                    break;
                }
            }
        } else if(code === 'ArrowUp') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.intHighlightCounter) {
                    let strChoiceToRemoveFocus = lst_choices[i];
                    let strChoiceToAddFocus = lst_choices[i-1];
                    if(strChoiceToRemoveFocus) {
                        strChoiceToRemoveFocus.classList.remove('list-highlighted');
                    }
                    if(strChoiceToAddFocus) {
                        strChoiceToAddFocus.classList.add('list-highlighted');
                        // strChoiceToAddFocus.scrollIntoView();
                        this.focusedElement = strChoiceToAddFocus;
                        this.strFocusedReason = strChoiceToAddFocus.dataset.api;
                        this.strFocusedRecordType = strChoiceToAddFocus.dataset.type;
                    }
                    if(this.intHighlightCounter !== 0)
                        this.intHighlightCounter = this.intHighlightCounter - 1;
                    break;
                }
            }
        } else if(code === 'Enter') {
            if(this.strFocusedReason) {
                this.blnIsVisible = false;
                fireCustomEvent(this, {
                    reason: this.strFocusedReason,
                    type: this.strFocusedRecordType
                } , 'selectcasereason');
            }
        } else if(code === 'Escape') {
            this.blnIsVisible = false;
        }
    }

    // When component is unloaded, remove event listeners
    disconnectedCallback() {
        this.removeEventListener('keyup', this.handleKeyPress.bind(this));
    }

    // Remove focus on an element
    removeFocus() {
        if(this.focusedElement && this.focusedElement.classList)
            this.focusedElement.classList.remove('list-highlighted');
    }

    // This method is invoked when users click close button
    handleClose() {
        this.blnIsVisible = true;
        fireCustomEvent(this, '' , 'selectcasereason');
        let lst_input = [...this.template.querySelectorAll('lightning-input')];
        if(lst_input.length > 0) {
            lst_input[0].focus();
        }
    }
    // when users focus out, set isvisible to false
    handleFocusOut() {
        this.blnIsVisible = false;
    }
}