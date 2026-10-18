# Dang Road Azure Deployment Plan

Status: Validated

## Scope

- Deploy the existing Flutter web application without changing app functionality.
- Keep Firebase Auth, Firestore, Storage, Analytics and Messaging integrations unchanged.
- Prefer Azure Static Web Apps Free and GitHub main branch continuous deployment.
- Reuse the existing workflow; review Azure-generated workflow before consolidating triggers.
- User requested direct deployment and autonomous completion after context/commit approval prompts on 2026-10-18. Only deployment files may be committed; application source remains unchanged.

## Architecture

- Source: app/lib and app/web; dependencies: app/pubspec.yaml and app/pubspec.lock.
- Output: app/build/web, produced by flutter build web --release.
- Hosting: Azure Static Web Apps; no server startup command or Azure database.
- Routing: app/staticwebapp.config.json copied into build output.

## Azure Context

- Subscription: 56f689bd-fc78-4a18-8598-4da361b629f5 (enabled; current context).
- Resource group: rg-dang-road-web; does not exist before deployment.
- Location: eastasia; Microsoft.Web/staticSites provider lists East Asia as supported.
- SKU: Free; Firebase and GitHub usage are billed separately if applicable.

## Deployment Recipe

- Type: AZCLI provisioning with GitHub source integration and GitHub Actions application deployment.
- Existing workflow: .github/workflows/flutter-web-deploy.yml.
- Provisioning: use GitHub integration where permissions permit automatic workflow creation.
- Authentication: SWA DeploymentToken stored only in GitHub Secrets. Identity-token combined upload was rejected in live runs; attempted policy change was rejected by ARM. Retain DeploymentToken and remove unused id-token permission.

## Required Gates

- Azure context verified; user requested autonomous completion after subscription/location and scoped commit prompts.
- GitHub KKiyatho authenticated with repo/workflow scopes and ADMIN access to KKiyatho/Dang-road; default branch main; no remote workflows folder.
- All validation checks pass:
	- Verify Azure login, region support and no resource-group collision.
	- Verify GitHub repository administrative permissions.
	- Parse deployment workflow and static host configuration.
	- Install locked dependencies, analyze, build release and check artifact size.
	- Review failure gates and secret handling; no Entra RBAC assignment or IaC role changes required for SWA deployment-token authentication.
- Deploy only after validation; verify HTTPS endpoint and GitHub Actions result separately.

## Validation Proof

Verified on 2026-10-18 before provisioning:

- az account show: enabled target subscription, authenticated context.
- gh auth status and gh repo view: authenticated repo/workflow scopes and ADMIN repository access; no tokens printed.
- az provider show: East Asia supported for Microsoft.Web/staticSites.
- az group exists: rg-dang-road-web does not yet exist.
- npx --package=yaml yaml valid: existing deployment workflow parsed successfully.
- staticwebapp.config.json: valid JSON with index.html fallback and WASM MIME type.
- flutter --version: 3.44.2 stable, Dart 3.12.2.
- flutter pub get --enforce-lockfile: exit 0; no lockfile changes.
- flutter analyze: no issues, exit 0.
- flutter build web --release: exit 0; index.html present; output 42,372,859 bytes, below 250 MB.
- No unit/widget tests exist; not reported as passing coverage.
- git status: application source and lockfile unchanged.
- No live deployment or successful GitHub Actions run is claimed yet.

## Role Assignment Verification

- Static review: no managed identities or new Entra role assignments are required for this static hosting recipe.
- Firebase data access remains governed by Firebase authentication and security rules.
- SWA publishing credentials remain GitHub Secrets; no subscription-wide service principal is created.
- Existing subscription role listing is accessible; resource create authorization will be verified by actual provisioning.

## Execution State

- Planning and local configuration review: passed; azure-validate workflow reached UpdateStatus gate after actual checks.
- Resource group and Static Web App created in East Asia, Free; GitHub integration automatically generated the workflow and deployment Secret.
- Endpoint: https://witty-hill-03dbc8b00.2.azurestaticapps.net
- Azure-generated main workflow reviewed and converted to call existing Flutter build/deploy workflow; no duplicate push trigger.
- Application upload and CI/CD verification: pending main configuration commit.
- HTTPS endpoint and CI/CD verification: not started.