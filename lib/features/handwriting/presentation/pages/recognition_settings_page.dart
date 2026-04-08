import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:biscuits/core/services/settings_service.dart';
import 'package:biscuits/features/handwriting/data/language_models_repository.dart';
import 'package:biscuits/features/handwriting/domain/models/language_model.dart';
import 'package:biscuits/features/handwriting/engine/recognition_engine.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_bloc.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_event.dart';
import 'package:biscuits/features/handwriting/presentation/bloc/handwriting_state.dart';
import 'package:biscuits/features/handwriting/presentation/widgets/writing_analysis_panel.dart';
import 'package:biscuits/shared/widgets/service_provider.dart';

/// Settings page for recognition: language, mode, thresholds, backend.
class RecognitionSettingsPage extends StatelessWidget {
  const RecognitionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognition Settings'),
        elevation: 0,
      ),
      body: BlocBuilder<HandwritingBloc, HandwritingState>(
        builder: (context, state) {
          final bloc = context.read<HandwritingBloc>();
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ── Recognition Mode ───────────────────────────────────────────
              _SectionHeader('Recognition Mode'),
              _ModeSelector(current: state.mode, bloc: bloc),

              const Divider(),

              // ── Language ───────────────────────────────────────────────────
              _SectionHeader('Language'),
              _LanguageSelector(
                activeCode: state.activeLanguage,
                models: LanguageModelsRepository.instance.all,
                onChanged: (code) => bloc.add(LanguageChanged(code)),
              ),

              const Divider(),

              // ── Recognition Settings ───────────────────────────────────────
              _SectionHeader('Recognition Engine'),
              const _BackendInfoTile(),
              _ConfidenceThresholdSlider(
                settings: ServiceProvider.of<SettingsService>(context),
              ),

              const Divider(),

              // ── Writing Analysis ───────────────────────────────────────────
              _SectionHeader('Writing Analysis'),
              ListTile(
                leading: const Icon(Icons.analytics_outlined),
                title: const Text('View Writing Statistics'),
                subtitle: const Text('Character size, speed, consistency'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => WritingAnalysisPanel.show(context),
              ),

              const Divider(),

              // ── Recognize All ─────────────────────────────────────────────
              _SectionHeader('Batch Operations'),
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Recognize All Handwriting'),
                subtitle: const Text(
                    'Process all strokes on current page'),
                trailing: state.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: state.isProcessing
                    ? null
                    : () => bloc.add(const RecognizeAllRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current, required this.bloc});

  final RecognitionMode current;
  final HandwritingBloc bloc;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (RecognitionMode.off, 'Off', 'No recognition', Icons.block_outlined),
      (
        RecognitionMode.manual,
        'Manual',
        'Tap "Recognize" to process',
        Icons.touch_app_outlined
      ),
      (
        RecognitionMode.realTime,
        'Real-time',
        'Continuous recognition while writing',
        Icons.bolt_outlined
      ),
      (
        RecognitionMode.autoConvert,
        'Auto-convert',
        'Automatically convert after pausing',
        Icons.auto_awesome_outlined
      ),
    ];

    return Column(
      children: modes.map((m) {
        final (mode, label, desc, icon) = m;
        return RadioListTile<RecognitionMode>(
          value: mode,
          groupValue: current,
          title: Text(label),
          subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
          secondary: Icon(icon, size: 20),
          onChanged: (v) {
            if (v != null) {
              bloc.add(RecognitionModeChanged(v));
            }
          },
        );
      }).toList(),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.activeCode,
    required this.models,
    required this.onChanged,
  });

  final String activeCode;
  final List<LanguageModel> models;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: models.map((m) {
        final isActive = m.code == activeCode;
        final isAvailable = m.status == LanguageModelStatus.available;
        return ListTile(
          leading: isAvailable
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : const Icon(Icons.cloud_download_outlined, size: 20),
          title: Text(m.name),
          subtitle: Text(m.nativeName),
          trailing: isActive
              ? Icon(Icons.radio_button_checked,
                  color: Theme.of(context).colorScheme.primary)
              : const Icon(Icons.radio_button_unchecked),
          onTap: isAvailable ? () => onChanged(m.code) : null,
          enabled: isAvailable,
        );
      }).toList(),
    );
  }
}

class _BackendInfoTile extends StatelessWidget {
  const _BackendInfoTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.memory_outlined),
      title: const Text('Built-in Recognizer'),
      subtitle: const Text(
          'Offline, privacy-preserving. Works without internet.'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Active',
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ConfidenceThresholdSlider extends StatelessWidget {
  const _ConfidenceThresholdSlider({required this.settings});

  final SettingsService settings;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: settings.recognitionConfidenceNotifier,
        builder: (context, value, _) => ListTile(
          leading: const Icon(Icons.tune, size: 20),
          title: const Text('Confidence Threshold'),
          subtitle: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(value * 100).round()}%',
            onChanged: settings.setRecognitionConfidence,
          ),
          trailing: Text(
            '${(value * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
}
