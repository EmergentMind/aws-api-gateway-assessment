# Steps to generate key for Google Books API

> 26.03.20

1. Log in to Google Cloud Console [https://console.cloud.google.com/]
2. In the top navigation bar, click the Project Dropdown and select `New Project`.
   This isn't obviously a dropdown if you don't know what to look for. If you
   have an existing project, just click the project name in the nav bar and it
   will show the dropdown (may be a darkmode thing)
3. Create a new project
4. Within the project, click the hamburger menu and select APIs & Services > Library
5. Search for "Books API"
6. Click on the Books API result and hit the `Enable` button.
7. On the API overview page that comes up click 'Create Credentials' on the right.
8. Copy the key to a pass vault
9. Select `Public data` radio option.
10. Click `Restrict key`
11. Name the key and restrict it to the Books API
12. Leave the Application restrictions to `None`
13. click `Done`
14. Add API key to `.env` as `GOOGLE_BOOKS_API_KEY=<KEY_DATA>` replacing
    `<KEY_DATA>` with actual  
    This should automatically get loaded to environment via devenv next time
    the shell refreshes but if you're not
    using devenv, you can run `set -a; source .env; set +a` to load the vars to
    memory
