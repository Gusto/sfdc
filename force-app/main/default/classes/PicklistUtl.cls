/**
 * Created by brent.johnson on 3/30/16.
 */

global class PicklistUtl {
	private PicklistRequest request;
	private PicklistResult result;
	private List<PicklistEntry> entries;

	@InvocableMethod(Label='Next Field Value' description='Returns next value for the provided fieldName')
	public static List<PicklistResult> getNext(List<PicklistRequest> requests) {
		List<PicklistResult> results = new List<PicklistResult>();
		for (PicklistRequest request : requests) {
			results.add(new PicklistUtl(request).offset(1));
		}
		return results;
	}

	public static PicklistResult getNext(PicklistRequest request) {
		return new PicklistUtl(request).offset(1);
	}

	private PicklistUtl(PicklistRequest request) {
		this.request = request;
		this.result = new PicklistResult();
		this.entries = getPicklistEntries();
	}

	private List<PicklistEntry> getPicklistEntries() {
		List<PicklistEntry> entries;
		try {
			entries = Utils.getSObjectDescribe(request.objectName).fields.getMap().get(request.fieldName).getDescribe().getPicklistValues();
		} catch (Exception ex) {
			handleException(ex);
		}
		return entries;
	}

	private PicklistResult offset(Integer offset) {
		try {
			offset += getCurrentIndex();
			result.setValue(entries.get(offset).getValue());
		} catch (Exception ex) {
			handleException(ex);
		}
		return result;
	}

	private Integer getCurrentIndex() {
		Integer i = 0;
		do {
			if (entries.get(i).getValue() == request.currentValue)
				break;
			i++;
		} while (i < entries.size());
		return i;
	}

	private void handleException(Exception ex) {
		ex.setMessage('\n*Object:* ' + request.objectName + '\n*Field:* ' + request.fieldName + '\n*Current Value:* ' + request.currentValue);
		this.result.setSuccess(false);
		this.result.setMessage(ex.getMessage());
		ExceptionHandler.notify(ex);
	}

	global class PicklistRequest {
		@InvocableVariable(required=true)
		public String objectName;

		@InvocableVariable(required=true)
		public String fieldName;

		@InvocableVariable(required=true)
		public String currentValue;
	}

	global class PicklistResult {
		@InvocableVariable
		public Boolean success;

		@InvocableVariable
		public String message;

		@InvocableVariable
		public String value;

		public PicklistResult() {
			success = true;
			message = 'success';
			value = '';
		}

		public void setSuccess(Boolean success) {
			this.success = success;
		}

		public void setMessage(String message) {
			this.message = message;
		}

		public void setValue(String value) {
			this.value = value;
		}

		public Boolean isSuccess() {
			return this.success;
		}

		public String getMessage() {
			return this.message;
		}

		public String getValue() {
			return this.value;
		}
	}
}