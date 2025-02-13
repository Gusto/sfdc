import BaseChatMessage from "lightningsnapin/baseChatMessage";
import { track } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import chatMessageStyle from "@salesforce/resourceUrl/GCorpV2_Style";

const DEFAULT_MESSAGE_PREFIX = "PLAIN_TEXT";
const RICHTEXT_MESSAGE_PREFIX = "RICH_TEXT";
const CHILIPIPER_MESSAGE_PREFIX = "CHILIPIPER_LINK";
const SUPPORTED_MESSAGE_PREFIX = [DEFAULT_MESSAGE_PREFIX, RICHTEXT_MESSAGE_PREFIX, CHILIPIPER_MESSAGE_PREFIX];

export default class BotHyperlinkCmp extends BaseChatMessage {
	messageType = DEFAULT_MESSAGE_PREFIX;
	@track content = "";
	@track blnChiliPiper = false;
	@track chilipiperLink = "";

	connectedCallback() {
		if (!this.isAgent) {
			return;
		}

		const messageTypePrefixPosition = SUPPORTED_MESSAGE_PREFIX.indexOf(this.messageContent.value.split(":")[0]);
		if (messageTypePrefixPosition > -1) {
			this.messageType = SUPPORTED_MESSAGE_PREFIX[messageTypePrefixPosition];
		}
		const contentValue = this.messageContent.value.split(this.messageType + ":").length === 1 ? this.messageContent.value : this.messageContent.value.split(this.messageType + ":")[1];
		Promise.all([loadStyle(this, chatMessageStyle)]);
		if (this.isPlainText) {
			this.content = contentValue;
		} else if (this.isRichText) {
			this.content = contentValue
				.replace(/&lt;/g, "<")
				.replace(/&gt;/g, ">")
				.replace(/&quot;/g, '"')
				.replace(/<a href='mailto:.*?' target='_blank'>(.*?)<\/a>/g, "$1")
				.replace(/<a href='/g, "")
				.replace(/' target='_blank'.*?<\/a>( +)/g, "$1")
				.replace(/' target='_blank'.*?<\/a>.*?<\/a>/g, "");
		} else if (this.isChiliPiper) {
			this.content = "";
			this.blnChiliPiper = true;
			this.chilipiperLink = contentValue.substring(9, 99);
		}
	}

	get isAgent() {
		return this.userType === "agent";
	}

	get isPlainText() {
		return this.messageType === DEFAULT_MESSAGE_PREFIX;
	}

	get isRichText() {
		return this.messageType === RICHTEXT_MESSAGE_PREFIX;
	}

	get isChiliPiper() {
		return this.messageType === CHILIPIPER_MESSAGE_PREFIX;
	}
}