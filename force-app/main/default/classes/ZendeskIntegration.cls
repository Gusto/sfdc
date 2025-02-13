public class ZendeskIntegration {
	private static Map<String, String> statusMap = new Map<String, String>{
		'Draft' => 'New',
		'New' => 'New',
		'Open' => 'New',
		'Pending' => 'Pending',
		'Solved' => 'Pending',
		'Submitted' => 'Pending',
		'Followup Completed' => 'Pending',
		'Invoice Reconciliation Completed' => 'Pending',
		'Closed' => 'Solved',
		'Cancelled' => 'Solved'
	};

	public HttpRequest createRequest(String reqMethod, String body, String fullPath, String app) {
		Integration_System_Information__c integInfo = new Integration_System_Information__c();
		String path = '';
		String username = '';
		String password = '';
		String authorizationHeader = '';
		if (app != 'ApIntego') {
			integInfo = IntegrationUtils.getIntegrationSystemInfo('Zendesk');
			path = integInfo.Url__c;
			username = integInfo.User_Name__c;
			password = integInfo.Password__c;
			authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
		} else {
			integInfo = IntegrationUtils.getIntegrationSystemInfo('ApIntego-Zendesk');
			path = integInfo.Url__c;
			username = integInfo.User_Name__c;
			password = integInfo.Password__c;
			authorizationHeader = 'Bearer ' + password;
		}
		String endPoint = '';
		if (fullPath.indexOf('https') > -1) {
			endPoint = fullPath;
		} else {
			endPoint = 'https://' + path + fullPath;
		}

		HttpRequest req = new HttpRequest();
		req.setMethod(reqMethod);
		req.setHeader('Authorization', authorizationHeader);
		req.setEndpoint(endpoint);

		if (reqMethod == 'POST' || reqMethod == 'PUT') {
			req.setTimeout(12 * 1000);
			req.setHeader('Accept', 'application/json');
			req.setHeader('User-Agent', 'Zendesk API for Salesforce');
			req.setHeader('Content-Type', 'application/json');
		}

		if (body != null) {
			req.setBody(body);
		}

		return req;
	}

	// Send an API Request
	public String sendRequest(HttpRequest req) {
		// Send it
		HttpResponse res = new Http().send(req);
		// Track it
		// Validate the response - anything outside the 200 range will result in an exception
		if (res.getStatusCode() < 200 || res.getStatusCode() > 299) {
			if (res.getStatusCode() == 429) {
				String retrySeconds = res.getHeader('Retry-After');
				throw new ZendeskException('Rate Limit Exception. Try after ' + retrySeconds);
			}
		}

		return res.getBody();
	}

	public String getTicketPayload(ZendeskTicket ticket) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('ticket');

		gen.writeStartObject();
		if (ticket.id != null) {
			gen.writeStringField('id', ticket.id);
		}
		String subject = '';
		if (ticket.subject != null) {
			subject = ticket.subject;
		}
		gen.writeStringField('subject', subject);
		gen.writeStringField('type', ticket.type);
		gen.writeStringField('priority', 'low');
		if (ticket.requester != null && ticket.requester.Name != null) {
			gen.writeFieldName('requester');
			gen.writeStartObject();
			gen.writeObjectField('name', ticket.requester.Name);
			if (ticket.requester.email != null) {
				gen.writeObjectField('email', ticket.requester.email);
			}
			gen.writeEndObject();
		}

		//gen.writeFieldName('comment');
		//gen.writeStartObject();
		//    gen.writeObjectField('body', ticket.description);
		//gen.writeEndObject();
		//if(ticket.description!=null){
		//    gen.writeStringField('description',ticket.description);
		//}
		//gen.writeStringField('description','-');
		if (ticket.description != null) {
			//gen.writeStartObject();
			gen.writeFieldName('comment');
			gen.writeStartObject();
			gen.writeObjectField('body', ticket.description);

			//gen.writeObjectField('plain_body', ticket.description);

			gen.writeObjectField('public', false);
			gen.writeObjectField('type', 'Comment');
			gen.writeEndObject();
			//gen.writeEndObject();

			//gen.writeEndArray();
			//gen.writeEndObject();
		}
		if (ticket.status != null) {
			gen.writeStringField('status', ticket.status);
		}
		if (ticket.groupid != null) {
			gen.writeStringField('group_id', ticket.groupid);
		} else {
			gen.writeStringField('group_id', Label.zendesk_group_id);
		}
		if (ticket.tags != null) {
			gen.writeObjectField('tags', ticket.tags);
		}
		/*if(Label.MF_Zendesk_Ticket_From_Id!='-'){
                    gen.writeNumberField('ticket_form_id', Integer.valueOf(Label.MF_Zendesk_Ticket_From_Id));
                }*/

		if (ticket.companyId != null || ticket.companyName != null) {
			gen.writeFieldName('custom_fields');
			gen.writeStartArray();

			if (ticket.companyId != null) {
				gen.writeStartObject();
				gen.writeStringField('id', Label.Zendesk_Company_Id_Field);
				gen.writeStringField('value', ticket.companyId);
				gen.writeEndObject();
			}

			if (ticket.companyName != null) {
				gen.writeStartObject();
				gen.writeStringField('id', Label.Zendesk_Company_Name_Field);
				gen.writeStringField('value', ticket.companyName);
				gen.writeEndObject();
			}

			//if(ticket.status=='Solved'){
			/*
                        gen.writeStartObject();
                        gen.writeStringField('id',Label.Zendesk_Case_Reason_Field);
                        gen.writeStringField('value','other_route');
                        gen.writeEndObject();     
                        gen.writeStartObject();
                        gen.writeStringField('id',Label.Zendesk_Confirm_Case_Reason_Field);
                        gen.writeStringField('value','other_con'); 
                        gen.writeEndObject(); 
                    */
			//}
			gen.writeEndArray();
		}
		gen.writeEndObject();

		//gen.writeEndArray();
		gen.writeEndObject();
		return gen.getAsString();
	}

	public String getUpdateInteractionIdPayload(String ticketId, String interactionId) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('ticket');
		//gen.writeStartArray();

		gen.writeStartObject();
		if (ticketId != null) {
			gen.writeStringField('id', ticketId);
		}

		if (interactionId != null || interactionId != null) {
			gen.writeFieldName('custom_fields');
			gen.writeStartArray();

			gen.writeStartObject();
			gen.writeStringField('id', Label.Zendesk_Genesys_Interaction_Field_Id);
			gen.writeStringField('value', interactionId);
			gen.writeEndObject();

			gen.writeEndArray();
		}
		gen.writeEndObject();

		//gen.writeEndArray();
		gen.writeEndObject();
		return gen.getAsString();
	}

	public String getUserPayload(ZendeskUser user) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('user');
		//gen.writeStartArray();

		gen.writeStartObject();
		if (user.Id != null) {
			gen.writeStringField('id', user.Id);
		}
		if (user.name != null && user.name != '') {
			gen.writeStringField('name', user.name);
		}
		if (user.email != null && user.email != '') {
			gen.writeStringField('email', user.email);
		}

		if ((user.careAccountManager != null && user.careAccountManager != '') || (user.currentProgram != null && user.currentProgram != '')) {
			//gen.writeFieldName('custom_fields');
			gen.writeFieldName('user_fields');
			gen.writeStartObject();
			//gen.writeStartArray();
			if (user.careAccountManager != null && user.careAccountManager != '') {
				//gen.writeStartObject();
				gen.writeStringField('care_account_manager', user.careAccountManager);
				//gen.writeStringField('id',Label.Zendesk_Care_Account_Manager_Field_Id);
				//gen.writeStringField('value',user.careAccountManager);
				//gen.writeEndObject();
			}
			if (user.currentProgram != null && user.currentProgram != '') {
				//gen.writeStartObject();
				gen.writeStringField('current_program', user.currentProgram);
				//gen.writeStringField('id',Label.Zendesk_Current_Program_Field_Id);
				//gen.writeStringField('value',user.currentProgram);
				//gen.writeEndObject();
			}
			//gen.writeEndArray();
			gen.writeEndObject();
		}

		gen.writeEndObject();

		//gen.writeEndArray();
		gen.writeEndObject();
		return gen.getAsString();
	}
	public String getCommentPayload(ZendeskComment comment) {
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		gen.writeFieldName('ticket');
		//gen.writeStartArray();

		gen.writeStartObject();
		/*
                gen.writeFieldName('requester');
                    gen.writeStartObject();
                    gen.writeObjectField('name', comment.requester.Name);
                    gen.writeObjectField('email', comment.requester.email);
                    gen.writeEndObject();
                */
		if (comment.createAsFollowup == true) {
			gen.writeObjectField('via_followup_source_id', comment.ticketId);
		}
		gen.writeFieldName('comment');
		gen.writeStartObject();
		if (comment.html_body != null && comment.html_body != '') {
			gen.writeObjectField('html_body', comment.html_body);
		}
		if (comment.plain_body != null && comment.plain_body != '') {
			gen.writeObjectField('plain_body', comment.plain_body);
		}

		//gen.writeObjectField('body', comment.comment);
		//gen.writeObjectField('public', comment.isPublic);
		gen.writeObjectField('public', false);
		gen.writeObjectField('type', comment.type);
		gen.writeEndObject();
		gen.writeEndObject();

		//gen.writeEndArray();
		gen.writeEndObject();
		return gen.getAsString();
	}

	public ZendeskTicketResponse createZendeskTicket(ZendeskTicket ticket, String app) {
		ZendeskTicketResponse response = new ZendeskTicketResponse();
		String payload = getTicketPayload(ticket);
		String endpoint = '';
		String method = 'POST';
		if (ticket.id == null) {
			endpoint = '.zendesk.com/api/v2/tickets.json';
		} else {
			method = 'PUT';
			endpoint = '.zendesk.com/api/v2/tickets/' + ticket.id + '.json';
		}
		HttpRequest req = createRequest(method, payload, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			response.id = '11111';
			response.ticket_id = '11111';
			response.status = 'Processed';
			response.message = 'Processed';
			return response;
		}
		response = parseCreateTicketResponse(responseJSON);
		return response;
	}

	public ZendeskUserResponse createZendeskUser(ZendeskUser user, String app) {
		ZendeskUserResponse response = new ZendeskUserResponse();
		String payload = getUserPayload(user);
		String endpoint = '';
		String method = 'POST';
		if (user.id == null) {
			endpoint = '.zendesk.com/api/v2/users.json';
		} else {
			method = 'PUT';
			endpoint = '.zendesk.com/api/v2/users/' + user.id + '.json';
		}
		HttpRequest req = createRequest(method, payload, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			response.id = '11111';
			response.status = 'Processed';
			response.message = 'Processed';
			return response;
		}
		response = parseCreateUserResponse(responseJSON);
		return response;
	}

	public ZendeskTicketResponse updateZendeskTicketInteractionId(String ticketId, String interactionId, String app) {
		ZendeskTicketResponse response = new ZendeskTicketResponse();
		String payload = getUpdateInteractionIdPayload(ticketId, interactionId);
		String endpoint = '';
		String method = 'POST';
		if (ticketId == null) {
			return null;
		} else {
			method = 'PUT';
			endpoint = '.zendesk.com/api/v2/tickets/' + ticketId + '.json';
		}
		HttpRequest req = createRequest(method, payload, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			response.id = '11111';
			response.ticket_id = '11111';
			response.status = 'Processed';
			response.message = 'Processed';
			return response;
		}
		response = parseCreateTicketResponse(responseJSON);
		return response;
	}

	public ZendeskTicketResponse createZendeskTicketComment(ZendeskComment comment, String app) {
		ZendeskTicketResponse response = new ZendeskTicketResponse();
		String payload = getCommentPayload(comment);
		String endpoint = '';
		String method = 'PUT';
		if (comment.createAsFollowup == false) {
			endpoint = '.zendesk.com/api/v2/tickets/' + comment.ticketId + '.json';
		} else {
			method = 'POST';
			endpoint = '.zendesk.com/api/v2/tickets.json';
		}

		HttpRequest req = createRequest(method, payload, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			responseJSON = '{"name": "Hello DJs", "id": 211, "url": "https://foo.zendesk.com/api/v2/groups/211.json”}';
		}
		response = parseCreateTicketResponse(responseJSON);
		return response;
	}

	public ZendeskTicketSearchResult searchZendeskTickets(String queryString, String app) {
		ZendeskTicketSearchResult response = new ZendeskTicketSearchResult();

		String endpoint = '';
		String method = 'GET';

		if (queryString.indexOf('.zendesk.com') > -1) {
			endpoint = queryString;
		} else {
			endpoint = '.zendesk.com/api/v2/search.json?query=type:ticket' + queryString;
		}

		HttpRequest req = createRequest(method, null, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			responseJSON = '{"results": [{"name": "Hello DJs", "id": 211,"subject": "test","description": "test","request_type": "test", "url": "test"}]}';
		}
		response = parseSearchTicketResponse(responseJSON);
		return response;
	}

	public ZendeskUserSearchResult searchZendeskUsers(String queryString, String app) {
		ZendeskUserSearchResult response = new ZendeskUserSearchResult();

		String endpoint = '';
		String method = 'GET';

		if (queryString.indexOf('.zendesk.com') > -1) {
			endpoint = queryString;
		} else {
			endpoint = '.zendesk.com/api/v2/search.json?query=' + queryString;
		}

		HttpRequest req = createRequest(method, null, endpoint, app);
		String responseJSON = '';
		if (!Test.isRunningTest()) {
			responseJSON = sendRequest(req);
		} else {
			responseJSON = '{"results": [{"name": "Hello DJs", "id": 211,"subject": "test","description": "test","request_type": "test", "url": "test"}]}';
		}
		response = parseSearchUserResponse(responseJSON);
		return response;
	}

	private ZendeskUserSearchResult parseSearchUserResponse(String jsonString) {
		ZendeskUserSearchResult response = new ZendeskUserSearchResult();
		List<ZendeskUser> userList = new List<ZendeskUser>();
		ZendeskUser user = new ZendeskUser();
		JSONParser parser = JSON.createParser(jsonString);
		boolean idSet = false;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
				if ((parser.getText() == 'error')) {
					response.status = 'Error';
					response.message = jsonString;
					break;
				}
				if ((parser.getText() == 'id' && idSet == false)) {
					if (user.Id != null) {
						userList.add(user);
						user = new ZendeskUser();
					}
					idSet = true;
					parser.nextToken();
					user.id = parser.getText();
				}
				if ((parser.getText() == 'name')) {
					parser.nextToken();
					user.name = parser.getText();
				}
				if ((parser.getText() == 'count')) {
					parser.nextToken();
					response.recordCount = integer.valueOf(parser.getText());
				}
				if ((parser.getText() == 'count')) {
					parser.nextToken();
					response.recordCount = integer.valueOf(parser.getText());
				}
				if ((parser.getText() == 'next_page')) {
					parser.nextToken();
					response.nextPage = parser.getText();
				}
			}
		}
		if (user.Id != null) {
			userList.add(user);
			user = new ZendeskUser();
		}
		response.users = userList;
		return response;
	}

	private ZendeskTicketResponse parseCreateTicketResponse(String jsonString) {
		ZendeskTicketResponse response = new ZendeskTicketResponse();

		JSONParser parser = JSON.createParser(jsonString);
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
				if (parser.getText().indexOf('error') > -1) {
					if (jsonString.indexOf(': closed prevents ticket update') > -1) {
						response.status = IntegrationUtils.PROCESSED_STATE;
						response.message = jsonString;
						break;
					}
					response.status = 'Error';
					response.message = jsonString;
					break;
				}
				if ((parser.getText() == 'id')) {
					parser.nextToken();
					response.id = parser.getText();
					response.message = jsonString;
					response.status = 'Processed';
					break;
				}
			}
		}
		return response;
	}

	private ZendeskUserResponse parseCreateUserResponse(String jsonString) {
		ZendeskUserResponse response = new ZendeskUserResponse();

		JSONParser parser = JSON.createParser(jsonString);
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
				if (parser.getText().indexOf('error') > -1) {
					if (jsonString.indexOf(': closed prevents ticket update') > -1) {
						response.status = IntegrationUtils.PROCESSED_STATE;
						response.message = jsonString;
						break;
					}
					response.status = 'Error';
					response.message = jsonString;
					break;
				}
				if ((parser.getText() == 'id')) {
					parser.nextToken();
					response.id = parser.getText();
					response.message = jsonString;
					response.status = 'Processed';
					break;
				}
			}
		}
		return response;
	}

	private ZendeskTicketSearchResult parseSearchTicketResponse(String jsonString) {
		ZendeskTicketSearchResult response = new ZendeskTicketSearchResult();
		List<ZendeskTicket> ticketList = new List<ZendeskTicket>();
		ZendeskTicket ticket = new ZendeskTicket();
		JSONParser parser = JSON.createParser(jsonString);
		boolean idSet = false;
		while (parser.nextToken() != null) {
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
				if ((parser.getText() == 'error')) {
					response.status = 'Error';
					response.message = jsonString;
					break;
				}
				if ((parser.getText() == 'url')) {
					ticket = new ZendeskTicket();
				}
				if ((parser.getText() == 'id' && idSet == false)) {
					idSet = true;
					parser.nextToken();
					ticket.id = parser.getText();
				}
				if ((parser.getText() == 'subject')) {
					parser.nextToken();
					ticket.subject = parser.getText();
				}
				if ((parser.getText() == 'description')) {
					parser.nextToken();
					ticket.description = parser.getText();
				}
				if ((parser.getText() == 'result_type')) {
					ticketList.add(ticket);
					ticket = new ZendeskTicket();
					idSet = false;
				}
				if ((parser.getText() == 'count')) {
					parser.nextToken();
					response.recordCount = integer.valueOf(parser.getText());
				}
				if ((parser.getText() == 'count')) {
					parser.nextToken();
					response.recordCount = integer.valueOf(parser.getText());
				}
				if ((parser.getText() == 'next_page')) {
					parser.nextToken();
					response.nextPage = parser.getText();
				}
			}
		}
		response.tickets = ticketList;
		return response;
	}

	public static void processCaseInformation(List<Zendesk_Integration_Queue__c> messagesList) {
		/***********Processing Case Information**************/
		Set<id> caseIdSet = new Set<id>();
		List<Case> caseList = new List<Case>();
		List<Zendesk_Integration_Queue__c> queueUpdateList = new List<Zendesk_Integration_Queue__c>();
		map<String, Zendesk_Integration_Queue__c> integrationMap = new Map<String, Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c message : messagesList) {
			caseIdSet.add(message.Case_Id__c);
			integrationMap.put(message.Case_Id__c, message);
		}

		map<Id, Case> caseMap = new Map<Id, Case>(
			[
				SELECT id, AccountId, status, Account.Name, Account.ZP_Company_ID__c, CaseNumber, Zendesk_Id__c, Subject, Priority, Type, ContactId, Contact.name, Contact.Email, Description
				FROM case
				WHERE id IN :caseIdSet
			]
		);
		for (Zendesk_Integration_Queue__c queue : messagesList) {
			if (queue.case_id__c == null || queue.case_id__c == '') {
				queue = setProcessingState('Error', 'Case Id does not exist', queue);
				queueUpdateList.add(queue);
				continue;
			}
			if (!caseMap.containskey(queue.case_id__c)) {
				queue = setProcessingState(IntegrationUtils.PROCESSED_STATE, 'Case does not exist', queue);
				queueUpdateList.add(queue);
				continue;
			}
			Case c = caseMap.get(queue.case_id__c);
			Zendesk_Integration_Queue__c msgQueue = new Zendesk_Integration_Queue__c(id = queue.id);
			ZendeskIntegration integration = new ZendeskIntegration();
			ZendeskIntegration.ZendeskTicket ticket = new ZendeskIntegration.ZendeskTicket();

			ticket.subject = c.subject;
			String description = '-';
			if (c.description != null && c.description != '') {
				description = c.description;
			}
			ticket.description = description;
			ZendeskIntegration.ZendeskUser user = new ZendeskIntegration.ZendeskUser();
			user.name = c.Contact.Name;
			user.email = c.Contact.Email;
			ticket.requester = user;
			ticket.type = 'task'; //c.Type.tolowercase();
			ticket.priority = c.Priority.tolowercase();
			ticket.externalTicketNumber = c.CaseNumber;
			String status = statusMap.get(c.Status);
			ticket.status = status.tolowercase();
			ticket.externalTicketId = c.Id;
			ticket.companyId = c.Account.Zp_Company_id__c;
			ticket.companyName = c.Account.Name;
			if (c.Zendesk_Id__c != null) {
				ticket.id = '' + c.Zendesk_Id__c;
			} else {
				ticket.tags = c.Type;
			}
			ZendeskIntegration.ZendeskTicketResponse response = integration.createZendeskTicket(ticket, queue.Zendesk_Instance__c);
			if (response.status == 'Processed') {
				if (c.Zendesk_Id__c == null || c.Zendesk_Id__c == '') {
					c.Zendesk_Id__c = response.id;
					caseList.add(c);
				}
			}
			msgQueue.Processing_State__c = response.status;
			msgQueue.Message__c = response.Message;
			queueUpdateList.add(msgQueue);
		}
		if (caseList.size() > 0) {
			update caseList;
		}
		if (queueUpdateList.size() > 0) {
			update queueUpdateList;
		}
	}

	public static void processCaseEmailInformation(List<Zendesk_Integration_Queue__c> messagesList) {
		/***********Processing Case Email Information**************/
		Set<id> caseIdSet = new Set<id>();
		Set<id> emailMessageIdSet = new Set<id>();
		List<EmailMessage> emailMessageList = new List<EmailMessage>();
		List<Zendesk_Integration_Queue__c> queueUpdateList = new List<Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c message : messagesList) {
			caseIdSet.add(message.Case_Id__c);
			emailMessageIdSet.add(message.Object_Id__c);
		}
		map<Id, Case> caseMap = new Map<Id, Case>(
			[SELECT id, AccountId, Account.ZP_Company_ID__c, CaseNumber, Zendesk_Id__c, Subject, Priority, Type, ContactId, Contact.name, Contact.Email, Description FROM case WHERE id IN :caseIdSet]
		);
		map<Id, EmailMessage> emailMessageMap = new Map<Id, EmailMessage>(
			[
				SELECT
					ActivityId,
					CreatedById,
					CreatedDate,
					FromAddress,
					FromName,
					HasAttachment,
					HtmlBody,
					Id,
					Incoming,
					IsDeleted,
					MessageDate,
					ParentId,
					RelatedToId,
					ReplyToEmailMessageId,
					Status,
					Subject,
					TextBody
				FROM EmailMessage
				WHERE id IN :emailMessageIdSet
			]
		);
		for (Zendesk_Integration_Queue__c queue : messagesList) {
			if (queue.case_id__c == null || queue.case_id__c == '') {
				queue = setProcessingState('Error', 'Case Id does not exist', queue);
				continue;
			}
			if (!caseMap.containskey(queue.case_id__c)) {
				queue = setProcessingState(IntegrationUtils.ERROR_STATE, 'Case does not exist', queue);
				continue;
			}
			Case c = caseMap.get(queue.case_id__c);
			if (c.Zendesk_Id__c == null || c.Zendesk_Id__c == '') {
				queue = setProcessingState(IntegrationUtils.ERROR_STATE, 'Zendesk Id is blank', queue);
				continue;
			}

			EmailMessage msg = emailMessageMap.get(queue.Object_Id__c);
			Zendesk_Integration_Queue__c msgQueue = new Zendesk_Integration_Queue__c(id = queue.id);
			ZendeskIntegration integration = new ZendeskIntegration();
			ZendeskIntegration.ZendeskComment comment = new ZendeskIntegration.ZendeskComment();

			comment.ticketId = c.Zendesk_Id__c;
			if (msg.HtmlBody != null) {
				comment.html_body = msg.HtmlBody;
			} else {
				comment.plain_body = msg.TextBody;
			}
			comment.createAsFollowup = queue.Create_As_Followup__c;

			comment.isPublic = 'false';
			comment.type = 'Comment';
			ZendeskIntegration.ZendeskUser user = new ZendeskIntegration.ZendeskUser();
			user.name = msg.FromName;
			user.email = msg.FromAddress;
			comment.requester = user;
			ZendeskIntegration.ZendeskTicketResponse response = integration.createZendeskTicketComment(comment, queue.Zendesk_Instance__c);
			msgQueue.Processing_State__c = response.status;
			msgQueue.Message__c = response.Message;
			queueUpdateList.add(msgQueue);
		}
		if (queueUpdateList.size() > 0) {
			update queueUpdateList;
		}
	}

	public static void processCaseChatterInformation(List<Zendesk_Integration_Queue__c> messagesList) {
		/***********Processing Case Chatter Information**************/
		Set<id> caseIdSet = new Set<id>();
		Set<id> feedItemIdSet = new Set<id>();
		Set<id> createdByIdSet = new Set<id>();
		List<FeedItem> feedItemList = new List<FeedItem>();
		List<Zendesk_Integration_Queue__c> queueUpdateList = new List<Zendesk_Integration_Queue__c>();
		for (Zendesk_Integration_Queue__c message : messagesList) {
			caseIdSet.add(message.Case_Id__c);
			feedItemIdSet.add(message.Object_Id__c);
			createdByIdSet.add(message.CreatedById);
		}
		map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE id IN :createdByIdSet]);
		map<Id, Case> caseMap = new Map<Id, Case>(
			[SELECT id, AccountId, Account.ZP_Company_ID__c, CaseNumber, Zendesk_Id__c, Subject, Priority, Type, ContactId, Contact.name, Contact.Email, Description FROM case WHERE id IN :caseIdSet]
		);
		map<Id, FeedItem> feedItemMap = new Map<Id, FeedItem>([SELECT Body, Id, IsRichText, Title, CreatedById FROM FeedItem WHERE id IN :feedItemIdSet]);
		for (Zendesk_Integration_Queue__c queue : messagesList) {
			if (queue.case_id__c == null || queue.case_id__c == '') {
				queue = setProcessingState('Error', 'Case Id does not exist', queue);
				continue;
			}
			if (!caseMap.containskey(queue.case_id__c)) {
				queue = setProcessingState(IntegrationUtils.ERROR_STATE, 'Case does not exist', queue);
				continue;
			}
			Case c = caseMap.get(queue.case_id__c);
			if (c.Zendesk_Id__c == null || c.Zendesk_Id__c == '') {
				queue = setProcessingState(IntegrationUtils.ERROR_STATE, 'Zendesk Id is blank', queue);
				continue;
			}
			feedItem feed = feedItemMap.get(queue.Object_Id__c);
			ZendeskIntegration integration = new ZendeskIntegration();
			ZendeskIntegration.ZendeskComment comment = new ZendeskIntegration.ZendeskComment();
			comment.createAsFollowup = queue.Create_As_Followup__c;

			comment.ticketId = c.Zendesk_Id__c;
			if (feed.IsRichText) {
				comment.html_body = feed.Body;
			} else {
				comment.plain_body = feed.Body;
			}
			comment.isPublic = 'false';
			comment.type = 'Comment';
			User user = userMap.get(queue.CreatedById);
			ZendeskIntegration.ZendeskUser zendeskUser = new ZendeskIntegration.ZendeskUser();
			zendeskUser.name = user.Name;
			zendeskUser.email = user.Email;
			comment.requester = zendeskUser;
			ZendeskIntegration.ZendeskTicketResponse response = integration.createZendeskTicketComment(comment, queue.Zendesk_Instance__c);
			queue.Processing_State__c = response.status;
			queue.Message__c = response.Message;
			queueUpdateList.add(queue);
		}
		if (queueUpdateList.size() > 0) {
			update queueUpdateList;
		}
	}

	private static Zendesk_Integration_Queue__c setProcessingState(String state, String message, Zendesk_Integration_Queue__c queue) {
		queue.Processing_State__c = state;
		queue.Message__c = message;
		queue.Last_Processed__c = System.now();
		return queue;
	}

	public class ZendeskException extends Exception {
	}

	public class ZendeskUser {
		public String id;
		public String name;
		public String email;
		public String role;
		public String careAccountManager;
		public String currentProgram;
	}

	public class ZendeskTicketSearchResult {
		public List<ZendeskTicket> tickets;
		public integer recordCount;
		public String nextPage;
		public String status;
		public String message;
	}

	public class ZendeskUserSearchResult {
		public List<ZendeskUser> users;
		public integer recordCount;
		public String nextPage;
		public String status;
		public String message;
	}

	public class ZendeskTicket {
		public String id;
		public String subject;
		public String description;
		public String type;
		public String status;
		public String priority;
		public String externalTicketId;
		public String externalTicketNumber;
		public String tags;
		public String companyId;
		public String companyName;
		public String groupId;
		public List<ZendeskUser> cc;
		public ZendeskUser requester;
		public List<String> comments;
	}

	public class ZendeskComment {
		public String ticketId;
		public String comment;
		public String html_body;
		public String plain_body;
		public String type;
		public String isPublic;
		public boolean createAsFollowup;
		public DateTime createdAt;
		public ZendeskUser requester;
	}

	public class ZendeskTicketResponse {
		public String id;
		public String ticket_id;
		public String status;
		public String message;
	}

	public class ZendeskUserResponse {
		public String id;
		public String status;
		public String message;
	}
}