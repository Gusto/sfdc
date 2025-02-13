/**
 * @name         : CarrierOrderGroupNumberKafkaCallout
 * @author       : Ajay Kumar Vijay
 * @date         : 07-20-2023
 * @description  : Sends the group number to workato when confirmation group number is populated on a Carrier Order
 **/
public with sharing class CarrierOrderGroupNumberKafkaCallout {
	@InvocableMethod(
        callout=true
        label='Send Carrier Order Group Number To Kafka'
        description='Sends the group number to kafka when group number is populated or updated on a Carrier Order'
    )
	public static void sendGroupNumber(List<Request> list_InputRequests) {
		Request objInputRequest = list_InputRequests[0];

		Http objHttp = new Http();
		HttpRequest objRequest = new HttpRequest();
		String strBody =
			'{"carrierGroupNumber": "' +
			objInputRequest.strCarrierGroupNumber +
			'", "gustoCompanyId": "' +
			objInputRequest.strZpCompanyId +
			'", "stateCarrierId": "' +
			objInputRequest.strHICarrierId +
			'"}';
		objRequest.setEndpoint('callout:Salesforce_Kafka_Group_Number');
		objRequest.setMethod('POST');
		objRequest.setHeader('Content-Type', 'application/json');
		objRequest.setHeader('API-TOKEN', '{!$Credential.Password}');
		objRequest.setBody(strBody);
		
		if(!Test.isRunningTest()) {
			objHttp.send(objRequest);
		}
	}

	/**
	 * @Author      : Ajay Kumar Vijay
	 * @Description : Request Object Defintion. Used for input parameters for invocable method.
	 **/
	public class Request {
		@InvocableVariable(label='Carrier Group Number' description='Carrier Group Number' required=true)
		public String strCarrierGroupNumber;

		@InvocableVariable(label='HI Carrier Id' description='HI Carrier Id' required=true)
		public String strHICarrierId;

		@InvocableVariable(label='ZP Company Id' description='ZP Company Id' required=true)
		public String strZpCompanyId;

		public Request(String strCarrierGroupNumber, String strHICarrierId, String strZpCompanyId) {
			this.strCarrierGroupNumber = strCarrierGroupNumber;
			this.strHICarrierId = strHICarrierId;
			this.strZpCompanyId = strZpCompanyId;
		}

		public Request() {}
	}
}