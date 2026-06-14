import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

Future<void> showProfileDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Mg.ink.withValues(alpha: 0.34),
    builder: (_) => const _ProfileModal(),
  );
}

class _ProfileModal extends ConsumerStatefulWidget {
  const _ProfileModal();

  @override
  ConsumerState<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends ConsumerState<_ProfileModal> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _titleProviderCtrl = TextEditingController();
  final _titleModelCtrl = TextEditingController();
  final _titleUrlCtrl = TextEditingController();
  final _titleKeyCtrl = TextEditingController();

  final _embedderCtrl = TextEditingController();
  final _embedUrlCtrl = TextEditingController();
  final _embedKeyCtrl = TextEditingController();
  final _embedModelCtrl = TextEditingController();
  
  final _ollamaUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final config = await ref.read(apiClientProvider).getConfig();
      if (mounted) {
        setState(() {
          _titleProviderCtrl.text = config.titleProvider;
          _titleModelCtrl.text = config.titleModel;
          _titleUrlCtrl.text = config.titleApiUrl;
          _titleKeyCtrl.text = config.titleApiKey;
          
          _embedderCtrl.text = config.embedder;
          _embedUrlCtrl.text = config.apiEmbedUrl;
          _embedKeyCtrl.text = config.apiEmbedKey;
          _embedModelCtrl.text = config.apiEmbedModel;
          
          _ollamaUrlCtrl.text = config.ollamaUrl;
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = BackendConfig(
        titleProvider: _titleProviderCtrl.text,
        titleModel: _titleModelCtrl.text,
        titleApiUrl: _titleUrlCtrl.text,
        titleApiKey: _titleKeyCtrl.text,
        embedder: _embedderCtrl.text,
        apiEmbedUrl: _embedUrlCtrl.text,
        apiEmbedKey: _embedKeyCtrl.text,
        apiEmbedModel: _embedModelCtrl.text,
        ollamaUrl: _ollamaUrlCtrl.text,
      );
      await ref.read(apiClientProvider).updateConfig(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Container(
            decoration: BoxDecoration(
              color: Mg.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Mg.border),
              boxShadow: [
                BoxShadow(
                  color: Mg.ink.withValues(alpha: 0.45),
                  blurRadius: 80,
                  offset: const Offset(0, 30),
                  spreadRadius: -20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Mg.divider)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'LLM Provider Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Mg.ink,
                          ),
                        ),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(Icons.close, size: 20, color: Mg.muted2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Body
                  Flexible(
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_error != null) ...[
                                  Text(_error!, style: const TextStyle(color: Mg.red, fontSize: 13)),
                                  const SizedBox(height: 16),
                                ],
                                
                                const Text('Ollama / Local', style: TextStyle(fontWeight: FontWeight.w600, color: Mg.ink)),
                                const SizedBox(height: 8),
                                _Field('Ollama URL', _ollamaUrlCtrl),
                                
                                const SizedBox(height: 24),
                                const Text('Title Generation', style: TextStyle(fontWeight: FontWeight.w600, color: Mg.ink)),
                                const SizedBox(height: 8),
                                _ProviderSelect(
                                  value: _titleProviderCtrl.text.isEmpty ? 'ollama' : _titleProviderCtrl.text,
                                  onChanged: (v) => setState(() => _titleProviderCtrl.text = v!),
                                ),
                                const SizedBox(height: 8),
                                _Field('Model ID (e.g. gemma4:latest or openai/gpt-4o-mini)', _titleModelCtrl),
                                if (_titleProviderCtrl.text == 'api') ...[
                                  _Field('API URL (e.g. https://openrouter.ai/api/v1/chat/completions)', _titleUrlCtrl),
                                  _Field('API Key', _titleKeyCtrl, obscure: true),
                                ],

                                const SizedBox(height: 24),
                                const Text('Search & Embeddings', style: TextStyle(fontWeight: FontWeight.w600, color: Mg.ink)),
                                const SizedBox(height: 8),
                                _ProviderSelect(
                                  value: _embedderCtrl.text.isEmpty ? 'ollama' : _embedderCtrl.text,
                                  onChanged: (v) => setState(() => _embedderCtrl.text = v!),
                                ),
                                const SizedBox(height: 8),
                                if (_embedderCtrl.text == 'api') ...[
                                  _Field('Model ID (e.g. text-embedding-3-small)', _embedModelCtrl),
                                  _Field('API URL (e.g. https://api.openai.com/v1/embeddings)', _embedUrlCtrl),
                                  _Field('API Key', _embedKeyCtrl, obscure: true),
                                ],
                                
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: MouseRegion(
                                    cursor: _saving ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _saving ? null : _save,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Mg.blue,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: _saving
                                            ? const SizedBox(
                                                width: 16, height: 16,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Text(
                                                'Save Configuration',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;

  const _Field(this.label, this.controller, {this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Mg.muted2)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 14, color: Mg.ink),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Mg.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Mg.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Mg.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSelect extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _ProviderSelect({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Mg.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Mg.muted2),
          style: const TextStyle(fontSize: 14, color: Mg.ink),
          items: const [
            DropdownMenuItem(value: 'ollama', child: Text('Local / Ollama')),
            DropdownMenuItem(value: 'api', child: Text('OpenRouter / OpenAI API')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
