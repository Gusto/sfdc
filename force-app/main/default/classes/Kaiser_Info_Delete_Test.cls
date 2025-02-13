@isTest
private class Kaiser_Info_Delete_Test {
	@isTest
	static void deleteCaliforniaGroups() {
		List<Kaiser_Groups_Info__c> list_GroupsInfo = null;
		Kaiser_Groups_Info__c objGroupInfo = new Kaiser_Groups_Info__c(Region_ID__c = 'SCR', Group_ID__c = '987654', Subgroup_ID__c = '002', Billgroup_ID__c = 'BB', Plan_Name__c = 'Dental');
		insert objGroupInfo;

		Test.startTest();
		list_GroupsInfo = [SELECT Id FROM Kaiser_Groups_Info__c];
		System.assert(!list_GroupsInfo.isEmpty());

		//create request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/kaiser/delete/kaiserInfo/';
		req.addParameter('object', 'Kaiser_Groups_Info__c');
		req.addParameter('region', 'CA');
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;

		String result = Kaiser_Info_Delete.DeleteGroupsOrMembersInfo();
		System.assertEquals('SUCCESS', result);

		list_GroupsInfo = [SELECT Id FROM Kaiser_Groups_Info__c];
		System.assert(list_GroupsInfo.isEmpty());
		Test.stopTest();
	}

	@isTest
	static void deleteOtherGroups() {
		List<Kaiser_Groups_Info__c> list_GroupsInfo = null;
		Kaiser_Groups_Info__c objGroupInfo = new Kaiser_Groups_Info__c(Region_ID__c = 'MA', Group_ID__c = '987654', Subgroup_ID__c = '002', Billgroup_ID__c = 'BB', Plan_Name__c = 'Dental');
		insert objGroupInfo;

		Test.startTest();
		list_GroupsInfo = [SELECT Id FROM Kaiser_Groups_Info__c];
		System.assert(!list_GroupsInfo.isEmpty());

		//create request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/kaiser/delete/kaiserInfo/';
		req.addParameter('object', 'Kaiser_Groups_Info__c');
		req.addParameter('region', 'MA');
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;

		String result = Kaiser_Info_Delete.DeleteGroupsOrMembersInfo();
		System.assertEquals('SUCCESS', result);

		list_GroupsInfo = [SELECT Id FROM Kaiser_Groups_Info__c];
		System.assert(list_GroupsInfo.isEmpty());
		Test.stopTest();
	}

	@isTest
	static void deleteCaliforniaMembers() {
		List<Kaiser_Member_Info__c> list_MembersInfo = null;
		Kaiser_Member_Info__c objMemberInfo = new Kaiser_Member_Info__c(KP_Region_Code__c = 'NCR', Subscriber_MRN__c = '987654');
		insert objMemberInfo;

		Test.startTest();
		list_MembersInfo = [SELECT Id FROM Kaiser_Member_Info__c];
		System.assert(!list_MembersInfo.isEmpty());

		//create request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/kaiser/delete/kaiserInfo/';
		req.addParameter('object', 'Kaiser_Member_Info__c');
		req.addParameter('region', 'CA');
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;

		String result = Kaiser_Info_Delete.DeleteGroupsOrMembersInfo();
		System.assertEquals('SUCCESS', result);

		list_MembersInfo = [SELECT Id FROM Kaiser_Member_Info__c];
		System.assert(list_MembersInfo.isEmpty());
		Test.stopTest();
	}

	@isTest
	static void deleteOtherMembers() {
		List<Kaiser_Member_Info__c> list_MembersInfo = null;
		Kaiser_Member_Info__c objMemberInfo = new Kaiser_Member_Info__c(KP_Region_Code__c = 'MA', Subscriber_MRN__c = '987654');
		insert objMemberInfo;

		Test.startTest();
		list_MembersInfo = [SELECT Id FROM Kaiser_Member_Info__c];
		System.assert(!list_MembersInfo.isEmpty());

		//create request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/kaiser/delete/kaiserInfo/';
		req.addParameter('object', 'Kaiser_Member_Info__c');
		req.addParameter('region', 'MA');
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;

		String result = Kaiser_Info_Delete.DeleteGroupsOrMembersInfo();
		System.assertEquals('SUCCESS', result);

		list_MembersInfo = [SELECT Id FROM Kaiser_Member_Info__c];
		System.assert(list_MembersInfo.isEmpty());
		Test.stopTest();
	}

	@isTest
	static void deleteGroupsWOParam() {
		Test.startTest();
		//create request
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		req.requestURI = '/kaiser/delete/kaiserInfo/';
		req.addParameter('object', 'No Param');
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;

		String result = Kaiser_Info_Delete.DeleteGroupsOrMembersInfo();
		System.assertEquals('FAILURE', result);
		Test.stopTest();
	}
}