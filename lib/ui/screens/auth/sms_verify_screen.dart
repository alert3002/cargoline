import 'dart:async';

import 'package:cargo_line_tj/parcel_app_theme.dart';
import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SmsVerifyScreen extends StatefulWidget {
  const SmsVerifyScreen({
    super.key,
    required this.phone,
    this.demoMode = false,
    this.viaTelegram = false,
  });

  final String phone;
  final bool demoMode;
  final bool viaTelegram;

  @override
  State<SmsVerifyScreen> createState() => _SmsVerifyScreenState();
}

class _SmsVerifyScreenState extends State<SmsVerifyScreen> {
  static const _len = 4;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  String? _error;
  bool _verifying = false;
  bool _resending = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_len, (_) => TextEditingController());
    _focusNodes = List.generate(_len, (_) => FocusNode());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
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

  Future<void> _verify() async {
    if (_verifying) return;
    final code =
        _controllers.map((c) => c.text).join().replaceAll(RegExp(r'\D'), '');
    if (code.length != _len) {
      final ru = context.read<AppProvider>().strings.isRu;
      setState(() => _error = ru ? 'Введите 4 цифры' : '4 рақамро ворид кунед');
      return;
    }
    final app = context.read<AppProvider>();
    setState(() {
      _verifying = true;
      _error = null;
    });
    final ok = await app.verifySms(code, widget.phone);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _error = widget.demoMode
            ? 'Демо-код: 1234'
            : (app.strings.isRu ? 'Неверный код' : 'Рамз нодуруст');
      });
    }
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await context.read<AppProvider>().sendSmsCode(widget.phone);
      if (!mounted) return;
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      _startTimer();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Не удалось отправить SMS');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < _len - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _error = null);
    final code = _controllers.map((c) => c.text).join();
    if (code.length == _len) {
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: CargoColors.red,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.smsTitle, style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                widget.demoMode
                    ? (s.isRu
                        ? 'Демо: введите код 1234'
                        : 'Демо: рамз 1234')
                    : s.smsSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.phone,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: CargoColors.red,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_len, (i) {
                  return SizedBox(
                    width: 58,
                    height: 58,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      enabled: !_verifying,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        height: 1.1,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : const Color(0xFFF5F5F7),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFFBDBDBD),
                            width: 1.4,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFFBDBDBD),
                            width: 1.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: CargoColors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CargoColors.red, fontSize: 13),
                ),
              ],
              if (!widget.demoMode) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: (_secondsLeft > 0 || _resending) ? null : _resend,
                  child: _resending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _secondsLeft > 0
                              ? (s.isRu
                                  ? 'Повтор через $_secondsLeft с'
                                  : 'Такрор пас аз $_secondsLeft с')
                              : s.resendCode,
                        ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.verify),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
