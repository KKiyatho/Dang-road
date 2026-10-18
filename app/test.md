# 댕로드 Flutter 웹 테스트

모든 명령은 `app` 폴더에서 Windows PowerShell로 실행합니다.

## Azure 배포 및 GitHub Actions

### 실제 배포 대상

- 사이트: https://witty-hill-03dbc8b00.2.azurestaticapps.net
- GitHub Actions: https://github.com/KKiyatho/Dang-road/actions
- Azure: `rg-dang-road-web` / `dang-road-web`, East Asia, Free.
- main 자동 실행 파일: `.github/workflows/azure-static-web-apps-witty-hill-03dbc8b00.yml`.
- 빌드·배포 구현: `.github/workflows/flutter-web-deploy.yml` (workflow_call 전용이므로 중복 실행하지 않음).
- Azure가 자동 생성한 배포 Secret을 그대로 참조합니다. 새 리소스나 Secret을 만들 필요가 없습니다.
- 2026-10-18 리소스 생성과 GitHub 연결을 완료했습니다. 실제 배포 완료 여부는 최신 Actions 실행의 Deploy 결과와 사이트 응답으로 확인합니다.

### 1. 현재 구성과 추천 서비스

- 프론트엔드: Flutter/Dart, Material 3. 소스는 `app/lib`, 웹 진입점은 `app/web`입니다.
- 의존성: `app/pubspec.yaml`, 잠금 파일: `app/pubspec.lock`입니다.
- Firebase 초기화: `app/lib/services/firebase_services.dart`, 웹 설정: `app/lib/firebase_options.dart`입니다.
- Firebase Auth, Firestore, Storage, Analytics, Messaging SDK가 포함되어 있습니다. SDK 설치는 각 기능 구현이나 클라우드 서비스 활성화 완료를 의미하지 않습니다.
- 별도 백엔드 서버, Azure API, 서버 실행 명령, Azure DB는 현재 없습니다. 기존 Firebase 프로젝트 `dang-dcd02`를 유지합니다.
- 권장: Azure Static Web Apps. Flutter의 정적 결과물만 호스팅하며, 앱은 기존처럼 Firebase에 직접 접근합니다. App Service나 컨테이너는 현재 서버가 없어 불필요합니다.
- 초기 로컬 검사에서 `.github/workflows`는 없었습니다. 이번에 추가한 호출형 워크플로는 독립적으로 push를 감지하지 않으며, Portal이 생성하는 워크플로에서 호출합니다.

### 2. 비용과 한도

2026-10-18 공식 공개 요금표 기준이며 실제 결제 금액은 구독, 환율, 세금에 따라 달라집니다.

| 구성 | 예상 비용 및 조건 |
| --- | --- |
| Static Web Apps Free | Azure 웹 호스팅 월 $0. 구독당 월 대역폭 100 GB, 배포당 250 MB, 앱당 저장소 500 MB, 사용자 도메인 2개, 무료 SSL. SLA 없음. 한도 초과 시 제공이 중단될 수 있습니다. |
| Static Web Apps Standard | 기준 월 약 $9/앱(730시간 기준). SLA와 추가 기능이 필요할 때 검토합니다. 대역폭 초과분 등은 별도입니다. |
| Firebase | Azure 요금과 별개. 현재 요금제와 Auth/Firestore/Storage 등 사용량에 따라 비용이 발생할 수 있습니다. Storage 등은 결제 계정 요구 여부를 콘솔에서 확인합니다. |
| GitHub Actions | 공개 저장소의 표준 GitHub 호스팅 러너는 일반적으로 무료. 비공개 저장소는 계정별 포함 실행 시간과 저장 용량을 확인합니다. |
| 도메인 | 기본 `azurestaticapps.net` 주소는 제공됩니다. 별도 도메인 구매 비용은 별개입니다. |

정확한 앱 크기는 빌드 결과로 확인합니다. Firebase 사용량과 Actions를 포함한 전체 운영 비용이 무조건 0원이라는 의미는 아닙니다.

### 3. Portal 자동 워크플로 생성 우선 절차

아래는 새 환경을 다시 만들 때의 절차입니다. 위 실제 배포 대상은 이미 생성되어 있으므로 반복 생성하지 않습니다. 이번 직접 배포에서는 Azure CLI의 GitHub 연동으로 Portal과 같은 자동 워크플로 및 Secret 생성을 사용했습니다.

