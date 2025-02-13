@isTest
private class UR_ManageCSVCtrl_Test {
	@testSetup
	static void CreateTestData() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		UR_TestDataUtil.createResearchConfig();
		List<Contact> list_Contacts = UR_TestDataUtil.createContact(3);
		Contact objContact = list_Contacts[2];
		objContact.Email = 'Test.user+user33@lirik.io';
		objContact.UXResearch_Opt_Out__c = true;
		objContact.HasOptedOutOfEmail = true;
		objContact.Salesloft_Email_Opt_Out__c = true;
		update objContact;

		Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 11');
		Research_Upload_Info__c objUploadInfo = new Research_Upload_Info__c();
		objUploadInfo.Research_Project_Master__c = projectObj.Id;
		objUploadInfo.First_Name__c = 'Test';
		objUploadInfo.Last_Name__c = 'user1';
		objUploadInfo.Email__c = 'TestEmail_0@gmail.com';
		objUploadInfo.Company_Id__c = '1001';
		objUploadInfo.User_Id__c = '44001';
		objUploadInfo.Employee_Id__c = '55001';
		objUploadInfo.Accountant_Firm_Id__c = '';
		insert objUploadInfo;
		UR_ManageCSVCtrl testObj = new UR_ManageCSVCtrl();

		ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(projectObj);
		ApexPages.currentPage().getParameters().put('projectId', projectObj.Id);
		UR_ManageContactCtrl controller1 = new UR_ManageContactCtrl(sc1);
		controller1.SearchContact();
		for (UR_ManageContactCtrl.ContactWrapper ctw : controller1.lstMainContactWrapper) {
			ctw.selContact = true;
		}
		controller1.AddContact();
		controller1.SaveContact();
        
