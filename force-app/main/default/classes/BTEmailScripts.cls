/*
    @Author : David (Dato) Tsamalashvili
    @Date   : May 29, 2020
    @Desc   : To run email scripts
*/
public class BTEmailScripts {
	//to create cases for @gusto mailboxes
	public static void createEmailCasesV2(Set<Id> setBizTempIds) {
		List<BizTech_Temp_Obj__c> list_tempObj = new List<BizTech_Temp_Obj__c>();
		List<Contact> list_contacts = new List<Contact>();
		Set<String> set_fromAddresses = new Set<String>();
		Map<String, Contact> map_emailIdToContact = new Map<String, Contact>();
		List<EmailMessage> list_emailMsgs = new List<EmailMessage>();

		//List of Case and EmailMessage to Insert
		List<Case> list_casesToInsert = new List<Case>();
		List<EmailMessage> list_emailMsgsToInsert = new List<EmailMessage>();

		//List of temp records to update
		List<BizTech_Temp_Obj__c> list_toUpdateTemps = new List<BizTech_Temp_Obj__c>();

		//dmo to run assignment rules
		Database.DMLOptions dmo = new Database.DMLOptions();
		dmo.assignmentRuleHeader.useDefaultRule = true;

		//get temp object records
		list_tempObj = [SELECT Id, To_Address__c, Text_Body__c, Subject__c, From_Addresses__c, From_Name__c, Is_Processed__c FROM BizTech_Temp_Obj__c WHERE Id IN :setBizTempIds];
		//populate set of email ids to query contacts
		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			set_fromAddresses.add(obj.From_Addresses__c);
		}

