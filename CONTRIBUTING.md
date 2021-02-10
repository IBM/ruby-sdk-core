# Pull Requests

If you want to contribute to the repository, here's a quick guide:
  1. Fork the repository  

  2. Clone the repository into a local directory.  

  3. Install `Ruby`. Supported versions in the core are:
     - 2.3.7
     - 2.4.5
     - 2.5.3
  4. Run
     ```sh
     gem install bundler
     bundle install
     ```

  5. Make your code changes as needed.  Be sure to add new tests for any new or modified functionality.  

  6. Test your changes:
     ```sh
     bundle exec rake
     ```  
  7. Commit your changes:
  * Commit messages should follow the [Angular commit message guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-guidelines).
  This is because this project uses `semantic-release` for build release automation, and `semantic-release` uses
  this commit message style for determining release versions and generating changelogs.
  To make this easier, we recommend using the [Commitizen CLI](https://github.com/commitizen/cz-cli)
  with the `cz-conventional-changelog` adapter.  

  9. Push your commit(s) to your fork and submit a pull request to the **main** branch.

# Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
   have the right to submit it under the open source license
   indicated in the file; or

(b) The contribution is based upon previous work that, to the best
   of my knowledge, is covered under an appropriate open source
   license and I have the right under that license to submit that
   work with modifications, whether created in whole or in part
   by me, under the same open source license (unless I am
   permitted to submit under a different license), as indicated
   in the file; or

(c) The contribution was provided directly to me by some other
   person who certified (a), (b) or (c) and I have not modified
   it.

(d) I understand and agree that this project and the contribution
   are public and that a record of the contribution (including all
   personal information I submit with it, including my sign-off) is
   maintained indefinitely and may be redistributed consistent with
   this project or the open source license(s) involved.

## Additional Resources
+ [General GitHub documentation](https://help.github.com/)
+ [GitHub pull request documentation](https://help.github.com/send-pull-requests/)

[dw]: https://developer.ibm.com/answers/questions/ask.html
[stackoverflow]: http://stackoverflow.com/questions/ask?tags=ibm
[dep]: https://github.com/golang/dep
