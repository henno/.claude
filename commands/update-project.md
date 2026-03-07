Stash any local changes, pull the latest from remote, re-apply the stashed changes, run any new database migrations, and handle rebasing onto main/master when needed.

Steps:
1. Check if there are uncommitted changes using `git status --porcelain`
2. If there are changes, stash them with `git stash push -m "Auto-stash before update"`
3. Determine the main branch name (main or master) using `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'` or check which exists
4. Get the current branch name using `git branch --show-current`
5. If on a feature/bug branch (not main/master):
   a. Save the current main/master commit hash before pulling: `git rev-parse origin/<main-branch>`
   b. Pull the latest changes with `git pull`
   c. Get the new main/master commit hash after pulling: `git rev-parse origin/<main-branch>`
   d. Check if the current branch is based on the latest main/master: `git merge-base --is-ancestor origin/<main-branch> HEAD`
   e. If new commits were pulled to main/master (hashes differ):
      - Automatically rebase onto main/master: `git rebase origin/<main-branch>`
      - After successful rebase, push with: `git push --force-with-lease`
   f. If NO new commits on main/master BUT branch is not based on latest main/master (merge-base check fails):
      - ASK the user if they want to rebase onto main/master
      - If yes, rebase and then push with: `git push --force-with-lease`
6. If on main/master branch, just pull: `git pull`
7. Check if any new migration files were pulled (look for changes in migrations directories)
8. If new migrations exist, run database migrations using the project's migration command (e.g., `docker compose exec dev bun run db:migrate`)
9. If changes were stashed, re-apply them with `git stash pop`
10. Report the results to the user
