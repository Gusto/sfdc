/**
Created by : Gaurav Khare
Created Date : 5/21/2019
**/

@isTest
public class BulkUserUploadControllerTest {
	@isTest
	static void uploadDataTest() {
		try {
			Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
			Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

			User cloneUsr = new User(
				Alias = 'gusst11',
				Email = 'cloneuserUnique12March@test.com',
				EmailEncodingKey = 'UTF-8',
				FirstName = 'CreateUser',
				LastName = 'Test',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				ProfileId = p.Id,
				TimeZoneSidKey = 'America/Los_Angeles',
				UserName = 'cloneuserUnique12March@test.com',
				Out_Of_Office__c = false
			);
			insert cloneUsr;

			User updateUser = new User(
				Alias = 'gusst11',
				Email = 'CloneUser2@test.com',
				EmailEncodingKey = 'UTF-8',
				FirstName = 'UpdateUser',
				LastName = 'Test',
				LanguageLocaleKey = 'en_US',
				LocaleSidKey = 'en_US',
				ProfileId = p2.Id,
				TimeZoneSidKey = 'America/Los_Angeles',
				UserName = 'update@user.com',
				Out_Of_Office__c = false
			);
			insert updateUser;

			System.runAs(cloneUsr) {
				PermissionSet ps1 = new PermissionSet();
				ps1.label = 'PermSet1';
				ps1.name = 'PermSet1';
				insert ps1;

				PermissionSet ps2 = new PermissionSet();
				ps2.label = 'PermSet2';
				ps2.name = 'PermSet2';
				insert ps2;
				insert new PermissionSetAssignment(AssigneeId = cloneUsr.id, PermissionSetId = ps1.Id);

				insert new PermissionSetAssignment(AssigneeId = updateUser.id, PermissionSetId = ps2.Id);
			}

			HR_Worker_Information__c hrw = new HR_Worker_Information__c();
			hrw.First_Name__c = 'RaghavTest';
			hrw.Last_Name__c = 'Gupta';
			hrw.Email__c = 'raghavtest.gupta@test.com';
			hrw.Manager_Email__c = 'mngrraghavtest.gupta@test.com';
			hrw.Team__c = 'Team C';
			hrw.Sub_Team__c = 'SubTeam C';
			insert hrw;

			HR_Worker_Information__c hrw3 = new HR_Worker_Information__c();
			hrw3.First_Name__c = 'RaghavTest1';
			hrw3.Last_Name__c = 'Gupta1';
			hrw3.Email__c = 'raghavtest1.gupta1@test.com';
			hrw3.Manager_Email__c = 'mngrraghavtest1.gupta1@test.com';
			hrw3.Team__c = 'Team D';
			hrw3.Sub_Team__c = 'SubTeam D';
			insert hrw3;

			HR_Worker_Information__c hrw1 = new HR_Worker_Information__c();
			hrw1.First_Name__c = 'CloneUser';
			hrw1.Last_Name__c = 'Gupta';
			hrw1.Email__c = 'cloneuserUnique12March@test.com';
			hrw1.Manager_Email__c = 'mngrcloneuserUnique12March@test.com';
			hrw1.Team__c = 'TeamA';
			hrw1.Sub_Team__c = 'SubTeamA';
			insert hrw1;

			HR_Worker_Information__c hrw2 = new HR_Worker_Information__c();
			hrw2.First_Name__c = 'CloneUser2';
			hrw2.Last_Name__c = 'Gupta2';
			hrw2.Email__c = 'cloneuser2@test.com';
			hrw2.Manager_Email__c = 'mngrcloneuser2@test.com';
			hrw2.Team__c = 'TeamB';
			hrw2.Sub_Team__c = 'SubTeamB';
			insert hrw2;

			List<Bulk_User_CSV_Columns__c> listCustSettings = new List<Bulk_User_CSV_Columns__c>();

			Bulk_User_CSV_Columns__c csvCustomSetting = new Bulk_User_CSV_Columns__c();
			csvCustomSetting.Name = 'Clone From User';
			csvCustomSetting.Field_Values__c = 'Clone From User';
			csvCustomSetting.Field_API_Name__c = 'Clone_From_User__c';
			listCustSettings.add(csvCustomSetting);

			Bulk_User_CSV_Columns__c csvCustomSetting1 = new Bulk_User_CSV_Columns__c();
			csvCustomSetting1.Name = 'Create New User';
			csvCustomSetting1.Field_Values__c = 'Create New User';
			csvCustomSetting1.Field_API_Name__c = 'Create_New_User__c';
			listCustSettings.add(csvCustomSetting1);

			Bulk_User_CSV_Columns__c csvCustomSetting2 = new Bulk_User_CSV_Columns__c();
			csvCustomSetting2.Name = 'Email';
			csvCustomSetting2.Field_Values__c = 'Email';
			csvCustomSetting2.Field_API_Name__c = 'Email__c';
			listCustSettings.add(csvCustomSetting2);

			Bulk_User_CSV_Columns__c csvCustomSetting3 = new Bulk_User_CSV_Columns__c();
			csvCustomSetting3.Name = 'Team';
			csvCustomSetting3.Field_Values__c = 'Team';
			csvCustomSetting3.Field_API_Name__c = 'Team__c';
			listCustSettings.add(csvCustomSetting3);

			Bulk_User_CSV_Columns__c csvCustomSetting4 = new Bulk_User_CSV_Columns__c();
			csvCustomSetting4.Name = 'Sub Team';
			csvCustomSetting4.Field_Values__c = 'Sub Team';
			csvCustomSetting4.Field_API_Name__c = 'Sub_Team__c';
			listCustSettings.add(csvCustomSetting4);

			insert listCustSettings;

			BulkUserUploadController bulkUserController = new BulkUserUploadController();

			Test.startTest();
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\nraghavtest.gupta@test.com,TeamA,SubTeamA,TRUE\r\ncloneuserUnique12March@test.com,TeamB,SubTeamB,FALSE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();
			bulkUserController.discard();

			bulkUserController.testCSVData = '';
			bulkUserController.readFromFile();
			Test.stopTest();
			// Clone from User
			bulkUserController.testCSVData = 'Email,Clone From User,Team,Sub Team,Create New User\r\nraghavtest1.gupta1@test.com,cloneuserUnique12March@test.com,TeamA,SubTeamA,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			bulkUserController.testCSVData = 'Email,Clone From User,Team,Sub Team,Create New User\r\ncloneuser2@test.com,cloneuserUnique12March@test.com,TeamB,SubTeamB,FALSE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// Clone from user but no user with matching email
			bulkUserController.testCSVData = 'Email,Clone From User,Team,Sub Team,Create New User\r\nraghavtest1.gupta1@test.com,differentemail@test.com,TeamA,SubTeamA,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// Blank Email
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\n,TEAM A,SUBTEAM A,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// Blank Team
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\ner_gauravaec@hotmail.com,,SUBTEAM A,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// Blank Sub Team
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\ner_gauravaec@hotmail.com,TEAM A,,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// No matching email in HR worker information
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\ner_gauravaec@hotmail.com,TEAM A,SUBTEAM A,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// No matching team in HR worker information
			bulkUserController.testCSVData = 'Email,Team,Sub Team,Create New User\r\nraghavtest.gupta@test.com,TEAM E,SUBTEAM E,TRUE\r\n';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			// Blank Email in Update User case
			bulkUserController.testCSVData = 'First Name,Last Name,Email,Clone From User,Create New User\r\nFname2,LastName2,,clonefrom@user.com,FALSE';
			bulkUserController.readFromFile();
			bulkUserController.confirm();

			Set<Id> setbulkCSVData = new Set<Id>();
			List<Bulk_User_CSV_Data__c> listBulkData = [
				SELECT Id, First_Name__c, Last_Name__c, Email__c, Clone_From_User__c, Create_New_User__c, Processing_State__c, Last_Processed__c, Message__c, CSV_id__c
				FROM Bulk_User_CSV_Data__c
			];

			for (Bulk_User_CSV_Data__c obj : listBulkData) {
				setbulkCSVData.add(obj.Id);
			}
			BulkUserCSVDataTriggerHelper helper = new BulkUserCSVDataTriggerHelper();
			helper.updateStatus(new Map<String, String>(), setbulkCSVData);

			// New User Created with First name = RaghavTest
			// User usersNew = [SELECT FirstName, LastName, Email FROM User WHERE email = 'RaghavTest.gupta@test.com'];

			// User update user updated with profile = p.Id
			User usersUpdate = [SELECT FirstName, LastName, Email, ProfileId FROM User WHERE Email = 'cloneuserUnique12March@test.com'];

			update listBulkData;
			delete listBulkData;
			undelete listBulkData;

			PageReference pageRef = Page.BulkUserUploadStatus;
			Test.setCurrentPageReference(pageRef);
			pageRef.getParameters().put('csvid', listBulkData[0].CSV_Id__c);
			BulkUserUploadStatus data = new BulkUserUploadStatus();
			data.refreshData();
		} catch (Exception e) {
			System.assert(false, 'There should be no exception while running the code.');
		}
	}
}