({
	handlePlay: function (cmp, event, helper) {
		// on button click, call apex method to serve next record
		helper.handleServeRecord(cmp, null);
	},

	doInit: function (cmp, event, helper) {
		// on load, decide the source of the component where it is placed
		var origin = String(event.getSource());
		let source = "";

		if (origin && origin.includes("util")) {
			source = "utility";
		} else if (origin && origin.includes("forceChatter:lightningComponent")) {
			source = "quickAction";
		}
		cmp.set("v.strSource", source);
		// if the source is quick action, set body to invisible and call handlePlay
		if (source == "quickAction") {
			cmp.set("v.blnBodyVisible", false);
			var functionCall = cmp.get("c.handlePlay");
			$A.enqueueAction(functionCall);
		}
	}
});