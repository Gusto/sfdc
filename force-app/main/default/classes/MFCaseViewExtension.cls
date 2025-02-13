public class MFCaseViewExtension {
	public Case theCase { get; private set; }
	public List<Case> theCasesList { get; set; }
	public string caseType { get; set; }
	public string encryptedInfo { get; private set; }
	public List<SelectOption> caseTypeOption { get; private set; }
	public boolean isFullAccess { get; private set; }
	public boolean isAdmin { get; private set; }
	public string strColor { get; set; }
	public boolean bln_showSubcrpEndDate { get; set; }
	public static final String RQ_QLE_RFI_TYPE_AND_REASON = 'Please enter QLE RFI Type & Insufficient Proof Reason.';
	public static final String RQ_QLE_RFI_TYPE = 'Please enter QLE RFI Type.';
	public static final String RQ_QLE_RFI_REASON = 'Please enter Insufficient Proof Reason.';
	public List<MultiPickList> list_SelectedRFIType { get; set; }
	public static Set<String> set_ExcludedRFIType = new Set<String>();

	public MFCaseViewExtension(ApexPages.StandardController controller) {
		bln_showSubcrpEndDate = false;
		theCase = (Case) controller.getRecord();
		if (theCase != null) {
			theCasesList = [
				SELECT
					Id,
					ContactEmail,
					RFI_Type__c,
					RecordType.Name,
					RecordTypeId,
					Termination_Date__c,
					MF_Coverage_End_Date__c,
					Generation_Reason__c,
					Audit_Action__c,
					Doc_Request_Status__c,
					Type,
					RFI_Status__c,
					Anticipated_Effective_Date__c,
					Contact.ZP_User_Id__c,
					Submission_Method__c,
					Special_Instructions__c,
					Follow_Up_Date__c,
					SuppliedEmail,
					carrier__r.Submission_Email__c,
					Contact.Email,
					Status,
					Status_Detail__c,
					Requires_Action__c,
					Google_Drive_URL__c,
					Carrier__c,
					Description,
					Follow_Up_Method__c,
					Benefit_Order__c,
					Opportunity__c,
					LastModifiedDate,
					Open_Enrollment_Start__c,
					Open_Enrollment_End__c,
					Benefit_Order_Submission_Deadline__c,
					Related_to_Incident__c,
					Covid_19_Note_s__c,
					Benefit_Order__r.Name,
					Form_Fully_Mapped__c,
					Form_Fits_Dependents__c,
					Missing_Form_Attributes__c,
					Subscription_End_Date__c,
					Notes__c,
					Event_timestamp__c,
					Company_Name__c,
					ContactId,
					Integration_Id__c,
					Enrollment_Message__c,
					QLE_RFI_Type__c,
					Contact.Name,
					Contact.LastName,
					Contact.FirstName,
					Insufficient_Proof_Reason__c,
					RFI_3rd_Business_Day__c,
					RFI_6th_Business_Day__c,
					RFI_9th_Business_Day__c,
					Case_Reference__c,
					OwnerId,
					Reviewed_by_Dedicated_Support__c,
					Fulfillment_Type__c,
					Fulfillment_Sub_Type__c,
					Benefit_Types__c,
					HI_Integration_Error_Message__c
				FROM Case
				WHERE Id = :theCase.Id
				FOR UPDATE
			];
		}

		if (theCasesList != null && theCasesList.size() > 0) {
			theCase = theCasesList.get(0);
			caseTypeOption = CaseUtils.caseTypeOptionList();
			List<Attachment> attachmentList = new List<Attachment>([SELECT Id, Body FROM Attachment WHERE parentId = :theCase.id AND name = 'encFile.txt']);

			if (
				string.isNotBlank(theCase.Type) &&
				(theCase.Type.equalsIgnoreCase('Employee termination') ||
				theCase.Type.equalsIgnoreCase('Employee status change') ||
				theCase.Type.equalsIgnoreCase('Dependent QLE - legal separation') ||
				theCase.Type.equalsIgnoreCase('Dependent QLE - court order') ||
				theCase.Type.equalsIgnoreCase('Dependent QLE - ages out'))
			) {
				strColor = 'green';
			} else {
				strColor = 'black';
			}

			encryptedInfo = '';
			if (attachmentList.size() > 0) {
				Blob encryptionKey = EncryptionUtils.getEncryptionKey('Master');
				Blob attachmentBlob = attachmentList[0].Body;
				encryptedInfo = EncryptionUtils.getDecryptedText(encryptionKey, attachmentBlob);
			}
			setAccessPermission(theCase.Contact.ZP_User_Id__c, theCase.SuppliedEmail);

			//Chaitanya 10-6-2020
			if (theCase != null && theCase.Subscription_End_Date__c != null) {
				bln_showSubcrpEndDate = true;
			}

			list_SelectedRFIType = new List<MultiPickList>();

			Configuration_Settings__c configSettings = Configuration_Settings__c.getOrgDefaults();
			if (String.isNotBlank(configSettings.RFI_Type_To_Be_Excluded__c)) {
				set_ExcludedRFIType = new Set<String>(configSettings.RFI_Type_To_Be_Excluded__c.split(';'));
			}

			for (Schema.PicklistEntry objPE : Case.RFI_Type__c.getDescribe().getPicklistValues()) {
				if (!set_ExcludedRFIType.contains(objPE.getLabel())) {
					list_SelectedRFIType.add(new MultiPickList(false, objPE.getLabel()));
				}
			}

			if (String.isNotBlank(theCase.RFI_Type__c)) {
				String strRFIType = theCase.RFI_Type__c;
				Set<String> set_String = new Set<String>();
				if (String.isNotBlank(strRFIType)) {
					for (String strValue : strRFIType.split(';')) {
						if (String.isNotBlank(strValue)) {
							set_String.add(strValue);
						}
					}
				}
				for (MultiPickList objMP : list_SelectedRFIType) {
					if (set_String.contains(objMP.strName)) {
						objMP.blnChecked = true;
					} else {
						objMP.blnChecked = false;
					}
				}
			}
		}
	}

	private void setAccessPermission(string userId, string email) {
		list<ZP_User_Role__c> zpUserRoles;

		list<ZP_User__c> userList = new List<ZP_User__c>();
		if (userId == '' && email != '') {
			userList = [SELECT Id__c, Email__c, Deleted_At__c FROM ZP_User__c WHERE email__c = :email];
			if (userList.size() > 0) {
				userId = userList.get(0).Id__c;
			}
		}

		map<string, boolean> companyVisePermissionMap = new Map<string, boolean>();
		isAdmin = false;
		if (userId != null) {
			for (ZP_User_Role__c roleRec : [
				SELECT id, User_Permissions__c, Company_Id__c, User_Id__c, Type__c
				FROM ZP_User_Role__c
				WHERE User_Id__c = :userId AND Company_Id__c != NULL AND Deleted_At__c = NULL
			]) {
				string companyUniqueKey = roleRec.Company_Id__c + roleRec.User_Id__c;

				if (roleRec.Type__c != null && roleRec.Type__c.indexOf('PayrollAdmin') > -1) {
					isAdmin = true;
				}

				if (roleRec.User_Permissions__c != null) {
					if (roleRec.User_Permissions__c.indexOf('full_access') > -1) {
						companyVisePermissionMap.put(companyUniqueKey, true);
					}
				}

				if (!companyVisePermissionMap.containsKey(companyUniqueKey)) {
					companyVisePermissionMap.put(companyUniqueKey, false);
				}
			}
		}

		integer fullAccessCount = 0;
		for (boolean permission : companyVisePermissionMap.values()) {
			if (permission) {
				fullAccessCount++;
			}
		}

		if (fullAccessCount == companyVisePermissionMap.keyset().size()) {
			isFullAccess = true;
		} else {
			isFullAccess = false;
		}
	}

	public pageReference SaveMFAuditCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFAuditCasePage');
	}

	public pageReference SaveMFNHECase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFNHECasePage');
	}
	//@Neha, September 15,2020 : Case Save and page refresh logic.
	private pageReference saveAndReloadCasePage(String strPageName) {
		setRFITypeFieldValue();
		Database.SaveResult result = Database.update(theCase, false);
		if (result.success) {
			if (String.isBlank(strPageName)) {
				return null;
			}
			PageReference pgref = new PageReference('/apex/' + strPageName + '?id=' + theCase.id + '&refreshPage=true');
			return pgref;
		} else {
			apexPages.addMessage(new apexPages.Message(ApexPages.Severity.ERROR, Utils.ConsolidateErrors(result.errors)));
			return null;
		}
	}

	public pageReference SaveMFQLECase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFQLECasePage');
	}

	public pageReference SaveMFTerminationCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFTerminationCasePage');
	}

	@remoteAction
	public static string getEmailCC(String caseId) {
		String val = ' subject: ';
		if (!string.isBlank(caseId)) {
			try {
				list<EmailMessage> emailMsgList = [SELECT id, subject, ccaddress, createddate FROM EmailMessage WHERE parentid = :caseId ORDER BY createddate DESC];
				List<Case> caseList = [
					SELECT
						Id,
						Subject,
						RecordType.Name,
						Type,
						Order__c,
						Order__r.Agent_Email__c,
						ccEmailAddress__c,
						contactId,
						contact.Email,
						Contact.Name,
						SuppliedEmail,
						SuppliedName,
						Requester_Email__c
					FROM Case
					WHERE Id = :caseId
				];
				String val1 = '';
				if (caseList.size() > 0) {
					if (caseList[0].RecordType.Name.indexOf('Payroll Transfer Case') > -1 && caseList[0].Order__c != null && caseList[0].Order__r.Agent_Email__c != null) {
						String ccEmail = caseList[0].Order__r.Agent_Email__c;
						val1 = ccEmail + 'subject:';
					} else {
						val1 = ' ' + 'subject:';
					}
				}

				if (emailMsgList.size() > 0) {
					if (emailMsgList[0].subject != null && emailMsgList[0].subject.trim() != '') {
						val1 = val1 + emailMsgList[0].subject.trim();
					} else {
						val1 = val1 + ' ';
					}
				} else {
					val1 = val1 + ' ';
				}
				return val1;
			} catch (Exception e) {
				ExceptionLogUtil.logException('MFCaseViewExtension', 'getEmailCC', e.getMessage(), e.getStackTraceString());
				return null;
			}
		}
		return val;
	}

	public pageReference SaveMFUpdatesCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFUpdatesCasePage');
	}

	public pageReference SaveMFEmailsCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('MFEmailsCasePage');
	}

	public pageReference SavePayrollTransferCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('PayrollTransferCasePage');
	}

	public pageReference SaveBORCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('BORCasePage');
	}

	public pageReference SaveRenewalCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('RenewalCasePage');
	}

	public pageReference SaveNewPlanCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('NewPlanCasePage');
	}

	public pageReference SavePayrollCareCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('PayrollCareCasePage');
	}

	public pageReference SaveBenefitsCareCase() {
		theCase.OwnerId = UserInfo.getUserId();

		return saveAndReloadCasePage('BenefitsCareCasePage');
	}

	public void routeCase() {
		caseUtils.routeCase(caseType, theCase);
	}

	public pageReference sendFirstRFI() {
		PageReference objPR = null;
		try {
			if (String.isBlank(theCase.QLE_RFI_Type__c) && String.isBlank(theCase.Insufficient_Proof_Reason__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RQ_QLE_RFI_TYPE_AND_REASON));
				return null;
			} else if (String.isBlank(theCase.QLE_RFI_Type__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RQ_QLE_RFI_TYPE));
				return null;
			} else if (String.isBlank(theCase.Insufficient_Proof_Reason__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RQ_QLE_RFI_REASON));
				return null;
			}

			theCase.RFI_Status__c = QLERFIAutomateEmailUtils.STATUS_RFI_1;
			theCase.Automated_RFI_Flow__c = true;
			theCase.Status = QLERFIAutomateEmailUtils.STATUS_PENDING;
			Date dtNextBusinessDay = System.today();
			theCase.RFI_3rd_Business_Day__c = Utils.getBusinessDayFromDate(dtNextBusinessDay, 3);
			theCase.RFI_6th_Business_Day__c = Utils.getBusinessDayFromDate(theCase.RFI_3rd_Business_Day__c, 3);
			theCase.RFI_9th_Business_Day__c = Utils.getBusinessDayFromDate(theCase.RFI_6th_Business_Day__c, 3);
			Map<Id, String> map_UserSignatures = OEEmailAutomationHelper.fetchUserSignature(new Set<Id>{ theCase.OwnerId });
			Messaging.SingleEmailMessage objEM = QLERFIAutomateEmailUtils.createEmailRecord(theCase, 1, map_UserSignatures);
			EmailMessage objEmailMessage = QLERFIAutomateEmailUtils.createEmailMessageRecord(objEM, theCase, 1);

			if (objEM != null) {
				Messaging.SendEmailResult[] objSendMails = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ objEM });

				if (objSendMails[0].success) {
					insert objEmailMessage;
				}

				objPR = SaveMFNHECase();
			}
		} catch (Exception objExp) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, objExp.getMessage()));
		}

		return objPR;
	}

	public void setRFITypeFieldValue() {
		String strRFIType = '';
		for (MultiPickList objMP : list_SelectedRFIType) {
			if (objMP.blnChecked) {
				strRFIType += ';' + objMP.strName;
			}
		}
		if (String.isNotBlank(strRFIType)) {
			strRFIType = strRFIType.replaceFirst(';', '');
		}
		theCase.RFI_Type__c = strRFIType;
	}

	//Wrapper class, for "User Reported Industry" search filter.
	public class MultiPickList {
		public Boolean blnChecked { get; set; }
		public String strName { get; set; }
		public MultiPickList(Boolean blnChecked, String strName) {
			this.blnChecked = blnChecked;
			this.strName = strName;
		}
	}
}