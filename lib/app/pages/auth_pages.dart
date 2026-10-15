import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/account_role.dart';
import '../../features/auth/domain/entities/user_profile.dart';
import '../../core/errors/failure.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../locale_cubit.dart';

class _Email extends FormzInput<String, String> {
  const _Email.pure() : super.pure('');
  const _Email.dirty([super.value = '']) : super.dirty();
  @override
  String? validator(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : 'emailInvalid';
}

class _Password extends FormzInput<String, String> {
  const _Password.pure() : super.pure('');
  const _Password.dirty([super.value = '']) : super.dirty();
  @override
  String? validator(String value) => value.length >= 8 ? null : 'passwordShort';
}

String _textForFailure(AppLocalizations l10n, AuthState state) =>
    switch (state.failure?.kind) {
      FailureKind.invalidCredentials => l10n.invalidCredentials,
      FailureKind.emailAlreadyRegistered => l10n.emailExists,
      FailureKind.network => l10n.networkError,
      FailureKind.profileNotFound ||
      FailureKind.sessionExpired => l10n.profileError,
      _ => l10n.genericError,
    };

abstract class _AuthPageState<T extends StatefulWidget> extends State<T> {
  AppLocalizations get l10n => AppLocalizations.of(context);
  bool get loading =>
      context.watch<AuthCubit>().state.status == AuthStatus.loading;
  Widget shell({required String title, required Widget child}) => Scaffold(
    appBar: AppBar(
      leading: context.canPop()
          ? BackButton(onPressed: () => context.pop())
          : null,
      title: Text(title),
      actions: [
        TextButton(
          onPressed: () {
            final current = Localizations.localeOf(context).languageCode;
            context.read<LocaleCubit>().setLanguage(
              current == 'ar' ? 'en' : 'ar',
            );
          },
          child: Text(l10n.language),
        ),
      ],
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 40),
            child: BlocListener<AuthCubit, AuthState>(
              listenWhen: (previous, current) =>
                  previous.failure != current.failure &&
                  current.failure != null,
              listener: (context, state) =>
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_textForFailure(l10n, state))),
                  ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );

