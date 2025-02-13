({
	doInit: function (component, event, helper) {
		var pageRef = component.get("v.pageReference");
		if (pageRef != null) {
			var state = pageRef.state;
			var base64Context = state.inContextOfRef;
			if (base64Context.startsWith("1.")) {
				base64Context = base64Context.substring(2);
			}
			var addressableContext = JSON.parse(window.atob(base64Context));
			var recordId = addressableContext.attributes.recordId;
			component.set("v.recordId", recordId);
		}
	}
});