import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool signUp = false;
  bool loading = false;
  String? error;

  @override void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) { setState(() => error = 'Enter your email and password.'); return; }
    setState(() { loading = true; error = null; });
    try {
      final auth = AuthService();
      final response = signUp
          ? await auth.signUp(_email.text, _password.text)
          : await auth.signIn(_email.text, _password.text);
      if (!mounted) return;
      if (signUp && response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created. Check your email to confirm your account.')));
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty) { setState(() => error = 'Enter your email first.'); return; }
    try {
      await AuthService().resetPassword(_email.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset instructions sent if the account exists.')));
    } on AuthException catch (e) { if (mounted) setState(() => error = e.message); }
  }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Icon(Icons.receipt_long_rounded, size: 54, color: theme.colorScheme.primary),
      const SizedBox(height: 14),
      Text('InvoiceEasy', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(signUp ? 'Create your cloud account' : 'Sign in to sync your business', textAlign: TextAlign.center),
      const SizedBox(height: 28),
      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
      const SizedBox(height: 14),
      TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
      if (error != null) ...[const SizedBox(height: 14), Text(error!, style: TextStyle(color: theme.colorScheme.error))],
      const SizedBox(height: 20),
      FilledButton.icon(onPressed: loading ? null : _submit, icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(signUp ? Icons.person_add_alt_1 : Icons.login), label: Text(signUp ? 'Create account' : 'Sign in')),
      if (!signUp) TextButton(onPressed: loading ? null : _resetPassword, child: const Text('Forgot password?')),
      TextButton(onPressed: loading ? null : () => setState(() { signUp = !signUp; error = null; }), child: Text(signUp ? 'Already have an account? Sign in' : 'New to InvoiceEasy? Create account')),
      const SizedBox(height: 12),
      Text('Your invoices remain available offline. Cloud sync is added when you sign in.', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
    ]))))))));
  }
}
