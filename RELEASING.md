# Releasing

To create a new release you will first create a pull request using the Github Actions workflow [Release – Draft](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/release-draft.yml). You need to manually select the version bump from patch, minor or major depending on the changes that are being deployed.

This will oepn a pull request where you need to validate that the correct files have been updated. These should be documented in the body of the pull request, your job is to validate these have updated correctly and that the release notes look correct for client consumption.

If everything checks out, and tests pass you can merge this pull request which will automatically trigger the [Release – Publish](https://github.com/ROKT/rokt-ux-helper-ios/actions/workflows/release-publish.yml) workflow.
