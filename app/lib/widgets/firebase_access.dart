import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_services.dart';

typedef SignedInBuilder = Widget Function(BuildContext context, User user);

class FirebaseAccess extends StatelessWidget {
  const FirebaseAccess({required this.builder, super.key});

  final SignedInBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (!FirebaseServices.isConfigured) {
      return const FirebaseSetupNotice();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data;
        if (user == null) return const EmailSignInForm();
        return builder(context, user);
      },
    );
  }
}

class FirebaseSetupNotice extends StatelessWidget {
  const FirebaseSetupNotice({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 32),
              const SizedBox(height: 12),
              Text(
                'Firebase 연결이 필요합니다',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '모임 공유와 기록 동기화는 dang-dcd02 Firebase를 사용합니다. '
                'Firebase Console에서 Authentication의 이메일/비밀번호 로그인을 켜고 '
                'Firestore Database를 생성한 뒤 firestore.rules를 배포해 주세요.',
              ),
              const SizedBox(height: 12),
              const SelectableText('firebase deploy --only firestore:rules'),
              const SizedBox(height: 8),
              const Text(
                '웹 인증을 사용하려면 Firebase Authentication의 승인된 도메인에 '
                '현재 앱 도메인도 추가해야 합니다.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({super.key});

  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreatingAccount = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (_isCreatingAccount) {
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _authErrorMessage(error.code));
    } catch (_) {
      setState(() => _error = '로그인에 실패했습니다. Firebase 설정과 네트워크를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isCreatingAccount ? '댕로드 계정 만들기' : '로그인하고 계속하기',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? '이메일을 확인해 주세요.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 (6자 이상)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? '비밀번호는 6자 이상 입력해 주세요.'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isCreatingAccount ? '계정 만들기' : '로그인'),
                  ),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                            _isCreatingAccount = !_isCreatingAccount;
                            _error = null;
                          }),
                    child: Text(
                      _isCreatingAccount ? '이미 계정이 있어요' : '처음 오셨나요? 계정 만들기',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  String _authErrorMessage(String code) => switch (code) {
    'email-already-in-use' => '이미 사용 중인 이메일입니다. 로그인해 주세요.',
    'invalid-email' => '이메일 주소 형식이 올바르지 않습니다.',
    'weak-password' => '조금 더 안전한 비밀번호를 사용해 주세요.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => '이메일 또는 비밀번호를 확인해 주세요.',
    'network-request-failed' => '네트워크 연결을 확인해 주세요.',
    'operation-not-allowed' => 'Firebase Console에서 이메일/비밀번호 로그인을 활성화해 주세요.',
    _ => '인증을 완료하지 못했습니다. Firebase 설정을 확인해 주세요.',
  };
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: '로그아웃',
    onPressed: () => FirebaseAuth.instance.signOut(),
    icon: const Icon(Icons.logout),
  );
}
