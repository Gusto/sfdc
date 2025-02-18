import { LightningElement, wire, api } from "lwc";
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from "lightning/messageService";
import { IsConsoleNavigation, setTabHighlighted, EnclosingTabId, getTabInfo } from "lightning/platformWorkspaceApi";
import ConversationEndedChannel from "@salesforce/messageChannel/lightning__conversationEnded";
import CHAT_PARAMETERS from "@salesforce/label/c.InactiveChatParameters";

export default class InactiveChatAlert extends LightningElement {
	// Record ID
	@api recordId;
	// Tab information
	tabInfo;
	// Event Subscription
	subscription = null;
	// Chat Parameters: {"timeoutmessage":"Timeout","timeoutlimit":180000}
	objChatParameter = JSON.parse(CHAT_PARAMETERS);
	// Reminder count
	intCount = 0;

	// To pass scope, you must get a message context.
	@wire(MessageContext) messageContext;
	// To determine if the component is in the console, you must use the IsConsoleNavigation wire adapter.
	@wire(IsConsoleNavigation) isConsoleNavigation;
	// To get the enclosing tab ID, you must use the EnclosingTabId wire adapter.
	@wire(EnclosingTabId) enclosingTabId;

	// Standard lifecycle hook used to subscribe to the message channel
	connectedCallback() {
		this.subscribeToMessageChannel();
		this.getTabInfo();
	}

	// Retrieve current tab information
	getTabInfo() {
		// Get tab information
		if (this.enclosingTabId) {
			getTabInfo(this.enclosingTabId)
				.then((tabInfo) => {
					this.tabInfo = tabInfo;
				})
				.catch((error) => {
					console.error("getTabInfo: " + error);
				});
		}
	}

	// Pass scope to the subscribe() method.
	subscribeToMessageChannel() {
		if (!this.subscription) {
			this.subscription = subscribe(
				this.messageContext, 
				ConversationEndedChannel, 
				(message) => this.validateTab(message), 
				{ scope: APPLICATION_SCOPE }
			);
		}
	}

	// Validate the message received recordId by the component
	validateTab(message) {
		if (message.recordId === this.recordId) {
			this.snoozeTab();
		}
	}

	// Handler for message received by component
	snoozeTab() {
		if (this.intCount !== 2) {
			this.intCount++;
			setTimeout(() => {
				this.redirectToSnoozedTab();
			}, this.objChatParameter.timeoutlimit);
		} else {
			this.unsubscribeToMessageChannel();
		}
	}

	// Snooze the alert for the defined time
	redirectToSnoozedTab() {
		const { tabId } = this.tabInfo;
		setTabHighlighted(tabId, true, {
			pulse: true,
			state: "error"
		})
		.then((tabInfo) => {
			alert(this.tabInfo.title + ": " + this.objChatParameter.timeoutmessage);
			this.snoozeTab();
		})
		.catch((error) => {
			console.error("setTabHighlighted: " + error);
		});
	}

	// Unsubscribe from the message channel
	unsubscribeToMessageChannel() {
		unsubscribe(this.subscription);
		this.subscription = null;
	}
}