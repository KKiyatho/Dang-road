# Dang Road Azure Deployment Plan

Status: Validated

## Scope

- Deploy the current Flutter web application to the existing Azure Static Web Apps resource.
- Reuse the existing Free tier resource; do not create additional paid Azure services.
- Include the current app navigation, live Open-Meteo/OpenStreetMap data, and Firebase Auth/Firestore client changes.
- Prefer Azure Static Web Apps Free and GitHub main branch continuous deployment.
- The requested direct CLI deployment will inspect the resource with Azure CLI and upload the built artifact with Static Web Apps CLI. No infrastructure provisioning is in scope.

## Architecture

- Source: app/lib and app/web; dependencies: app/pubspec.yaml and app/pubspec.lock.
- Output: app/build/web, produced by flutter build web --release.
- Hosting: Azure Static Web Apps; no server startup command or Azure database.
- Routing: app/staticwebapp.config.json copied into build output.

## Azure Context

- Subscription: 56f689bd-fc78-4a18-8598-4da361b629f5 (enabled; current context).
- Resource group: rg-dang-road-web; existing resource group.
- Location: eastasia; Microsoft.Web/staticSites provider lists East Asia as supported.
- SKU: Free; Firebase and GitHub usage are billed separately if applicable.

## Deployment Recipe

- Type: Existing-resource deployment; Azure CLI inspection plus Static Web Apps CLI artifact upload using the existing deployment token.
- Existing workflow: .github/workflows/flutter-web-deploy.yml.
- No provisioning or SKU change is planned.
- Authentication: SWA DeploymentToken stored only in GitHub Secrets. Identity-token combined upload was rejected in live runs; attempted policy change was rejected by ARM. Retain DeploymentToken and remove unused id-token permission.

## Required Gates

- Azure context verified; user requested autonomous completion after subscription/location and scoped commit prompts.
- GitHub KKiyatho authenticated with repo/workflow scopes and ADMIN access to KKiyatho/Dang-road; default branch main; no remote workflows folder.
- All validation checks pass:
	- Verify Azure CLI authentication and the existing SWA resource/SKU; do not create resources.
	- Install locked Flutter dependencies, analyze, run tests, and build the release web artifact.
	- Copy and verify `app/staticwebapp.config.json` in `app/build/web`.
	- Upload only `app/build/web` to the existing production environment; do not print or persist the deployment token.
	- Verify the deployed URL and critical web assets after upload.
	- No Entra RBAC or infrastructure role changes are required for deployment-token authentication.
- Deploy only after validation; verify HTTPS endpoint and GitHub Actions result separately.

## Validation Proof

Verified on 2026-10-24 before the current artifact upload:

- Azure CLI `az account show`: authenticated enabled subscription `56f689bd-fc78-4a18-8598-4da361b629f5`.
- Azure CLI `az staticwebapp show`: existing `dang-road-web`, East Asia, Free, host `witty-hill-03dbc8b00.2.azurestaticapps.net`.
- `flutter pub get --enforce-lockfile`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed; 2 tests.
- `flutter build web --release`: passed.
- `app/staticwebapp.config.json` copied to `app/build/web` and both it and `index.html` verified.
- `swa deploy ... --dry-run` could not complete because the connected resource's API request required a pull request ID. No content was uploaded by the dry-run. Production deployment must be verified by its own result and subsequent HTTPS checks.
- The deployment token was retrieved into a process environment variable only; it was not printed or stored in the repository.
- No infrastructure files, managed identities, or RBAC assignments are required for this existing static site.
- `swa deploy .\build\web --app-name dang-road-web --resource-group rg-dang-road-web --env production`: succeeded on 2026-10-24 using the existing deployment token.
- Production smoke checks: `/`, `/flutter_bootstrap.js`, `/main.dart.js`, and `/manifest.json` returned HTTP 200; HTML title is `댕로드`; browser rendered a Flutter canvas with no page errors.

## Role Assignment Verification

- Static review: no Bicep/Terraform infrastructure or managed identities are used; no new Entra role assignments are required for deployment-token publishing.
- Firebase data access remains governed by Firebase authentication and security rules.
- SWA publishing credentials remain GitHub Secrets; no subscription-wide service principal is created.
- Existing subscription role listing is accessible; resource create authorization will be verified by actual provisioning.

## Execution State

- Planning and local configuration review: passed; azure-validate workflow reached UpdateStatus gate after actual checks.
- Resource group and Static Web App created in East Asia, Free; GitHub integration automatically generated the workflow and deployment Secret.
- Endpoint: https://witty-hill-03dbc8b00.2.azurestaticapps.net
- Azure-generated main workflow reviewed and converted to call existing Flutter build/deploy workflow; no duplicate push trigger.
- Application upload and CI/CD verification: passed. GitHub Actions run 39091456997 completed successfully for main commit 3a26becf57d5074cb53a3bc7085bc881badf1eb8.
- GitHub run: https://github.com/KKiyatho/Dang-road/actions/runs/39091456997
- Azure environment default: Ready, source branch main.
- HTTPS verification: root, flutter_bootstrap.js, main.dart.js and manifest.json return 200; /courses/deployment-check rewrites to index.html; flutter-view is present, title is Dang Road (Korean).
- Historical 2026-10-18 check: `git diff cc4739f HEAD -- app/lib app/pubspec.yaml app/pubspec.lock app/web` showed no app changes at that time. The app was subsequently updated and directly deployed on 2026-10-24.
- Runtime Firebase domain features were not end-to-end tested; check authorized domains and existing Firebase configuration separately.
- The current app artifact is deployed directly, but the source and documentation changes remain uncommitted. A future GitHub Actions run from `main` can replace the direct deployment with the version currently committed there.