/**
* @name         : EmailToCaseRecoveryEmlSvc
* @author       : Sean DesMarteau
* @date         : 03-05-2021
* @description  : Inbound email handler that can be used for reprocessing failed Email to Case records.
                  The class will attempt to find the From, To, Subject, and Body from the email to case failure email
                  and populate a record in the BizTech Temp Object. This record can then be used to create a Case and Email
                  so the email is not lost. If the email can not be parsed correctly a record is still inserted with the full email
                  so manual parsing can be done.
* @test classes : EmailToCaseRecoveryEmlSvcTest
**/
global inherited sharing class EmailToCaseRecoveryEmlSvc implements Messaging.InboundEmailHandler {
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelop) {
		BizTechTempObjTriggerHandler.SkipTrigger = true;
		String strActualEmailMessage;
		String strFrom = '';
		String strTo = '';
		String strSubjectAndBody = '';

		String strFullFrom = '';
		String strFullTo = '';
		String strFullSubject = '';
		String strFullSubjectToRemove = '';

		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		BizTech_Temp_Obj__c objBizTechTemp = new BizTech_Temp_Obj__c();

		try {
			// INTIALIZE TEMP OBJECT
			objBizTechTemp = new BizTech_Temp_Obj__c();
			objBizTechTemp.Full_Email__c = email.plainTextBody.length() > 131072 ? email.plainTextBody.substring(0, 131068) : email.plainTextBody;

			// REMOVE EMAIL TO CASE ERROR MESSAGING
			strActualEmailMessage = objBizTechTemp.Full_Email__c.substring(objBizTechTemp.Full_Email__c.indexOf('From:', objBizTechTemp.Full_Email__c.indexOf('From:') + 1));

			// GET FROM
			strFrom = strActualEmailMessage.substring(0, strActualEmailMessage.indexOf('Sent: ')).substringAfter('From: ');
			List<String> list_FromSplit = strFrom.split('\\n');
			for (String strFromSplitValue : list_FromSplit) {
				if (String.isBlank(strFromSplitValue)) {
					break;
				}

				if (String.isBlank(strFullFrom)) {
					strFullFrom += strFromSplitValue;
				} else {
					strFullFrom = strFullFrom + ' ' + strFromSplitValue;
				}
			}

			objBizTechTemp.From_Addresses__c = strFullFrom.substring(0, strFullFrom.indexof('('));

			objBizTechTemp.From_Name__c = strFullFrom.substringBetween('(', ')');

			// GET TO
			strTo = strActualEmailMessage.substring(0, strActualEmailMessage.indexOf('Subject: ')).substringAfter('To: ');
			List<String> list_ToSplit = strTo.split('\\n');
			for (String strToSplitValue : list_ToSplit) {
				strToSplitValue = strToSplitValue.replace('\\n', '');
				if (String.isBlank(strToSplitValue)) {
					break;
				}

				if (String.isBlank(strFullTo)) {
					strFullTo = strToSplitValue;
				} else {
					strFullTo = strFullTo + ' ' + strToSplitValue;
				}
			}

			objBizTechTemp.To_Address__c = strFullTo.substringBetween('[', ']');

			// GET SUBJECT
			strSubjectAndBody = strActualEmailMessage.substringAfter('Subject: ');
			List<String> list_SubjectAndBodySplit = strSubjectAndBody.split('\\n');
			for (String strSubjectAndBodySplitValue : list_SubjectAndBodySplit) {
				if (String.isBlank(strSubjectAndBodySplitValue)) {
					strFullSubjectToRemove = strFullSubjectToRemove + '\n' + strSubjectAndBodySplitValue;
					break;
				}

				if (String.isBlank(strFullSubject)) {
					strFullSubject += strSubjectAndBodySplitValue;
					strFullSubjectToRemove += strSubjectAndBodySplitValue;
				} else {
					strFullSubject = strFullSubject + ' ' + strSubjectAndBodySplitValue;
					strFullSubjectToRemove = strFullSubjectToRemove + '\n' + strSubjectAndBodySplitValue;
				}
			}

			objBizTechTemp.Subject__c = strFullSubject;

			// GET BODY
			objBizTechTemp.Text_Body__c = strSubjectAndBody.removeStart(strFullSubjectToRemove);

			objBizTechTemp.Processing_State__c = 'Processed';
			objBizTechTemp.Message__c = 'Inbound Email Parsed Successfully';

			insert objBizTechTemp;
		} catch (Exception ex) {
			ExceptionLogUtil.logException('EmailToCaseRecoveryInboundService', 'handleInboundEmail', ex.getMessage(), ex.getStackTraceString());

			// Insert Full Email and Parse Manually
			objBizTechTemp = new BizTech_Temp_Obj__c();
			objBizTechTemp.Full_Email__c = email.plainTextBody.length() > 131072 ? email.plainTextBody.substring(0, 131068) : email.plainTextBody;

			objBizTechTemp.Processing_State__c = 'Error';
			objBizTechTemp.Message__c = ex.getMessage();

			insert objBizTechTemp;
		}

		result.success = true;
		return result;
	}
}