		//query contacts
		if (set_fromAddresses.size() > 0) {
			list_contacts = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email IN :set_fromAddresses];
		}

		//populate map of email to contact
		for (Contact obj : list_contacts) {
			map_emailIdToContact.put(obj.Email, obj);
		}

		//iterate over temp records and create cases
		for (BizTech_Temp_Obj__c obj : list_tempObj) {
			Case cse = new Case();
			//get contact associated with email
			Contact c = map_emailIdToContact.containsKey(obj.From_Addresses__c) ? map_emailIdToContact.get(obj.From_Addresses__c) : null;

			//Check if match was found
			Boolean bln_matchFound = false;

			if (obj.To_Address__c.contains('success@gusto.com') || obj.To_Address__c.contains('smallgroupbenefits@gusto.com') || obj.To_Address__c.contains('success@zenpayroll.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Sales Cases');
				cse.Origin = 'Success Email';
				cse.Type = 'Sales Email';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('support@gusto.com') || obj.To_Address__c.contains('concierge@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Payroll Care');
				cse.Origin = 'Payroll Care Email';
				cse.Type = 'Payroll Care';
				cse.Status = 'New';
				cse.Priority = 'High';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('benefits@gusto.com') || obj.To_Address__c.contains('gustobenefitscard@benefits.gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits Care');
				cse.Origin = 'Email';
				cse.Type = 'Benefits Care';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (
				obj.To_Address__c.contains('bor-transfer@gusto.com') ||
				obj.To_Address__c.contains('bor-transfer+expressdynamics@gusto.com') ||
				obj.To_Address__c.contains('bor-transfer+percival@gusto.com') ||
				obj.To_Address__c.contains('bor-transfer+wonolo@gusto.com')
			) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits BoR');
				cse.Origin = 'Email';
				cse.Type = 'Benefits BoR';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005n7Kq';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('newplans@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits New Plan Case');
				cse.Origin = 'Email';
				cse.Type = 'Benefits New Plan Case';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('renewalcarriercomms@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits Renewal Case');
				cse.Origin = 'Email';
				cse.Type = 'Benefits Renewal Case';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('cashout-support@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Modern Bank');
				cse.Origin = 'Email';
				cse.Type = 'Modern Bank';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('renewals@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits Renewal Case');
				cse.Origin = 'Email';
				cse.Type = 'Benefits Renewal Case';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('cobra@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits Care');
				cse.Origin = 'Cobra Email';
				cse.Type = 'Benefits Care';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005mxcS';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('compliance@gusto.com') || obj.To_Address__c.contains('compliance@zenpayroll.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Tax Ops');
				cse.Origin = 'Compliance Email';
				cse.Type = 'Tax Ops';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('payrollonboarding@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Payroll Transfer Case');
				cse.Origin = 'Email';
				cse.Type = 'Payroll Transfer Case';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005SvX9';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('memberfulfillment@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Member Fulfillment Emails');
				cse.Origin = 'Email';
				cse.Type = 'Member Fulfillment Emails';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('payopsptserrors@gusto.com') || obj.To_Address__c.contains('payrollops@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Tax Ops');
				cse.Origin = 'Email';
				cse.Type = 'Tax Ops';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005mxcd';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('poa.support@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Tax Res');
				cse.Origin = 'Email';
				cse.Type = 'Tax Res';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('assurance@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Risk Assurance');
				cse.Origin = 'Email';
				cse.Type = 'Risk Assurance';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('payrollops@zenpayroll.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Tax Ops');
				cse.Origin = 'HelloFax Email';
				cse.Type = 'Tax Ops';
				cse.Status = 'New';
				cse.Priority = 'Low';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('benefits-newplans@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits New Plan Case');
				cse.Origin = 'Email';
				cse.Type = 'Benefits New Plan Case';
				cse.Status = 'New';
				cse.Priority = 'Low';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('benefits-onboarding@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits BoR');
				cse.Origin = 'Email';
				cse.Type = 'Benefits BoR';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G16000005SE5S';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('cash-reserve-support@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Modern Bank');
				cse.Origin = 'Email';
				cse.Type = 'Modern Bank';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '0051M000007dRa8';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('cashout-support@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Modern Bank');
				cse.Origin = 'Email';
				cse.Type = 'Modern Bank';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('flexible-pay-support@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Modern Bank');
				cse.Origin = 'Email';
				cse.Type = 'Modern Bank';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('garnishments@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Tax Ops');
				cse.Origin = 'Email';
				cse.Type = 'Tax Ops';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005mxcc';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('recovery@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Recovery Cases');
				cse.Origin = 'Email';
				cse.Type = 'Recovery Cases';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G16000004pXWL';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('setup@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Sales Cases');
				cse.Origin = 'Email';
				cse.Type = 'Sales Cases';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.OwnerId = '00G1M000005aUMX';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('taxcompliance@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Payroll Compliance');
				cse.Origin = 'Email';
				cse.Type = 'Payroll Compliance';
				cse.Status = 'New';
				cse.Priority = 'High';
				cse.OwnerId = '00G1M000005mxcl';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('underwriting@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Risk Assurance');
				cse.Origin = 'Email';
				cse.Type = 'Risk Assurance';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('qsehra@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Benefits Care');
				cse.Origin = 'QSEHRA Email';
				cse.Type = 'Benefits Care';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				bln_matchFound = true;
			} else if (obj.To_Address__c.contains('wallet@gusto.com')) {
				cse.RecordTypeId = cache.getRecordTypeId('case', 'Modern Bank');
				cse.Origin = 'Email';
				cse.Type = 'Modern Bank';
				cse.Status = 'New';
				cse.Priority = 'Medium';
				cse.setOptions(dmo);
				bln_matchFound = true;
			}

			if (bln_matchFound) {
				if (c != null) {
					cse.ContactId = c.Id;
					if (c.AccountId != null)
						cse.AccountId = c.AccountId;
				}

				cse.Description = obj.Text_Body__c;
				cse.Subject = obj.Subject__c;
				cse.SuppliedEmail = obj.From_Addresses__c;
				cse.SuppliedName = obj.From_Name__c;
				cse.Batch_Id__c = 'EmailToCase03-05-2021';
				list_casesToInsert.add(cse);

				EmailMessage msg = new EmailMessage();
				msg.FromAddress = cse.SuppliedEmail;
				msg.FromName = cse.SuppliedName;
				msg.Subject = cse.Subject;
				msg.TextBody = cse.Description;
				msg.ToAddress = obj.To_Address__c;
				msg.Incoming = true;
				list_emailMsgsToInsert.add(msg);

				obj.status__c = 'Case Created';
				obj.Is_Processed__c = true;
				list_toUpdateTemps.add(obj);
			}
		}

		if (!list_casesToInsert.isEmpty() && list_casesToInsert.size() > 0) {
			insert list_casesToInsert;

			//Assign the Case Ids back to BizTech Temp Object and Parent Id on Email Message Records
			for (Integer i = 0; i < list_casesToInsert.size(); i++) {
				//Set Case Ids back to BizTech Temp Obj Record
				list_toUpdateTemps[i].Case__c = list_casesToInsert[i].Id;
				//Set ParentId for the email messages
				list_emailMsgsToInsert[i].ParentId = list_casesToInsert[i].Id;
			}
		}

		if (!list_emailMsgsToInsert.isEmpty() && list_emailMsgsToInsert.size() > 0) {
			insert list_emailMsgsToInsert;
		}

		if (!list_toUpdateTemps.isEmpty() && list_toUpdateTemps.size() > 0) {
			update list_toUpdateTemps;
		}
	}
}