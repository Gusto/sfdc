/***************************************************
Purpose : This class controls the PrivacyRequestsPortal page
Written By : Alex
Test Classes : PrivacyRequestTests, PrivacyRequestsPortalCtrlTest
****************************************************/
public without sharing class PrivacyRequestsPortalCtrl {
	public ApexPages.StandardController stdCtrl;
	public Case requestCase { get; set; }
	public Boolean boolIsSubmitted { get; set; }
	public List<ContentDocumentLink> attachments { get; set; }
	public Boolean boolReadyToDisclose { get; set; }
	public Boolean boolShowDataCollectionInfo { get; set; }
	public String strStatus { get; set; }
	public String strUser_Type { get; set; }
	public String strSSN { get; set; }
	public Date dtDateOfBirth { get; set; }
	public Date dtDateOfHire { get; set; }
	public String strPhoneNumber { get; set; }
	public String strName_of_Business { get; set; }
	public String strFEIN { get; set; }
	public String strLast_Employee_Hired { get; set; }
	public Blob blobFile { get; set; }
	public String strFileName { get; set; }
	public String strMaskedSSN { get; set; }
	public Boolean boolDeleteConfirm { get; set; }
	public Boolean boolInfoConfirm { get; set; }
	public Boolean boolIsDelete { get; set; }
	public Boolean boolSubmitToggle { get; set; }
	public Boolean boolIsDeniedIdentity { get; set; }
	public Boolean boolIsDeniedLocation { get; set; }
	public Boolean boolIsDenied { get; set; }

	public PrivacyRequestsPortalCtrl() {
		boolShowDataCollectionInfo = false;
		requestCase = [
			SELECT
				Id,
				Status,
				CaseNumber,
				User_Type__c,
				SSN__c,
				Date_of_Birth__c,
				Date_of_Hire__c,
				Privacy_Requester_Phone__c,
				Name_of_Business__c,
				Last_Employee_Hired__c,
				FEIN_Last_4_digits__c,
				Privacy_Requester_Email__c,
				Privacy_Requester_First_Name__c,
				Privacy_Requester_Last_Name__c,
				Confirmation_Code__c,
				Privacy_Request_Deletion_Confirmation__c,
				Privacy_Request_Info_Confirmation__c,
				Request_Type__c,
				Status_Detail__c
			FROM Case
			WHERE Id = :ApexPages.currentPage().getParameters().get('id')
		];

		strStatus = requestCase.Status;
		strUser_Type = requestCase.User_Type__c;
		strSSN = requestCase.SSN__c;
		dtDateOfBirth = requestCase.Date_of_Birth__c;
		dtDateOfHire = requestCase.Date_of_Hire__c;
		strPhoneNumber = requestCase.Privacy_Requester_Phone__c;
		strName_of_Business = requestCase.Name_of_Business__c;
		strFEIN = requestCase.FEIN_Last_4_digits__c;
		strLast_Employee_Hired = requestCase.Last_Employee_Hired__c;
		boolDeleteConfirm = requestCase.Privacy_Request_Deletion_Confirmation__c;
		boolInfoConfirm = requestCase.Privacy_Request_Info_Confirmation__c;

		//if the request type is Disclosure and Deletion or Deletion, show the checkbox
		if (requestCase.Request_Type__c.contains('Delet')) {
			boolIsDelete = true;
		} else {
			boolIsDelete = false;
		}

		if (requestCase.Status == 'New' || requestCase.Status == 'Email Confirmed' || requestCase.Status == 'Pending User Submission') {
			boolIsSubmitted = false;
		} else {
			if (requestCase.Status == 'Ready to Disclose') {
				boolReadyToDisclose = true;
			}
			if (requestCase.Status == 'Request Denied') {
				if (requestCase.Status_Detail__c == 'Location') {
					boolIsDeniedLocation = true;
				} else if (requestCase.Status_Detail__c == 'Identity') {
					boolIsDeniedIdentity = true;
				}
				boolIsDenied = true;
			}
			boolIsSubmitted = true;
			strMaskedSSN = maskString(strSSN);
		}
		queryAttachments();
	}
	/*
    Query for the attachments on the Case
    Written by: Alex
    */
	public void queryAttachments() {
		attachments = [SELECT ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId = :requestCase.Id];
	}

	/*
    Validate the cookie on the page
    Written by: Alex
    */
	public PageReference validateCookie() {
		//check for the cookie
		//if it doesn't exist, redirect back to the entrance page
		try {
			Cookie cookie_authCookie = ApexPages.currentPage().getCookies().get('prAuth');
			if (cookie_authCookie == null) {
				PageReference entrancePage = new PageReference('/apex/PrivacyRequestsPortalEntrance');
				entrancePage.setRedirect(true);
				return entrancePage;
			} else {
				String strCookieValue = cookie_authCookie.getValue();
				if (matchCookieValue(strCookieValue) == true) {
					return null;
				} else {
					PageReference entrancePage = new PageReference('/apex/PrivacyRequestsPortalEntrance');
					entrancePage.setRedirect(true);
					return entrancePage;
				}
			}
		} catch (Exception e) {
			ExceptionLogUtil.logException('PrivacyRequestsPortalCtrl', 'validateCookie', e.getMessage(), e.getStackTraceString());
			PageReference entrancePage = new PageReference('/apex/PrivacyRequestsPortalEntrance');
			entrancePage.setRedirect(true);
			return entrancePage;
		}
	}

	/*
    This method matches an encrypted string to the case requester's email + a delimiter + case requester's confirmation code 
    Written by: Alex
    */
	public Boolean matchCookieValue(String strStringToCheck) {
		if (PrivacyRequestsPortalEntranceCtrl.decryptString(strStringToCheck) == requestCase.Privacy_Requester_Email__c + '$$' + requestCase.Confirmation_Code__c) {
			return true;
		}

		return false;
	}

	public void toggleShowInformation() {
		boolShowDataCollectionInfo = true;
	}

	public void toggleSubmitButton() {
		if (boolInfoConfirm == true) {
			boolSubmitToggle = true;
			if (requestCase.Request_Type__c.contains('Delet')) {
				if (boolDeleteConfirm == true) {
					boolSubmitToggle = true;
				} else {
					boolSubmitToggle = false;
				}
			}
		} else {
			boolSubmitToggle = false;
		}
	}

	/*
    This method uploads a file and attaches it to the Case
    Written by: Alex
    */
	public void uploadFileLogic() {
		//create the Content Version
		if (String.isBlank(strFileName) || blobFile == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a file to upload'));
			return;
		}

		ContentVersion cv = new ContentVersion();
		cv.versionData = blobFile;
		cv.title = strFileName;
		cv.pathOnClient = strFileName;
		insert cv;
		//clear the blob variable to save space
		blobFile = null;
		//attach the file to the Case
		List<ContentVersion> list_ContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
		ContentDocumentLink cdLink = new ContentDocumentLink();
		cdLink.ContentDocumentId = list_ContentVersion[0].ContentDocumentId;
		cdLink.LinkedEntityId = requestCase.Id;
		cdLink.ShareType = 'i';
		insert cdLink;
	}

	/*
    This method uploads a file and attaches it to the Case. Updates the Case as well.
    Written by: Alex
    */
	public PageReference uploadFile() {
		try {
			uploadFileLogic();
			updateCase();
			queryAttachments();
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
			blobFile = null;
		}
		return null;
	}

	/*
    This method uploads a file and attaches it to the Case. Does not update the Case.
    Written by: Alex
    */
	public void uploadFile2() {
		uploadFileLogic();
		queryAttachments();
	}

	/*
    This method masks the string provided.
    Written by: Alex
    */
	public static String maskString(String strInput) {
		String strMask = '';
		if (!String.isBlank(strInput)) {
			for (Integer i = 0; i < strInput.length(); i++) {
				strMask += '*';
			}
		}

		return strMask;
	}

	/*
    This method sets fields on the Case
    Written by: Alex
    */
	public Case syncCase() {
		return (new Case(
			Id = requestCase.Id,
			User_Type__c = strUser_Type,
			SSN__c = strSSN,
			Date_of_Birth__c = dtDateOfBirth,
			Date_of_Hire__c = dtDateOfHire,
			Privacy_Requester_Phone__c = strPhoneNumber,
			Name_of_Business__c = strName_of_Business,
			Last_Employee_Hired__c = strLast_Employee_Hired,
			FEIN_Last_4_digits__c = strFEIN,
			Privacy_Request_Info_Confirmation__c = boolInfoConfirm,
			Privacy_Request_Deletion_Confirmation__c = boolDeleteConfirm
		));
	}

	/*
    This method updates the Case
    Written by: Alex
    */
	public void updateCase() {
		Case objCase = syncCase();
		update objCase;
	}

	/*
    This method updates the Case and sets the status to Submitted
    Written by: Alex
    */
	public void updateCaseSubmit() {
		Case objCase = syncCase();
		objCase.Status = 'Submitted';
		strMaskedSSN = maskString(strSSN);
		update objCase;
	}

	/*
    This method saves the case. If is a delete request: if both checkboxes are not checked then throw error. 
    if it is not a delete request, only check for info confirm. Uploads a file as well.
    Written by: Alex
    */
	public void save() {
		try {
			if (boolIsDelete) {
				if (!boolInfoConfirm || !boolDeleteConfirm) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please complete the required fields below.'));
					blobFile = null;
				} else {
					if (blobFile != null)
						uploadFile2();

					if (ApexPages.hasMessages())
						return;
					else
						updateCase();
				}
			} else {
				if (!boolInfoConfirm) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please complete the required fields below.'));
					blobFile = null;
				} else {
					if (blobFile != null)
						uploadFile2();

					if (ApexPages.hasMessages())
						return;
					else
						updateCase();
				}
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
			blobFile = null;
		}
	}

	/*
    This method saves the case and sets the status to Submitted. If is a delete request: if both checkboxes are not checked then throw error. 
    if it is not a delete request, only check for info confirm. Uploads a file as well
    Written by: Alex
    */
	public PageReference saveAndSubmit() {
		try {
			if (boolIsDelete) {
				if (!boolInfoConfirm || !boolDeleteConfirm) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please complete the required fields below.'));
					blobFile = null;
					return null;
				} else {
					if (blobFile != null)
						uploadFile2();

					if (ApexPages.hasMessages())
						return null;
					else {
						updateCaseSubmit();
						PageReference pageRef = ApexPages.currentPage();
						pageRef.getParameters().clear();
						pageRef.getParameters().put('id', requestCase.Id);
						pageRef.setRedirect(true);
						return pageRef;
					}
				}
			} else {
				if (!boolInfoConfirm) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please complete the required fields below.'));
					blobFile = null;
					return null;
				} else {
					if (blobFile != null) {
						uploadFile2();
					}

					if (ApexPages.hasMessages())
						return null;
					else {
						updateCaseSubmit();
						PageReference pageRef = ApexPages.currentPage();
						pageRef.getParameters().clear();
						pageRef.getParameters().put('id', requestCase.Id);
						pageRef.setRedirect(true);
						return pageRef;
					}
				}
			}
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage()));
			blobFile = null;
			return null;
		}
	}
}