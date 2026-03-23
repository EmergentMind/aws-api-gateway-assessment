import json
import os
import pytest
from unittest.mock import patch, MagicMock
from urllib.error import HTTPError

from lambda_function import handler

@pytest.fixture
def mock_env():
    """Ensure clean environment vars for each test"""
    with patch.dict(os.environ, {"GITHUB_TOKEN": "fake-token"}, clear=True):
        yield

#
# ========= Mock the API Gateway event =========
#
def create_mock_event(query_params=None):
    """Mock API Gateway event"""
    return {
        "queryStringParameters": query_params or {}
    }

#
# ========= Happy Path =========
#
@patch('urllib.request.urlopen')
def test_successful_github_api_call(mock_urlopen, mock_env):
    # Mock response payload
    mock_github_data = [
        {
            "sha": "a1b2c3d4e5f6",
            "commit": {
                "author": {"name": "Nicki Haflinger", "date": "2026-03-22T12:00:00Z"},
                "message": "feat: fancy feature\n\nextra details"
            }
        },
        {
            "sha": "8129asfd3434",
            "commit": {
                "author": {"name": "Nicki Haflinger", "date": "2026-03-20T12:00:00Z"},
                "message": "fix: some bug\n\nextra details"
            }
        }
    ]

    # mock payload response
    mock_response = MagicMock()
    mock_response.read.return_value = json.dumps(mock_github_data).encode('utf-8')
    # FIXME: fast fix. better way to do this?
    # Use __enter__ to support the 'with' context manager in the actual code
    mock_urlopen.return_value.__enter__.return_value = mock_response

    event = create_mock_event({"repo": "tarnover/project-321"})
    response = handler(event, None)

    assert response.get("statusCode") == 200
    body = json.loads(response.get("body"))

    results = body.get("results")
    assert len(results) == 2

    first_commit = results[0]
    # check truncation to short hash (7 chars)
    assert first_commit.get("sha") == "a1b2c3d" 
    assert first_commit.get("author") == "Nicki Haflinger"
     # check that we only grab the first line
    assert first_commit.get("message") == "feat: fancy feature"
##
## ========= Data Handling =========
##
#FIXME(pytest): test more edge cases
@patch('urllib.request.urlopen')
def test_malformed_github_data(mock_urlopen, mock_env):
    # Mock payload missing several expected keys
    mock_github_data = [
        {
            # 'sha' is missing entirely
            "commit": {
                "author": {}, # 'name' is missing
                # 'message' is missing
            }
        }
    ]
    
    mock_response = MagicMock()
    mock_response.read.return_value = json.dumps(mock_github_data).encode('utf-8')
    mock_urlopen.return_value.__enter__.return_value = mock_response

    event = create_mock_event({"repo": "tarnover/project-321"})
    response = handler(event, None)
    
    assert response.get("statusCode") == 200
    
    body = json.loads(response.get("body"))
    first_commit = body.get("results")[0]
    
    # handle missing data cleanly rather than crashing
    assert first_commit.get("author") == ""
    assert first_commit.get("message") == ""
    assert first_commit.get("sha") == ""

##
## ========= Response Code Handling (non-200) =========
##
##  ========= 400 series =========
def test_missing_repo_parameter(mock_env):
    event = create_mock_event({})
    response = handler(event, None)

    assert response.get("statusCode") == 400
    body = json.loads(response.get("body"))
    assert "Missing required query parameter" in body.get("message")

@patch('urllib.request.urlopen')
def test_github_rate_limit(mock_urlopen, mock_env):
    # Simulate a 403 Rate Limit error from GitHub
    error = HTTPError(url="", code=403, msg="Forbidden", hdrs=None, fp=None)
    mock_urlopen.side_effect = error

    event = create_mock_event({"repo": "tarnover/project-321"})
    response = handler(event, None)

    assert response.get("statusCode") == 429
    body = json.loads(response.get("body"))
    assert "Error communicating" in body.get("message")

##  ========= 500 series =========
def test_missing_github_token():
    # Intentionally clear the environment to test the 500 error
    with patch.dict(os.environ, {}, clear=True):
        event = create_mock_event({"repo": "tarnover/project-321"})
        response = handler(event, None)

        assert response.get("statusCode") == 500
        body = json.loads(response.get("body"))
        assert "Missing configuration data" in body.get("message")

@patch('urllib.request.urlopen')
def test_unhandled_exception_catch(mock_urlopen, mock_env):
    # Force a catastrophic exception
    mock_urlopen.side_effect = Exception("Simulated DNS resolution failure")
    
    event = create_mock_event({"repo": "tarnover/project-321"})
    response = handler(event, None)
    
    assert response.get("statusCode") == 500
    body = json.loads(response.get("body"))
    assert "An unexpected error occurred" in body.get("message")

@patch('urllib.request.urlopen')
def test_github_api_502_fallback(mock_urlopen, mock_env):
    # Simulate a generic 500 Internal Server Error from GitHub
    error = HTTPError(url="", code=500, msg="Internal Server Error", hdrs=None, fp=None)
    mock_urlopen.side_effect = error

    event = create_mock_event({"repo": "tarnover/project-321"})
    response = handler(event, None)

    assert response.get("statusCode") == 502
    body = json.loads(response.get("body"))
    assert "Error communicating" in body.get("message")



