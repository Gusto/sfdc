@isTest
class ConfirmationAutomationHelperTest {
	@TestSetup
	static void createDataForConfirmationAutomationEvent() {
		OpportunityTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		BenefitOrderHelper.skipTrigger = true;
		BenefitOrderHelper.skipTaskCreation = true;

		Opportunity objOpp = TestUtility.BenefitsRenewalOpportunity();

		Account objAcc = new Account(Id = objOpp.AccountId, ZP_Company_Id__c = '5102020');
		objOpp.Source_ID__c = 'hawaiian_ice-renewal-24643';
		update objOpp;
		update objAcc;

		Carrier__c objCarrier = TestUtility.Carrier();
		objCarrier.Name = 'Beam Dental';
		objCarrier.Key__c = 'Beam64';
		objCarrier.ID__c = '259';
		objCarrier.Carrier_Id__c = '64';
		update objCarrier;

		Benefit_Order__c objBenefitOrder = new Benefit_Order__c();
		objBenefitOrder.Opportunity__c = objOpp.id;
		objBenefitOrder.Account__c = objOpp.Accountid;
		objBenefitOrder.UW_Owner__c = UserInfo.getUserId();
		objBenefitOrder.Type__c = 'BOR BOR TAdA Only';
		objBenefitOrder.Order_Status__c = 'Ready for Qualification';
		objBenefitOrder.BOR_ID__c = 'zpEIN6789021';
		objBenefitOrder.ownerid = userInfo.getuserId();
		objBenefitOrder.Is_Multi_EIN__c = false;
		objBenefitOrder.RecordTypeId = Cache.getRecordTypeId('Benefit_Order__c', 'Renewal');
		insert objBenefitOrder;

		Carrier_Order__c objCarrierOrder = new Carrier_Order__c();
		objCarrierOrder.Carrier__c = objCarrier.Id;
		objCarrierOrder.Benefit_Order__c = objBenefitOrder.id;
		objCarrierOrder.Implementation_Stage__c = 'Ready for Qualification';
		objCarrierOrder.Start_Date__c = System.today() - 50;
		objCarrierOrder.RecordTypeId = Cache.getRecordTypeId('Carrier_Order__c', 'Renewal');
		objCarrierOrder.OwnerId = UserInfo.getUserId();
		objCarrierOrder.Is_Multi_EIN__c = false;
		objCarrierOrder.Order_Playable_Date__c = system.today().addDays(10);
		insert objCarrierOrder;
	}

