/**
 * @name         HIGroupTerminationCaseJSON
 * @author       Rushi R
 * @date         31 May 2023
 * @description  JSON structure for HIGroupEvent.Event_Info for group_termination_case events
 * @test classes HIGroupEventTerminationCasesTest
 **/
public class HIGroupTerminationCaseJSON {
	public String event_id; // store as integration id on case
	public String event_type;
	public String termination_type; // Carrier Switch, Full Termination, BoR Away
	public String termination_reason; //Reason input by advisor or customer in termination flow
	public String group_termination_event_id; // id of the group term event
	public String company_id; // ZP Company ID
	public String application_id; // ID of the renewal object if the term is related to a group still renewing with Gusto, can be null
	public String application_type; // New Plan, Renewal, Change
	public String company_hippo_link;
	public String terminating_provider_key; // carrier key of the carrier to be terminated, can be null. "Alegeus" and "BASIC" are possible values
	public String new_provider_key; // carrier key of the new carrier if this is a carrier switch, can be null
	public String group_number; // group number on file for the carrier to be terminated, can be null
	public List<String> benefit_types; // Medical, Dental, Vision, Life, Long Term Disability, Short Term Disability, FSA, DCA, HSA
	public String termination_deadline; // Date termination needs to be submitted to carrier by
	public String coverage_end_date; // Date coverage ends for the group
	public String contact_id; // employee ID for the benefits signatory OR user who went through the in-app flow to term group benefits, can be null
	public String form_link;

	// Sample - BBO-972
	/* {
		"event_id": "slwoeifwi-293iwk-oweif",
		"event_type": "group_termination_case",
		"termination_type": "Carrier Switch",
		"termination_reason": "The company is being dissolved.",
		"group_termination_event_id": "03980",
		"company_id": "786780989909",
		"application_id": "78090",
		"application_type": "Renewal",
		"company_hippo_link": "https://hippo.gusto.com/companies/7757616924743905",
		"terminating_provider_key": "guardian_ca",
		"new_provider_key": "beam_ca",
		"group_number": "9X780980",
		"benefit_types": [
			"Dental"
		],
		"termination_deadline": "2023-05-27",
		"coverage_end_date": "2023-06-01",
		"contact_id": "78809987809",
		"form_link": "https://hippo.gusto.com/attachments/forms/6308864"
	} */
}