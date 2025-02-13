/*
   Copyright 2011 Mavens Consulting, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
@isTest
private class SmartFactoryTest {
	static {
		SmartFactory.FillAllFields = true; // increase test coverage without creating custom objects
	}

	static testMethod void createsSingleObjectWithSingleRequiredStringField() {
		Account account = (Account) SmartFactory.createSObject('Account');
		account.Partner_Detailed_Status__c = 'No Additional Clients to Move';
		account.HI_Closed_Lost_Detail__c = null;
		account.HI_Closed_Lost_Detail_2__c = null;
		account.agentsync__NPN__c = '12312312';
		insert account;
		System.assert(account.Id != null);
		System.assert(account.Name != null);
	}

	static testMethod void createObjectWithUnsupportedTypeThrowsException() {
		try {
			SmartFactory.createSObject('Unsupported');
			System.assert(false);
		} catch (UnsupportedObjectTypeException ex) {
			System.assert(true);
		}
	}

	/**
	 * @Author       : Alex Xiong
	 * @Description  : Tests createSObjectList()
	 */
	@isTest
	static void testCreateSObjectList() {
		List<Account> list_Account = (List<Account>) SmartFactory.createSObjectList('Account', false, 1);
		System.assert(list_Account.size() > 0);
	}

	/**
	 * @Author       : Alex Xiong
	 * @Description  : Tests createGFTicket()
	 */
	@isTest
	static void testCreateGFTicket() {
		GF_Ticket__c objGFTix = SmartFactory.createGFTicket(
			'000002345',
			'0101111',
			'testCreateSObjectList',
			'testCreateSObjectList@test.com',
			'support_form',
			'{"accounting_firm_id":null,"company_first_pay_date":"2021-01-14","active_employee_count":10,"inactive_employee_count":0,"contractor_count":0,"payroll_schedule":"Every other week","states":["CO","CA"],"notice_period":"Q1 2021","agency_slug":"unknown","is_in_app_notice":"false"}',
			'SomeRandomString',
			'[]',
			'route_to_taxres'
		);
		System.assert(objGFTix != null);
	}
}