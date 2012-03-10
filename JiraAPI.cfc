component displayname="Jira REST API Manager" output="false" {
	
	/* Jira 5 REST API Docs
	 * https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+in+JIRA+5.0
	 **/
	
	/**
	 * @hint "I am the constructor. Give me the Jira REST API config properties and I'll return myself."
	 * @output false
	 **/
	public component function init( string BaseURL, string ProjectKey, string UserName, string Password ) {
		variables.BaseURL = arguments.BaseURL;
		variables.RestURL = arguments.BaseURL & '/rest/api/2/';
		variables.ProjectKey = arguments.ProjectKey;
		variables.UserName = arguments.UserName;
		variables.Password = arguments.Password;
		return this;
	}
	
	/**
	 * @hint "I will give you a partially populated http request." 
	 * @output false
	 **/
	private component function getHTTPRequest() {
		var httpSvc = new HTTP( username = variables.UserName, password = variables.Password );
		httpSvc.addParam( type="header", name="Accept", value="application/json" );
		return httpSvc;
	}
	
	/**
	 * @hint "I will create an issue in Jira via the REST API and return the key." 
	 * @output false
	 **/
	public string function createIssue(
		required string Summary,
		required string Description,
		required string Assignee,
		string Type = "Task",
		string Reporter = variables.UserName,
		array CustomFields = []
	) {
		/* Build Issue packet. */
		/* Jira Issue Docs: https://developer.atlassian.com/static/rest/jira/5.0.html#id199290 */
		var packet = {
			"fields"= {
				"project" = {
					"key" = variables.ProjectKey
				},
				"summary" = arguments.Summary,
				"description"= arguments.Description,
				"issuetype" = {
					"name" = arguments.Type
				},
				"reporter" = {
					"name" = arguments.Reporter
				},
				"assignee" = {
					"name" = arguments.Assignee
				}
			}
		};
		/* Add Custom Fields */
		for (var field in arguments.CustomFields) {
			packet.fields['customfield_' & field.id] = field.value;
		}
		
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* Set it up. */
		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
		httpSvc.addParam( type="body", value=serializeJSON(packet) );
		/* Post to Jira */
		var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'issue' );
		var response = deserializeJSON(callResult.getPrefix().filecontent);
		
		return response.key;
	}
	
	/**
	 * @hint "I will fetch an issue from Jira via the REST API." 
	 * @output false
	 **/
	public struct function getIssue( required string Key ) {
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* GET from Jira */
		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'issue/' & arguments.Key );
		var response = deserializeJSON(callResult.getPrefix().filecontent);
		if ( structKeyExists(response, 'key') ) {
			/* Add a link to the regular non-REST url. */
			response['href'] = variables.BaseURL & '/browse/' & response.key;
		}
		return response;
	}
	
}