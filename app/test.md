# 댕로드 Flutter 웹 테스트

모든 명령은 `app` 폴더에서 Windows PowerShell로 실행합니다.

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