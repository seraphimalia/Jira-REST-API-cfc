# License

Copyright (c) 2012 DealerPeak LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# About

This CFC is to facilitate making calls to the Jira 5 REST API. The API allows you to do things like create and update issues, etc.

# Docs

## Jira

See the [Jira Wiki](https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+in+JIRA+5.0) for their REST API docs.

## Usage

	<cfscript>
		/* Get an instance of the CFC. You would normally cache this in ColdSpring or some other Bean Factory */
		jira = new com.jira.JiraAPI(
			BaseURL = 'http://jira.YOURDOMAIN.com',
			ProjectKey = 'AA',
			UserName = 'REDACTED',
			Password = 'REDACTED'
		);
		/* Create an issue in Jira. Include "External issue ID" custom field. */
		newKey = jira.createIssue(
			Summary = 'API TESTING',
			Description = 'As a developer, I hope this is posted to Jira.',
			Assignee = 'REDACTED',
			Reporter = 'REDACTED',
			CustomFields = [{id = '10100', value = 'Ticket XXXXX'}]
		);
		/* Add a comment to the newly created issue. */
		newComment = jira.createIssueComment(
			IssueKey = newKey,
			Body = 'I hope this note shows up. That would be awesome!'
		);
		/* Close the issue */
		jira.transitionIssue(
			IssueKey = newKey,
			TransitionName = "Close Issue"
		);
		/* Get full details of issue from Jira */
		issue = jira.getIssue( newKey );
	</cfscript>