import 'package:flutter/material.dart';

const _pink = Color(0xFF5BC8F5);

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _GuideSection(
          number: 1,
          title: '키보드 추가하는 방법',
          steps: [
            '설정 → 일반 → 키보드 → 키보드 추가',
            'Fonkii 선택',
            '전체 접근 허용 (GIF / 즐겨찾기 동기화에 필요해요)',
          ],
        ),
        SizedBox(height: 12),
        _GuideSection(
          number: 2,
          title: '폰트 변경하는 방법',
          steps: [
            'Fonkii 키보드로 전환 후 Aa 탭 선택',
            '원하는 폰트 카테고리를 고르고 폰트 알약을 탭',
            '선택한 폰트로 그대로 타이핑됩니다',
            '이미 입력된 텍스트를 선택하고 폰트 알약을 탭하면\n해당 폰트로 즉시 변환됩니다',
          ],
        ),
        SizedBox(height: 12),
        _GuideSection(
          number: 3,
          title: '폰트 즐겨찾기',
          steps: [
            'Aa 탭에서 원하는 폰트 알약을 꾹 누르면 즐겨찾기에 추가',
            '즐겨찾기 탭(♥)에서 모아 볼 수 있어요',
          ],
        ),
        SizedBox(height: 12),
        _GuideSection(
          number: 4,
          title: '번역 기능 사용하기',
          steps: [
            '번역 탭 선택',
            '원본 / 도착 언어를 고르고 텍스트 입력',
            '번역 버튼을 탭하면 결과가 나타납니다',
            '"삽입" 버튼으로 호스트 앱에 결과를 바로 붙여넣을 수 있어요',
          ],
        ),
        SizedBox(height: 12),
        _GuideSection(
          number: 5,
          title: '키보드 컬러 변경',
          steps: [
            '팔레트 탭(🎨) 선택',
            '6가지 프리셋 색상을 고르거나, RGB 슬라이더로 직접 만드세요',
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
