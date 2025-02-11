import { LightningElement, track, api } from 'lwc';

import { fireCustomEvent } from 'c/utilityService';

export default class CustomLookup extends LightningElement {
    //label for the input field
    @api objectlabel;
    @api listrecords = [];
    @api maprecords = [];
    @api boolrecordfound;
    @api searchterm;
    @api lookupicon;
    @api blndisabled;

    // To keep a track of the highlighted value
    @track intHighlightCounter = 0;
    // Flag to show/hide the queue dropdown
    @track blnIsvisible = false;
    @track input = '';
    @track map_recordmap = [];
    @track mapjson = '';
    //To store the string entered to Search Queue
    @track strTextInput;


    connectedCallback() {
        this.addEventListener('keyup', this.handleKeyPress.bind(this));
    }

    handleKeyPress({code}) {
        let lst_choices = [...this.template.querySelectorAll('li.selectable-option')];
        if(code === 'ArrowDown') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.intHighlightCounter) {
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
                    if(this.intHighlightCounter !== lst_choices.length -1 )
                        this.intHighlightCounter = this.intHighlightCounter + 1;
                    break;
                }
            }
        } else if(code === 'ArrowUp') {
            for(let i =0; i< lst_choices.length; i++) {
                if(i == this.intHighlightCounter) {
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
                    if(this.intHighlightCounter !== 0)
                        this.intHighlightCounter = this.intHighlightCounter - 1;
                    break;
                }
            }
        } else if(code === 'Enter') {
            // if(this.focusedReason) {
            //     this.blnIsvisible = false;
            //     this.searchterm = this.focusedReason;
            //     fireCustomEvent(this, this.focusedReason , 'selectrecord');
            // }
        } else if(code === 'Escape') {
            this.blnIsvisible = false;
        }
    }

    disconnectedCallback() {
        this.removeEventListener('keyup', this.handleKeyPress.bind(this));
    }

    handleChange(event) {
        if(!this.blndisabled) {
            this.intHighlightCounter = 0;
            this.removeFocus();
            this.blnIsvisible = true;
            if(event.detail) {
                this.strTextInput = event.detail.value;
                fireCustomEvent(this, event.detail.value , 'filterrecord');
            } else if(this.strTextInput) {
                fireCustomEvent(this, this.strTextInput , 'filterrecord');
            } else {
                fireCustomEvent(this, '' , 'filterrecord');
            }
        }
    }

    removeFocus() {
        if(this.focusedElement && this.focusedElement.classList)
            this.focusedElement.classList.remove('list-highlighted');
    }

    handleSelected(event) {
        this.blnIsvisible = false;
        this.searchterm = event.target.dataset.api;
        fireCustomEvent(this, {
            name: event.target.dataset.api,
            id: event.target.dataset.value
            }, 'selectrecord');

    }
    handleFocusOut() {
      this.blnIsvisible = false;
    }


}