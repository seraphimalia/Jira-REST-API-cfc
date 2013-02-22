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
	 * @hint "I will create an issue in Jira via the REST API and return the key." 
	 * @output false
	 **/
	public string function createIssue(
		required string Summary,
		required string Description,
		required string Assignee,
		string ProjectKey = variables.ProjectKey,
		string Type = "Task",
		string Reporter = variables.UserName,
		array CustomFields = []
	) {
		/* Build Issue packet. */
		/* Jira Issue Docs: https://developer.atlassian.com/static/rest/jira/5.0.html#id199290 */
		var packet = {
			"fields"= {
				"project" = {
					"key" = arguments.ProjectKey
				},
				"summary" = arguments.Summary,
				"description" = arguments.Description,
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
	 * @hint "I will create a comment on an issue in Jira via the REST API and return the ID." 
	 * @output false
	 **/
	public struct function createIssueComment(
		required string IssueKey,
		required string Body
	) {
		/* Build Comment packet. */
		/* Jira Comment Docs: https://developer.atlassian.com/static/rest/jira/5.0.html#id199362 */
		var packet = {
		    "body" = convertHTMLToWiki(arguments.Body)
		};
		
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* Set it up. */
		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
		httpSvc.addParam( type="body", value=serializeJSON(packet) );
		/* Post to Jira */
		var callResult = httpSvc.send( method = "POST", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/comment' );
		var response = deserializeJSON(callResult.getPrefix().filecontent);
		
		return response;
	}
	
	/**
	* @hint "I transition an issue in Jira"
	* @output false
	**/
	public void function transitionIssue( required string IssueKey, required string TransitionName ) {
		var transitionID = getTransitionIDByName( arguments.IssueKey, arguments.TransitionName );
		if (len(transitionID) == 0) {
			/* no transition is available for the name */
			return;	
		}
		/* Build Transition packet. */
		/* Jira Transition Docs: http://docs.atlassian.com/jira/REST/latest/#id326996 */
		var packet = {
			"transition": {
				"id": transitionID
			}
		};
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* Set it up. */
		httpSvc.addParam( type="header", name="Content-Type", value="application/json" );
		httpSvc.addParam( type="body", value=serializeJSON(packet) );
		/* Post to Jira */
		httpSvc.send( method = "POST", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/transitions' );
	}
	
	/**
	* @hint "I get a transition id from a name"
	* @output false
	**/
	public string function getTransitionIDByName( required string IssueKey, required string TransitionName ) {
		var transitionID = "";
		var transitions = getAvailableTransitions( IssueKey );
		for (var transition in transitions) {
			if ( transition.name == arguments.TransitionName ) {
				transitionID = transition.id;
			}	
		}
		return transitionID;
	}
	
	/**
	* @hint "I get all the possible transitions for an issue"
	* @output false
	**/
	public array function getAvailableTransitions( required string IssueKey ) {
		/* Get http object. */
		var httpSvc = getHTTPRequest();
		/* GET from Jira */
		var callResult = httpSvc.send( method = "GET", url = variables.RestURL & 'issue/' & arguments.IssueKey & '/transitions?expand=transitions.fields' );
		var response = deserializeJSON(callResult.getPrefix().filecontent);
		if (structKeyExists(response, 'transitions')) {
			return response.transitions;
		}
		return [];
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
	
	
	/* UTILITY METHODS */
	
	/**
	* @hint "I will convert HTML to Jira wiki markup."
	* @output false
	**/
	public string function convertHTMLToWiki( required String markup ) {
		var wiki = arguments.markup;
		wiki = reReplaceNoCase(wiki, "<br[^>]*[/]*>", chr(10), "all");	/* Replace <br>s with a line break. */
		wiki = reReplaceNoCase(wiki, "<"&"p>", chr(10), "all");			/* Replace opening <p>s with a line break. */
		wiki = reReplaceNoCase(wiki, "<"&"/p>", "", "all");				/* Remove closing <p>s. */
		wiki = reReplaceNoCase(wiki, "[\r\n]\s+[\r\n]", RepeatString(chr(10),2), "all");	/* Remove whitespace between line breaks. */
		wiki = reReplaceNoCase(wiki, ">\s+[\r\n]", ">#chr(10)#", "all");			/* Replace whitespace at the end of a line after a closing tag. */
		wiki = reReplaceNoCase(wiki, "[\r\n]{3,}", RepeatString(chr(10),2), "all");	/* Replace 3 or more line breaks with just two. */
		wiki = reReplaceNoCase(wiki, "<[/]*(strong|b)>", "*", "all");				/* Replace <strong|b> with wiki markup. */
		wiki = reReplaceNoCase(wiki, "<[/]*(em|i)>", "_", "all");					/* Replace <em|i> with wiki markup. */
		wiki = reReplaceNoCase(wiki, '<img[^>]+src="(.*?)"[^>]*>', "!\1!", "all");	/* Replace <img> with wiki markup. */
		return wiki;
	}
	
	/**
	* @hint "I will convert Jira wiki markup to HTML."
	* @output false
	**/
	public string function convertWikiToHTML( required String markup ) {
		var html = arguments.markup;
		html = reReplaceNoCase(html, chr(10), "<br />", "all"); /* replace line breaks with a br tag */
		return html;
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
	
}