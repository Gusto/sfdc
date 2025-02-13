@isTest
public class BORAdditionalInformationJSONTest {

    @isTest
    static void testJSONFormatting() {
        String jsonStr = '{"administrators"=>{"fsa"=>"Zenefits", "dca"=>"Zenefits", "commuter"=>"Wage Works", "hsa"=>"Zenefits"}, "title"=>"President", "effective_month"=>6, "effective_month_same_as_medical"=>"no", "effective_month_fsa"=>5, "effective_month_dca"=>5}';
        
        BORAdditionalInformationJSON parsedData = (BORAdditionalInformationJSON)JSON.deserialize(jsonStr.replace('=>',': '), BORAdditionalInformationJSON.class);
        
        BORAdditionalInformationJSON.parse(jsonStr.replace('=>',': '));
    }

}