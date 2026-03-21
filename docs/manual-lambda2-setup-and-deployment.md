# Log of steps taken to deploy lambda2

> 26.03.21

The python environment setup is a bit more involved than my typical python
projects becasue I only want the python environment to spin up in specific sub
dirs

1. Python environments through devenv are opinionated about git root so
   add a `pyproject.toml` to gitroot that points to python code sub dir
   using workspaces

```toml
[project]
name = "aws-api-gateway-assessment"
version = "0.1.0"
dependencies = []

[tool.uv.workspace]
members = ["lambdas/lambda2"]
```

2. Add nixpkgs-python as an input source to devenv

```bash
devenv inputs add nixpkgs-python github:cachix/nixpkgs-python --follows nixpkgs
```

This will generate `devenv.yaml` witht he input details

3. Add required pkgs and language reqs to `devenv.nix` as needed
4. reload the shell `direnv reload`
5. init `uv` within the lambda2 dir to generate a `pyproject.toml` for the
   lambda2 sub directory

   ```bash
   cd lambdas/lambda2 && uv init --lib
   ```

   result:

   ```bash
   Project `lambda2` is already a member of workspace `/home/ta/src/aws-api-gateway-assessment`
   Initialized project `lambda2`
   ```

6. edit `lambdas/lambda2/pyproject.toml` as needed
7. verify
8. `direnv reload` should note return any errors
9. `uv tree` should return:

   ```bash
   Resolved 2 packages in 0.97ms
   lambda2 v0.1.0
   aws-api-gateway-assessment v0.1.0

   ```

10. create basic python function at lambdas/lambda2/lambda_function.py
11. update cloudformation/main.yaml with `DevActivityFunction` and
    `DevActivityExecutionRole`
12. package the code. we'll use the same s3 bucket as we did with lambda1

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
aws lambda invoke --function-name DevActivityFunction response_py.json
cat response_py.json
```

result:

```
File: response_py.json
{"statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": "{\"message\": \"Hello from the lambda2\"}"}
```
