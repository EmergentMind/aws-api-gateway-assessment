#
# Developer Activity Check
#
# Fetch recent commits from a specified GitHub repo and return metdata
# including short hash, author, first line the commit message, and date
#
# For simplicity, this function returns data for the latest 10 commits
#
# This function uses the GitHub REST API `commits/` endpoint
# https://docs.github.com/en/rest/commits/commits

import json
import os
import urllib.request
import urllib.error
import logging

# Configure logging for production monitoring
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    try:
        # verify token exits
        token = os.environ.get('GITHUB_TOKEN')
        if not token:
            logger.error("Error: Missing GITHUB_TOKEN environment variable.")
            return {
                "statusCode": 500,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "Internal server error: Missing configuration data."})
            }

        # validate query parameters
        # FIXME: add sanitization and bounds
        query_params = event.get('queryStringParameters') or {}
        repo = query_params.get('repo')
        
        if not repo:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message": "Missing required query parameter: 'repo'"})
            }

        # Fetch the last 10 commits from GitHub REST API
        url = f"https://api.github.com/repos/{repo}/commits?per_page=10"

        req = urllib.request.Request(url)
        req.add_header('Authorization', f'Bearer {token}')
        req.add_header('Accept', 'application/vnd.github.v3+json')
        req.add_header('User-Agent', 'AWS-Lambda-Assessment-App')

        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            
            # extract and return the commit metadata we want
            commits = []
            for item in data:
                commits.append({
                    "sha": item.get("sha")[:7], # we only need the short hash
                    "author": item.get("commit", {}).get("author", {}).get("name"),
                    "message": item.get("commit", {}).get("message", "").split('\n'), # First line only
                    "date": item.get("commit", {}).get("author", {}).get("date")
                })

            return {
                "statusCode": 200,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"results": commits})
            }
    # handle external errors
    # FIXME: handle external errors?
    except urllib.error.HTTPError as e:
        logger.error(f"HTTPError fetching from GitHub: {e.code} - {e.reason}")
        # If we get a  (403/429) to a standard 429 response, else generic 502
        # 403 Forbidden   do we wnat to assume this is 429?
        status_code = 429 if e.code in (403, 429) else 502
        return {
            "statusCode": status_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Error communicating with the external service."})
        }
    except Exception as e:
        logger.error(f"Unexpected error in DevActivityFunction: {str(e)}")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "An unexpected error occurred processing the request."})
        }
