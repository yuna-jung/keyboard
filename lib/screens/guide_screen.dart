import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

const _pink = Color(0xFF5BC8F5);

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    final tabLabels = isKo
        ? const ['키보드 추가', '번역', '폰트', '내 목록', '즐겨찾기', '테마']
        : const ['Add Keyboard', 'Translation', 'Fonts', 'My List', 'Favorites', 'Themes'];

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF70C7F5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF70C7F5),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: tabLabels.map((t) => Tab(text: t)).toList(),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TabPage1(isKo: isKo, l: l),
              _TabPage4(isKo: isKo, l: l),
              _TabPage2(isKo: isKo, l: l),
              _TabPage6(isKo: isKo, l: l),
              _TabPage3(isKo: isKo, l: l),
              _TabPage5(isKo: isKo, l: l),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 탭 1: 키보드 추가 ──────────────────────────────────────────────────────

class _TabPage1 extends StatelessWidget {
  const _TabPage1({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 1,
        emoji: '⌨️',
        title: l.guideSection1Title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final imgWidth = (constraints.maxWidth - 8) / 2;
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/guide/guide_1a.png',
                          width: imgWidth, height: 250, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/guide/guide_1b.png',
                          width: imgWidth, height: 250, fit: BoxFit.contain),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _StepList(steps: isKo
                ? const [
                    '설정 → 일반 → 키보드 → 새로운 키보드 추가',
                    'Fonkii 선택',
                    '전체 접근 허용 ON',
                  ]
                : const [
                    'Settings → General → Keyboard → Add New Keyboard',
                    'Select Fonkii',
                    'Allow Full Access ON',
                  ]),
          ],
        ),
      ),
    );
  }
}

// ── 탭 2: 폰트 변경 ────────────────────────────────────────────────────────

class _TabPage2 extends StatelessWidget {
  const _TabPage2({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 2,
        emoji: '✏️',
        title: l.guideSection2Title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // 파트 1 - 보라색
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD0F5), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isKo ? '① 텍스트에 커서를 올리고 폰트를 탭해요' : 'Tap a font after placing cursor on text',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3C3489))),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDD0F5)),
                        ),
                        child: RichText(
                          text: TextSpan(children: [
                            WidgetSpan(child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0D8FF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text('Hello Fonkii',
                                  style: TextStyle(fontSize: 15, color: Color(0xFF3C3489))),
                            )),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Normal', 'Bold', 'Script', 'Gothic', 'Typewriter'].map((f) {
                            final selected = f == 'Bold';
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF9B7EE8) : const Color(0xFFEEE8FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF9B7EE8),
                                  width: selected ? 0 : 0.5,
                                ),
                              ),
                              child: Text(f, style: TextStyle(
                                fontSize: 12,
                                color: selected ? Colors.white : const Color(0xFF3C3489),
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              )),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 파트 2 - 녹색
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FBF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFC0EDD5), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isKo ? '② 선택한 폰트로 즉시 변환돼요' : 'Your text converts instantly',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF085041))),
                      const SizedBox(height: 12),
                      Text(isKo ? '변환 전' : 'Before', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFe0e0e0)),
                        ),
                        child: Text('Hello Fonkii',
                            style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                      ),
                      const SizedBox(height: 8),
                      const Center(child: Icon(Icons.arrow_downward, color: Color(0xFF2DBD7E), size: 20)),
                      const SizedBox(height: 8),
                      Text(isKo ? '변환 후' : 'After', style: const TextStyle(fontSize: 11, color: Color(0xFF085041))),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC0EDD5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('𝗛𝗲𝗹𝗹𝗼 𝗙𝗼𝗻𝗸𝗶𝗶',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF085041))),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF2DBD7E),
                              child: const Icon(Icons.check, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(child: Text(isKo ? '다른 폰트를 탭하면 언제든지 변경할 수 있어요' : 'Tap any font to change anytime',
                          style: const TextStyle(fontSize: 11, color: Colors.grey))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: '💬',
              title: isKo ? '폰트 선택' : 'Select a Font',
              desc: isKo
                  ? 'Aa 탭에서 원하는 폰트를 탭하면 이후 입력되는 텍스트에 바로 적용돼요.'
                  : 'Tap any font in the Aa tab to apply it to your next typed text.',
            ),
            const SizedBox(height: 8),
            _infoCard(
              icon: '✏️',
              title: isKo ? '기존 텍스트 변환' : 'Convert Existing Text',
              desc: isKo
                  ? '이미 입력한 텍스트에 커서를 올린 뒤 폰트를 선택하면 해당 텍스트가 변환돼요.'
                  : 'Place the cursor on existing text, then tap a font to convert it.',
            ),
            const SizedBox(height: 8),
            _infoCard(
              icon: '🔄',
              title: isKo ? '폰트 변경' : 'Change Font',
              desc: isKo
                  ? '다른 폰트를 탭하면 언제든지 자유롭게 바꿀 수 있어요.'
                  : 'Tap a different font anytime to switch freely.',
            ),
          ],
        ),
      ),
    );
  }
}

