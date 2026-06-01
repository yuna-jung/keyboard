import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const _pink = Color(0xFF5BC8F5);

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _GuideSection(
          number: 1,
          title: l.guideSection1Title,
          steps: [
            l.guideSection1Step1,
            l.guideSection1Step2,
            l.guideSection1Step3,
          ],
        ),
        const SizedBox(height: 12),
        _GuideSection(
          number: 2,
          title: l.guideSection2Title,
          steps: [
            l.guideSection2Step1,
            l.guideSection2Step2,
            l.guideSection2Step3,
            l.guideSection2Step4,
          ],
        ),
        const SizedBox(height: 12),
        _GuideSection(
          number: 3,
          title: l.guideSection3Title,
          steps: [
            l.guideSection3Step1,
            l.guideSection3Step2,
          ],
        ),
        const SizedBox(height: 12),
        _GuideSection(
          number: 4,
          title: l.guideSection4Title,
          steps: [
            l.guideSection4Step1,
            l.guideSection4Step2,
            l.guideSection4Step3,
            l.guideSection4Step4,
          ],
        ),
        const SizedBox(height: 12),
        _GuideSection(
          number: 5,
          title: l.guideSection5Title,
          steps: [
            l.guideSection5Step1,
            l.guideSection5Step2,
          ],
        ),
      ],
    );
  }
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.number,
    required this.title,
    required this.steps,
  });
  final int number;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final stepColor = isDark ? Colors.white70 : Colors.black87;
    final borderColor =
        isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _pink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final isLast = entry.key == steps.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: _pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: stepColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
