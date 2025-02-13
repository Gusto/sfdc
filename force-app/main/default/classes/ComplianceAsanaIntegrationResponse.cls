/**
 * @description  The below Class is the Insert response wrapper class for SendComplianceToAsanaRouting
 * @author       Sindhu
 * @date         06-12-2024
 **/
public class ComplianceAsanaIntegrationResponse {

	public String status;
	public String event_id;
	public Message message;
    public String error_message;
	public class Message {
		public String asana_task_id;
	}
    
	public static ComplianceAsanaIntegrationResponse parse(String json) {
		return (ComplianceAsanaIntegrationResponse) System.JSON.deserialize(json, ComplianceAsanaIntegrationResponse.class);
	}
}