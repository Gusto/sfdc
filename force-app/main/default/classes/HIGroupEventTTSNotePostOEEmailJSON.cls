/**
 * @name         HIGroupEventTTSNotePostOEEmailJSON
 * @author       Deepika Saini
 * @date         10-04-2021
 * @description  JSON structure for HIGroupEvent.Event_Info for tts_note_post_oe_email events
 * @test classes HIGroupEventTTSNotePostOEEmailTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class HIGroupEventTTSNotePostOEEmailJSON {
	public String event_id;
	public String company_id;
	public String application_id;
	public String application_type;
	public String event_type;
	public List<GhostPlans> ghost_plans;
	public String encrypted_continuation_ee_notes;
	public String encrypted_additional_details;
	public Boolean riders;
	public String er_signature_location;
	public String encrypted_poa_signatory_name;
	public String poa_signatory_title;
	public String encrypted_benefits_admin_name;
	public String benefits_admin_title;
	public String company_name;

	/**
	 * @name         GhostPlans
	 * @author       Bhagat Singh
	 * @date         11-11-2021
	 * @description  JSON structure for GhostPlans
	 * @test classes HIGroupEventTTSNotePostOEEmailTest
	 * @revisions    Date ------------ Name ------------ Comments
	 **/
	public class GhostPlans {
		public String carrier_name;
		public List<String> plan_details;
	}
}