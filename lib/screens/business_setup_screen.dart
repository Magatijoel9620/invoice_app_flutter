import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_profile.dart';
import '../providers/app_providers.dart';
import 'widgets/app_card.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupState();
}

class _BusinessSetupState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _type = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _kraPin = TextEditingController();

  int step = 0;
  bool saving = false;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    _phone.dispose();
    _email.dispose();
    _kraPin.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      /*
       * When cloud authentication is active, use the authenticated user's
       * ID as the business/profile owner key.
       *
       * If there is no authenticated user, retain the local-only default ID.
       */
      final user = Supabase.instance.client.auth.currentUser;

      final businessId = user?.id ?? 'default';

      final business = BusinessProfile(
        id: businessId,
        name: _name.text.trim(),
        businessType: _type.text.trim().isEmpty ? 'Other' : _type.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        kraPin: _kraPin.text.trim(),
      );

      /*
       * Save through the provider/repository so the same persistence path
       * is used by both local and cloud modes.
       */
      await ref.read(businessProvider.notifier).save(business);

      if (!mounted) return;

      widget.onComplete();
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: step,

            onStepContinue: saving
                ? null
                : () {
                    if (step < 2) {
                      setState(() {
                        step++;
                      });
                    } else {
                      _save();
                    }
                  },

            onStepCancel: step == 0
                ? null
                : () {
                    setState(() {
                      step--;
                    });
                  },

            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: details.onStepContinue,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(step == 2 ? 'Finish setup' : 'Continue'),
                    ),

                    if (step > 0) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },

            steps: [
              Step(
                title: const Text('Business'),
                subtitle: const Text('Your identity on invoices'),
                isActive: step >= 0,
                content: AppCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Business name',
                          hintText: 'e.g. Acme Traders',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your business name';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _type,
                        decoration: const InputDecoration(
                          labelText: 'Business type',
                          hintText: 'e.g. Retail, Consultancy',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Step(
                title: const Text('Contact'),
                subtitle: const Text('How customers can reach you'),
                isActive: step >= 1,
                content: AppCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                    ],
                  ),
                ),
              ),

              Step(
                title: const Text('Tax'),
                subtitle: const Text('Optional KRA details'),
                isActive: step >= 2,
                content: AppCard(
                  child: TextField(
                    controller: _kraPin,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'KRA PIN',
                      hintText: 'Optional',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
