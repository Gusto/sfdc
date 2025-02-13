/**
 * Created by brent.johnson on 3/31/16.
 */
//String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'))
global class ExceptionHandler {
	private Exception ex;
	private HttpRequest request;

	public static void notify(Exception ex) {
		new ExceptionHandler(ex).sendNotification();
	}

	private ExceptionHandler(Exception ex) {
		request = new HttpRequest();
		this.ex = ex;
	}

	private void sendNotification() {
		setEndpoint();
		setMethod();
		setBody();
		Http http = new Http();
		if (!Test.isRunningTest()) {
			http.send(request);
		}
	}

	private void setMethod() {
		request.setMethod('POST');
	}

	private void setEndpoint() {
		String channel = 'sfdc_';
		if (OrganizationUtilities.isProduction()) {
			channel += 'production';
		} else {
			channel += 'development';
		}
		request.setEndpoint('callout:' + channel);
	}

	private void setBody() {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeStringField('token', 'xoxp-2170599925-10028884753-10583507666-62e1e6d100');
		gen.writeStringField('link_names', '1');
		gen.writeStringField('text', new SlackMessage(ex, 'ExceptionHandler').getMessage());
		gen.writeEndObject();
		String body = gen.getAsString();
		request.setBody(body);
	}

	private class SlackMessage {
		private String apexClass;
		private String exType;
		private String line;
		private String exMessage;
		private String userName;
		private String timestamp;
		private String stackTrace;

		public SlackMessage(Exception ex, String sourceClass) {
			apexClass = sourceClass;
			exType = ex.getTypeName();
			line = String.valueOf(ex.getLineNumber());
			exMessage = ex.getMessage();
			userName = UserInfo.getName();
			timestamp = System.now().formatLong();
			stackTrace = ex.getStackTraceString();
		}

		public String getMessage() {
			String message;
			if (apexClass != null) {
				message = '*Apex Class*: ' + apexClass + '\n';
			}
			if (exType != null) {
				message += '*' + exType + '*';
			}
			if (line != null) {
				message += '[' + line + '] ';
			}
			if (exMessage != null) {
				message += exMessage + '\n';
			}
			if (userName != null) {
				message += userName;
			}
			if (timestamp != null) {
				message += ' on ' + timestamp;
			}
			if (stackTrace != null) {
				message += '\n\n' + stackTrace;
			}
			return message;
		}
	}
}