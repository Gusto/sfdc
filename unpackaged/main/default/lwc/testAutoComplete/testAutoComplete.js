import { LightningElement, track, api } from 'lwc';

import { fireCustomEvent } from 'c/utilityService';

export default class TestAutoComplete extends LightningElement {

    @track isvisible = false;
    @api casereasons = [];
    @track input = '';

    @api casereasonmap = [];

    @track map_caseReasonMap = [];

    @track mapjson = '';

    @api casereasonfound;
    @api casereason = '';

    @api label;
    @api isrequired = false;

    @track highlightCounter = 0;
    focusedElement = {};
    @track focusedReason = '';

    @track textStyleClass = 'slds-input';
    @api isdisabled = false;



    handleChange(event) {
        if(!this.isdisabled) {
            this.highlightCounter = 0;
            this.removeFocus();
            this.isvisible = true;
            if(event.detail) {
                this.casereason = event.detail.value;
                fireCustomEvent(this, event.detail.value , 'filtercasereason');
            } else {
                fireCustomEvent(this, this.casereason , 'filtercasereason');
            }
        }
    }

    handleSelected(event) {
        this.isvisible = false;
        this.casereason = event.target.dataset.api;
        fireCustomEvent(this, event.target.dataset.api , 'selectcasereason');
    }
    
    renderedCallback() {
        console.log('rendering list complete');
    }

    connectedCallback() {
        this.addEventListener('keyup', this.handleKeyPress.bind(this));
        if(!this.casereason) {
            this.textStyleClass = 'slds-input text-style';
        } else {
            this.textStyleClass = 'slds-input';
        }
        this.casereason = this.casereason ? this.casereason : '';
    }

    handleKeyPress({code}) {
        let lst_choices = [...this.template.querySelectorAll('li.selectable-option')];
        if(code === 'ArrowDown') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.highlightCounter) {
                    let choiceToRemoveFocus = lst_choices[i-1];
                    let choiceToAddFocus = lst_choices[i];
                    if(choiceToRemoveFocus) {
                        choiceToRemoveFocus.classList.remove('list-highlighted');
                    }
                    if(choiceToAddFocus) {
                        lst_choices[i].classList.add('list-highlighted');
                        this.focusedElement = choiceToAddFocus;
                        this.focusedReason = choiceToAddFocus.dataset.api;
                    }
                    if(this.highlightCounter !== lst_choices.length -1 )
                        this.highlightCounter = this.highlightCounter + 1;
                    break;
                }
            }
        } else if(code === 'ArrowUp') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.highlightCounter) {
                    let choiceToRemoveFocus = lst_choices[i];
                    let choiceToAddFocus = lst_choices[i-1];
                    if(choiceToRemoveFocus) {
                        choiceToRemoveFocus.classList.remove('list-highlighted');
                    }
                    if(choiceToAddFocus) {
                        choiceToAddFocus.classList.add('list-highlighted');
                        // choiceToAddFocus.scrollIntoView();
                        this.focusedElement = choiceToAddFocus;
                        this.focusedReason = choiceToAddFocus.dataset.api;
                    }
                    if(this.highlightCounter !== 0)
                        this.highlightCounter = this.highlightCounter - 1;
                    break;
                }
            }
        } else if(code === 'Enter') {
            if(this.focusedReason) {
                this.isvisible = false;
                fireCustomEvent(this, this.focusedReason , 'selectcasereason');
            }
        } else if(code === 'Escape') {
            this.isvisible = false;
        }
    }


    disconnectedCallback() {
        this.removeEventListener('keyup', this.handleKeyPress.bind(this));
    }

    removeFocus() {
        if(this.focusedElement && this.focusedElement.classList)
            this.focusedElement.classList.remove('list-highlighted');
    }


    handleClose() {
        this.isvisible = true;
        fireCustomEvent(this, '' , 'selectcasereason');
        let lst_input = [...this.template.querySelectorAll('lightning-input')];
        if(lst_input.length > 0) {
            lst_input[0].focus();
        }
    }

    handleFocusOut() {
        this.isvisible = false;
    }
}