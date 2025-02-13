/**
 * @name        OrgLimitWrapper
 * @author      David Schach
 * @date        11-10-2021
 * @description Wrapper for org limits class, which cannot be serialized in Apex/Visualforce
 */
public without sharing class OrgLimitWrapper implements Comparable {
	public Integer intLValue { get; set; }
	public Integer intLLimit { get; set; }
	public String strLName { get; set; }
	public Integer intLRemain { get; private set; }
	public String strLTitle { get; private set; }
	public String strLSubtitle { get; private set; }
	public String strLValue { get; private set; }
	public String strLLimit { get; private set; }
	public Decimal decPercent { get; private set; }
	public String strPercent { get; private set; }

	/**
	 * Constructor for OrgLimitWrapper
	 * @author David Schach
	 * @param  strOLName     the API name of the Limit
	 * @param  intOLLimit    The API limit value of the limit
	 * @param  intOLValue    The value of the limit
	 * @param  strOLTitle    For overwriting titles in gauges, if desired
	 * @param  strOLSubtitle The subtitle for overwriting gauges, if desired
	 */
	public OrgLimitWrapper(String strOLName, Integer intOLLimit, Integer intOLValue, String strOLTitle, String strOLSubtitle) {
		this.strLName = strOLName;
		this.intLValue = intOLValue;
		this.intLLimit = intollimit;
		this.intLRemain = intLLimit - intLValue;
		this.strLTitle = strOLTitle;
		this.strLSubtitle = strOLSubtitle != null ? strOLSubtitle : '';
		List<String> list_Args = new List<String>{ '0', 'number', '###,###,##0' };
		this.strLValue = String.format(intLValue.format(), list_Args);
		this.strLLimit = String.format(intLLimit.format(), list_Args);
		List<String> list_UsedArgs = new List<String>{ '0', 'percent', '##0' };
		if (intLLimit == 0) {
			this.decPercent = 0;
		} else {
			this.decPercent = 100 * intLValue / intLLimit;
		}
		this.strPercent = String.format(decPercent.format(), list_UsedArgs);
	}

	/**
	 * @description Constructor for specifying the name, limit, and value
	 * @author David Schach
	 * @param  strOLName  Unique name
	 * @param  intOLLimit Limit
	 * @param  intOLValue Value
	 */
	public OrgLimitWrapper(String strOLName, Integer intOLLimit, Integer intOLValue) {
		this(strOLName, intOLLimit, intOLValue, '', '');
	}

	/**
	 * @description Basic construcytor
	 * @author David Schach
	 * @param  objOL System.OrgLimit object
	 */
	public OrgLimitWrapper(System.OrgLimit objOL) {
		this(objOL.getName(), objOL.getLimit(), objOL.getValue());
	}

	/**
	 * Comparable interface
	 * @author David Schach
	 * @param  objCompareTo OrgLimitWrapper to compare to
	 * @return              Integer
	 */
	public Integer compareTo(Object objCompareTo) {
		OrgLimitWrapper objCompareToOLimit = (OrgLimitWrapper) objCompareTo;

		if (decPercent > objCompareToOLimit.decPercent) {
			return -1;
		} else if (decPercent < objCompareToOLimit.decPercent) {
			return 1;
		} else {
			if (intLValue > objCompareToOLimit.intLValue) {
				return -1;
			} else if (intLValue < objCompareToOLimit.intLValue) {
				return 1;
			} else {
				return 0;
			}
		}
	}
}