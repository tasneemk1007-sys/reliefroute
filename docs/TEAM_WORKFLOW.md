# Team workflow

## GitHub workflow

1. Keep `master` as the approved final branch.
2. Before starting work, update your local copy:

   ```bash
   git checkout master
   git pull origin master
   ```

3. Create a branch for one task:

   ```bash
   git checkout -b feature/short-task-name
   ```

4. Make and test the changes. Then commit them:

   ```bash
   git add .
   git commit -m "Describe the change"
   git push -u origin feature/short-task-name
   ```

5. Open a pull request from the feature branch into `master`.
6. Add a clear summary, testing notes, and screenshots where useful.
7. A project administrator reviews and approves the pull request.
8. Merge only after the review is complete.

## Good teamwork habits

- Divide work into small tasks such as frontend, backend, database, testing,
  documentation, and presentation.
- Do not commit passwords, Firebase service accounts, or database secrets.
- Pull the latest `master` before opening a pull request.
- Mention conflicts or unfinished work in the pull request description.
- Use the GitHub Issues tab to record tasks and assign group members.

## Version control

Git and GitHub are the version-control tools used by this project. A suitable
substitute is GitLab or Bitbucket, but the team should use one shared platform
and one agreed branching process.

## Time management and presentation

Track tasks in GitHub Issues, assign a person and due date, and update the issue
when work is complete. For the presentation, explain the problem, target users,
UI/UX design, Flutter frontend, Spring Boot backend, database, testing, and
future improvements.
