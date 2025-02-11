({
	isValidURL: function (strUrl) {
		const pattern = new RegExp(
			"^(https?:\\/\\/)?" +
				"((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|" +
				"((\\d{1,3}\\.){3}\\d{1,3}))" +
				"(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*" +
				"(\\?[;&a-z\\d%_.~+=-]*)?" +
				"(\\#[-a-z\\d_]*)?$",
			"i"
		);
		return Boolean(pattern.test(strUrl));
	},

	showToast: function (type, title, message, mode) {
		type = type || "error";
		mode = mode || "dismissible";

		$A.get("e.force:showToast")
			.setParams({
				type,
				title,
				message,
				mode
			})
			.fire();
	}
});