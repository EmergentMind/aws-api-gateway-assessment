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
import urllib.parse
import logging
from http import HTTPStatus

# Configure logging for production monitoring
logger = logging.getLogger()
logger.setLevel(logging.INFO)

GITHUB_API_BASE_URL = "https://api.github.com/repos"
MAX_COMMITS = "10"
MAX_TITLE_LENGTH = 100

def create_response(status_code: int, body: dict) -> dict:
    """Creates a standardized API Gateway proxy response."""
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

def map_commit(item: dict) -> dict:
    """Maps a raw GitHub commit item to our standard dictionary format."""
    # default to empties if data is None/missing
    commit = item.get("commit") or {}
    author_info = commit.get("author") or {}
    message = commit.get("message") or ""
    sha = item.get("sha") or ""

    return {
        # we only want the short hash
        "sha": sha[:7],
        "author": author_info.get("name") if author_info else "",
        # we only want the first line of the message
        "message": message.split('\n')[0] if message else "",
        "date": author_info.get("date")
    }

def handler(event, context):
    try:
        # verify token exits
        token = os.environ.get('GITHUB_TOKEN')
        if not token:
            logger.error("Error: Missing GITHUB_TOKEN environment variable.")
            return create_response(HTTPStatus.INTERNAL_SERVER_ERROR, {
                "message": "Internal server error: Missing configuration data."
            })

        # validate query parameters
        query_params = event.get('queryStringParameters') or {}
        raw_repo = query_params.get('repo')
        if not raw_repo:
            return create_response(HTTPStatus.BAD_REQUEST, {
                "message": "Missing required query parameter: 'repo'"
            })
        elif len(raw_repo) > MAX_TITLE_LENGTH:
            return create_response(HTTPStatus.BAD_REQUEST, {
                "message": "Query parameter 'repo' is longer than maximum allowed length."
            })

        # santize but preserve `/` (e.g. `account/repo` is expected)
        sanitized_repo = urllib.parse.quote(raw_repo, safe='/')

        # Fetch the last MAX_COMMITS from GitHub REST API
        url = f"{GITHUB_API_BASE_URL}/{sanitized_repo}/commits?per_page={MAX_COMMITS}"

        req = urllib.request.Request(url)
        req.add_header('Authorization', f'Bearer {token}')
        req.add_header('Accept', 'application/vnd.github.v3+json')
        req.add_header('User-Agent', 'AWS-Lambda-Assessment-App')

        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))

            # Map GitHub data to our own dictionary format functionally
            commits = [map_commit(item) for item in data]

            return create_response(HTTPStatus.OK, {"results": commits})

    # handle external errors
    except urllib.error.HTTPError as e:
        logger.error(f"HTTPError fetching from GitHub: {e.code} - {e.reason}")
        # If we get 403 or 429 pass 429, otherwise assume 502
        # We are including 403 here because GitHub sometimes sends 403 rate limit is exceeded
        status_code = HTTPStatus.TOO_MANY_REQUESTS if e.code in (HTTPStatus.TOO_MANY_REQUESTS, HTTPStatus.FORBIDDEN) else HTTPStatus.BAD_GATEWAY
        return create_response(status_code, {
            "message": "Error communicating with the external service."
        })

    except Exception as e:
        logger.error(f"Unexpected error in DevActivityFunction: {str(e)}")
        return create_response(HTTPStatus.INTERNAL_SERVER_ERROR, {
            "message": "An unexpected error occurred processing the request."
        })
