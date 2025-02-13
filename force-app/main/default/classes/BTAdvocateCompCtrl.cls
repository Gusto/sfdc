/**
 * @name         BTAdvocateCompCtrl
 * @author       Anand Singh
 * @date         05/08/2020
 * @description  Build logic header of Advocate View
 * @test class   BTAdvocateCompCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BTAdvocateCompCtrl {
	public string strUserId { get; set; }
	public string strLoggedInUserId { get; set; }
	public List<SelectOption> list_NonManagerUserList { get; set; }
	public boolean isManager { get; set; }
	public string strCohort { get; set; }
	public string strOpenTask { get; set; }
	public string strOOOTab { get; set; }
	private static string strCurrentUserName = UserInfo.getName();

	public BTAdvocateCompCtrl() {
		isManager = false;
		strUserId = UserInfo.getUserId();
		strLoggedInUserId = ApexPages.currentPage().getParameters().get('userid');
		if (strLoggedInUserId == null) {
			strLoggedInUserId = strUserId;
		}
		populateteam();
	}

	private void populateteam() {
		list_NonManagerUserList = new List<SelectOption>();
		//get My Role
		List<User> lst_User = [
			SELECT Id, Name, UserRoleId, UserRole.Name
			FROM user
			WHERE isActive = TRUE AND UserRole.name = 'Benefit Transfer Fulfillment' AND id = :strUserId
			LIMIT 1
		];
		if (lst_User != null && lst_User.size() > 0) {
			isManager = true;
			list_NonManagerUserList.add(new SelectOption(lst_User[0].id, lst_User[0].Name));
			for (User usr : [
				SELECT Id, Name, UserRoleId, UserRole.Name
				FROM user
				WHERE isActive = TRUE AND UserRole.name = 'Benefit Transfer Fulfillment Team'
				ORDER BY name ASC
			]) {
				list_NonManagerUserList.add(new SelectOption(usr.id, usr.Name));
			}
		}
	}
	public PageReference UpdateUserView() {
		string pageName = null;
		if (strCohort == 'active') {
			pageName = 'BTAdvocateMyCohortView';
		}
		if (strOOOTab == 'active') {
			pageName = 'BTAdvocateOOOView';
		}
		if (strOpenTask == 'active') {
			pageName = 'BTAdvocateOpenTaskView';
		}
		PageReference pg = new PageReference('/apex/' + pageName + '?userid=' + strLoggedInUserId);
		pg.setRedirect(true);
		return pg;
	}
}