	static testMethod void testConfirmationAutomationEventApplicationTypeMissing() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_type__c = 'group_confirmations_automation');
		objHIGroupEvent.Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12';
		objHIGroupEvent.Event_Info__c = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","state_carrier_id":259,"hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Failed"}],"event_type":"group_confirmations_automation"}';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Error'
		);
	}

	static testMethod void testConfirmationAutomationEventCompanyIdMissing() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_type__c = 'group_confirmations_automation');
		objHIGroupEvent.Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12';
		objHIGroupEvent.Event_Info__c = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","state_carrier_id":259,"hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Failed"}],"event_type":"group_confirmations_automation"}';
		objHIGroupEvent.Company_Id__c = null;
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Error'
		);
	}

	static testMethod void testConfirmationAutomationEventApplicationIdMissing() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_type__c = 'group_confirmations_automation');
		objHIGroupEvent.Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12';
		objHIGroupEvent.Event_Info__c = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","state_carrier_id":259,"hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Failed"}],"event_type":"group_confirmations_automation"}';
		objHIGroupEvent.Application_Id__c = null;
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Error'
		);
	}

	static testMethod void testConfirmationAutomationEventInfoMissing() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_type__c = 'group_confirmations_automation');
		objHIGroupEvent.Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12';
		objHIGroupEvent.Event_Info__c = '';
		objHIGroupEvent.Application_Id__c = '24643';
		objHIGroupEvent.Company_Id__c = '5102020';
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Error'
		);
	}

	static testMethod void testConfirmationAutomationEventsValidation() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		String strMasterJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","state_carrier_id":259,"hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Failed"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(Event_type__c = 'group_confirmations_automation');
		objHIGroupEvent.Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12';
		objHIGroupEvent.Event_Info__c = strMasterJSON;
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Processed'
		);
	}

	static testMethod void testConfirmationAutomationEventsForUnableToAuditStatus() {
		Test.StartTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		String strJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"unable to audit"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Event_type__c = 'group_confirmations_automation',
			Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12',
			Event_Info__c = strJSON,
			Company_Id__c = '5102020',
			Application_Id__c = '24643',
			Application_type__c = 'Renewal'
		);
		insert objHIGroupEvent;

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Processed'
		);

		objHIGroupEvent.Event_Info__c = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"testing ","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":null,"event_type":"group_confirmations_automation"}';
		objHIGroupEvent.Processing_State__c = 'Queued';
		update objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Processed'
		);
	}

	static testMethod void testConfirmationAutomationCarrierDataNotAvailableYetStatus() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		String strJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Carrier data not available yet"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Event_type__c = 'group_confirmations_automation',
			Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12',
			Event_Info__c = strJSON,
			Company_Id__c = '5102020',
			Application_Id__c = '24643',
			Application_type__c = 'Renewal'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Processed'
		);
	}

	static testMethod void testConfirmationAutomationSuccessStatus() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		String strJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Success"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Event_type__c = 'group_confirmations_automation',
			Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12',
			Event_Info__c = strJSON,
			Company_Id__c = '5102020',
			Application_Id__c = '24643',
			Application_type__c = 'Renewal'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			'Processed'
		);
	}

	static testMethod void testConfirmationAutomationPendingAuditStatus() {
		Test.startTest();
		Carrier_Order__c objCarrierOrder = [
			SELECT Implementation_Stage__c
			FROM Carrier_Order__c
			WHERE
				Benefit_Order__c != NULL
				AND Benefit_Order__r.Account__c != NULL
				AND Benefit_Order__r.Account__r.ZP_Company_Id__c = '5102020'
			LIMIT 1
		];
		objCarrierOrder.Implementation_Stage__c = 'Ready for Confirmation';
		update objCarrierOrder;

		String strJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Pending audit"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Event_type__c = 'group_confirmations_automation',
			Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12',
			Event_Info__c = strJSON,
			Company_Id__c = '5102020',
			Application_Id__c = '24643',
			Application_type__c = 'Renewal'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			IntegrationUtils.PROCESSED_STATE
		);
		System.assert(
			[SELECT Implementation_Stage__c FROM Carrier_Order__c WHERE Id = :objCarrierOrder.Id]
			.Implementation_Stage__c == 'Approved Pending EE Audit'
		);
	}

	static testMethod void testConfirmationAutomationCarrierOrderNotPresent() {
		Test.startTest();
		String strJSON = '{"Id":"c58b1e1a-b0f3-4602-a067-7bfbaab8kjll","state_carrier_id":"259","error_message":"","company_id":5102020,"application_id":24643,"application_type":"Renewal","policies":[{"benefit_type":"Dental","id":1234999,"name":"new dental 2","hi_confirmation_page_link":"https://hippo.gusto.com/companies/7757616923608981/group_confirmations/data_comparison_table?policy_id=1234999","hi_confirmation_automation_message":"error details","hi_confirmation_automation_status":"Pending audit"}],"event_type":"group_confirmations_automation"}';
		HIGroupEvent__c objHIGroupEvent = new HIGroupEvent__c(
			Event_type__c = 'group_confirmations_automation',
			Event_Id__c = 'ecbc176c-815e-4bc3-b545-58f3fe4deae12',
			Event_Info__c = strJSON,
			Company_Id__c = '5102020',
			Application_Id__c = '24643',
			Application_type__c = 'Renewal'
		);
		insert objHIGroupEvent;
		Test.stopTest();

		System.assert(
			[SELECT Processing_State__c FROM HIGroupEvent__c WHERE Id = :objHIGroupEvent.Id].Processing_State__c ==
			IntegrationUtils.ERROR_STATE
		);
	}
}