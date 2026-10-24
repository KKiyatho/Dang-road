# 댕로드 앱

Flutter 기반 산책 앱입니다. 홈과 산책로 화면은 현재 위치 또는 검색한 지역을 기준으로 Open-Meteo 날씨·대기질, OpenStreetMap 타일·보행로 데이터를 조회합니다. Google Maps API 키는 필요하지 않습니다.

## 실행

```powershell
Set-Location app
flutter pub get
flutter run -d chrome
```

위치 기능은 브라우저 권한이 필요합니다. 권한을 허용하지 않아도 지역 검색으로 사용할 수 있습니다.

## 계정과 저장

함께 걷기 모임, 반려견 프로필, 산책 기록은 Firebase Authentication과 Cloud Firestore에 저장됩니다. 현재 웹 Firebase 설정은 `lib/firebase_options.dart`의 `dang-dcd02` 프로젝트를 사용합니다. 이메일/비밀번호 로그인 제공자와 Firestore 생성, 보안 규칙 배포 방법은 저장소 루트의 [FIREBASE_SETUP.md](../FIREBASE_SETUP.md)를 참고하세요.

Android/iOS에서 Firebase 인증을 사용하려면 FlutterFire로 해당 플랫폼 설정을 추가해야 합니다. 위치 권한 문구와 OS 권한은 준비되어 있습니다.

## 확인

```powershell
flutter analyze
flutter test
flutter build web --release
```

환경 데이터와 지도는 외부 공개 서비스의 가용성과 이용 정책을 따릅니다. 안전 보장 정보가 아니며 실제 코스 운영 상태는 현장에서 확인해야 합니다.