1. 먼저 이 저장소의 배포 준비 변경을 GitHub `main`에 반영합니다.
2. Azure Portal에서 구독과 리소스 그룹(예: `rg-dang-road-web`)을 선택하고 **Static Web Apps > Create**를 엽니다.
3. 이름(예: `dang-road-web`), Free 요금제, 사용 가능한 지역을 선택합니다. 별도 App Service/DB는 만들지 않습니다.
4. 배포 원본으로 **GitHub**를 선택하고 본인 계정으로 승인합니다. 저장소 `KKiyatho/Dang-road`, 브랜치 `main`을 선택합니다.
5. 빌드 프리셋은 **Custom**, App location은 `app`, API location은 빈 값, Output location은 `build/web`으로 설정합니다.
6. 생성하면 Portal이 저장소에 `azure-static-web-apps-<자동이름>.yml`과 GitHub 배포 Secret을 자동 생성합니다. Flutter는 기본 Oryx 빌드 대상이 아니므로 이 초기 자동 실행은 실패할 수 있습니다. 아래처럼 생성된 파일 자체를 보완해야 합니다.
7. GitHub에서 자동 생성된 파일의 `secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_...` 참조 이름을 확인합니다. **토큰 값이 아니라 이름**만 필요합니다.
8. 기존 자동 생성 파일의 내용을 아래 호출자로 교체합니다. `PORTAL_GENERATED_SECRET_NAME` 부분을 7번에서 확인한 실제 Secret 이름으로 바꿉니다. 파일을 하나 더 만들지 않습니다.

```yaml
name: Dang Road Azure Production

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: azure-production
  cancel-in-progress: false

jobs:
  deploy:
    uses: ./.github/workflows/flutter-web-deploy.yml
    secrets:
      deployment_token: ${{ secrets.PORTAL_GENERATED_SECRET_NAME }}
```

9. 교체한 파일을 `main`에 반영합니다. 이후 main push마다 호출자 1개가 공통 워크플로를 실행합니다. PR 미리보기 배포는 이 구성에 포함하지 않았습니다.
10. Portal 작업 후 로컬을 갱신할 때는 본인 변경을 먼저 정리한 후 `git pull --rebase origin main`을 사용합니다. 생성된 원격 파일과 같은 역할의 워크플로를 추가로 만들지 않습니다.

새 환경을 Portal에서 생성할 때만 위 절차를 사용합니다. 기존 환경에는 자동 생성된 워크플로를 이미 보완했으므로 이후 main push로 배포합니다.

### 4. 빌드, 실행, 환경변수

GitHub Actions는 Ubuntu에서 Flutter stable **3.44.2**를 설치하고 다음을 순서대로 실행합니다.

```bash
cd app
flutter pub get --enforce-lockfile
flutter analyze
# test/*_test.dart가 있으면 flutter test, 없으면 경고
flutter build web --release
```

빌드 결과는 `app/build/web`입니다. 워크플로가 `app/staticwebapp.config.json`을 이 결과 폴더에 복사합니다. Azure 업로드 시 `app_location: app/build/web`, `output_location: ''`, `api_location: ''`, `skip_app_build: true`로 Oryx 재빌드를 건너뜁니다.

Static Web Apps의 서버 시작 명령은 **없습니다**. 로컬 실행은 `app`에서 `flutter run -d chrome`입니다. 분석, 테스트 또는 빌드가 실패하면 후속 업로드 단계가 실행되지 않으며 기존 배포는 유지됩니다. 테스트 파일이 없는 현재 상태는 테스트 통과가 아니라 검증 공백으로 경고합니다.

| 설정 | 관리 위치 |
| --- | --- |
| Firebase 웹 apiKey/appId/projectId/authDomain/storageBucket/messagingSenderId/measurementId | 현재 `app/lib/firebase_options.dart`에 정적으로 포함되어 있으므로 추가 빌드 환경변수는 필요 없습니다. 브라우저에 공개되는 클라이언트 설정입니다. |
| Azure 배포 토큰 | Portal이 만든 GitHub Actions Repository Secret. 토큰을 YAML, Dart, 채팅, 로그에 넣지 않습니다. |
| GitHub OIDC | 현재 SWA는 DeploymentToken 정책입니다. identity token 병용 업로드가 실제로 거부되어 활성화하지 않습니다. 불필요한 id-token 권한도 부여하지 않습니다. |
| Firebase 서비스 계정/Admin SDK private key | 프론트엔드 및 dart-define에 절대 넣지 않습니다. 이 배포에는 필요하지 않습니다. |

