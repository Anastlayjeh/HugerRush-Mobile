import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/auth_social_buttons.dart';

enum RegistrationType { hungryUser, restaurant }

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  RegistrationType _type = RegistrationType.hungryUser;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFEA),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = math.min(constraints.maxWidth, 420.0);
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 22 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _HeroHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RewardBanner(),
                            const SizedBox(height: 14),
                            _AccountTypeTabs(
                              type: _type,
                              onChanged: (value) {
                                setState(() => _type = value);
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_type == RegistrationType.hungryUser)
                              ..._buildHungryUserFields()
                            else
                              ..._buildRestaurantFields(),
                            const SizedBox(height: 14),
                            _TermsRow(
                              accepted: _acceptedTerms,
                              onTap: () {
                                setState(() {
                                  _acceptedTerms = !_acceptedTerms;
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            _PrimaryActionButton(
                              label: _type == RegistrationType.hungryUser
                                  ? 'Create Account'
                                  : 'Request for approve',
                            ),
                            if (_type == RegistrationType.hungryUser) ...[
                              const SizedBox(height: 16),
                              const _DividerText(text: 'OR SIGN UP WITH'),
                              const SizedBox(height: 14),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AuthSocialButton(child: GoogleMark()),
                                  SizedBox(width: 16),
                                  AuthSocialButton(
                                    child: Icon(
                                      Icons.apple,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Color(0xFF9D8E80),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFF68B1F),
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Log In',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHungryUserFields() {
    return [
      const _LabeledField(label: 'Full Name', hint: 'Jon Doe'),
      const SizedBox(height: 12),
      const _LabeledField(
        label: 'Email',
        hint: 'john@example.com',
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      const _PhoneNumberBlock(
        label: 'Phone Number',
        countryCode: 'LB +961',
        phoneHint: '03 123 456',
      ),
      const SizedBox(height: 12),
      _LabeledField(
        label: 'Password',
        hint: '********',
        obscureText: _obscurePassword,
        suffix: _EyeButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          visible: !_obscurePassword,
        ),
      ),
      const SizedBox(height: 12),
      _LabeledField(
        label: 'Confirm Password',
        hint: '********',
        obscureText: _obscureConfirmPassword,
        suffix: _EyeButton(
          onPressed: () {
            setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            );
          },
          visible: !_obscureConfirmPassword,
        ),
      ),
    ];
  }

  List<Widget> _buildRestaurantFields() {
    return [
      const _LabeledField(label: 'Restaurant Name', hint: 'The Pizza Hub'),
      const SizedBox(height: 12),
      const _LabeledField(label: 'Cuisine Type', hint: 'e.g. Italian, Lebanese'),
      const SizedBox(height: 12),
      const _LabeledField(
        label: 'Email',
        hint: 'contact@restaurant.com',
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      const _FieldLabelWithAction(
        label: 'Phone Numbers',
        actionLabel: 'Add another',
      ),
      const SizedBox(height: 8),
      const _InlinePhoneRow(
        countryCode: '+961',
        countryFlag: 'LB',
        phoneHint: '03 123 456',
      ),
      const SizedBox(height: 14),
      const _SectionTitle(text: 'LOCATION DETAILS'),
      const SizedBox(height: 10),
      const Row(
        children: [
          Expanded(child: _LabeledField(label: 'Country', hint: 'Lebanon')),
          SizedBox(width: 10),
          Expanded(child: _LabeledField(label: 'City', hint: 'Beirut')),
        ],
      ),
      const SizedBox(height: 12),
      const _LabeledField(label: 'Street', hint: 'Hamra St, Bldg 42'),
      const SizedBox(height: 12),
      const SizedBox(
        width: 125,
        child: _LabeledField(label: 'Postal Code', hint: '1103'),
      ),
      const SizedBox(height: 12),
      _LabeledField(
        label: 'Password',
        hint: '********',
        obscureText: _obscurePassword,
        suffix: _EyeButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          visible: !_obscurePassword,
        ),
      ),
      const SizedBox(height: 12),
      _LabeledField(
        label: 'Confirm Password',
        hint: '********',
        obscureText: _obscureConfirmPassword,
        suffix: _EyeButton(
          onPressed: () {
            setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            );
          },
          visible: !_obscureConfirmPassword,
        ),
      ),
    ];
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: SizedBox(
        height: 186,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const ColoredBox(
                color: Color(0xFF8D5A32),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x70000000), Color(0xA0000000)],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 52, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFFF68B1F),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'HUNGERRUSH',
                        style: TextStyle(
                          color: Color(0xFFEBDCCF),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Text(
                    'Create your\naccount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEE3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5D7C9)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sell_outlined, color: Color(0xFFF68B1F), size: 15),
          SizedBox(width: 6),
          Text(
            'Earn points on every order',
            style: TextStyle(
              color: Color(0xFFF68B1F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 4),
          Icon(Icons.campaign_outlined, color: Color(0xFFF68B1F), size: 14),
        ],
      ),
    );
  }
}

class _AccountTypeTabs extends StatelessWidget {
  const _AccountTypeTabs({
    required this.type,
    required this.onChanged,
  });

  final RegistrationType type;
  final ValueChanged<RegistrationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 47,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6DCCF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeTabButton(
              text: 'Hungry User',
              selected: type == RegistrationType.hungryUser,
              onTap: () => onChanged(RegistrationType.hungryUser),
            ),
          ),
          Expanded(
            child: _TypeTabButton(
              text: 'Restaurant',
              selected: type == RegistrationType.restaurant,
              onTap: () => onChanged(RegistrationType.restaurant),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  const _TypeTabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF6F3EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: const Color(0xFFE3D5C6))
              : Border.all(color: Colors.transparent),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? const Color(0xFFF68B1F) : const Color(0xFF8E7E72),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF46372D),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        _RoundedTextInput(
          hint: hint,
          keyboardType: keyboardType,
          obscureText: obscureText,
          suffix: suffix,
        ),
      ],
    );
  }
}

