# Template for MarkdownMaster CMS

This template does not contain the application code but instead serves as a starting point for building your own site using MarkdownMaster CMS.

To get started, fork this repo as a new repository and run `scripts/update.sh`
to retrieve the latest full application.

[MarkdownMaster CMS Documentation](https://markdownmaster.com/docs.html)

[Upstream Framework Repository](https://github.com/eVAL-Agency/MarkdownMasterCMS)


## Update.sh

Update supports two sources; 

* "stable" - latest stable release from Github
* "unstable" - latest development build from MarkdownMaster.com

Updating the application will download the following resources:

* `app/` - the primary client-side application
* `backend/` - the PHP backend and all libraries for full site operation
* `extras/` - extra functionality and plugins included with the core framework
* `authors/` - example content
* `pages/` - example content
* `posts/` - example content
* `themes/` - starter themes


## Deploy.sh

Deployment script to provide a convenience function for transferring the application, themes, and extras
to a production server environment.

This environment can be a remote SFTP target or a local file share.

This deployment **does not** include content, database, or configuration.


## Choice of deployment

It is entirely up to you about how to use and deploy MarkdownMaster CMS.

Common scenarios include:

### Everything in git

Remove `pages/`, `posts/`, and any other content from your `.gitignore` to commit everything to your repo.
You can then use CI/CD to auto deploy to your production server on push.

### Local production

You can use the `update.sh` script to deploy a working application directly to your web server or file share.

### Staging environment

You can use the `update.sh` script to download a working application to your own project
or a fork of this template.

You can then build and test your site in a testing environment before you use `deploy.sh`
to deploy the application, themes, and plugins to your live environment.

