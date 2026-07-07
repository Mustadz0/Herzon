import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Affiche la politique de confidentialitÃ© conforme Ã  la loi algÃ©rienne 18-07
/// et au RGPD (pour les utilisateurs europÃ©ens).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de ConfidentialitÃ©'),
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
            body: 'ProximitÃ© (Â« l\'Application Â») respecte votre vie privÃ©e. '
                'Cette politique explique quelles donnÃ©es sont collectÃ©es, pourquoi, '
                'et comment elles sont traitÃ©es, conformÃ©ment Ã  la loi algÃ©rienne '
                'nÂ° 18-07 relative Ã  la protection des personnes physiques dans le '
                'traitement des donnÃ©es Ã  caractÃ¨re personnel, modifiÃ©e par la loi nÂ° 25-11, '
                'ainsi qu\'au RÃ¨glement GÃ©nÃ©ral sur la Protection des DonnÃ©es (RGPD) '
                'pour les utilisateurs europÃ©ens.',
          ),
          _Section(
            title: '2. DonnÃ©es collectÃ©es',
            body: 'Nous collectons les catÃ©gories de donnÃ©es suivantes :\n\n'
                'â€¢ DonnÃ©es d\'identification : nom, prÃ©nom, adresse e-mail, photo de profil.\n'
                'â€¢ DonnÃ©es de localisation : coordonnÃ©es GPS (latitude, longitude) pour '
                'les fonctionnalitÃ©s de proximitÃ©.\n'
                'â€¢ DonnÃ©es de contenu : publications, photos, commentaires, rÃ©actions.\n'
                'â€¢ DonnÃ©es techniques : adresse IP, type d\'appareil, version du systÃ¨me '
                'd\'exploitation, identifiants uniques de l\'appareil.\n'
                'â€¢ DonnÃ©es d\'interaction : historique des connexions, prÃ©fÃ©rences, '
                'centres d\'intÃ©rÃªt.',
          ),
          _Section(
            title: '3. Base lÃ©gale du traitement',
            body: 'Le traitement de vos donnÃ©es repose sur :\n\n'
                'â€¢ Votre consentement explicite (article 7 de la loi 18-07) : '
                'vous acceptez la prÃ©sente politique lors de la crÃ©ation du compte.\n'
                'â€¢ L\'exÃ©cution du contrat : les donnÃ©es sont nÃ©cessaires au '
                'fonctionnement de l\'Application.\n'
                'â€¢ L\'intÃ©rÃªt lÃ©gitime : amÃ©lioration des services et sÃ©curitÃ©.',
          ),
          _Section(
            title: '4. FinalitÃ©s du traitement',
            body: 'Vos donnÃ©es sont traitÃ©es uniquement pour :\n\n'
                'â€¢ Fournir les fonctionnalitÃ©s de l\'Application (fil d\'actualitÃ©, '
                'carte interactive, messagerie, covoiturage, etc.).\n'
                'â€¢ Personnaliser votre expÃ©rience (suggestions basÃ©es sur vos centres d\'intÃ©rÃªt).\n'
                'â€¢ Assurer la sÃ©curitÃ© et la modÃ©ration du contenu.\n'
                'â€¢ AmÃ©liorer nos services via des analyses statistiques anonymisÃ©es.\n'
                'â€¢ Se conformer aux obligations lÃ©gales.',
          ),
          _Section(
            title: '5. Stockage et sÃ©curitÃ©',
            body: 'Vos donnÃ©es sont stockÃ©es sur des serveurs sÃ©curisÃ©s Supabase '
                'hÃ©bergÃ©s dans l\'Union EuropÃ©enne. Nous mettons en Å“uvre des mesures '
                'techniques et organisationnelles appropriÃ©es pour protÃ©ger vos donnÃ©es :\n\n'
                'â€¢ Chiffrement des donnÃ©es en transit (TLS 1.3).\n'
                'â€¢ ContrÃ´le d\'accÃ¨s strict basÃ© sur les rÃ´les (RLS).\n'
                'â€¢ Authentification sÃ©curisÃ©e via Supabase Auth / Google OAuth.\n'
                'â€¢ Sauvegardes rÃ©guliÃ¨res chiffrÃ©es.',
          ),
          _Section(
            title: '6. Transfert international des donnÃ©es',
            body: 'ConformÃ©ment Ã  l\'article 40 de la loi 18-07, les donnÃ©es peuvent '
                'Ãªtre transfÃ©rÃ©es vers des pays offrant un niveau de protection adÃ©quat '
                '(dÃ©cision de la Commission europÃ©enne) ou encadrÃ© par des clauses '
                'contractuelles types approuvÃ©es.',
          ),
          _Section(
            title: '7. Droits des utilisateurs',
            body: 'ConformÃ©ment Ã  la loi 18-07 et au RGPD, vous disposez des droits suivants :\n\n'
                'â€¢ Droit d\'accÃ¨s : obtenir une copie de vos donnÃ©es.\n'
                'â€¢ Droit de rectification : corriger des donnÃ©es inexactes.\n'
                'â€¢ Droit Ã  l\'effacement (droit Ã  l\'oubli) : demander la suppression '
                'de vos donnÃ©es.\n'
                'â€¢ Droit Ã  la limitation du traitement.\n'
                'â€¢ Droit Ã  la portabilitÃ© des donnÃ©es.\n'
                'â€¢ Droit d\'opposition au traitement.\n'
                'â€¢ Droit de retirer votre consentement Ã  tout moment.\n\n'
                'Pour exercer ces droits, contactez-nous Ã  l\'adresse :\n'
                'herzon.privacy@email.com',
          ),
          _Section(
            title: '8. Conservation des donnÃ©es',
            body: 'Vos donnÃ©es sont conservÃ©es pendant la durÃ©e de votre compte actif. '
                'En cas de suppression de compte, toutes les donnÃ©es sont dÃ©finitivement '
                'effacÃ©es dans un dÃ©lai maximal de 30 jours, sauf obligation lÃ©gale de '
                'conservation.',
          ),
          _Section(
            title: '9. Cookies et traceurs',
            body: 'L\'Application utilise uniquement des cookies strictement nÃ©cessaires '
                'Ã  son fonctionnement (session d\'authentification). Aucun cookie '
                'publicitaire ou de traÃ§age tiers n\'est utilisÃ©.',
          ),
          _Section(
            title: '10. Contact et AutoritÃ© de contrÃ´le',
            body: 'Pour toute question relative Ã  cette politique, contactez notre '
                'DÃ©lÃ©guÃ© Ã  la Protection des DonnÃ©es (DPO) :\n'
                'herzon.privacy@email.com\n\n'
                'AutoritÃ© nationale compÃ©tente (AlgÃ©rie) :\n'
                'AutoritÃ© Nationale de Protection des DonnÃ©es Ã  CaractÃ¨re Personnel (ANPDP)\n'
                'http://www.anpdp.dz\n\n'
                'AutoritÃ© compÃ©tente (Europe) :\n'
                'Votre autoritÃ© locale de protection des donnÃ©es (CNIL pour la France).',
          ),
          _Section(
            title: '11. Modifications',
            body: 'Cette politique peut Ãªtre mise Ã  jour. Vous serez informÃ© de tout '
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
        content: const Text('La version arabe de la politique de confidentialitÃ© '
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
