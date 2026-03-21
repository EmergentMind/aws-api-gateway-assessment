# Log of steps taken to generate cognito token and verify the API

These steps should be taken after a Google Books API key was added, an initial
lambda1 booktitlesearch function was written, and the main IaC wasadeployed

> 26.03.21

1. Add test user password to .env
   `TEST_USER_PASSWORD=NoLooking-123`
   This should automatically get loaded to environment via devenv next time
   the shell refreshes but if you're not
   using devenv, you can run `set -a; source .env; set +a` to load the vars to
   memory
2. Get config details

```bash
aws cloudformation describe-stacks \
  --stack-name api-assessment-stack \
  --output yaml
```

Results:

```bash
Stacks:
- Capabilities:
  - CAPABILITY_IAM
  ChangeSetId: arn:aws:cloudformation:ca-west-1:897421227257:changeSet/awscli-cloudformation-package-deploy-1774053779/f04c1f20-fd75-43da-a9b9-6a24e94121d4
  CreationTime: '2026-03-20T00:22:40.279000+00:00'
  Description: 'AWS API Gateway for assessment. Uses lambdas to connect with Goolge
    Books and GitHub.

    '
  DisableRollback: false
  DriftInformation:
    StackDriftStatus: NOT_CHECKED
  EnableTerminationProtection: false
  LastOperations:
  - OperationId: 9f14e5c8-38b6-41ec-a4f0-d419acebbe01
    OperationType: UPDATE_STACK
  LastUpdatedTime: '2026-03-21T00:43:05.561000+00:00'
  NotificationARNs: []
  Outputs:
  - Description: ID of the Cognito App Client
    OutputKey: UserPoolClientId
    OutputValue: 5q2itelopsugn6rpdt2lf0h26
  - Description: ID of the Cognito User Pool
    OutputKey: UserPoolId
    OutputValue: ca-west-1_U6EqHjLHO
  - Description: Base URL for API Gateway
    OutputKey: ApiUrl
    OutputValue: https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod
  Parameters:
  - ParameterKey: GoogleBooksApiKey
    ParameterValue: '****'
  RollbackConfiguration: {}
  StackId: arn:aws:cloudformation:ca-west-1:897421227257:stack/api-assessment-stack/e7c06700-23f2-11f1-b742-062dc0fb5db5
  StackName: api-assessment-stack
  StackStatus: UPDATE_COMPLETE
  Tags: []
```

Take note of `UserPoolClientId` and `ApiUrl`:

```bash
...
    OutputKey: UserPoolClientId
    OutputValue: 5q2itelopsugn6rpdt2lf0h26
...
    OutputKey: ApiUrl
    OutputValue: https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod
...
```

NOTE: I've tried using adding a query arg to the command, as follows, so only
the stack outputs are printed but it didn't return anything. May be worth
solving later.

```bash
aws cloudformation describe-stacks \
  --stack-name api-assessment-stack \
  --query "Stacks.Outputs" \
  --output yaml
```

3. Generate Cognito auth token, replacing `<APP_CLIENT_ID>` with value from
   previous step, and save it to an environment var in memory

```bash
export ID_TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <APP_CLIENT_ID> \
  --auth-parameters USERNAME=testuser@example.com,PASSWORD=$TEST_USER_PASSWORD \
  --query "AuthenticationResult.IdToken" \
  --output text)
```

      actual:

```bash
export ID_TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id 5q2itelopsugn6rpdt2lf0h26 \
--auth-parameters USERNAME=testuser@example.com,PASSWORD=$TEST_USER_PASSWORD \
--query "AuthenticationResult.IdToken" \
--output text)
```

No output will be printed to tty

4. Verify by printing first 20 chars of token

```bash
echo "${ID_TOKEN:0:20..."
```

result:

```bash
> echo "${ID_TOKEN:0:20}..."
eyJraWQiOiJjcGdXZUZH...
```

5. Test endpoint, replacing `<API_URL>` with ApiUrl `OutputValue:` from earlier steps

```bash
curl -X GET "<API_URL>/books?q=snow%20crash" -H "Authorization: $ID_TOKEN"
```

actual:

```bash
curl -X GET "https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod/books?q=snow%20crash" -H "Authorization: $ID_TOKEN"
```

result:

```bash
curl -X GET "https://z2cgbqhiz9.execute-api.ca-west-1.amazonaws.com/prod/books?q=snow%20crash" -H "Authorization: $ID_TOKEN"
{"results":[{"id":"mqpvVydYo-8C","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780553380958"},{"id":"Q6-JPwAACAAJ","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780606216364"},{"id":"RMd3GpIFxcUC","title":"Snow Crash","authors":["Neal Stephenson"],"isbn":"9780553898194"},{"id":"uQv3EAAAQBAJ","title":"Snow Crash (Urania)","authors":["Neal Stephenson"],"isbn":"9788835732419"},{"id":"1yWqPwAACAAJ","title":"Snow crash","authors":["Neal Stephenson"],"isbn":"9783442424504"}]}%
```