현재 구성은 실제 리소스의 **DeploymentToken** 정책과 GitHub Actions Secret을 사용합니다. OIDC를 검토했으나 identity token 병용 업로드가 거부되었고 GitHub 정책 전환도 현재 API에서 거부되어, 검증 가능한 배포 토큰 방식으로 구성합니다. Entra client secret이나 서비스 계정을 새로 만들지 않습니다. 토큰 노출 시 Portal에서 재발급 후 GitHub Secret을 갱신합니다.

정적 Flutter 앱은 Azure의 런타임 환경변수를 Dart 코드에 자동 주입하지 않습니다. 향후 dart-define을 추가해도 빌드에 포함된 값은 사용자에게 공개되므로 서버 비밀정보를 넣으면 안 됩니다.

### 5. Firebase 배포 전 확인

- Firebase Console > Authentication > Settings > Authorized domains에 최종 `...azurestaticapps.net` 호스트와 사용자 도메인을 추가합니다. 스킴이나 경로가 아닌 호스트 이름을 입력합니다. Firebase `authDomain`을 Azure 주소로 무조건 변경하지 않습니다.
- Auth 제공자 활성화, Firestore/Storage 생성 및 보안 규칙을 별도로 확인합니다. 웹 API 키는 접근 제어 수단이 아니므로 테스트 모드의 공개 쓰기 규칙을 운영에 사용하지 않습니다.
- 현재 소스의 API 키가 이전에 전달된 웹 설정값과 다릅니다. Firebase Console의 해당 웹 앱 설정과 대조하세요. 이번 배포 작업은 앱 기능을 보존하기 위해 이 값을 수정하지 않습니다.
- Firebase 초기화 실패를 앱이 내부에서 처리하므로 첫 화면만 열린다고 연결 성공은 아닙니다. 브라우저 콘솔과 실제 Firebase 기능을 별도로 확인합니다.
- 웹 FCM은 서비스 워커, VAPID와 권한 처리가 추가로 필요합니다. 이번 배포 설정은 푸시 기능을 새로 구현하지 않습니다.

### 6. 배포 검증 및 반복 작업

1. GitHub 저장소 > **Actions** > `Dang Road Azure Production` > 최신 main 실행을 엽니다.
2. Checkout, Flutter 설치, 의존성, Analyze, Tests, Build, Output, Deploy 단계가 성공했는지 확인합니다. 빌드만 녹색이고 Deploy가 실패한 경우 배포 완료가 아닙니다.
3. 실행 Summary의 Website URL 또는 Azure Portal > `dang-road-web` > **Overview > URL / Browse**에서 실제 주소를 확인합니다. 현재 URL은 https://witty-hill-03dbc8b00.2.azurestaticapps.net 입니다.
4. 새 브라우저 탭에서 첫 화면, 새로고침, 깊은 경로 진입, 모바일 폭, Firebase 연결 오류를 확인합니다. 비어 있는 화면이면 브라우저 Network에서 JS/WASM/폰트 404와 콘솔 오류를 확인합니다.
5. 토큰 오류는 Secret 참조 이름과 Portal 배포 토큰을, index.html 오류는 `app/build/web` 경로와 빌드 단계를 확인합니다.
6. 이후 흐름: 코드 수정 > 로컬 분석/테스트 > 본인이 commit > `git push origin main` > Actions 자동 빌드/배포 > Summary와 실제 사이트 확인입니다. 이 설정을 반영하기 전에는 main push만으로 배포되지 않습니다.
7. 운영 반영을 되돌릴 때는 원하는 이전 코드로 revert commit을 만들어 main에 push하고 동일 파이프라인을 실행합니다.

공식 참고:

- https://learn.microsoft.com/en-us/azure/static-web-apps/get-started-portal
- https://learn.microsoft.com/en-us/azure/static-web-apps/build-configuration
- https://learn.microsoft.com/en-us/azure/static-web-apps/deployment-token-management
- https://azure.microsoft.com/en-us/pricing/details/app-service/static/

## 저장소 루트에서 바로 실행

현재 위치가 `D:\dev\Dang-road`라면 먼저 Flutter 프로젝트 폴더로 이동해야 합니다.

```powershell
Set-Location .\app
```