  Widget actionButton(String text, VoidCallback? onPressed) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.auto_stories_rounded, size: 72),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.welcomeBody, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go('/sign-in'),
                    child: Text(l10n.signIn),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/roles'),
                    child: Text(l10n.createAccount),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    child: TextButton(
                      onPressed: () {
                        final current = Localizations.localeOf(
                          context,
                        ).languageCode;
                        context.read<LocaleCubit>().setLanguage(
                          current == 'ar' ? 'en' : 'ar',
                        );
                      },
                      child: Text(l10n.language),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AccountRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roles = <(AccountRole, String, String, IconData)>[
      (
        AccountRole.student,
        l10n.student,
        l10n.studentRoleHint,
        Icons.school_outlined,
      ),
      (
        AccountRole.teacher,
        l10n.teacher,
        l10n.teacherRoleHint,
        Icons.cast_for_education_outlined,
      ),
      (
        AccountRole.guardian,
        l10n.guardian,
        l10n.guardianRoleHint,
        Icons.family_restroom_outlined,
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createAccount),
        actions: [
          TextButton(
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              context.read<LocaleCubit>().setLanguage(
                current == 'ar' ? 'en' : 'ar',
              );
            },
            child: Text(l10n.language),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                l10n.chooseRole,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              for (final (role, label, description, icon) in roles) ...[
                Builder(
                  builder: (context) {
                    final selected = role == _selectedRole;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 1.5 : 0.7,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = role),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(18),
                          child: Row(
                            children: [
                              _roleArtwork(
                                context,
                                role,
                                fallback: icon,
                                size: 88,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(description),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              TextButton(
                onPressed: () => context.push('/sign-in'),
                child: Text(l10n.signIn),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _selectedRole == null
                    ? null
                    : () => context.push(
                        _selectedRole == AccountRole.student
                            ? '/register/student'
                            : '/register?role=${_selectedRole!.value}',
                      ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

Widget _roleArtwork(
  BuildContext context,
  AccountRole role, {
  required IconData fallback,
  double size = 88,
}) {
  final asset = switch (role) {
    AccountRole.student => 'assets/student_background.png',
    AccountRole.teacher => 'assets/teacher_background.png',
    AccountRole.guardian => 'assets/parents_background.png',
  };
  return Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(fallback, color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _SignInPageState extends _AuthPageState<SignInPage> {
  final _form = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _Email _email = const _Email.pure();
  _Password _password = const _Password.pure();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => shell(
    title: l10n.signIn,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.signInTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _emailField(
            _emailController,
            _email,
            (value) => setState(() => _email = value),
          ),
          const SizedBox(height: 16),
          _passwordField(
            _passwordController,
            _password,
            _obscure,
            () => setState(() => _obscure = !_obscure),
            (value) => setState(() => _password = value),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => context.go('/reset'),
              child: Text(l10n.forgotPassword),
            ),
          ),
          const SizedBox(height: 12),
          actionButton(l10n.signIn, () {
            final valid = Formz.validate([_email, _password]);
            setState(() {
              _email = _Email.dirty(_emailController.text);
              _password = _Password.dirty(_passwordController.text);
            });
            if (valid) {
              context.read<AuthCubit>().signIn(_email.value, _password.value);
            } else {
              _form.currentState?.validate();
            }
          }),
          TextButton(
            onPressed: () => context.push('/register'),
            child: Text(l10n.createAccount),
          ),
        ],
      ),
    ),
  );
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({required this.role, super.key});
  final String role;
  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends _AuthPageState<RegistrationPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _school = TextEditingController();
  final _grade = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _step = 0;
  var _obscure = true;
  _Email _emailValue = const _Email.pure();
  _Password _passwordValue = const _Password.pure();

  AccountRole get role =>
      AccountRoleValue.parse(widget.role) ?? AccountRole.student;
  String get roleLabel => switch (role) {
    AccountRole.student => l10n.student,
    AccountRole.teacher => l10n.teacher,
    AccountRole.guardian => l10n.guardian,
  };

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _school.dispose();
    _grade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => shell(
    title: l10n.createAccount,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == 0) ...[
            Center(
              child: _roleArtwork(
                context,
                role,
                fallback: switch (role) {
                  AccountRole.student => Icons.school_outlined,
                  AccountRole.teacher => Icons.cast_for_education_outlined,
                  AccountRole.guardian => Icons.family_restroom_outlined,
                },
                size: 148,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            l10n.registerTitle(roleLabel),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.stepOf(_step + 1, 2),
            child: LinearProgressIndicator(value: (_step + 1) / 2),
          ),
          const SizedBox(height: 8),
          Text(l10n.stepOf(_step + 1, 2)),
          const SizedBox(height: 20),
          if (_step == 0 && role == AccountRole.teacher) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l10n.teacherRoleHint)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_step == 0) ...[
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.fullName),
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.nameRequired
                  : null,
            ),
            const SizedBox(height: 16),
            _emailField(
              _email,
              _emailValue,
              (value) => setState(() => _emailValue = value),
            ),
            const SizedBox(height: 16),
            _passwordField(
              _password,
              _passwordValue,
              _obscure,
              () => setState(() => _obscure = !_obscure),
              (value) => setState(() => _passwordValue = value),
            ),
          ] else ...[
            if (role == AccountRole.guardian)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.family_restroom_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(l10n.guardianSpaceBody)),
                    ],
                  ),
                ),
              )
            else
              Text(l10n.optionalStep),
            if (role != AccountRole.guardian) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _school,
                decoration: InputDecoration(labelText: l10n.school),
              ),
            ],
            if (role == AccountRole.student) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _grade,
                decoration: InputDecoration(labelText: l10n.grade),
              ),
            ],
          ],
          const SizedBox(height: 24),
          if (_step == 0)
            actionButton(l10n.continueLabel, () {
              setState(() {
                _emailValue = _Email.dirty(_email.text);
                _passwordValue = _Password.dirty(_password.text);
              });
              if (_form.currentState!.validate()) setState(() => _step = 1);
            })
          else ...[
            actionButton(
              l10n.submit,
              () => context.read<AuthCubit>().signUp(
                email: _email.text,
                password: _password.text,
                fullName: _name.text,
                role: role,
                school: role == AccountRole.guardian ? null : _school.text,
                grade: role == AccountRole.student ? _grade.text : null,
              ),
            ),
            TextButton(
              onPressed: loading ? null : () => setState(() => _step = 0),
              child: Text(l10n.back),
            ),
          ],
        ],
      ),
    ),
  );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});
  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends _AuthPageState<UpdatePasswordPage> {
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  _Password _value = const _Password.pure();
  var _obscure = true;
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => shell(
    title: l10n.resetTitle,
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.resetTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          _passwordField(
            _password,
            _value,
            _obscure,
            () => setState(() => _obscure = !_obscure),
            (value) => setState(() => _value = value),
          ),
          const SizedBox(height: 20),
          actionButton(l10n.submit, () {
            setState(() => _value = _Password.dirty(_password.text));
            if (_form.currentState!.validate()) {
              context.read<AuthCubit>().updatePassword(_password.text);
            }
          }),
        ],
      ),
    ),
  );
}

