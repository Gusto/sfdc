import { LightningElement, api, track } from "lwc";

import { fireCustomEvent, sendAuraEvent } from "c/utilityService";

export default class AutoCompleteCmp extends LightningElement {
	/* List of Auto Complete values to be shown as a drop down */
	@api autocompletelist;
	/* Name of the field */
	@api label;
	/* icons to be used for auto complete choices */
	@api icon;
	/* values that user selects */
	@api selectedvalue;
	/* Indicates if parent is an LWC or Aura Component */
	/* It is created to differentiate the way we communicate to parent comments using events */
	@api auracomponent = false;

	/* Creating a new variable to dynamically decide whether values need to be shown on mouse over */
	@api disablemouseover = false;

	/* Creating a new variable to dynamically decide whether need to disable the combobox or not */
	@api blnDisabled = false;
	/* Creating a new variable to hold the placeholder */
	@api strPlaceHolder = "";

	/* Decides whether auto complete options need to be visible */
	@track blnIsVisible = false;
	/* Indication of which option is highlighted */
	@track intHighlightCounter = 0;
	/* Value that user types */
	@api strTextInput;
	/* Id of the text box */
	@api id;
	/* css property to aling properly the close btn */
	customTop = 'top: 50% !important;';

	/* When users focus out of the textbox, auto complete choices should not be visible */
	handleFocusOut() {
		this.blnIsVisible = false;
	}

	/* When users type any value to search, send events to the parent component to filter */
	handleChange(event) {
		// Set highlight counter to 0 intially. So that we automatically highlight the first option
		this.intHighlightCounter = 0;
		this.blnIsVisible = !this.blnDisabled;
		// If event has value, send the value to parent LWC or Aura
		// If event does not have a value, send input text's value to parent component
		if (event.detail) {
			this.strTextInput = event.detail.value;
			if (this.auracomponent) {
				sendAuraEvent(this, event.detail.value, "filterlist");
			} else {
				fireCustomEvent(this, event.detail.value, "filterlist");
			}
		} else if (this.strTextInput) {
			if (this.auracomponent) {
				sendAuraEvent(this, this.strTextInput, "filterlist");
			} else {
				fireCustomEvent(this, this.strTextInput, "filterlist");
			}
		} else {
			if (this.auracomponent) {
				sendAuraEvent(this, "", "filterlist");
			} else {
				fireCustomEvent(this, "", "filterlist");
			}
		}
	}

	/* This method fires when any auto complete options are selected. we roll up to parent component by sending events */
	handleSelected(event) {
		this.blnIsVisible = false;
		this.strTextInput = event.target.dataset.api;
		if (this.auracomponent) {
			sendAuraEvent(this, event.target.dataset.api, "filterselected");
		} else {
			fireCustomEvent(this, event.target.dataset.api, "filterselected");
		}
	}

	/* When users click close button, we show all auto complete choices */
	handleClose() {
		this.blnIsVisible = !this.blnDisabled;
		this.strTextInput = "";
		if (this.auracomponent) {
			sendAuraEvent(this, "", "filterselected");
		} else {
			fireCustomEvent(this, "", "filterselected");
		}
		// Setting the focus on the input element
		let lst_input = [...this.template.querySelectorAll("lightning-input")];
		if (lst_input.length > 0) {
			lst_input[0].focus();
		}
	}

	/* When component loads, add an onkeyp listener to listen for key press events */
	connectedCallback() {
		this.addEventListener("keyup", this.handleKeyPress.bind(this));
	}

	/* This method is used for navigation of the list using arrow keys. and when users click Enter, send highlighted option to parent Aura or LWC*/
	handleKeyPress({ code }) {
		let lst_choices = [...this.template.querySelectorAll("li.selectable-option")];
		if (code === "ArrowDown") {
			// Iterate over list of selectable choices
			// Iterate over every choice. as user presses up or down, add or remove focus on an element
			// ArrowDown function is used for removing an element's focus and focussing on an element that is below it
			for (let i = 0; i < lst_choices.length; i++) {
				if (i == this.intHighlightCounter) {
					let objChoiceToRemoveFocus = lst_choices[i - 1];
					let choiceToAddFocus = lst_choices[i];
					if (objChoiceToRemoveFocus) {
						objChoiceToRemoveFocus.classList.remove("list-highlighted");
					}
					if (choiceToAddFocus) {
						lst_choices[i].classList.add("list-highlighted");
						this.focusedElement = choiceToAddFocus;
						this.focusedReason = choiceToAddFocus.dataset.api;
					}
					if (this.intHighlightCounter !== lst_choices.length - 1) this.intHighlightCounter = this.intHighlightCounter + 1;
					break;
				}
			}
		} else if (code === "ArrowUp") {
			// Iterate over list of selectable choices
			// Iterate over every choice. as user presses up or down, add or remove focus on an element
			// ArrowUp function is used for removing an element's focus and focussing on an element that is above it
			for (let i = 0; i < lst_choices.length; i++) {
				if (i == this.intHighlightCounter) {
					let objChoiceToRemoveFocus = lst_choices[i];
					let choiceToAddFocus = lst_choices[i - 1];
					if (objChoiceToRemoveFocus) {
						objChoiceToRemoveFocus.classList.remove("list-highlighted");
					}
					if (choiceToAddFocus) {
						choiceToAddFocus.classList.add("list-highlighted");
						// Optionally uncomment if you want all the elements to scroll into view
						// choiceToAddFocus.scrollIntoView();
						this.focusedElement = choiceToAddFocus;
						this.focusedReason = choiceToAddFocus.dataset.api;
					}
					if (this.intHighlightCounter !== 0) this.intHighlightCounter = this.intHighlightCounter - 1;
					break;
				}
			}
		} else if (code === "Enter") {
			// When user presses Enter, set visibility to false and send the focusedReason
			if (this.focusedReason) {
				this.blnIsVisible = false;
				if (this.auracomponent) {
					sendAuraEvent(this, this.focusedReason, "filterselected");
				} else {
					fireCustomEvent(this, this.focusedReason, "filterselected");
				}
			}
		} else if (code === "Escape") {
			// When user enters Escape, do not show any choices
			this.blnIsVisible = false;
		}
	}

	/* When component is unloaded. remove keyup listener */
	disconnectedCallback() {
		this.removeEventListener("keyup", this.handleKeyPress.bind(this));
	}

	/* Fired when user hovers over the text box */
	handleMouseOver(event) {
		if (this.disablemouseover === false) {
			this.handleChange(event);
		}
	}

	/* api method to reset the text box */
	@api
	resetTextBox() {
		let lst_input = [...this.template.querySelectorAll("lightning-input")];
		lst_input.forEach((input) => {
			input.value = null;
		});
	}

	@api
	setErrorMessage(strMessage) {
		let lst_input = [...this.template.querySelectorAll("lightning-input")];
		lst_input.forEach((input) => {
			input.setCustomValidity(strMessage);
			input.reportValidity();
		});
		this.customTop = (strMessage === '') ? 'top: 50% !important;' : 'top: 32% !important;'
	}

	/* api method to reset the text box */
	@api
	setTextBox(value) {
		let lst_input = [...this.template.querySelectorAll("lightning-input")];
		lst_input.forEach((input) => {
			input.value = value;
		});
	}
}