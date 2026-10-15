# Clair

Un nettoyeur macOS élégant, transparent et réversible.

Clair analyse les zones temporaires de votre Mac, les présente clairement et vous laisse toujours le dernier mot. Les éléments choisis sont déplacés vers la Corbeille : l’application n’effectue jamais de suppression définitive.

## Ce que Clair analyse

- Caches utilisateur inactifs depuis au moins 7 jours
- Journaux de diagnostic âgés de plus de 30 jours
- Éléments déjà présents dans la Corbeille
- Images disque, paquets et archives anciennes dans Téléchargements
- Données Xcode anciennes, uniquement si cette option est activée dans Réglages

Documents, Photos, Mail et les données de vos applications sont intentionnellement exclus.

## Utilisation

Lancez `Clair.app`, cliquez sur **Analyser**, sélectionnez les éléments souhaités puis choisissez **Déplacer vers la Corbeille**. Utilisez **Clair > Réglages…** pour inclure ou non les données de compilation Xcode.

## Compiler

macOS 13+ et Apple Silicon sont requis. Exécutez :

```sh
./build.sh
```

L’application est générée dans `outputs/Clair.app`.
