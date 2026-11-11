/// Adresse du serveur MEMA, a un seul endroit.
///
/// - Chrome (Flutter web) : "localhost" fonctionne directement.
/// - Telephone Android branche en USB : lancer d'abord `adb reverse tcp:8080 tcp:8080`,
///   le telephone joint alors le PC via "localhost".
/// - Plus tard : remplacer par l'adresse du serveur en ligne (https://...).
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
}
