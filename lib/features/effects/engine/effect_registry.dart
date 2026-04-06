import 'package:y2notes2/features/effects/engine/effect_config.dart';

/// Central registry for all writing effects.
///
/// Effects self-register by calling [EffectRegistry.register]. Adding a new
/// effect is a one-liner: create the class and call register.
class EffectRegistry {
  EffectRegistry._();

  static final EffectRegistry instance = EffectRegistry._();

  final Map<String, WritingEffect> _effects = {};

  /// Register an effect. The effect's [WritingEffect.id] is used as the key.
  void register(WritingEffect effect) {
    _effects[effect.id] = effect;
  }

  /// Retrieve a registered effect by [id], or null if not registered.
  WritingEffect? get(String id) => _effects[id];

  /// All registered effects in registration order.
  List<WritingEffect> get all => List.unmodifiable(_effects.values);

  /// All currently-enabled effects.
  List<WritingEffect> get enabled =>
      _effects.values.where((e) => e.isEnabled).toList();

  /// Remove an effect from the registry.
  void unregister(String id) => _effects.remove(id);

  /// Clear all registered effects.
  void clear() => _effects.clear();
}
