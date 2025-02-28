/**
 * @description  Utility class to run Enterprise Territory Management Assignment rules
 * @author       Praveen Sethu
 * @see          RunTerritoryRulesTest
 **/
public class RunTerritoryRules implements Queueable, Database.AllowsCallouts {
	// Constructor
	public RunTerritoryRules(Set<String> set_AccountIds) {
		this.set_AccountIds = set_AccountIds;
	}

	// Declare all variables needed
	public Set<String> set_AccountIds = null;
	private String strSessionId = null;
	String strAccountTag = '<urn:sObjects> ' + '<urn1:type>Account</urn1:type>  ' + '<urn1:Id>{ACCID}</urn1:Id>   ' + '</urn:sObjects> ';
	String strRequestTemplate =
		'<soapenv:Envelope ' +
		'xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"' +
		' xmlns:urn="urn:partner.soap.sforce.com"' +
		' xmlns:urn1="urn:sobject.partner.soap.sforce.com">' +
		'<soapenv:Header> ' +
		'<urn:AssignmentRuleHeader> ' +
		'<urn:useDefaultRule>true</urn:useDefaultRule> ' +
		'<urn:assignmentRuleId></urn:assignmentRuleId> ' +
		'</urn:AssignmentRuleHeader>  ' +
		'<urn:SessionHeader> ' +
		'<urn:sessionId>{SESSID}</urn:sessionId> ' +
		'</urn:SessionHeader> ' +
		'</soapenv:Header> ' +
		'<soapenv:Body> ' +
		'<urn:update> ' +
		' {ACCLISTS}' +
		'</urn:update> ' +
		'</soapenv:Body> ' +
		'</soapenv:Envelope>';

	/**
	 * @description  Sends API call to Salesforce to run Enterprise Territory Management Assignment rules
	 * @author       Praveen Sethu
	 **/
	public void execute(QueueableContext context) {
		// Create data needed for HTTP Request
		// Test methods do not support getContent() call
		strSessionId = Test.isRunningTest() ? 'testSessionId' : Page.GetSessionId.getContent().toString();
		List<String> list_Accounts = new List<String>();
		if (set_AccountIds != null) {
			for (String accId : set_AccountIds) {
				list_Accounts.add(strAccountTag.replace('{ACCID}', accId));
			}
		}
		strRequestTemplate = strRequestTemplate.replace('{ACCLISTS}', String.join(list_Accounts, ' '));
		strRequestTemplate = strRequestTemplate.replace('{SESSID}', strSessionId);

		// Form HTTP Request
		HttpRequest objRequest = new HttpRequest();
		objRequest.setEndpoint(System.URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/41.0/' + UserInfo.getOrganizationId());
		objRequest.setMethod('POST');
		objRequest.setHeader('Content-Type', 'text/xml;charset=UTF-8');
		objRequest.setHeader('SOAPAction', '""');
		objRequest.setBody(strRequestTemplate);
		// Not sending a callout from test class - this is causing several tests to fail
		if (!Test.isRunningTest()) {
			HTTPResponse objResponse = new Http().send(objRequest);
		}

		// Calculation of Territories Complete
		// Build a map of Account Id and list of territories
		Map<Id, List<Id>> map_AccountTerritories = new Map<Id, List<Id>>();
		Map<Id, Territory2> map_Territories = new Map<Id, Territory2>();
		Map<Id, Account> map_AccountsToRoute = new Map<Id, Account>();

		if (Test.isRunningTest()) {
			for (Account objTestAcc : [SELECT Id FROM Account WHERE ZP_Company_ID__c = 'testhirouting']) {
				set_AccountIds.add(objTestAcc.Id);
			}
		}

		// Build a map of Account Id and their assoicated territories
		for (ObjectTerritory2Association objAccTerritory : [SELECT Id, ObjectId, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId IN :set_AccountIds]) {
			List<Id> list_TerritoryIds;
			if (!map_AccountTerritories.containsKey(objAccTerritory.ObjectId)) {
				list_TerritoryIds = new List<Id>();
			} else {
				list_TerritoryIds = map_AccountTerritories.get(objAccTerritory.ObjectId);
			}
			list_TerritoryIds.add(objAccTerritory.Territory2Id);
			map_AccountTerritories.put(objAccTerritory.ObjectId, list_TerritoryIds);
		}

		// Build a map of all territories
		for (Territory2 objTerritory : [SELECT Id, Name, Territory2Type.DeveloperName, DeveloperName FROM Territory2]) {
			map_Territories.put(objTerritory.Id, objTerritory);
		}

		// Calculate Territory on the Account
		for (Account objAcc : [SELECT Id, Territory__c FROM Account WHERE Id IN :set_AccountIds]) {
			String strTerritory;
			if (map_AccountTerritories.containsKey(objAcc.Id)) {
				for (Id idTerritory : map_AccountTerritories.get(objAcc.Id)) {
					if (map_Territories.containsKey(idTerritory)) {
						Territory2 objTerritory = map_Territories.get(idTerritory);
						if (objTerritory.Territory2Type.DeveloperName == 'Region') {
							// Form territory based on if territory type = Region. Replace _ from Territory Name and set it on the Account
							strTerritory = objTerritory.DeveloperName.replaceAll('_', ' ');
						}
					}
				}

				// If Territory does not match - Set on the Account and send it for routing
				if (strTerritory != objAcc.Territory__c) {
					objAcc.Territory__c = strTerritory;
					map_AccountsToRoute.put(objAcc.Id, objAcc);
				}
			} else {
				objAcc.Territory__c = strTerritory;
				map_AccountsToRoute.put(objAcc.Id, objAcc);
			}
		}

		// Add DML statements after routing callout
		update map_AccountsToRoute.values();

		Set<Id> set_AccountIdsToRoute = new Set<Id>();
		// Send account to Ringlead for routing
		for (Account objAcc : map_AccountsToRoute.values()) {
			if (String.isNotBlank(objAcc.Territory__c)) {
				set_AccountIdsToRoute.add(objAcc.Id);
			}
		}

		if (!set_AccountIdsToRoute.isEmpty() && !Test.isRunningTest()) {
			AccountUtil.sendAccountForHIOwnerRoutingFuture(set_AccountIdsToRoute);
		}
	}
}