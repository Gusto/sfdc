/**
 * @name         BTFacilitatorCompCtrl
 * @author       Sanjay Paryani
 * @date         04/02/2020
 * @description  Used as an extension on BTFacilitatorComp VF page component to role information for logged in user.
 * @test class   BTFacilitatorCompCtrlTest
 * @revisions    Date ------------ Name ------------ Comments
 **/
public class BTFacilitatorCompCtrl {
	// Variables & Collections
	public Id IdLoggedInUser { get; set; }
	public Boolean blnIsFAC1 { get; set; }
	public Boolean blnIsFAC2 { get; set; }
	static String ROLE_BT_FAC1 = 'Benefit Transfer Facilitator 1';
	static String ROLE_BT_FAC2 = 'Benefit Transfer Facilitator 2';

	//Contructor
	public BTFacilitatorCompCtrl() {
		IdLoggedInUser = UserInfo.getUserId();
		blnIsFAC1 = false;
		blnIsFAC2 = false;
		getUserData();
	}

	//Query to see if role is Benefit Transfer Facilitator 1 or Benefit Transfer Facilitator 2
	public void getUserData() {
		Set<String> set_CurrentUserRoles = new Set<String>();
		set_CurrentUserRoles = UtilitiesFactory.RetriveUserRole(IdLoggedInUser);
		if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(ROLE_BT_FAC1)) {
			blnIsFAC1 = true;
		}
		if (!set_CurrentUserRoles.isEmpty() && set_CurrentUserRoles.contains(ROLE_BT_FAC2)) {
			blnIsFAC2 = true;
		}
	}
}