        delete objUploadInfo;
	}

	static testMethod void uploadCSVTest() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		List<Research_Project_Master__c> projectObjList = [SELECT id FROM Research_Project_Master__c WHERE name = 'Test Case 11'];
		Research_Project_Master__c projectObj = projectObjList[0];
		List<Contact> contactList = [SELECT id FROM contact LIMIT 2];
		List<Research_Project_Detail__c> projectDetailList = UR_TestDataUtil.createResearchProjectDetails(contactList, projectObj.Id);

		UR_TestDataUtil.createResearchUploadInfoList(projectObj.Id);

		createRsUploadRecord(projectObj.Id, 2, 'testcase1');
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
		ApexPages.currentPage().getParameters().put('projectId', projectObj.Id);
		UR_ManageCSVCtrl controller = new UR_ManageCSVCtrl(sc);
		controller.init();
		String csvBody =
			'first_name,last_name,email,company_id,user_id,employee_id,accounting_firm_id,Role' +
			'\n' +
			'Test,user1,TestEmail_0@gmail.com,33001,44001,55001,,Test' +
			'\n' +
			'Test,user2,Test.user+user22@lirik.io,33002,44002,,100041,Test' +
			'\n' +
			'Test,user3,Test.user+user33@lirik.io,33003,44003,55003,100042,Test';

		controller.csvFileBody = Blob.valueOf(csvBody);
		controller.csvFileName = 'Test.csv';
		controller.importCSVFile();
		Research_Upload_Info__c uploadInfoObj = [SELECT id FROM Research_Upload_Info__c LIMIT 1];
		if (uploadInfoObj != null) {
			update uploadInfoObj;
		}

		controller.init();
		controller.FirstName = 'Test';
		controller.LastName = 'user1';
		controller.Email = 'Test.user+user11@lirik.io';
		controller.CompanyId = '33001';
		controller.UserId = '44001';
		controller.EmployeeId = '55001';

		controller.showAll();
		controller.HideFilter();
		controller.resetAll();

		controller.showAll();
		Integer iCount = 0;
		for (UR_ManageCSVCtrl.ResearchUploadInfo resUploadObj : controller.researchUploadInfoList) {
			resUploadObj.flag = true;
			if (iCount == 0) {
				resUploadObj.removeflag = true;
			}
			iCount = iCount + 1;
		}
		controller.addContact();

		controller.convertedResList.addAll(controller.researchUploadInfoList);
		Integer recordCount = 0;
		for (UR_ManageCSVCtrl.ResearchUploadInfo resUploadObj : controller.convertedResList) {
			if (recordCount == 0) {
				resUploadObj.removeflag = true;
			} else {
				resUploadObj.removeflag = false;
			}
			recordCount = recordCount + 1;
		}
		controller.removeContact();
		controller.saveContact();
		controller.updatedExistingParicipant();
	}

	static testMethod void uploadCSVProgress() {
		Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 22');
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
		ApexPages.currentPage().getParameters().put('projectId', projectObj.Id);
		UR_ManageCSVCtrl controller = new UR_ManageCSVCtrl(sc);
		controller.init();
		String csvBody =
			'first_name,last_name,email,company_id,user_id,employee_id,accounting_firm_id,Role' +
			'\n' +
			'Test,user1,TestEmail_0@gmail.com,33001,44001,55001,,Test' +
			'\n' +
			'Test,user2,Test.user+user22@lirik.io,33002,44002,,100041,Test' +
			'\n' +
			'Test,user3,Test.user+user33@lirik.io,33003,44003,55003,100042,Test';

		controller.csvFileBody = Blob.valueOf(csvBody);
		controller.csvFileName = 'Test.csv';
		controller.importCSVFile();

		controller.checkUploadInprogress();
		controller.addParticipants();
		controller.selSetSortingFilter();
		controller.setSortingFilter();

		//controller.sortManageContactList();
		//controller.selSortManageContactList();

		//projectObj.Uploaded_CSV_Column__c = 8;
		//update projectObj;

		/*
        ApexPages.CurrentPage().getparameters().put('projectId', projectObj.Id);
        UR_ManageCSVRecordCtrl failCSVObj = new UR_ManageCSVRecordCtrl();
        failCSVObj.fetchList();
        */

		/*  controller.getTotalRecord();
        controller.getTotalPages();
        controller.first();
        controller.last();
        controller.previous();
        controller.next();
        controller.downloadCSV();
        controller.markProjectCompleted();
        controller.manageParticipant();
        controller.CheckParticipant();
        controller.extraNOP = '13';
        controller.SendApprovalRequest();
        controller.deleteResearchUploadInfo();*/
	}

	static testMethod void downloadFailCSVRecordTest() {
		List<Research_Project_Master__c> projectObjList = [SELECT id FROM Research_Project_Master__c WHERE name = 'Test Case 11'];
		Research_Project_Master__c projectObj = projectObjList[0];

		UXR_CSV_Staging__c objStaging = new UXR_CSV_Staging__c();
		objStaging.Research_Project_Master__c = projectObj.Id;
		objStaging.First_Name__c = 'Test1';
		objStaging.Last_Name__c = 'Test1';
		objStaging.Email__c = 'Test1@gmail.com';
		objStaging.CSV_Header__c = false;
		objStaging.CSV_File_Name__c = 'test@.csv';
		objStaging.User_Id__c = '12121';
		objStaging.Employee_Id__c = '12111';
		objStaging.Company_Id__c = '12222';
		objStaging.Status__c = 'Fail';
		objStaging.Message__c = 'Company Id does not exist';
		objStaging.Accountant_Firm_Id__c = '121211';
		insert objStaging;

		ApexPages.CurrentPage().getparameters().put('projectId', projectObj.Id);
		UR_ManageCSVRecordCtrl failCSVObj = new UR_ManageCSVRecordCtrl();
		failCSVObj.fetchList();
	}

	static testMethod void excludedRecordTest() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		List<Research_Project_Master__c> projectObjList = [SELECT id, Project_Status__c FROM Research_Project_Master__c WHERE name = 'Test Case 11'];
		Research_Upload_Info__c objUploadInfo = new Research_Upload_Info__c();
		objUploadInfo.Research_Project_Master__c = projectObjList[0].Id;
		objUploadInfo.First_Name__c = 'Test';
		objUploadInfo.Last_Name__c = 'user1';
		objUploadInfo.Email__c = 'TestEmail_0@gmail.com';
		objUploadInfo.Company_Id__c = '1001';
		objUploadInfo.User_Id__c = '1';
		objUploadInfo.Employee_Id__c = '55001';
		objUploadInfo.Accountant_Firm_Id__c = '';
		insert objUploadInfo;

		Research_Upload_Info__c objUploadInfo1 = new Research_Upload_Info__c();
		objUploadInfo1.Research_Project_Master__c = projectObjList[0].Id;
		objUploadInfo1.First_Name__c = 'Test';
		objUploadInfo1.Last_Name__c = 'user1';
		objUploadInfo1.Email__c = 'TestEmail_5@gmail.com';
		objUploadInfo1.Company_Id__c = '1001';
		objUploadInfo1.User_Id__c = '1';
		objUploadInfo1.Employee_Id__c = '55001';
		objUploadInfo1.Accountant_Firm_Id__c = '';
		insert objUploadInfo1;

		Research_Upload_Info__c objUploadInfo2 = new Research_Upload_Info__c();
		objUploadInfo2.Research_Project_Master__c = projectObjList[0].Id;
		objUploadInfo2.First_Name__c = 'Test';
		objUploadInfo2.Last_Name__c = 'user1';
		objUploadInfo2.Email__c = 'TestEmail_5@gmail.com';
		objUploadInfo2.Company_Id__c = '1001';
		objUploadInfo2.User_Id__c = '10';
		objUploadInfo2.Employee_Id__c = '1001';
		objUploadInfo2.Accountant_Firm_Id__c = '';
		insert objUploadInfo2;

		Research_Upload_Info__c objUploadInfo3 = new Research_Upload_Info__c();
		objUploadInfo3.Research_Project_Master__c = projectObjList[0].Id;
		objUploadInfo3.First_Name__c = 'Test';
		objUploadInfo3.Last_Name__c = 'user1';
		objUploadInfo3.Email__c = 'TestEmail_7@gmail.com';
		objUploadInfo3.Company_Id__c = '1001';
		objUploadInfo3.User_Id__c = '11';
		objUploadInfo3.Employee_Id__c = '1005';
		objUploadInfo3.Accountant_Firm_Id__c = '';
		objUploadInfo3.Blacklist__c = true;
		objUploadInfo3.Opt_Out__c = true;
		insert objUploadInfo3;

		Research_Project_Master__c projectObj = UR_TestDataUtil.createResearchProjectMaster('Test Case 22');
		List<Contact> contactList = [SELECT id FROM contact LIMIT 2];
		List<Research_Project_Detail__c> projectDetailList = UR_TestDataUtil.createResearchProjectDetails(contactList, projectObj.Id);
		//projectObj.Project_Status__c = 'Complete';
		//update projectObj;

		UR_ExcludedCSVCtrl excludeObj = new UR_ExcludedCSVCtrl();
		excludeObj.ProjectMasterObj = projectObjList[0];
		excludeObj.fetchExcludedRecord();

		UR_ImportCSVJob csvObj = new UR_ImportCSVJob();
		csvObj.projectObjId = projectObjList[0].Id;
		csvObj.traceErrorMessage('trace error message');

		UR_ProcessUXResearchCSVData csvDataObj = new UR_ProcessUXResearchCSVData();
		csvDataObj.projectId = projectObjList[0].Id;
		csvDataObj.traceErrorMessage('trace error message');
	}

	static testMethod void manageCSVTest() {
		ContactTriggerHelper.skipTrigger = true;
		AccountTriggerHelper.skipTrigger = true;
		List<Research_Project_Master__c> projectObjList = [SELECT id FROM Research_Project_Master__c WHERE name = 'Test Case 11'];
		Research_Upload_Info__c uploadedInfo = new Research_Upload_Info__c(
			First_Name__c = 'Test',
			Last_Name__c = 'user1',
			Email__c = 'TestEmail_0@gmail.com',
			Employee_Id__c = '55001',
			User_Id__c = '44001',
			Research_Project_Master__c = projectObjList[0].Id
		);
		insert uploadedInfo;
		Research_Upload_Field_Data__c uploadedData = new Research_Upload_Field_Data__c(Field_Label__c = 'Role', Field_Value__c = 'Test', Research_Upload_Info__c = uploadedInfo.Id);
		insert uploadedData;

		Research_Project_Master__c projectObj = projectObjList[0];
		createRsUploadRecord(projectObj.Id, 2, 'dummycase1');
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(projectObj);
		ApexPages.currentPage().getParameters().put('projectId', projectObj.Id);
		UR_ManageCSVCtrl controller = new UR_ManageCSVCtrl(sc);
		controller.init();
		String csvBody =
			'first_name,last_name,email,company_id,user_id,employee_id,accounting_firm_id,Role' +
			'\n' +
			'Test,user1,TestEmail_0@gmail.com,33001,44001,55001,,Test' +
			'\n' +
			'Test,user2,Test.user+user22@lirik.io,33002,44002,,100041,Test' +
			'\n' +
			'Test,user3,Test.user+user33@lirik.io,33003,44003,55003,100042,Test';

		controller.csvFileBody = Blob.valueOf(csvBody);
		controller.csvFileName = 'Test.csv';
		controller.importCSVFile();

		controller.init();
		controller.FirstName = 'Test';
		controller.LastName = 'user1';

		createRsUploadRecord(projectObj.Id, 2, 'testcase2');
		controller.showAll();

		controller.getTotalRecord();
		controller.getTotalPages();
		controller.first();
		controller.last();
		controller.previous();
		controller.next();
		controller.downloadCSV();
		controller.markProjectCompleted();
		controller.manageParticipant();
		controller.CheckParticipant();
		controller.extraNOP = '13';
		controller.SendApprovalRequest();
		controller.deleteResearchUploadInfo();

        Test.startTest();

		controller.getTotalRecordParticipant();
		controller.getTotalPagesParticipant();
		controller.firstParticipant();
		controller.lastParticipant();
		controller.previousParticipant();
		controller.nextParticipant();
		UR_ManageCSVCtrl.fieldLabelInfo lableInfoObj = new UR_ManageCSVCtrl.fieldLabelInfo();
		controller.sortManageContactList();
		controller.selSortManageContactList();
		controller.viewMoreFields();

        Test.stopTest();
	}

	public static void createRsUploadRecord(Id ProjectId, Integer recordCount, String emailPrefix) {
		List<Research_Upload_Info__c> uploadInfoList = new List<Research_Upload_Info__c>();
		for (Integer iCount = 0; iCount < recordCount; iCount++) {
			Research_Upload_Info__c objUploadInfo = new Research_Upload_Info__c();
			objUploadInfo.Research_Project_Master__c = ProjectId;
			objUploadInfo.First_Name__c = 'Test';
			objUploadInfo.Last_Name__c = 'user1';
			objUploadInfo.Email__c = emailPrefix + '_' + iCount + '@gmail.com';
			objUploadInfo.User_Id__c = '44001';
			objUploadInfo.Employee_Id__c = '55001';
			if (iCount / 2 == 0) {
				objUploadInfo.Company_Id__c = '1001';
			} else {
				objUploadInfo.Accountant_Firm_Id__c = '1001';
			}
			uploadInfoList.add(objUploadInfo);
		}
		insert uploadInfoList;
	}
}