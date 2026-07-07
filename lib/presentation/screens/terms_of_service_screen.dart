import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Affiche les Conditions GÃ©nÃ©rales d'Utilisation (CGU) de ProximitÃ©.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions d\'Utilisation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: '1. Acceptation des conditions',
            body: 'En crÃ©ant un compte et en utilisant l\'Application ProximitÃ©, '
                'vous acceptez pleinement les prÃ©sentes Conditions GÃ©nÃ©rales '
                'd\'Utilisation (CGU). Si vous n\'acceptez pas ces conditions, '
                'veuillez ne pas utiliser l\'Application.',
          ),
          _Section(
            title: '2. Description du service',
            body: 'ProximitÃ© est un rÃ©seau social de proximitÃ© qui permet aux '
                'utilisateurs de : publier du contenu gÃ©olocalisÃ©, interagir avec '
                'd\'autres utilisateurs Ã  proximitÃ©, crÃ©er et rejoindre des Ã©vÃ©nements, '
                'partager des trajets en covoiturage, crÃ©er des pages pour des '
                'organisations, et utiliser d\'autres fonctionnalitÃ©s sociales.',
          ),
          _Section(
            title: '3. CrÃ©ation de compte',
            body: 'Pour utiliser l\'Application, vous devez :\n\n'
                'â€¢ ÃŠtre Ã¢gÃ© d\'au moins 13 ans (ou 16 ans dans l\'UE).\n'
                'â€¢ Fournir des informations exactes et Ã  jour.\n'
                'â€¢ Ne pas crÃ©er de comptes multiples de maniÃ¨re abusive.\n'
                'â€¢ ProtÃ©ger la confidentialitÃ© de vos identifiants de connexion.\n\n'
                'Vous Ãªtes responsable de toutes les activitÃ©s effectuÃ©es via votre compte.',
          ),
          _Section(
            title: '4. Contenu publiÃ©',
            body: 'Vous conservez la propriÃ©tÃ© intellectuelle de votre contenu. '
                'En publiant sur ProximitÃ©, vous nous accordez une licence non '
                'exclusive, gratuite, mondiale, pour afficher et distribuer votre '
                'contenu dans le cadre de l\'Application.\n\n'
                'Il est interdit de publier :\n'
                'â€¢ Du contenu illÃ©gal, diffamatoire, haineux ou discriminatoire.\n'
                'â€¢ Du contenu Ã  caractÃ¨re pornographique ou violent.\n'
                'â€¢ Des informations personnelles sans consentement.\n'
                'â€¢ Du spam, des programmes malveillants ou des liens frauduleux.\n'
                'â€¢ Du contenu violant les droits de propriÃ©tÃ© intellectuelle.',
          ),
          _Section(
            title: '5. ModÃ©ration et suspension',
            body: 'Nous nous rÃ©servons le droit de :\n\n'
                'â€¢ Supprimer tout contenu violant les prÃ©sentes CGU, sans prÃ©avis.\n'
                'â€¢ Suspendre ou supprimer votre compte en cas de violation grave '
                'ou rÃ©pÃ©tÃ©e.\n'
                'â€¢ Signaler aux autoritÃ©s compÃ©tentes tout contenu illÃ©gal.\n\n'
                'Vous pouvez signaler un contenu abusif via l\'interface de '
                'l\'Application.',
          ),
          _Section(
            title: '6. Comportement des utilisateurs',
            body: 'Vous vous engagez Ã  :\n\n'
                'â€¢ Ne pas usurper l\'identitÃ© d\'une autre personne.\n'
                'â€¢ Ne pas harceler, menacer ou intimider d\'autres utilisateurs.\n'
                'â€¢ Ne pas utiliser l\'Application Ã  des fins frauduleuses.\n'
                'â€¢ Ne pas tenter de contourner les mesures de sÃ©curitÃ©.\n'
                'â€¢ Ne pas collecter les donnÃ©es d\'autres utilisateurs sans autorisation.',
          ),
          _Section(
            title: '7. PropriÃ©tÃ© intellectuelle',
            body: 'L\'Application ProximitÃ©, son nom, son logo, et son code source '
                'sont la propriÃ©tÃ© exclusive du dÃ©veloppeur. Toute reproduction '
                'ou utilisation non autorisÃ©e est interdite.',
          ),
          _Section(
            title: '8. Limitation de responsabilitÃ©',
            body: 'L\'Application est fournie Â« en l\'Ã©tat Â». Nous ne garantissons pas '
                'une disponibilitÃ© ininterrompue ou sans erreur.\n\n'
                'Dans toute la mesure permise par la loi, nous dÃ©clinons toute '
                'responsabilitÃ© pour :\n'
                'â€¢ Les dommages directs ou indirects rÃ©sultant de l\'utilisation '
                'de l\'Application.\n'
                'â€¢ Les interactions entre utilisateurs en dehors de l\'Application.\n'
                'â€¢ La perte de donnÃ©es ou d\'opportunitÃ©s.\n'
                'â€¢ L\'exactitude des informations de localisation.',
          ),
          _Section(
            title: '9. DonnÃ©es personnelles',
            body: 'L\'utilisation de vos donnÃ©es est rÃ©gie par notre Politique de '
                'ConfidentialitÃ©, accessible depuis les paramÃ¨tres de l\'Application. '
                'ConformÃ©ment Ã  la loi algÃ©rienne 18-07 et au RGPD, vous disposez '
                'de droits sur vos donnÃ©es (accÃ¨s, rectification, suppression).',
          ),
          _Section(
            title: '10. Loi applicable',
            body: 'Les prÃ©sentes CGU sont rÃ©gies par le droit algÃ©rien. Tout litige '
                'relatif Ã  l\'interprÃ©tation ou Ã  l\'exÃ©cution des CGU sera soumis '
                'aux tribunaux compÃ©tents d\'Alger.',
          ),
          _Section(
            title: '11. Contact',
            body: 'Pour toute question concernant ces conditions, contactez-nous :\n'
                'herzon.legal@email.com',
            isLast: true,
          ),
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
