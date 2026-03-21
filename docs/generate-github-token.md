# Steps to generate personal access token GitHub REST API

> 26.03.21

1. Log in to github
2. Click top right avatar and select `Settings`
3. On left hand menu, go to `Developer settings`
4. Click `Personal access tokens > Tokens (classic)`
5. Generate a new token, name it, and give it access to `public_repo`
6. Copy the token to pass vault
7. add the token to `.env` as `GITHUB_TOKEN=<KEY_DATA>` replacing `<KEY_DATA>`
   with actual