class _RoundedTextInput extends StatelessWidget {
  const _RoundedTextInput({
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEEA),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE2D5C8)),
      ),
      child: TextField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFC0B1A4),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        ),
        style: const TextStyle(
          color: Color(0xFF2D201A),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({
    required this.onPressed,
    required this.visible,
  });

  final VoidCallback onPressed;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      splashRadius: 18,
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: const Color(0xFFA58F7C),
        size: 18,
      ),
    );
  }
}

class _PhoneNumberBlock extends StatelessWidget {
  const _PhoneNumberBlock({
    required this.label,
    required this.countryCode,
    required this.phoneHint,
  });

  final String label;
  final String countryCode;
  final String phoneHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 96,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF2EEEA),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: const Color(0xFFE2D5C8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    countryCode,
                    style: const TextStyle(
                      color: Color(0xFF725C4C),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFF68B1F),
                    size: 17,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RoundedTextInput(
                hint: phoneHint,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabelWithAction extends StatelessWidget {
  const _FieldLabelWithAction({
    required this.label,
    required this.actionLabel,
  });

  final String label;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FieldLabel(label),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_circle_outline, size: 14),
          label: Text(actionLabel),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF68B1F),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}

class _InlinePhoneRow extends StatelessWidget {
  const _InlinePhoneRow({
    required this.countryCode,
    required this.countryFlag,
    required this.phoneHint,
  });

  final String countryCode;
  final String countryFlag;
  final String phoneHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 102,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEEA),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFE2D5C8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(countryFlag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Text(
                countryCode,
                style: const TextStyle(
                  color: Color(0xFF725C4C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFF68B1F),
                size: 17,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoundedTextInput(
            hint: phoneHint,
            keyboardType: TextInputType.phone,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFF68B1F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF46372D),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.accepted,
    required this.onTap,
  });

  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accepted ? const Color(0xFFF68B1F) : Colors.transparent,
              border: Border.all(color: const Color(0xFFD6C8BB)),
            ),
            child: accepted
                ? const Icon(Icons.check, color: Colors.white, size: 11)
                : null,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(
                  color: Color(0xFFAF9D90),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFFF68B1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFFF68B1F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF68B1F),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          elevation: 3,
          shadowColor: const Color(0x40C26300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0xFFE2D7CB),
            thickness: 1,
            height: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFA8978A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0xFFE2D7CB),
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}
