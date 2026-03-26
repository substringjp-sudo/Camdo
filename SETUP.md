# Camdo 앱 설정 가이드

## Firebase 설정

### 1. Firebase Console에서 Android 앱 추가

1. [Firebase Console](https://console.firebase.google.com/) → `camdo-todo` 프로젝트 선택
2. **Android 앱 추가** 클릭
3. 패키지 이름: `com.camdo.todo`
4. `google-services.json` 다운로드
5. `android/app/google-services.json`으로 저장 (`.gitignore`에 포함됨)

### 2. Firebase 서비스 활성화

Firebase Console에서 다음을 활성화:
- **Authentication** → Google, Anonymous 로그인 사용 설정
- **Cloud Firestore** → 데이터베이스 생성 (프로덕션 모드)
- **Cloud Messaging** (FCM) → 기본값으로 활성화됨

### 3. Firestore 보안 규칙

Firebase Console → Firestore → 규칙 탭에서:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/todos/{todoId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. lib/firebase_options.dart 업데이트

`lib/firebase_options.dart`의 placeholder를 실제 값으로 교체:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: '실제_API_KEY',
  appId: '실제_APP_ID',
  messagingSenderId: '실제_SENDER_ID',
  projectId: 'camdo-todo',
  storageBucket: 'camdo-todo.appspot.com',
);
```

또는 FlutterFire CLI 사용:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=camdo-todo
```

## Google 캘린더 API 설정

1. [Google Cloud Console](https://console.cloud.google.com/) → `camdo-todo` 프로젝트 선택
2. **APIs & Services** → **Enable APIs** → `Google Calendar API` 활성화
3. **OAuth consent screen** 설정 (앱 이름: Camdo)
4. `google-services.json`에 OAuth 클라이언트 ID가 포함됨

## 개발 환경 설정

```bash
# Flutter 의존성 설치
flutter pub get

# 앱 실행 (디버그)
flutter run

# 릴리즈 빌드
flutter build apk --release
```

## 앱 기능 요약

| 기능 | 설명 |
|------|------|
| 📋 오늘의 체크리스트 | 오늘 완료해야 할 일 목록 + 진행률 |
| 📅 캘린더 뷰 | 월별 캘린더 + Google 캘린더 이벤트 표시 |
| 🔁 루틴 | 매일 반복 항목 관리 |
| ⏱ D-Day | 마감일 카운트다운 (마감 전까지 매일 표시) |
| 🔔 알림 | 마감 당일/전날 알림 + 매일 아침 알림 |
| 📱 반응형 UI | 모바일(하단 네비게이션) + 태블릿(사이드 네비게이션) |
| 🔥 Firebase | 실시간 동기화, 익명/구글 로그인 |

## 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점
├── firebase_options.dart      # Firebase 설정
├── models/
│   └── todo_model.dart        # 데이터 모델
├── providers/
│   ├── auth_provider.dart     # 인증 상태
│   ├── todo_provider.dart     # 할 일 CRUD
│   └── calendar_provider.dart # 캘린더 상태
├── services/
│   ├── auth_service.dart      # Firebase Auth
│   ├── firebase_service.dart  # Firestore CRUD
│   ├── notification_service.dart # 로컬/FCM 알림
│   └── google_calendar_service.dart # Google Calendar API
├── screens/
│   ├── login_screen.dart      # 로그인
│   ├── main_shell.dart        # 반응형 네비게이션 쉘
│   ├── home_screen.dart       # 홈/일일 체크리스트
│   ├── calendar_screen.dart   # 캘린더 뷰
│   ├── routine_screen.dart    # 루틴 관리
│   ├── dday_screen.dart       # D-Day 목록
│   └── settings_screen.dart   # 설정
├── widgets/
│   ├── todo_item_widget.dart  # 할 일 항목 (스와이프 가능)
│   └── add_todo_sheet.dart    # 할 일 추가/편집 시트
└── utils/
    └── app_theme.dart         # 테마/색상
```
