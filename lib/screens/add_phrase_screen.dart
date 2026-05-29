import 'package:flutter/material.dart';
import '../services/app_group_service.dart';

const _pointColor = Color(0xFF7FC7FF);

class AddPhraseScreen extends StatefulWidget {
  const AddPhraseScreen({super.key});

  @override
  State<AddPhraseScreen> createState() => _AddPhraseScreenState();
}

class _AddPhraseScreenState extends State<AddPhraseScreen> {
  final _controller = TextEditingController();
  List<String> _phrases = [];
  bool _loading = true;
  bool _adding = false;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  @override
  void initState() {
    super.initState();
    _loadPhrases();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPhrases() async {
    final phrases = await AppGroupService.getCustomPhrases();
    if (!mounted) return;
    setState(() {
      _phrases = phrases;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _adding = true);
    await AppGroupService.addCustomPhrase(text);
    _controller.clear();
    await _loadPhrases();
    if (!mounted) return;
    setState(() => _adding = false);
  }

  Future<void> _delete(String phrase) async {
    await AppGroupService.deleteCustomPhrase(phrase);
    if (!mounted) return;
    setState(() => _phrases.remove(phrase));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isKo ? '내 목록 관리' : 'My List'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _phrases.isEmpty
                    ? Center(
                        child: Text(
                          _isKo ? '저장된 문장이 없어요' : 'No phrases yet',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _phrases.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 16, endIndent: 0),
                        itemBuilder: (context, i) => ListTile(
                          contentPadding:
                              const EdgeInsets.fromLTRB(16, 0, 4, 0),
                          title: Text(
                            _phrases[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _delete(_phrases[i]),
                          ),
                        ),
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _isKo ? '문장을 입력하세요...' : 'Add your phrase...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _pointColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _adding ? null : _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pointColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _pointColor.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isKo ? '추가' : 'Add',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
