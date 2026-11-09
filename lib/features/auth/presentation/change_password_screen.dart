import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../domain/password_rules.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      await Supabase.instance.client.auth.signOut();
      return;
    }

    setState(() => _loading = true);
    try {
      // التحقق من كلمة المرور الحالية بإعادة مصادقة صريحة
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _currentController.text,
      );

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newController.text),
      );

      // يرفض الخادم الإغلاق إن لم يكن auth.users.updated_at أحدث من وقت الإجبار
      await Supabase.instance.client.rpc('complete_password_change');

      AppRouter.mustChangePassword = false;
      AppRouter.passwordStateChecked = true;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تغيير كلمة المرور بنجاح'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRouter.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyMessage(Object error) {
    if (error is PostgrestException &&
        RegExp(r'[\u0600-\u06FF]').hasMatch(error.message)) {
      return error.message;
    }
    return AppErrorHandler.friendlyMessage(error);
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(AppStrings.logout,
            style: TextStyle(color: AppColors.gold, fontFamily: 'Cairo')),
        content: const Text(
            'يجب تغيير كلمة المرور قبل استخدام التطبيق. هل تريد تسجيل الخروج؟',
            style:
                TextStyle(color: AppColors.textPrimary, fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await NotificationService.instance.unregisterDeviceToken();
    } catch (_) {
      // لا نمنع تسجيل الخروج بسبب تعذر إزالة التوكن
    }
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: Responsive.fontSize(context, 14),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A4A38), Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: Responsive.pagePadding(context),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          color: AppColors.gold,
                          size: Responsive.iconSize(context, 64),
                        ),
                        SizedBox(height: Responsive.spacing(context, 12)),
                        Text(
                          'تغيير كلمة المرور',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontFamily: 'Cairo',
                            fontSize: Responsive.fontSize(context, 20),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 8)),
                        Text(
                          'لأسباب أمنية، يجب تغيير كلمة المرور المؤقتة قبل استخدام التطبيق',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Cairo',
                            fontSize: Responsive.fontSize(context, 13),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 24)),

                        TextFormField(
                          controller: _currentController,
                          obscureText: _obscureCurrent,
                          style: textStyle,
                          validator: PasswordRules.validateCurrent,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور الحالية',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureCurrent = !_obscureCurrent),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 14)),

                        TextFormField(
                          controller: _newController,
                          obscureText: _obscureNew,
                          style: textStyle,
                          validator: (value) => PasswordRules.validateNew(
                            value,
                            current: _currentController.text,
                          ),
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور الجديدة',
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNew
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureNew = !_obscureNew),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 14)),

                        TextFormField(
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          style: textStyle,
                          validator: (value) => PasswordRules.validateConfirm(
                            value,
                            password: _newController.text,
                          ),
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور الجديدة',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 28)),

                        SizedBox(
                          width: double.infinity,
                          height: Responsive.buttonHeight(context),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'حفظ كلمة المرور',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.fontSize(context, 18),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: Responsive.spacing(context, 12)),

                        TextButton(
                          onPressed: _loading ? null : _confirmLogout,
                          child: const Text(
                            AppStrings.logout,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
