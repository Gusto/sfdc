global class EmailPublisherLoader implements QuickAction.QuickActionDefaultsHandler {
	public string ccAddress { get; set; }

	// Empty constructor
	global EmailPublisherLoader() {
	}

	// The main interface method
	global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
		QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
		Boolean blnLEX = false;
		String actype = '';
		// Check if the quick action is the standard Case Feed send email action
		for (Integer j = 0; j < defaults.size(); j++) {
			if (
				defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults &&
				defaults.get(j).getTargetSObject().getSObjectType() == EmailMessage.sObjectType &&
				((defaults.get(j).getActionName().equals('Case.Email') && defaults.get(j).getActionType().equals('Email')) ||
				defaults.get(j).getActionName().equals('Case.SendEmail') ||
				defaults.get(j).getActionName().equals('Case.SendEmailLTE'))
			) {
				sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults) defaults.get(j);
				break;
			}
		}

		if (defaults[0].getActionName().equals('Case.SendEmailLTE')) {
			blnLEX = true;
		}
		if (sendEmailDefaults != null) {
			//Fetch CaseTeam members along with case details, @Neha 8 Oct 2019
			Case c = [
				SELECT
					Id,
					CaseNumber,
					Order__c,
					Order__r.Agent_Email__c,
					RecordType.Name,
					RecordTypeId,
					ContactId,
					Contact.Email,
					Type,
					(SELECT Id, ParentId, MemberId FROM TeamMembers),
					(SELECT Id FROM Bulk_Migration_Requests__r WHERE Type__c = 'Bulk Migration')
				FROM Case
				WHERE Id = :sendEmailDefaults.getContextId()
			];
			EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();
			if (c.RecordType.Name.indexOf('Payroll Care') > -1 || c.RecordType.Name.indexOf('Benefits Care') > -1 || c.RecordType.Name.indexOf('Tax Res') > -1) {
				emailMessage = setEmailInfo(c.Id, emailMessage, blnLEX);
				sendEmailDefaults.setIgnoreTemplateSubject(true);

				/**
				 * Author: Alex
				 * Date: 12/7/2020
				 * Desc: remove {{id}} from EOY emails being sent
				 */
				if (c.RecordType.Name.indexOf('Payroll Care') > -1 || c.RecordType.Name.indexOf('Benefits Care') > -1) {
					if (emailMessage.HtmlBody != null && emailMessage.HtmlBody.contains('id::{{')) {
						String strGFId = emailMessage.HtmlBody.substringBetween('id::{{', '}}');

						String strBrokenId = 'id::{{' + strGFId + '}}';
						emailMessage.HtmlBody = emailMessage.HtmlBody.replace(strBrokenId, '');
					}
				}
			} else if (c.RecordType.Name.indexOf('Payroll Transfer Case') > -1) {
				if (c.ContactId != null && c.Contact.Email != null) {
					if (emailMessage.toAddress == null) {
						emailMessage.toAddress = c.Contact.Email;
					} else if (emailMessage.toAddress.indexOf(c.Contact.Email) < 0) {
						emailMessage.toAddress += ';' + c.Contact.Email;
					}
				}

				if (c.Order__c != null && c.Order__r.Agent_Email__c != null) {
					emailMessage.CcAddress = c.Order__r.Agent_Email__c;
				}
				if (null != c.Bulk_Migration_Requests__r && c.Bulk_Migration_Requests__r.size() > 0) {
					Configuration_Settings__c cs = Configuration_Settings__c.getInstance();
					if (null != cs && String.isNotBlank(cs.BMR_Aditional_CC_Addresses__c)) {
						String strColonSeparatedAddress = cs.BMR_Aditional_CC_Addresses__c.replaceAll(',', ';');
						emailMessage.CcAddress += emailMessage.CcAddress == '' ? strColonSeparatedAddress : ';' + strColonSeparatedAddress;
					}
				}
				//Include CaseTeam members in toAddress, @Neha 8 Oct 2019
				Set<Id> setMemberIds = new Set<Id>();
				if (null != c && null != c.TeamMembers) {
					for (CaseTeamMember objCaseTeamMember : c.TeamMembers) {
						setMemberIds.add(objCaseTeamMember.MemberId);
					}
					for (Contact objContact : [SELECT Id, Email FROM Contact WHERE Id IN :setMemberIds AND Email != NULL]) {
						if (emailMessage.toAddress == null || emailMessage.toAddress.indexOf(objContact.Email) < 0) {
							emailMessage.toAddress = (emailMessage.toAddress == '' || emailMessage.toAddress == null) ? objContact.Email : emailMessage.toAddress + ';' + objContact.Email;
						}
					}
				}
			} else if (c.RecordType.Name.indexOf('MF Termination') > -1 && 'Continuation Termination'.equalsIgnoreCase(c.Type)) {
				emailMessage.FromAddress = 'memberfulfillment@gusto.com;cobra@gusto.com';
			} else if (c.Type == 'Investigations') {
				emailMessage.ValidatedFromAddress = Label.fci_risk_email;
				emailMessage.FromAddress = Label.fci_risk_email;
			} else if (c.RecordTypeId == CaseUtils.RECTYPE_R_D_TAX_CREDITS) {
				emailMessage.ValidatedFromAddress = Label.R_D_Tax_Credits_Default_Case_From_Address;
				emailMessage.FromAddress = Label.R_D_Tax_Credits_Default_Case_From_Address;
			} else if (c.RecordTypeId == CaseUtils.RECTYPE_GEP_CX) {
				emailMessage.ValidatedFromAddress = Label.GEP_CX_Default_Case_From_Address;
				emailMessage.FromAddress = Label.GEP_CX_Default_Case_From_Address;
			}
		}
	}

	// return email address, Email Address is a from Address and this value is stored in custom label Email Address Label
	private EmailMessage setEmailInfo(String caseId, EmailMessage emailMessage, Boolean blnLEX) {
		List<Case> caseList = [SELECT id, Subject, Type, ccEmailAddress__c, contactId, contact.Email, Contact.Name, SuppliedEmail, SuppliedName FROM case WHERE id = :caseId];
		if (caseList != null) {
			Case cse = caseList[0];
			emailMessage.CcAddress = cse.ccEmailAddress__c;
			if (emailMessage.ToAddress == null || emailMessage.ToAddress == '') {
				if (cse.SuppliedEmail != null && cse.SuppliedEmail != '') {
					emailMessage.ToAddress = cse.SuppliedEmail;
				} else if (cse.ContactId != null && cse.contact.Email != null) {
					emailMessage.ToAddress = cse.contact.Email;
				}
			}
			List<String> GustoEmailsToSkipList = label.GustoEmailsToSkip.split(';');
			for (String eml : GustoEmailsToSkipList) {
				if (emailMessage.ToAddress != null) {
					emailMessage.ToAddress = emailMessage.ToAddress.replace(eml, '');
				}
				if (emailMessage.CcAddress != null) {
					emailMessage.CcAddress = emailMessage.CcAddress.replace(eml, '');
				}
				if (emailMessage.BccAddress != null) {
					emailMessage.BccAddress = emailMessage.BccAddress.replace(eml, '');
				}
			}

			if (emailMessage.Subject == null || emailMessage.Subject == '' || emailMessage.Subject == 'RE:') {
				emailMessage.Subject = cse.Subject;
			}
			if (cse.type == 'Cobra') {
				if (blnLEX) {
					emailMessage.ValidatedFromAddress = Label.Cobra_Email;
				} else {
					emailMessage.FromAddress = Label.Cobra_Email;
				}
				emailMessage.FromName = Label.Cobra_Email;
			} else if (cse.type == 'Savings') {
				if (blnLEX) {
					emailMessage.ValidatedFromAddress = Label.Modern_Bank_Email;
				} else {
					emailMessage.FromAddress = Label.Modern_Bank_Email;
				}
				emailMessage.FromName = Label.Modern_Bank_Email;
			} else if (cse.type == 'QSEHRA') {
				if (blnLEX) {
					emailMessage.ValidatedFromAddress = Label.QSEHRA_Email;
				} else {
					emailMessage.FromAddress = Label.QSEHRA_Email;
				}
				emailMessage.FromName = Label.QSEHRA_Email;
			}
		}
		return emailMessage;
	}
}