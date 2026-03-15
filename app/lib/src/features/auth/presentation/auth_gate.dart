import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../recommendation/data/recommendation_controller.dart';

final authEmailProvider = StateProvider<String>((ref) => '');
final authPasswordProvider = StateProvider<String>((ref) => '');
final authRegisterModeProvider = StateProvider<bool>((ref) => false);

class AuthGate extends ConsumerWidget {
  const AuthGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authControllerProvider);

    return authAsync.when(
      data: (auth) {
        if (auth.isAuthenticated) return child;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AuthPanel(),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '인증 오류: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
                const _AuthPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPanel extends ConsumerWidget {
  const _AuthPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authEmailProvider);
    final password = ref.watch(authPasswordProvider);
    final isRegisterMode = ref.watch(authRegisterModeProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '로그인하면 저장한 옷장과 추천 기록을 다시 불러올 수 있어요.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: '이메일',
            hintText: 'you@example.com',
          ),
          onChanged: (value) => ref.read(authEmailProvider.notifier).state = value.trim(),
        ),
        const SizedBox(height: 12),
        TextField(
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '비밀번호',
            hintText: '8자 이상',
          ),
          onChanged: (value) => ref.read(authPasswordProvider.notifier).state = value,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
          icon: const Icon(Icons.login),
          label: const Text('Google로 로그인'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: email.isEmpty || password.isEmpty
              ? null
              : () {
                  final controller = ref.read(authControllerProvider.notifier);
                  if (isRegisterMode) {
                    controller.signUpWithEmail(email: email, password: password);
                  } else {
                    controller.signInWithEmail(email: email, password: password);
                  }
                },
          child: Text(isRegisterMode ? '회원가입하고 시작' : '로그인'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => ref.read(authRegisterModeProvider.notifier).state = !isRegisterMode,
          child: Text(isRegisterMode ? '이미 계정이 있어요' : '처음이라면 회원가입'),
        ),
        const SizedBox(height: 12),
        Text(
          '계정 없이도 체험 가능',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signIn(),
          child: const Text('게스트로 시작하기'),
        ),
      ],
    );
  }
}
