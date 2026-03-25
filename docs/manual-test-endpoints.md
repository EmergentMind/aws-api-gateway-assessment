# Manually testing the two endpoints

This assumes that the lambdas have been successfuly packaged and deployed.

1. Regenerate Cognito token

Cognito `IdToken` expiry is 60 minutes

```bash
export ID_TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 5q2itelopsugn6rpdt2lf0h26 \
--auth-parameters USERNAME=testuser@example.com,PASSWORD=$TEST_USER_PASSWORD \
--query "AuthenticationResult.IdToken" \
--output text)
```

actual:

2. Test lambda1 using the `/books` endpoint

```bash
curl -X GET "https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod/books?q=snow%20crash" -H "Authorization: $ID_TOKEN"

{"results":[{"id":"mqpvVydYo-8C","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780553380958"},{"id":"Q6-JPwAACAAJ","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780606216364"},{"id":"RMd3GpIFxcUC","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780553898194"},{"id":"uQv3EAAAQBAJ","title":"Snow Crash (Urania)","authors":["Neal Stephenson"],"isbn":"9788835732419"},{"id":"1yWqPwAACAAJ","title":"Snow crash","authors":["Neal Stephenson"],"isbn":"9783442424504"}]}%
```

3. Test lambda2 using the `/activity` endpoint

```bash
curl -X GET "https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod/activity?repo=emergentmind/nix-config" -H "Authorization: $ID_TOKEN"

{"results": [{"sha": "afbe850", "author": "emergentmind", "message": ["chore: bump lock"], "date": "2026-03-19T02:15:55Z"}, {"sha": "5be71a8", "author": "emergentmind", "message": ["refactor: disable gl signatures"], "date": "2026-03-19T02:00:14Z"}, {"sha": "7cffa9f", "author": "emergentmind", "message": ["refactor(vim): move to introdus based neovim wrapper that is wrapped by", "my neovim flake"], "date": "2026-03-19T01:41:28Z"}, {"sha": "33f5c20", "author": "emergentmind", "message": ["refactor: tweaks"], "date": "2026-03-18T19:55:03Z"}, {"sha": "1449583", "author": "emergentmind", "message": ["docs: minor cleaning"], "date": "2026-03-13T22:10:18Z"}, {"sha": "1fe3ac1", "author": "emergentmind", "message": ["docs: simplify anatomy diagram"], "date": "2026-03-13T22:02:17Z"}, {"sha": "238fefb", "author": "emergentmind", "message": ["chore: bump lock"], "date": "2026-03-12T19:26:32Z"}, {"sha": "ea2e7ad", "author": "emergentmind", "message": ["chore: bump lock"], "date": "2026-03-12T16:50:33Z"}, {"sha": "c9ea835", "author": "emergen
```
