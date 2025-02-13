/**
 * @name         : CarrierOrderCensusExportReqKafkaCallout
 * @author       : Ajay Kumar Vijay
 * @date         : 07-21-2023
 * @description  : Sends the request for Carrier Order Census Export.
 **/
public with sharing class CarrierOrderCensusExportReqKafkaCallout {
	@InvocableMethod(
        callout=true
        label='Carrier Order Census Export Request'
        description='Sends the request for Carrier Order Census Export'
    )
	public static void carrierOrderCensusExportRequest(List<Request> list_InputRequests) {
		Request objInputRequest = list_InputRequests[0];

		Http objHttp = new Http();
		HttpRequest objRequest = new HttpRequest();
		String body =
			'{"applicationType": "' +
			objInputRequest.strApplicationType +
			'", "applicationId": "' +
			objInputRequest.strApplicationId +
			'", "companyId": "' +
			objInputRequest.strCompanyId +
			'"}';
		objRequest.setEndpoint('callout:Salesforce_Kafka_Census_Export');
		objRequest.setMethod('POST');
		objRequest.setHeader('Content-Type', 'application/json');
		objRequest.setBody(body);

		if(!Test.isRunningTest()) {
			objHttp.send(objRequest);
		}
	}

	/**
	 * @Author      : Ajay Kumar Vijay
	 * @Description : Request Object Defintion. Used for input parameters for invocable method.
	 **/
	public class Request {
		@InvocableVariable(label='Application Type' description='Application Type' required=true)
		public String strApplicationType;

		@InvocableVariable(label='Application Id' description='Application Id' required=true)
		public String strApplicationId;

		@InvocableVariable(label='Company Id' description='Company Id' required=true)
		public String strCompanyId;

		public Request(String strApplicationType, String strApplicationId, String strCompanyId) {
			this.strApplicationType = strApplicationType;
			this.strApplicationId = strApplicationId;
			this.strCompanyId = strCompanyId;
		}

		public Request() {}
	}
}