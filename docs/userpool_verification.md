# Steps to manually verify user pool creation

> 26.03.19

After deploying the cloudformation stack with the ApiUserPool and
ApiUserPoolClient resources, you can verify with the following steps using the
`aws-cli` tool:

1. Retrive UserPoolID

```bash
aws cloudformation describe-stacks \
  --stack-name api-assessment-stack \
  --output yaml
```

This will return inormation about the stack.

2. Look for the `OutputKey: UserPoolId` line and copy the value from the
   `OutputValue` tag next line that follows
   e.g. `OutputValue: <value to copy>`

3. Create a test user. Replace `<OutputValueFromStep2>` with the actual value
   you copied in step 2.

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <OutputValueFromStep2> \
  --username testuser@example.com \
  --user-attributes Name=email,Value=testuser@example.com Name=email_verified,Value=true \
  --message-action SUPPRESS
```

4. Run the following command to set a password, replace `<OutputValueFromStep2>`
   with the actual value you copied in step 2.

```bash
aws cognito-idp admin-set-user-password \
  --user-pool-id <OutputValueFromStep2> \
  --username testuser@example.com \
  --password "NoLooking-123" \
  --permanent
```
