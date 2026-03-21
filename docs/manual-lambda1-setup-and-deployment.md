# Log of steps taken to deploy lambda1

> 26.03.19

1. setup node environment using typical devenv and pnpm install process
   `direnv allow`
   `pnpm init`
   `pnpm install -D typescript @types/aws-lamda`
   `pnpm add -D @types/node`
   `npx tsc --init`
2. repalce default tsconfig.json with minimal config
3. create basic ts function at lambdas/lambda1/index.ts and compile it with node
   `npx tsc`
4. create an s3 bucket
   `aws s3 mb s3://api-assessment-bucket-01`
5. package the code

```bash
aws cloudformation package \
  --template-file cloudformation/main.yaml \
  --s3-bucket api-assessment-bucket-01 \
  --output-template-file cloudformation/packaged.yaml
```

6. deploy

```bash
aws cloudformation deploy \
  --template-file cloudformation/packaged.yaml \
  --stack-name api-assessment-stack \
  --capabilities CAPABILITY_IAM
```

7. verify

```bash
aws lambda invoke --function-name BookTitleSearchFunction response_ts.json
cat response_ts.json
```

result:

```
File: response_ts.json
{"statusCode":200,"headers":{"Content-Type":"application/json"},"body":"{\"message\":\"Hello from lambda1\"}"}
```
