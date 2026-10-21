import 'package:cargo_line_tj/providers/app_provider.dart';
import 'package:cargo_line_tj/ui/screens/auth/sms_verify_screen.dart';
import 'package:cargo_line_tj/ui/widgets/cargo_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Вход: лого + номер +992 и 9 цифр (без списка операторов).
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy) return;
    final local = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (local.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 9 цифр номера после +992'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final phone = '+992 $local';
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmsVerifyScreen(phone: phone, demoMode: true),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppProvider>().strings;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const CargoLogo(height: 64, heroTag: null, showText: true),
              const SizedBox(height: 48),
              Text(
                s.isRu
                    ? 'Номер телефона Таджикистана'
                    : 'Рақами телефони Тоҷикистон',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: InputDecoration(
                  labelText: s.isRu ? 'Номер телефона' : 'Рақами телефон',
                  prefixText: '+992 ',
                  prefixStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  counterText: '',
                  hintText: 'XXXXXXXXX',
                ),
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.isRu ? 'Продолжить' : 'Давом додан'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.isRu
                    ? 'Демо-вход: код 1234 (без SMS)'
                    : 'Демо: рамз 1234 (бе SMS)',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
