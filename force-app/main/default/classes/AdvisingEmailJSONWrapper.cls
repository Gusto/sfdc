public class AdvisingEmailJSONWrapper {
  //Common Node
  public String application_id;
  public String application_type;
  public String company_id;
  public String selection_deadline;

  //Intro Email Nodes Start
  public String survey_completed_by;
  public Boolean tada_interest_from_survey;
  public Benefit_Address benefit_address;
  public Boolean scorp;
  public class Benefit_Address {
    public String street_1;
    public String street_2;
    public String city;
    public String state;
    public String zip;
    public String country;
  }
  //Intro Email Nodes End

  //Followup Email Nodes Start
  public String number_of_days_remaining;
  public Medical[] medical;
  public Dental[] dental;
  public Vision[] vision;
  public Life[] life;
  public Long_Term_Disability[] long_term_disability;
  public Short_Term_Disability[] short_term_disability;
  public String tadas;

  public class Medical {
    public String carrier_name;
    public String plan_name;
  }
  public class Dental {
    public String carrier_name;
    public String plan_name;
  }
  public class Vision {
    public String carrier_name;
    public String plan_name;
  }
  public class Life {
    public String carrier_name;
    public String plan_name;
  }
  public class Long_Term_Disability {
    public String carrier_name;
    public String plan_name;
  }
  public class Short_Term_Disability {
    public String carrier_name;
    public String plan_name;
  }
  //Followup Email Nodes End

  public static AdvisingEmailJSONWrapper parse(String json) {
    return (AdvisingEmailJSONWrapper) System.JSON.deserialize(
      json,
      AdvisingEmailJSONWrapper.class
    );
  }
}