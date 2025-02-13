/**
 * @name         : TaxOpsNiceLandingPageControllerTest
 * @author       : Ela Nagarathinam
 * @date         : 08/07/2024
 * @description  : Controller related to nice call landing page
 * @test classes for : TaxOpsNiceLandingPageController
 **/
@isTest
public class TaxOpsNiceLandingPageControllerTest {
    
    /**
     * @Author      : Ela Nagarathinam
     * @Description : Read the parameter passed on vf page
     * @Parm        : NA
     * @Return      : NA
     **/
    @isTest
    public static void testTaxOpsLandingPage(){
        
        PageReference pageRef = Page.TaxOpsNiceLandingPage;
        pageRef.getParameters().put('p1', '123-456-7890');
        Test.setCurrentPage(pageRef);
        TaxOpsNiceLandingPageController contrl = new TaxOpsNiceLandingPageController();
        system.assertEquals(contrl.strPhoneNumber, '123-456-7890', 'Error on reading parameter from URL');
    }

}