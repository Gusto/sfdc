/**
 * @name         : ChimaChatInternalWidgetCtrl
 * @author       : Yogesh Kherajani
 * @date         : 24/04/2024
 * @description  : Controller class to provide case and chat transcript details to chat
 * @see 		 : ChimaChatInternalWidgetCtrlTest
 **/
public class ChimaChatInternalWidgetCtrl {
	private static String LIVE_CHATTRANSCRIPT_INTERNAL_RECORDTYPE = 'Internal';
	private static String PANDA_COMPANY_LINK = 'https://app.gusto.com/panda/companies/';
	private static String PANDA_RESELLER_LINK = 'https://app.gusto.com/panda/accounting_firms/';

	public ChatWrapper objChatWrapper { get; set; }

	public Id idChatTranscriptRecordType {
		get {
			List<RecordType> lst_LiveChatInternalRecordType = [
				SELECT Id
				FROM RecordType
				WHERE Name = :LIVE_CHATTRANSCRIPT_INTERNAL_RECORDTYPE
			];

			if (!lst_LiveChatInternalRecordType.isEmpty()) {
				return lst_LiveChatInternalRecordType[0].Id;
			}

			return null;
		}
		set;
	}

	public ChimaChatInternalWidgetCtrl(ApexPages.StandardController controller) {
		// Retrieve the URL parameters
		Map<String, String> map_URLParams = ApexPages.currentPage().getParameters();

		// Get the value of the paramName parameter
		String strCaseRecId = map_URLParams.get('recordId');

		if (String.isNotBlank(strCaseRecId)) {
			List<Case> lst_Case = [
				SELECT Id, CaseNumber, Confirm_Case_Reason_Classification__c, AccountId, Account.ZP_Company_ID__c, Account.RecordType.DeveloperName, Account.ZP_Firm_ID__c
				FROM Case
				WHERE Id = :strCaseRecId
			];

			objChatWrapper = new ChatWrapper();
			if (!lst_Case.isEmpty()) {
				objChatWrapper.strCaseRecId = strCaseRecId;
				objChatWrapper.strCaseReason = lst_Case[0].Confirm_Case_Reason_Classification__c;
				objChatWrapper.strPandaLink = '';

				if (lst_Case[0].AccountId != null) {
					if (lst_Case[0].Account.RecordType.DeveloperName == 'Company' && lst_Case[0].Account.ZP_Company_ID__c != null) {
						objChatWrapper.strPandaLink = PANDA_COMPANY_LINK + lst_Case[0].Account.ZP_Company_ID__c;
					} else if (lst_Case[0].Account.RecordType.DeveloperName == 'Reseller' && lst_Case[0].Account.ZP_Firm_ID__c != null) {
						objChatWrapper.strPandaLink = PANDA_RESELLER_LINK + lst_Case[0].Account.ZP_Firm_ID__c;
					}
				}

				objChatWrapper.strCaseNumber = lst_Case[0].CaseNumber;
			}
		}
	}

	public class ChatWrapper {
		public String strCaseRecId { get; set; }
		public String strCaseReason { get; set; }
		public String strPandaLink { get; set; }
		public String strCaseNumber { get; set; }
	}
}