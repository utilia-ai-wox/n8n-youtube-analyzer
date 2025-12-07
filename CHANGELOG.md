# 📝 Changelog

Toutes les modifications notables de ce projet sont documentées ici.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).

---

## [2.0.0] - 2025-12-07

### ✨ Ajouté

- **Dashboard Notion complet**
  - Création automatique de pages structurées
  - Propriétés : Score, Grade, Type, Sentiment, Topics
  - Contenu : TL;DR, Résumé, Chapitres, Insights, Citations, Takeaways
  - Contenus générés en code blocks

- **IA Décisionnelle**
  - L'IA analyse le contenu et décide quels formats générer
  - `recommended_outputs` : LinkedIn, Twitter, Newsletter
  - Plus besoin de configuration manuelle

- **Architecture Map-Reduce**
  - Chunking intelligent pour vidéos longues (>30min)
  - Claude Haiku pour résumés intermédiaires (économie)
  - Agrégation automatique des chunks

- **Transcription via Apify**
  - Scraping robuste des sous-titres YouTube
  - Support multi-langue
  - Adaptateur de format universel

- **Score de Qualité**
  - Calcul 0-100 basé sur richesse du contenu
  - Grade A-F automatique
  - Facteurs détaillés

- **Error Handling Global**
  - Capture automatique de toutes les erreurs
  - Alertes Slack en temps réel
  - Réponse HTTP 500 formatée

### 🔄 Modifié

- **Cache Supabase amélioré**
  - Pattern Check → Create → Update
  - Évite les erreurs d'upsert
  - Flag `from_cache` dans les réponses

- **Génération conditionnelle**
  - Nodes IF basés sur `recommended_outputs`
  - NoOp nodes pour flux propre
  - Merge en mode Append

- **Notes sur tous les nodes**
  - Format uniforme avec emojis
  - Input/Output documentés
  - 45 nodes documentés

### 🐛 Corrigé

- Perte de données après Cache Check (merge ajouté)
- Erreur UUID sur video_id (type TEXT)
- NOT NULL constraint sur analysis_data
- Optional chaining manquant sur classification

---

## [1.0.0] - 2025-12-06

### ✨ Ajouté

- **Workflow initial**
  - Extraction metadata YouTube
  - Analyse IA (Summary + Insights)
  - Génération LinkedIn + Twitter
  - Sauvegarde Supabase
  - Notification Slack

- **Support multi-entrée**
  - Webhook POST
  - Chat Trigger

- **Documentation de base**
  - README
  - Structure de projet

---

## Roadmap

### [2.1.0] - Prévu

- [ ] Veille automatique sur chaînes YouTube (RSS trigger)
- [ ] Analyse comparative de playlists
- [ ] Export PDF du rapport
- [ ] Intégration Airtable alternative

### [3.0.0] - Futur

- [ ] Multi-vidéo batch processing
- [ ] Dashboard analytics Metabase
- [ ] API publique documentée
- [ ] White-label pour clients
