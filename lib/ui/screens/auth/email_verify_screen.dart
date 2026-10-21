import 'dart:async';

import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  String? _error;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _verifying = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _code;
    if (code.length != 4) {
      setState(() => _error = 'Введите 4 цифры из письма');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final ok =
        await context.read<AppProvider>().verifyEmail(widget.email, code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      setState(() => _error = 'Неверный или просроченный код');
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      await context.read<AppProvider>().sendEmailCode(widget.email);
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код отправлен повторно на email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: CargoColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Код из email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Код отправлен на\n${widget.email}',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  width: 52,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 3) {
                        _focusNodes[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _focusNodes[i - 1].requestFocus();
                      }
                      if (_code.length == 4) _verify();
                    },
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CargoColors.red),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Войти'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? 'Повтор через $_secondsLeft с'
                    : 'Отправить код ещё раз',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
