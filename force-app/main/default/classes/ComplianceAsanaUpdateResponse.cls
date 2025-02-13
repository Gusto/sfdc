/**
 * @description  The below Class is the  update response wrapper class for SendComplianceToAsanaRouting
 * @author       Sindhu
 * @date         06-15-2024
 **/
public class ComplianceAsanaUpdateResponse {

	public String status;
	public String event_id;
	public String message;
	public String error_message;

	public static ComplianceAsanaUpdateResponse parse(String json) {
		return (ComplianceAsanaUpdateResponse) System.JSON.deserialize(json, ComplianceAsanaUpdateResponse.class);
	}
}