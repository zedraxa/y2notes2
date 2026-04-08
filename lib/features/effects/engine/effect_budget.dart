import 'package:biscuits/core/constants/app_constants.dart';
import 'package:biscuits/core/utils/device_capability.dart';

/// Performance budget that scales effect complexity based on device tier.
class EffectBudget {
  EffectBudget({
    required this.tier,
    required this.maxParticles,
    required this.enableBlur,
    required this.particleDensityScale,
  });

  final DeviceTier tier;
  int maxParticles;
  bool enableBlur;
  double particleDensityScale;

  /// Detect the device tier and build an appropriate budget.
  factory EffectBudget.detect() {
    final tier = DeviceCapability.detect();
    switch (tier) {
      case DeviceTier.high:
        return EffectBudget(
          tier: tier,
          maxParticles: AppConstants.maxParticlesHigh,
          enableBlur: true,
          particleDensityScale: AppConstants.particleDensityHigh,
        );
      case DeviceTier.medium:
        return EffectBudget(
          tier: tier,
          maxParticles: AppConstants.maxParticlesMedium,
          enableBlur: true,
          particleDensityScale: AppConstants.particleDensityMedium,
        );
      case DeviceTier.low:
        return EffectBudget(
          tier: tier,
          maxParticles: AppConstants.maxParticlesLow,
          enableBlur: false,
          particleDensityScale: AppConstants.particleDensityLow,
        );
    }
  }

  /// Scale [count] by the device density factor.
  int scaledParticleCount(int count) =>
      (count * particleDensityScale).round().clamp(1, maxParticles);

  // ── Shared budget split ────────────────────────────────────────────────────

  /// Maximum particles reserved for writing effects (60 % of total budget).
  int get writingMaxParticles => (maxParticles * 0.6).round();

  /// Maximum particles reserved for interaction effects (40 % of total budget).
  int get interactionMaxParticles => (maxParticles * 0.4).round();
}
