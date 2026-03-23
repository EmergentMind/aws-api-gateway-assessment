# Setting up jest test framework for the first time

> 26.03.22

1. install deps

```bash
cd lambdas/lambda1
pnpm add -D jest @types/jest ts-jest
```

2. decided to update to devenv 2.0 to pull more recent sources (was still on 1.x).
   need to update inputs for git-hooks:

`devenv inputs add git-hooks github:cachix/git-hooks.nix --follows nixpkgs`

3. init jest config

```bash
npx ts-jest config:init

Jest configuration written to "/home/ta/src/aws-api-gateway-assessment/lambdas/lambda1/jest.config.js".
```

4. replace default test script in `lambdas/lambda1/package.json` with jest

```diff
...
  "scripts" : {
- "test": "echo \"Error: no test specified\" && exit 1"
+ "test": "jest"
  },
...
```

5. verify it works using basic example from Jest getting started page:

## sum.js

```javascript
function sum(a, b) {
  return a + b;
}
module.exports = sum;
```

## sum.test.js

```javascript
const sum = require("./sum");

test("adds 1 + 2 to equal 3", () => {
  expect(sum(1, 2)).toBe(3);
});
```

6. run and verify

```bash
$ cd lambdas/lambda1
$ pnpm test

> lambda1@1.0.0 test /home/ta/src/aws-api-gateway-assessment/lambdas/lambda1
> jest

 PASS  ./sum.test.js
  ✓ adds 1 + 2 to equal 3 (2 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
Snapshots:   0 total
Time:        1.017 s
Ran all test suites.
```
