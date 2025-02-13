/* eslint-disable prettier/prettier */
({
	handlePreview: function (component, event) {
		component.set("v.fileId", event.getParam("data"));
		component.set("v.viewOperationType", true);
		component.set("v.showModal", true);
	},

	handleDownload: function (component, event, helper) {
		component.set("v.fileId", event.getParam("data"));
		component.set("v.viewOperationType", false);
		component.set("v.showModal", true);
	},

	modalClose: function (component, event, helper) {
		component.set("v.showModal", false);
		component.set("v.modalRecordId", "");
	}
});