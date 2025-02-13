@isTest
private class GFTicketAdditionalInfoJSONTest {
	
	@isTest
    static void testJSONParse() {
        String jsonStr = '{"external_comment":{"isPublic":true, "html_body":"test Body"}, "accounting_firm_id": "1111111111", "employee_ids":"222222222", "tax_id":"333333333", "doc_request_status":"Pending", "is_wallet_app":true}';
        
        //GFTicketAdditionalInfoJSON parsedData = (GFTicketAdditionalInfoJSON)JSON.deserialize(jsonStr.replace('=>',': '), GFTicketAdditionalInfoJSON.class);
        
        GFTicketAdditionalInfoJSON.parse(jsonStr);
    }
    
}