class _ResetPasswordPageState extends _AuthPageState<ResetPasswordPage> {
  final _email = TextEditingController();
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => shell(
    title: l10n.resetTitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.resetTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.email),
        ),
        const SizedBox(height: 20),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => state.notice == 'resetSent'
              ? Text(l10n.resetEmailSent)
              : const SizedBox.shrink(),
        ),
        actionButton(
          l10n.sendReset,
          () => context.read<AuthCubit>().requestPasswordReset(_email.text),
        ),
      ],
    ),
  );
}

class ConfirmEmailPage extends StatelessWidget {
  const ConfirmEmailPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppLocalizations.of(context).confirmEmailSent,
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class InvalidLinkPage extends StatelessWidget {
  const InvalidLinkPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 56),
              const SizedBox(height: 16),
              Text(l10n.invalidRecoveryLink, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/reset'),
                child: Text(l10n.sendReset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileUnavailablePage extends StatelessWidget {
  const ProfileUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(l10n.profileError, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<AuthCubit>().retryProfile(),
                child: Text(l10n.continueLabel),
              ),
              TextButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PendingTeacherPage extends StatelessWidget {
  const PendingTeacherPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.select<AuthCubit, UserProfile?>(
      (cubit) => cubit.state.profile,
    );
    final rejected = profile?.teacherStatus == TeacherStatus.rejected;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                rejected ? l10n.rejectedTitle : l10n.pendingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                rejected ? l10n.rejectedBody : l10n.pendingBody,
                textAlign: TextAlign.center,
              ),
              if (rejected && profile?.rejectionReason != null) ...[
                const SizedBox(height: 12),
                Text(profile!.rejectionReason!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.read<AuthCubit>().signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.select<AuthCubit, UserProfile?>(
      (cubit) => cubit.state.profile,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            onPressed: () => context.read<AuthCubit>().signOut(),
            icon: const Icon(Icons.logout),
          ),
          TextButton(
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              context.read<LocaleCubit>().setLanguage(
                current == 'ar' ? 'en' : 'ar',
              );
            },
            child: Text(l10n.language),
          ),
        ],
      ),
      body: profile == null
          ? Center(child: Text(l10n.profileError))
          : RoleHomeContent(role: profile.role, name: profile.fullName),
    );
  }
}

class RoleHomeContent extends StatelessWidget {
  const RoleHomeContent({required this.role, this.name, super.key});

  final AccountRole role;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, body, icon) = switch (role) {
      AccountRole.student => (
        l10n.studentSpaceTitle,
        l10n.studentSpaceBody,
        Icons.school_outlined,
      ),
      AccountRole.teacher => (
        l10n.teacherSpaceTitle,
        l10n.teacherSpaceBody,
        Icons.cast_for_education_outlined,
      ),
      AccountRole.guardian => (
        l10n.guardianSpaceTitle,
        l10n.guardianSpaceBody,
        Icons.family_restroom_outlined,
      ),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  if (name != null && name!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(name!),
                  ],
                  const SizedBox(height: 12),
                  Text(body, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _emailField(
  TextEditingController controller,
  _Email value,
  ValueChanged<_Email> onChange,
) => Builder(
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(labelText: l10n.email),
      validator: (_) => value.isValid ? null : l10n.emailInvalid,
      onChanged: (text) => onChange(_Email.dirty(text)),
    );
  },
);

Widget _passwordField(
  TextEditingController controller,
  _Password value,
  bool obscure,
  VoidCallback toggle,
  ValueChanged<_Password> onChange,
) => Builder(
  builder: (context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: l10n.password,
        suffixIcon: IconButton(
          onPressed: toggle,
          tooltip: obscure ? l10n.showPassword : l10n.hidePassword,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
      validator: (_) => value.isValid ? null : l10n.passwordShort,
      onChanged: (text) => onChange(_Password.dirty(text)),
    );
  },
);
