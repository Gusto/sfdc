public class GFTicketAdditionalInfoJSON{
    public String accounting_firm_id;
	public String employee_ids;	//7750208167620506
	public String tax_id;
	public cls_external_comment external_comment;
	public String[] verification_steps;
	public String doc_request_status;
	public String notice_period;
	public String agency_slug;
	public String is_in_app_notice;
	public String notice_type;
	public String payment_due_date;
	public String penalty_amount;
	public String benefit_adjustment_request_id;
	public String is_wallet_app;
	
	public class cls_external_comment {
		public boolean isPublic;
		public String html_body; 
	}

	public static GFTicketAdditionalInfoJSON parse(String json){
		return (GFTicketAdditionalInfoJSON) System.JSON.deserialize(json, GFTicketAdditionalInfoJSON.class);
	}

}