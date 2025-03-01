/*
 * @name			CreateWarningMessagesLwc
 * @author			Deepika Saini
 * @date			25/02/2025
 * @description		Show Confitmation Coverage Email Warning Messages.
 * @test class		CreateWarningMessagesLwcTest
 * @revisions		February 25,2025  ------------ Deepika Saini ------------
 */

public class CreateWarningMessagesLwc {
	/**
	 * @Author      : Deepika Saini
	 * @Description : Show specific object Confitmation Coverage Email Warning Messages.
	 * @Parm        : objId - Id of Generic Object, objApiName - String Api Name of Generic Object
	 * @Return      : WarningMessagesWrapper
	 **/
	@AuraEnabled
	public static WarningMessagesWrapper showEmailWarningMessages(Id idObjectId, String strObjApiName) {
		List<String> list_WarningMessages;
		if (strObjApiName.equals(BenefitOrderUtil.Benefit_Order)) {
			Set<String> setMessages = checkQATTIAValidations(idObjectId);
			if (!setMessages.isEmpty()) {
				list_WarningMessages = new List<String>(setMessages);
			}
			String strEmailWarningMessage = showEmailWarningMessagesBO(idObjectId);
			if (String.isNotBlank(strEmailWarningMessage)) {
				list_WarningMessages.add(strEmailWarningMessage);
			}
		}

		if (list_WarningMessages != null && !list_WarningMessages.isEmpty() && list_WarningMessages.size() > 0) {
			return new WarningMessagesWrapper(true, list_WarningMessages);
		} else {
			return new WarningMessagesWrapper(false, list_WarningMessages);
		}
	}

