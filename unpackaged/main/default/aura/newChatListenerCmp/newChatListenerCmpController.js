({
	onWorkAssigned: function (component, event, helper) {
		console.log("work assigned");
		if (!window.Notification) {
			console.log("Browser does not support notifications.");
		} else {
			console.log("else");
			// check if permission is already granted
			if (Notification.permission === "granted") {
				console.log("granted");
				// show notification here
				var notify = new Notification("You have a new chat request!", {});
			} else {
				// request permission from user
				Notification.requestPermission()
					.then(function (p) {
						console.log("request");
						if (p === "granted") {
							// show notification here
							var notify = new Notification("You have a new chat request!", {});
						} else {
							console.log("User blocked notifications.");
						}
					})
					.catch(function (err) {
						console.error(err);
					});
			}
		}
	}
});