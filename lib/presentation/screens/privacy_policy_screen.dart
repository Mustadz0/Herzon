import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Affiche la politique de confidentialité conforme Ã  la loi algérienne 18-07
/// et au RGPD (pour les utilisateurs européens).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de Confidentialité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () => _showLanguageDialog(context),
            tooltip: 'Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: '1. Introduction',
            body: 'Proximité (Â« l\'Application Â») respecte votre vie privée. '
                'Cette politique explique quelles données sont collectées, pourquoi, '
                'et comment elles sont traitées, conformément Ã  la loi algérienne '
                'nÂ° 18-07 relative Ã  la protection des personnes physiques dans le '
                'traitement des données Ã  caractère personnel, modifiée par la loi nÂ° 25-11, '
                'ainsi qu\'au Règlement Général sur la Protection des Données (RGPD) '
                'pour les utilisateurs européens.',
          ),
          _Section(
            title: '2. Données collectées',
            body: 'Nous collectons les catégories de données suivantes :\n\n'
                'â€¢ Données d\'identification : nom, prénom, adresse e-mail, photo de profil.\n'
                'â€¢ Données de localisation : coordonnées GPS (latitude, longitude) pour '
                'les fonctionnalités de proximité.\n'
                'â€¢ Données de contenu : publications, photos, commentaires, réactions.\n'
                'â€¢ Données techniques : adresse IP, type d\'appareil, version du système '
                'd\'exploitation, identifiants uniques de l\'appareil.\n'
                'â€¢ Données d\'interaction : historique des connexions, préférences, '
                'centres d\'intérêt.',
          ),
          _Section(
            title: '3. Base légale du traitement',
            body: 'Le traitement de vos données repose sur :\n\n'
                'â€¢ Votre consentement explicite (article 7 de la loi 18-07) : '
                'vous acceptez la présente politique lors de la création du compte.\n'
                'â€¢ L\'exécution du contrat : les données sont nécessaires au '
                'fonctionnement de l\'Application.\n'
                'â€¢ L\'intérêt légitime : amélioration des services et sécurité.',
          ),
          _Section(
            title: '4. Finalités du traitement',
            body: 'Vos données sont traitées uniquement pour :\n\n'
                'â€¢ Fournir les fonctionnalités de l\'Application (fil d\'actualité, '
                'carte interactive, messagerie, covoiturage, etc.).\n'
                'â€¢ Personnaliser votre expérience (suggestions basées sur vos centres d\'intérêt).\n'
                'â€¢ Assurer la sécurité et la modération du contenu.\n'
                'â€¢ Améliorer nos services via des analyses statistiques anonymisées.\n'
                'â€¢ Se conformer aux obligations légales.',
          ),
          _Section(
            title: '5. Stockage et sécurité',
            body: 'Vos données sont stockées sur des serveurs sécurisés Supabase '
                'hébergés dans l\'Union Européenne. Nous mettons en Å“uvre des mesures '
                'techniques et organisationnelles appropriées pour protéger vos données :\n\n'
                'â€¢ Chiffrement des données en transit (TLS 1.3).\n'
                'â€¢ Contrôle d\'accès strict basé sur les rôles (RLS).\n'
                'â€¢ Authentification sécurisée via Supabase Auth / Google OAuth.\n'
                'â€¢ Sauvegardes régulières chiffrées.',
          ),
          _Section(
            title: '6. Transfert international des données',
            body: 'Conformément Ã  l\'article 40 de la loi 18-07, les données peuvent '
                'être transférées vers des pays offrant un niveau de protection adéquat '
                '(décision de la Commission européenne) ou encadré par des clauses '
                'contractuelles types approuvées.',
          ),
          _Section(
            title: '7. Droits des utilisateurs',
            body: 'Conformément Ã  la loi 18-07 et au RGPD, vous disposez des droits suivants :\n\n'
                'â€¢ Droit d\'accès : obtenir une copie de vos données.\n'
                'â€¢ Droit de rectification : corriger des données inexactes.\n'
                'â€¢ Droit Ã  l\'effacement (droit Ã  l\'oubli) : demander la suppression '
                'de vos données.\n'
                'â€¢ Droit Ã  la limitation du traitement.\n'
                'â€¢ Droit Ã  la portabilité des données.\n'
                'â€¢ Droit d\'opposition au traitement.\n'
                'â€¢ Droit de retirer votre consentement Ã  tout moment.\n\n'
                'Pour exercer ces droits, contactez-nous Ã  l\'adresse :\n'
                'herzon.privacy@email.com',
          ),
          _Section(
            title: '8. Conservation des données',
            body: 'Vos données sont conservées pendant la durée de votre compte actif. '
                'En cas de suppression de compte, toutes les données sont définitivement '
                'effacées dans un délai maximal de 30 jours, sauf obligation légale de '
                'conservation.',
          ),
          _Section(
            title: '9. Cookies et traceurs',
            body: 'L\'Application utilise uniquement des cookies strictement nécessaires '
                'Ã  son fonctionnement (session d\'authentification). Aucun cookie '
                'publicitaire ou de traçage tiers n\'est utilisé.',
          ),
          _Section(
            title: '10. Contact et Autorité de contrôle',
            body: 'Pour toute question relative Ã  cette politique, contactez notre '
                'Délégué Ã  la Protection des Données (DPO) :\n'
                'herzon.privacy@email.com\n\n'
                'Autorité nationale compétente (Algérie) :\n'
                'Autorité Nationale de Protection des Données Ã  Caractère Personnel (ANPDP)\n'
                'http://www.anpdp.dz\n\n'
                'Autorité compétente (Europe) :\n'
                'Votre autorité locale de protection des données (CNIL pour la France).',
          ),
          _Section(
            title: '11. Modifications',
            body: 'Cette politique peut être mise Ã  jour. Vous serez informé de tout '
                'changement substantiel via l\'Application ou par email.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Langue / Ø§Ù„Ù„ØºØ©'),
        content: const Text('La version arabe de la politique de confidentialité '
            'sera disponible prochainement.\n\n'
            'Ù†Ø³Ø®Ø© Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© Ù…Ù† Ø³ÙŠØ§Ø³Ø© Ø§Ù„Ø®ØµÙˆØµÙŠØ© Ø³ØªÙƒÙˆÙ† Ù…ØªØ§Ø­Ø© Ù‚Ø±ÙŠØ¨Ø§Ù‹.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  final bool isLast;

  const _Section({required this.title, required this.body, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 32 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(title,
              style: t.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ),
          const SizedBox(height: 12),
          Text(body,
            style: t.textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