또는 저장소 루트에서 아래 명령을 한 번에 실행할 수 있습니다.

```powershell
Set-Location .\app; flutter pub get; dart format lib; flutter analyze; if (Test-Path test) { flutter test } else { Write-Host 'test 폴더가 없어 Flutter 테스트를 건너뜁니다.' -ForegroundColor Yellow }; flutter build web; flutter run -d chrome
```

## Firebase 프로젝트 연결

Firebase CLI 로그인과 프로젝트 연결은 최초 1회만 실행합니다. Firebase 프로젝트를 먼저 만든 뒤 아래 명령을 실행합니다.

```powershell
firebase login
dart pub global run flutterfire_cli:flutterfire configure
```

프로젝트 선택 시 Web을 포함해 사용할 플랫폼을 선택합니다. 명령이 끝나면 `lib/firebase_options.dart`가 실제 Firebase 설정으로 갱신됩니다.

연결 후 서비스 콘솔에서 다음 기능을 활성화합니다.

- Authentication: 이메일/비밀번호 또는 사용할 간편 로그인 제공자
- Firestore Database: 사용자, 반려견, 코스, 산책 기록, 후기
- Storage: 반려견 사진과 후기 이미지
- Cloud Messaging: 위험 알림과 시스템 알림

Firebase CLI 또는 FlutterFire CLI가 PATH에 없다면 다음 방식으로도 실행할 수 있습니다.

```powershell
dart pub global run flutterfire_cli:flutterfire configure
```

Firebase 설정 전에는 앱이 데모 모드로 실행되며, 실제 인증과 데이터 저장은 동작하지 않습니다.

## 원클릭 검증 및 Chrome 실행

아래 명령은 의존성 설치, 코드 포맷, 정적 분석, 테스트, 웹 빌드 후 Chrome에서 앱을 실행합니다.

```powershell
flutter pub get; dart format lib; flutter analyze; if (Test-Path test) { flutter test } else { Write-Host 'test 폴더가 없어 Flutter 테스트를 건너뜁니다.' -ForegroundColor Yellow }; flutter build web; flutter run -d chrome
```

`flutter run -d chrome`은 개발 서버를 계속 실행합니다. 종료하려면 터미널에서 `q`를 누릅니다.

## 단계별 실행

### 1. 의존성 설치

```powershell
flutter pub get
```

### 2. 포맷 검사 및 적용

```powershell
dart format lib
```

### 3. 정적 분석

```powershell
flutter analyze
```

### 4. 단위 테스트

현재 프로젝트에 `test/` 폴더가 있을 때 실행합니다.

```powershell
flutter test
```

테스트 폴더가 아직 없다면 다음처럼 건너뛸 수 있습니다.

```powershell
if (Test-Path test) { flutter test } else { Write-Host 'test 폴더가 없어 Flutter 테스트를 건너뜁니다.' -ForegroundColor Yellow }
```

### 5. 웹 배포 빌드

```powershell
flutter build web
```

빌드 결과는 `build/web`에 생성됩니다.

### 6. Chrome에서 실행

```powershell
flutter run -d chrome
```

### 7. Edge에서 실행

```powershell
flutter run -d edge
```

## 변경 후 최소 검증

UI 코드만 수정한 경우에는 아래 명령으로 빠르게 확인할 수 있습니다.

```powershell
dart format lib; flutter analyze; flutter build web
```

## 브라우저별 확인 항목

- 데스크톱 폭에서 좌측 코스 목록과 우측 지도 패널이 나란히 표시되는지 확인
- 모바일 폭에서 코스 목록과 지도가 세로로 배치되는지 확인
- 코스 카드를 누르면 선택 코스와 지도 경로가 변경되는지 확인
- `그늘 70%↑`, `안전 80점↑` 필터가 목록을 줄이는지 확인
- 지도 레이어 버튼으로 편의시설 핀이 숨겨지고 다시 표시되는지 확인
- 코스 상세 패널의 저장 버튼과 접기 버튼이 동작하는지 확인
- `flutter analyze`에 오류가 없는지 확인

## 참고

- 현재 지도와 환경 데이터는 목업입니다.
- 실제 API 연동 전까지 코스 정보는 `lib/main.dart`의 샘플 데이터에서 관리합니다.
- `flutter test`를 사용하려면 `test/` 폴더와 `*_test.dart` 파일을 추가해야 합니다.