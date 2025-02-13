public class GenesysCallbackIntegration {
	public string sumitCallBack(
		String queueId,
		String phone,
		String name,
		String requestedTime,
		String loggedInUserName,
		String caseId,
		Boolean userCallBack,
		String auth,
		String authPath,
		String interactionID,
		String userSkillId,
		String CaseNumber,
		String strCaseOrigin
	) {
		String jsonRequest = getJsonRequest(queueId, phone, name, requestedTime, loggedInUserName, caseId, userCallBack, auth, authPath, interactionID, userSkillId, CaseNumber, strCaseOrigin);
		HttpRequest req = createRequest(jsonRequest);
		String responseJSON = sendRequest(req);
		return responseJSON;
	}

	private string getJsonRequest(
		String queueId,
		String phone,
		String name,
		string requestedTime,
		String loggedInUserName,
		String caseId,
		Boolean userCallBack,
		String auth,
		String authPath,
		String interactionID,
		String userSkillId,
		String CaseNumber,
		String strCaseOrigin
	) {
		string jsonRequest = '{' + '"queueId": "' + queueId + '",' + '"callbackUserName": "' + name + '",' + '"callbackNumber": "' + phone + '",';
		if (requestedTime == null || requestedTime == '') {
			jsonRequest += '"RequestedTime": null,';
		} else {
			jsonRequest += '"RequestedTime": "' + requestedTime + '",';
		}

		jsonRequest += '"SFUser": "' + loggedInUserName + '",' + '"CaseID": "' + caseId + '",' + '"CaseNumber": "' + CaseNumber + '",' + '"UserCallback": ' + userCallBack + ',';

		if (auth == null || auth == '') {
			jsonRequest += '"Auth": null,';
		} else {
			jsonRequest += '"Auth": "' + auth + '",';
		}
		if (authPath == null || authPath == '') {
			jsonRequest += '"AuthPath": null,';
		} else {
			jsonRequest += '"AuthPath": "' + authPath + '",';
		}
		if (interactionID == null || interactionID == '') {
			jsonRequest += '"InteractionID": null,';
		} else {
			jsonRequest += '"InteractionID": "' + interactionID + '",';
		}
		if (userSkillId == null || userSkillId == '') {
			jsonRequest += '"SFUserPersonalSkillID": null,';
		} else {
			jsonRequest += '"SFUserPersonalSkillID": "' + userSkillId + '",';
		}
		if (String.isNotBlank(strCaseOrigin)) {
			jsonRequest += '"Origin":  "' + strCaseOrigin + '",';
		}

		jsonRequest += '"Source": "SF"';
		jsonRequest += '}';
		return jsonRequest;
	}

	public HttpRequest createRequest(String body) {
		Integration_System_Information__c integInfo = new Integration_System_Information__c();
		String url = '';
		String username = '';
		String password = '';
		String authorizationHeader = '';

		integInfo = IntegrationUtils.getIntegrationSystemInfo('GenesysCallBack');
		url = integInfo.Url__c;
		username = integInfo.User_Name__c;
		password = integInfo.Password__c;

		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setHeader('API-TOKEN', password);
		req.setEndpoint(url);

		req.setTimeout(12 * 1000);
		req.setHeader('Accept', 'application/json');
		req.setHeader('Content-Type', 'application/json');

		if (body != null) {
			req.setBody(body);
		}

		return req;
	}

	// Send an API Request
	public String sendRequest(HttpRequest req) {
		HttpResponse res;

		if (!test.isRunningTest()) {
			res = new Http().send(req);
		}

		return (res != null ? res.getBody() : 'Success');
	}
}