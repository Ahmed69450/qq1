import '../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/intent_match.dart';
import 'intent_catalog.dart';

class SemanticRouter {
  final double confidenceThreshold;

  SemanticRouter({this.confidenceThreshold = 0.70});

  IntentMatch? matchIntent(String rawQuery) {
    final normalized = ArabicNormalizer.normalize(rawQuery);
    final tokens = ArabicNormalizer.tokenize(normalized);

    CanonicalIntent? bestMatch;
    double highestScore = 0.0;

    for (final intent in canonicalCatalog) {
      int matchedCount = 0;
      for (final kw in intent.triggerKeywords) {
        final normalizedKw = ArabicNormalizer.normalize(kw);
        if (tokens.any((t) => t.contains(normalizedKw) || normalizedKw.contains(t))) {
          matchedCount++;
        }
      }

      if (matchedCount > 0) {
        // Calculate semantic keyword density score
        final score = (matchedCount / intent.triggerKeywords.length).clamp(0.0, 1.0) * 0.4 + 0.6;
        if (score > highestScore) {
          highestScore = score;
          bestMatch = intent;
        }
      }
    }

    if (bestMatch != null && highestScore >= confidenceThreshold) {
      return IntentMatch(
        action: bestMatch.action,
        confidence: highestScore,
        spokenConfirmation: bestMatch.confirmationResponse,
        parameters: bestMatch.defaultParams,
      );
    }

    return null;
  }
}