// ── 탭 3: 즐겨찾기 ────────────────────────────────────────────────────────

class _TabPage3 extends StatelessWidget {
  const _TabPage3({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 1,
        title: l.guideSection3Title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                // STEP 1: 길게 누르기
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8ECF0),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Aa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const Text('번역', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('💬', style: TextStyle(fontSize: 12)),
                            const Text('( ᵔ )', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                            const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('⠿', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                            const Text('♥', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                            const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        color: const Color(0xFFEFEFEF),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            _catChip(isKo ? '즐겨찾기' : 'Favorites', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '클래식' : 'Classic', true),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '모던' : 'Modern', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '굵게' : 'Bold', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '재미있는' : 'Fun', false),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _fontCell('Normal', false, false, false)),
                              Expanded(child: _fontCell('Italic', false, true, false)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _fontCell('Bold', true, false, false)),
                              Expanded(child: _fontCell('Bold Italic', true, true, true)),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(16)),
                            child: Text(isKo ? '즐겨찾기에 추가됐어요' : 'Added to Favorites', style: const TextStyle(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_downward, color: Color(0xFFF77BAA), size: 20),
                      Text(isKo ? '길게 누르기' : 'Long press', style: const TextStyle(fontSize: 10, color: Color(0xFFF77BAA))),
                    ],
                  ),
                ),
                // STEP 2: 즐겨찾기 카테고리
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8ECF0),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Aa', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const Text('번역', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('💬', style: TextStyle(fontSize: 12)),
                            const Text('( ᵔ )', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                            const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                            const Text('⠿', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                            const Text('♥', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                            const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        color: const Color(0xFFEFEFEF),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            _catChip(isKo ? '즐겨찾기' : 'Favorites', true),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '클래식' : 'Classic', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '모던' : 'Modern', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '굵게' : 'Bold', false),
                            const SizedBox(width: 6),
                            _catChip(isKo ? '재미있는' : 'Fun', false),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: _fontCellFav('Bold Italic', true, true)),
                          Expanded(child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                            ),
                            child: Center(child: Text(isKo ? '+ 추가 가능' : '+ Add more', style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))),
                          )),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(isKo ? '즐겨찾기 카테고리에서 바로 확인!' : 'Find it in Favorites category!',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF77BAA))),
                            const SizedBox(height: 4),
                            Text(isKo ? '텍스트대치 · 카오모지 · 특수문자는 ♥ 탭에서 확인' : 'Text replacements · Kaomoji · Symbols in ♥ tab',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF70C7F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('2',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                ),
                const SizedBox(width: 10),
                Text(isKo ? '♥ 탭 즐겨찾기' : 'Heart Tab Favorites',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            // STEP 1: 카오모지 길게 누르기
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8ECF0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Aa', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('번역', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(12)),
                          child: const Text('( ᵔ )', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                        const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('⠿', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('♥', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                        const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    color: const Color(0xFFEFEFEF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _catChip(isKo ? '행복' : 'Happy', true),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '슬픔' : 'Sad', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '화남' : 'Angry', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '동물' : 'Animals', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '사랑' : 'Love', false),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9F3),
                          border: Border.all(color: const Color(0xFFF77BAA), width: 1.5),
                        ),
                        child: const Center(child: Text('(●ᴗ●)', style: TextStyle(fontSize: 16))),
                      )),
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        ),
                        child: const Center(child: Text('(★ᴗ★)', style: TextStyle(fontSize: 16))),
                      )),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        ),
                        child: const Center(child: Text('ʕ•ᴥ•ʔ', style: TextStyle(fontSize: 14))),
                      )),
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        ),
                        child: const Center(child: Text('(˘▾˘)', style: TextStyle(fontSize: 14))),
                      )),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(isKo ? '↑ 길게 누르기' : '↑ Long press', style: const TextStyle(fontSize: 10, color: Color(0xFFF77BAA))),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(isKo ? '♥ 즐겨찾기 추가' : '♥ Add to Favorites',
                              style: const TextStyle(fontSize: 13, color: Color(0xFFF77BAA), fontWeight: FontWeight.w600)),
                        ),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(isKo ? '📋 복사' : '📋 Copy', style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                        ),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(isKo ? '취소' : 'Cancel', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Icon(Icons.arrow_downward, color: Color(0xFFF77BAA), size: 20),
            ),
            // STEP 2: 하트 탭 결과
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8ECF0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Aa', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('번역', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('( ᵔ )', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('⠿', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(12)),
                          child: const Text('♥', style: TextStyle(fontSize: 13, color: Colors.white)),
                        ),
                        const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    color: const Color(0xFFEFEFEF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _catChip(isKo ? '전체' : 'All', true),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '자동완성' : 'Auto', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '이모티콘' : 'Emoji', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '기호' : 'Symbols', false),
                        const SizedBox(width: 6),
                        _catChip('GIF', false),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF77BAA), width: 1.5),
                        ),
                        child: const Center(child: Text('(●ᴗ●)', style: TextStyle(fontSize: 16))),
                      )),
                      Expanded(child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9F9),
                          border: Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                        ),
                        child: const Center(child: Text('+ 추가 가능', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)))),
                      )),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Text(isKo ? '♥ 탭에서 한번에 확인!' : 'Find all in ♥ tab!',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF77BAA))),
                        const SizedBox(height: 4),
                        Text(isKo ? '카오모지 · 특수문자 · 텍스트대치 모두 가능' : 'Kaomoji · Symbols · Text replacements',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(isKo ? '전체 · 이모티콘 · 기호 · GIF 탭으로 분류' : 'Sorted by All · Emoji · Symbols · GIF',
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
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

// ── 탭 4: 번역 ────────────────────────────────────────────────────────────

class _TabPage4 extends StatelessWidget {
  const _TabPage4({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 4,
        emoji: '🌍',
        title: l.guideSection4Title,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFC8ECF0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA8D8E0), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB8E4EC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Text('🇰🇷 Korean ▼', style: TextStyle(fontSize: 12, color: Color(0xFF333333))),
                        const SizedBox(width: 12),
                        const Text('→', style: TextStyle(fontSize: 14, color: Color(0xFFF77BAA))),
                        const SizedBox(width: 12),
                        const Text('🇺🇸 English ▼', style: TextStyle(fontSize: 12, color: Color(0xFF333333))),
                        const Spacer(),
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('🔄', style: TextStyle(fontSize: 12))),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('🗑', style: TextStyle(fontSize: 12))),
                        ),
                      ],
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('나 좀 낯가리는데..', style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                              const SizedBox(height: 40),
                              const Align(
                                alignment: Alignment.bottomRight,
                                child: Text('11 / 200', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                        )),
                        Expanded(child: Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFF0F0F0),
                          child: const Text("I'm a bit shy\naround new people.", style: TextStyle(fontSize: 13, color: Color(0xFF444444))),
                        )),
                      ],
                    ),
                  ),
                  Container(
                    height: 36,
                    color: const Color(0xFFC8ECF0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Aa', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(8)),
                          child: const Text('번역', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const Text('💬', style: TextStyle(fontSize: 12)),
                        const Text('( ᵔ )', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('♥', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                        const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8ECF0),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFF8AB8C8), borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('En', style: TextStyle(fontSize: 10, color: Colors.white))),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 56, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('!?123', style: TextStyle(fontSize: 10, color: Colors.white))),
                        ),
                        const SizedBox(width: 4),
                        Expanded(child: Container(
                          height: 28,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFDDDDDD))),
                          child: const Center(child: Text('space', style: TextStyle(fontSize: 11, color: Colors.grey))),
                        )),
                        const SizedBox(width: 4),
                        Container(
                          width: 48, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('번역', style: TextStyle(fontSize: 11, color: Colors.white))),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 48, height: 28,
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Text('삽입', style: TextStyle(fontSize: 11, color: Colors.white))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FBF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC0EDD5), width: 0.5),
              ),
              child: Column(
                children: [
                  Text(isKo ? '🌍 10개 언어 지원' : '🌍 10 Languages Supported', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF085041))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      '🇰🇷 Korean', '🇺🇸 English', '🇯🇵 Japanese', '🇨🇳 Chinese',
                      '🇪🇸 Spanish', '🇫🇷 French', '🇩🇪 German', '🇻🇳 Vietnamese',
                      '🇹🇭 Thai', '🇮🇩 Indonesian',
                    ].map((lang) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC0EDD5), width: 0.5),
                      ),
                      child: Text(lang, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5DFA0), width: 0.5),
              ),
              child: Column(
                children: [
                  Text(isKo ? '✨ 자연스러운 AI 번역' : '✨ Natural AI Translation', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF633806))),
                  const SizedBox(height: 8),
                  Text(isKo ? '문맥을 이해한 자연스러운 번역을 제공해요' : 'Context-aware translation that sounds natural', style: const TextStyle(fontSize: 11, color: Color(0xFF854F0B))),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE0E0E0))),
                    child: Text(isKo ? '직역:  "Today weather very good!"  ❌' : 'Literal:  "Today weather very good!"  ❌', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F8EF), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC0EDD5))),
                    child: const Text('Fonkii: "The weather is so nice today!"  ✓', style: TextStyle(fontSize: 11, color: Color(0xFF085041))),
                  ),
                  const SizedBox(height: 6),
                  Text(isKo ? '원어민처럼 자연스러운 표현으로 소통하세요!' : 'Communicate like a native speaker!', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 탭 5: 테마 ────────────────────────────────────────────────────────────

class _TabPage5 extends StatelessWidget {
  const _TabPage5({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 5,
        emoji: '🎨',
        title: l.guideSection5Title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKo ? '⚙ 탭을 눌러 테마를 선택하세요' : 'Tap ⚙ to select a theme',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    isKo ? 'assets/guide/guide_5a.png' : 'assets/guide/guide_5a_en.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              isKo ? '8가지 테마' : '8 Themes',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _themeCard(isKo ? '코튼캔디' : 'Cotton Candy', 'assets/guide/guide_5b.png'),
                _themeCard(isKo ? '퍼플' : 'Purple', 'assets/guide/guide_5c.png'),
                _themeCard(isKo ? '파스텔 레인보우' : 'Pastel Rainbow', 'assets/guide/guide_5d.png'),
                _themeCard(isKo ? '소프트' : 'Soft', 'assets/guide/guide_5e.png'),
                _themeCard(isKo ? '버블 민트' : 'Bubble Mint', 'assets/guide/guide_5f.png'),
                _themeCard(isKo ? '레트로 크림' : 'Retro Cream', 'assets/guide/guide_5g.png'),
                _themeCard(isKo ? '빈티지 그레이' : 'Vintage Gray', 'assets/guide/guide_5h.png'),
                _themeCard(isKo ? '미드나잇 핑크' : 'Midnight Pink', 'assets/guide/guide_5i.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 탭 6: 내 목록(문장 저장) ──────────────────────────────────────────────

class _TabPage6 extends StatelessWidget {
  const _TabPage6({required this.isKo, required this.l});
  final bool isKo;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _GuideCard(
        number: 1,
        emoji: '💬',
        title: isKo ? '내 목록에 문장 저장하기' : 'Save Phrases to My List',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: 다른 앱에서 텍스트 선택
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isKo ? '다른 앱에서' : 'In any app',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: isKo ? '오히려 좋아! 💜' : 'Have a good one!',
                          style: const TextStyle(
                              backgroundColor: Color(0xFFB3D9FF)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  const Icon(Icons.arrow_downward,
                      color: Color(0xFFF77BAA), size: 20),
                  Text(isKo ? '텍스트를 드래그해서 선택' : 'Drag to select text',
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFFF77BAA))),
                ],
              ),
            ),
            // STEP 2: 💬 탭에서 +추가
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8ECF0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Aa', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('번역', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF77BAA), borderRadius: BorderRadius.circular(8)),
                          child: const Text('💬', style: TextStyle(fontSize: 12)),
                        ),
                        const Text('✦', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('GIF', style: TextStyle(fontSize: 11, color: Color(0xFF555555))),
                        const Text('⠿', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                        const Text('♥', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                        const Text('⚙', style: TextStyle(fontSize: 13, color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    color: const Color(0xFFEFEFEF),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        _catChip(isKo ? '내 목록' : 'My List', true),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '빠른메시지' : 'Quick', false),
                        const SizedBox(width: 6),
                        _catChip(isKo ? '일상' : 'Daily', false),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF77BAA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(isKo ? '+ 추가' : '+ Add',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(16)),
                        child: Text(isKo ? '내 목록에 저장했어요!' : 'Saved to My List!',
                            style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StepList(steps: isKo
                ? const [
                    '원하는 텍스트를 드래그해서 선택하세요',
                    "💬 탭에서 '+추가' 버튼을 누르세요",
                    '선택한 문장이 내 목록에 저장돼요! (한글·이모지 모두 가능)',
                    '저장한 문장은 길게 눌러 즐겨찾기에 추가할 수도 있어요',
                  ]
                : const [
                    'Select the text you want by dragging',
                    "Tap the '+Add' button in the 💬 tab",
                    'The selected phrase is saved to My List! (Works with any language and emojis)',
                    'Long-press a saved phrase to add it to Favorites too',
                  ]),
          ],
        ),
      ),
    );
  }
}

// ── 공통 헬퍼 ─────────────────────────────────────────────────────────────


class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.number,
    required this.title,
    required this.child,
    this.emoji,
  });

  final int number;
  final String title;
  final Widget child;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF70C7F5),
                  shape: BoxShape.circle,
                ),
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 14))
                    : Text(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        final isLast = entry.key == steps.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key + 1}. ',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: _pink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

Widget _catChip(String label, bool selected) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFF77BAA) : const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(label, style: TextStyle(
      fontSize: 10,
      color: selected ? Colors.white : const Color(0xFF555555),
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
    )),
  );
}

Widget _fontCell(String label, bool bold, bool italic, bool pressing) {
  return Container(
    height: 44,
    decoration: BoxDecoration(
      color: pressing ? const Color(0xFFFFE9F3) : Colors.white,
      border: Border.all(
        color: pressing ? const Color(0xFFF77BAA) : const Color(0xFFE8E8E8),
        width: pressing ? 1.5 : 0.5,
      ),
    ),
    child: Center(child: Text(label, style: TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    ))),
  );
}

Widget _fontCellFav(String label, bool bold, bool italic) {
  return Container(
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFF77BAA), width: 1.5),
    ),
    child: Center(child: Text(label, style: TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    ))),
  );
}

Widget _infoCard({
  required String icon,
  required String title,
  required String desc,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F5FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _themeCard(String name, String assetPath) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          assetPath,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
      ),
    ],
  );
}