	/**
	 * @Author      : Deepika Saini
	 * @Description : Show Benefit Order Confitmation Coverage Email Warning Messages.
	 * @Parm        : objId - Id of Benefit Order
	 * @Return      : String
	 **/
	public static String showEmailWarningMessagesBO(Id idBO) {
		Set<String> set_ValidBORecTypes = new Set<String>{ BenefitOrderUtil.BENEFIT_ORDER_RT_RENEWAL, BenefitOrderUtil.BENEFIT_ORDER_RT_CHANGE, BenefitOrderUtil.BENEFIT_ORDER_RT_NEW_PLAN_DN };
		Set<String> set_OrderStatusToExclude = new Set<String>{ BenefitOrderUtil.STATUS_CANCELLED, BenefitOrderUtil.STATUS_CLOSED_ADMIN };
		Set<String> set_CarriersToExclude = new Set<String>{ CarrierOrderUtil.Name_BASIC };

		try {
			if (String.isBlank(idBO)) {
				return null;
			}

			Benefit_Order__c objBO = [
				SELECT
					RecordType.DeveloperName,
					OwnerId,
					Order_Status__c,
					OE_Complete__c,
					(
						SELECT Id
						FROM Cases__r
						WHERE Integration_Id__c != NULL AND Carrier_Order__c = NULL
						LIMIT 1
					),
					(
						SELECT Order_Assignment__c, Carrier__r.Carrier_Unique_Name__c, Group_Number__c
						FROM Carrier_Orders__r
						WHERE
							Order_Assignment__c != NULL
							AND Carrier__c != NULL
							AND Implementation_Stage__c NOT IN :set_OrderStatusToExclude
							AND Carrier__r.Carrier_Unique_Name__c NOT IN :set_CarriersToExclude
							AND Carrier__r.Partner_Type__c != :CarrierOrderUtil.PARTNER_TYPE_TADA
					)
				FROM Benefit_Order__c
				WHERE Id = :idBO
			];

			if (objBO == null) {
				return null;
			}

			if (set_ValidBORecTypes.contains(objBO.RecordType.DeveloperName) && objBO.Order_Status__c == BenefitOrderUtil.STATUS_APPROVED) {
				if (objBO.Cases__r == null || objBO.Cases__r.isEmpty()) {
					return BenefitOrderUtil.ERR_No_Customer_Case_Associated_BO;
				}

				Map<Id, Integer> map_ExistingEmailCount = OEEmailAutomationHelper.fetchSentEmailCountForCases(
					new Set<Id>{ objBO.Cases__r[0].Id },
					new Set<String>{ BenefitOrderUtil.Template_OE_Confirmation_Email_Default }
				);

				if (map_ExistingEmailCount != null && map_ExistingEmailCount.containsKey(objBO.Cases__r[0].Id) && map_ExistingEmailCount.get(objBO.Cases__r[0].Id) > 0) {
					return BenefitOrderUtil.ERR_Coverage_Confirmation_Email_Sent;
				}

				if (objBO.Carrier_Orders__r != null && !objBO.Carrier_Orders__r.isEmpty()) {
					for (Carrier_Order__c objCO : objBO.Carrier_Orders__r) {
						if (
							(objCO.Order_Assignment__c.containsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_NEW_TO_GUSTO) ||
							objCO.Order_Assignment__c.containsIgnoreCase(TransitiontoFulfilmentUtil.CO_ORDER_TYPE_NEW_LINE_OF_COVERAGE) ||
							objCO.Order_Assignment__c.containsIgnoreCase(CarrierOrderUtil.ORDER_TYPE_CARRIER_SWITCH)) && String.isBlank(objCO.Group_Number__c)
						) {
							return BenefitOrderUtil.ERR_GN_Missing_Send_Email_Manually;
						}
					}
				}
			}
			return null;
		} catch (Exception objExcep) {
			System.debug('BBO-2191 : Exception ' + objExcep + ' Message : ' + objExcep.getMessage());
			return null;
		}
	}

	/**
	 * @name         : checkQATTIAValidations
	 * @author       : Deepika Saini
	 * @date         : 02/25/2025
	 * @description  : Show error on BO detail page for user convenience
	 **/
	public static Set<String> checkQATTIAValidations(Id idBO) {
		QA_Sheet__c objQASheet = new QA_Sheet__c();
		List<QA_Sheet__c> list_QASheet = [
			SELECT
				id,
				name,
				Benefits_Point_of_Contact_Name_SFDC__c,
				Mailing_Address__c,
				Effective_Date__c,
				Benefit_Order__c,
				Benefit_Order__r.Account__c,
				Benefit_Order__r.Account__r.ZP_Company_ID__c,
				RecordTypeId,
				Benefit_Order__r.Opportunity__c,
				Benefit_Order__r.Submission_Deadline__c,
				Benefit_Order__r.Type__c,
				Benefit_Order__r.Opportunity__r.Source_ID__c,
				Benefit_Order__r.Opportunity__r.RecordType.Name,
				Benefit_Order__r.Application_Id__c,
				RecordType.Name,
				Benefit_Order__r.Parent_Benefit_Order__c
			FROM QA_Sheet__c
			WHERE Benefit_Order__c = :idBO
			ORDER BY createdDate DESC
		];
		if (list_QASheet != null && list_QASheet.size() > 0) {
			objQASheet = list_QASheet[0];
		}
		Set<String> set_QACoveragesRequiredFieldsName = new Set<String>{ 'Participation_Requirements__c' };
		Set<String> set_Messages = new Set<String>();
		if (objQASheet.Benefit_Order__c != null && objQASheet.Benefit_Order__r.Submission_Deadline__c == null && objQASheet.Benefit_Order__r.Type__c == null) {
			set_Messages.add(BenefitOrderUtil.ERR_ORDER_TYPE_AND_SUBMISSION_DATE_IS_BLANK);
		} else if (objQASheet.Benefit_Order__c != null && objQASheet.Benefit_Order__r.Submission_Deadline__c == null) {
			set_Messages.add(BenefitOrderUtil.ERR_SUBMISSION_DATE_IS_BLANK);
		} else if (objQASheet.Benefit_Order__c != null && objQASheet.Benefit_Order__r.Type__c == null) {
			set_Messages.add(BenefitOrderUtil.ERR_ORDER_TYPE_IS_BLANK);
		}

		String strCarrierNames = '';
		if (String.isNotBlank(objQASheet.Benefit_Order__c)) {
			for (Carrier_Order__c ObjCarrierOrder : [
				SELECT Id, Name, Order_Type__c, Submission_Deadline_Date__c
				FROM Carrier_Order__c
				WHERE Benefit_Order__c = :objQASheet.Benefit_Order__c AND (Order_Type__c = NULL OR Submission_Deadline_Date__c = NULL)
			]) {
				if (ObjCarrierOrder.Order_Type__c == null || ObjCarrierOrder.Submission_Deadline_Date__c == null) {
					strCarrierNames += ObjCarrierOrder.Name + ', ';
				}
			}
		}

		if (String.isNotBlank(strCarrierNames)) {
			strCarrierNames = strCarrierNames.removeEnd(', ');
			String strErrorMessage = BenefitOrderUtil.ERR_ORDER_TYPE_AND_SUBMISSION_DATE_IS_BLANK_ON_CO.replace('[CARRIERNAMES]', strCarrierNames);
			set_Messages.add(strErrorMessage);
		}

		return set_Messages;
	}

	/**
	 * @name         : WarningMessagesWrapper
	 * @author       : Deepika Saini
	 * @date         : 02/25/2025
	 * @description  : Wrapper class to share data between Apex and LWC
	 **/
	public class WarningMessagesWrapper {
		/* Success flag */
		@AuraEnabled
		public Boolean blnIsSuccess;

		/* Message */
		@AuraEnabled
		public List<String> list_Message;

		public WarningMessagesWrapper(Boolean blnIsSuccess, List<String> list_Message) {
			this.blnIsSuccess = blnIsSuccess;
			this.list_Message = list_Message;
		}
	}
}