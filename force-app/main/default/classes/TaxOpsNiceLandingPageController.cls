/**
 * @name         : TaxOpsNiceLandingPageController
 * @author       : Ela Nagarathinam
 * @date         : 08/07/2024
 * @description  : Controller related to nice call landing page
 * @test classes : TaxOpsNiceLandingPageControllerTest
 **/
public class TaxOpsNiceLandingPageController {
	
    public String strPhoneNumber {get;set;}
    
    public TaxOpsNiceLandingPageController() {
        strPhoneNumber = ApexPages.currentPage().getParameters().get('p1');
    }
}