import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Affiche les Conditions Générales d'Utilisation (CGU) de Proximité.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions d\'Utilisation')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Section(
            title: '1. Acceptation des conditions',
            body: 'En créant un compte et en utilisant l\'Application Proximité, '
                'vous acceptez pleinement les présentes Conditions Générales '
                'd\'Utilisation (CGU). Si vous n\'acceptez pas ces conditions, '
                'veuillez ne pas utiliser l\'Application.',
          ),
          _Section(
            title: '2. Description du service',
            body: 'Proximité est un réseau social de proximité qui permet aux '
                'utilisateurs de : publier du contenu géolocalisé, interagir avec '
                'd\'autres utilisateurs Ã  proximité, créer et rejoindre des événements, '
                'partager des trajets en covoiturage, créer des pages pour des '
                'organisations, et utiliser d\'autres fonctionnalités sociales.',
          ),
          _Section(
            title: '3. Création de compte',
            body: 'Pour utiliser l\'Application, vous devez :\n\n'
                'â€¢ ÃŠtre âgé d\'au moins 13 ans (ou 16 ans dans l\'UE).\n'
                'â€¢ Fournir des informations exactes et Ã  jour.\n'
                'â€¢ Ne pas créer de comptes multiples de manière abusive.\n'
                'â€¢ Protéger la confidentialité de vos identifiants de connexion.\n\n'
                'Vous êtes responsable de toutes les activités effectuées via votre compte.',
          ),
          _Section(
            title: '4. Contenu publié',
            body: 'Vous conservez la propriété intellectuelle de votre contenu. '
                'En publiant sur Proximité, vous nous accordez une licence non '
                'exclusive, gratuite, mondiale, pour afficher et distribuer votre '
                'contenu dans le cadre de l\'Application.\n\n'
                'Il est interdit de publier :\n'
                'â€¢ Du contenu illégal, diffamatoire, haineux ou discriminatoire.\n'
                'â€¢ Du contenu Ã  caractère pornographique ou violent.\n'
                'â€¢ Des informations personnelles sans consentement.\n'
                'â€¢ Du spam, des programmes malveillants ou des liens frauduleux.\n'
                'â€¢ Du contenu violant les droits de propriété intellectuelle.',
          ),
          _Section(
            title: '5. Modération et suspension',
            body: 'Nous nous réservons le droit de :\n\n'
                'â€¢ Supprimer tout contenu violant les présentes CGU, sans préavis.\n'
                'â€¢ Suspendre ou supprimer votre compte en cas de violation grave '
                'ou répétée.\n'
                'â€¢ Signaler aux autorités compétentes tout contenu illégal.\n\n'
                'Vous pouvez signaler un contenu abusif via l\'interface de '
                'l\'Application.',
          ),
          _Section(
            title: '6. Comportement des utilisateurs',
            body: 'Vous vous engagez Ã  :\n\n'
                'â€¢ Ne pas usurper l\'identité d\'une autre personne.\n'
                'â€¢ Ne pas harceler, menacer ou intimider d\'autres utilisateurs.\n'
                'â€¢ Ne pas utiliser l\'Application Ã  des fins frauduleuses.\n'
                'â€¢ Ne pas tenter de contourner les mesures de sécurité.\n'
                'â€¢ Ne pas collecter les données d\'autres utilisateurs sans autorisation.',
          ),
          _Section(
            title: '7. Propriété intellectuelle',
            body: 'L\'Application Proximité, son nom, son logo, et son code source '
                'sont la propriété exclusive du développeur. Toute reproduction '
                'ou utilisation non autorisée est interdite.',
          ),
          _Section(
            title: '8. Limitation de responsabilité',
            body: 'L\'Application est fournie Â« en l\'état Â». Nous ne garantissons pas '
                'une disponibilité ininterrompue ou sans erreur.\n\n'
                'Dans toute la mesure permise par la loi, nous déclinons toute '
                'responsabilité pour :\n'
                'â€¢ Les dommages directs ou indirects résultant de l\'utilisation '
                'de l\'Application.\n'
                'â€¢ Les interactions entre utilisateurs en dehors de l\'Application.\n'
                'â€¢ La perte de données ou d\'opportunités.\n'
                'â€¢ L\'exactitude des informations de localisation.',
          ),
          _Section(
            title: '9. Données personnelles',
            body: 'L\'utilisation de vos données est régie par notre Politique de '
                'Confidentialité, accessible depuis les paramètres de l\'Application. '
                'Conformément Ã  la loi algérienne 18-07 et au RGPD, vous disposez '
                'de droits sur vos données (accès, rectification, suppression).',
          ),
          _Section(
            title: '10. Loi applicable',
            body: 'Les présentes CGU sont régies par le droit algérien. Tout litige '
                'relatif Ã  l\'interprétation ou Ã  l\'exécution des CGU sera soumis '
                'aux tribunaux compétents d\'Alger.',
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
