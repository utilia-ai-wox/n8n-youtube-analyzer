# 📺 YouTube Content Analyzer Pro

[![n8n](https://img.shields.io/badge/n8n-workflow-orange?logo=n8n)](https://n8n.io)
[![Claude](https://img.shields.io/badge/Claude-Sonnet%204.5-blueviolet?logo=anthropic)](https://anthropic.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Workflow n8n intelligent** qui analyse automatiquement n'importe quelle vidéo YouTube et génère du contenu social media prêt à publier.

![Architecture](docs/assets/architecture-overview.png)

---

## 🎯 Fonctionnalités

| Feature | Description |
|---------|-------------|
| 🔍 **Extraction Metadata** | Titre, chaîne, durée, vues, likes via YouTube Data API |
| 📝 **Transcription** | Récupération automatique via Apify (multi-langue) |
| 🧠 **Analyse IA Multi-pass** | Classification, résumé, insights, sentiment |
| ✂️ **Chunking Intelligent** | Map-Reduce pour vidéos longues (>30min) |
| 📱 **Génération Conditionnelle** | LinkedIn, Twitter, Newsletter (l'IA décide) |
| 💾 **Cache Supabase** | Évite de retraiter une vidéo déjà analysée |
| 📊 **Dashboard Notion** | Pages structurées avec chapitres, insights, takeaways |
| 🔔 **Notifications Slack** | Alertes temps réel + gestion d'erreurs |

---

## 🏗️ Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   TRIGGER   │────▶│   EXTRACT   │────▶│    CACHE    │
│  Webhook /  │     │  Parse URL  │     │  Supabase   │
│    Chat     │     │ YouTube API │     │   Check     │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                         ┌─────────────────────┴─────────────────────┐
                         │                                           │
                         ▼                                           ▼
                  ┌─────────────┐                            ┌─────────────┐
                  │   CACHED    │                            │  TRANSCRIBE │
                  │   Return    │                            │    Apify    │
                  └─────────────┘                            └──────┬──────┘
                                                                    │
                                               ┌────────────────────┴────────────────────┐
                                               │                                         │
                                               ▼                                         ▼
                                        ┌─────────────┐                          ┌─────────────┐
                                        │   < 30min   │                          │   > 30min   │
                                        │   Direct    │                          │  Map-Reduce │
                                        └──────┬──────┘                          └──────┬──────┘
                                               │                                         │
                                               └────────────────┬────────────────────────┘
                                                                │
                                                                ▼
                                                     ┌─────────────────────┐
                                                     │      ANALYZE        │
                                                     │  Summary + Insights │
                                                     │   (Claude Sonnet)   │
                                                     └──────────┬──────────┘
                                                                │
                                                                ▼
                                                     ┌─────────────────────┐
                                                     │       SCORE         │
                                                     │  Quality 0-100      │
                                                     └──────────┬──────────┘
                                                                │
                              ┌──────────────────────┬──────────┴──────────┬──────────────────────┐
                              │                      │                     │                      │
                              ▼                      ▼                     ▼                      ▼
                       ┌────────────┐         ┌────────────┐        ┌────────────┐        ┌────────────┐
                       │  LinkedIn  │         │  Twitter   │        │ Newsletter │        │   Skip     │
                       │  (if rec)  │         │  (if rec)  │        │  (if rec)  │        │            │
                       └─────┬──────┘         └─────┬──────┘        └─────┬──────┘        └─────┬──────┘
                             │                      │                     │                      │
                             └──────────────────────┴─────────┬───────────┴──────────────────────┘
                                                              │
                                                              ▼
                                              ┌───────────────────────────────┐
                                              │          OUTPUT               │
                                              │  Build Report + Save + Notify │
                                              └───────────────┬───────────────┘
                                                              │
                                    ┌─────────────────────────┼─────────────────────────┐
                                    │                         │                         │
                                    ▼                         ▼                         ▼
                             ┌────────────┐            ┌────────────┐            ┌────────────┐
                             │  Supabase  │            │   Notion   │            │   Slack    │
                             │   Save     │            │  Dashboard │            │   Notify   │
                             └────────────┘            └────────────┘            └────────────┘
```

---

## 📊 Stats du Workflow

| Métrique | Valeur |
|----------|--------|
| Nodes | 45 |
| Connexions | 43 |
| Nodes Code | 14 |
| Nodes IA (Claude) | 6 |
| Intégrations | 6 services |

---

## 🔧 Intégrations

| Service | Usage | Credentials |
|---------|-------|-------------|
| **YouTube Data API** | Metadata extraction | OAuth 2.0 |
| **Apify** | Transcription scraping | API Key |
| **Anthropic (Claude)** | Analyse IA + Génération | API Key |
| **Supabase** | Cache + Storage | API Key |
| **Notion** | Dashboard structuré | API Key |
| **Slack** | Notifications | OAuth 2.0 |

---

## 🚀 Démarrage Rapide

### Prérequis

- n8n Cloud ou Self-hosted (v1.0+)
- Comptes & API Keys pour les 6 services

### Installation

1. **Importer le workflow**
   ```
   n8n → Settings → Import from File → YouTube_Content_Analyzer_Pro.json
   ```

2. **Configurer les credentials**
   - YouTube OAuth
   - Apify API Key
   - Anthropic API Key
   - Supabase URL + API Key
   - Notion Integration Token
   - Slack OAuth

3. **Créer la table Supabase**
   ```sql
   CREATE TABLE youtube_analyses (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     video_id TEXT UNIQUE NOT NULL,
     video_url TEXT,
     video_title TEXT,
     channel_name TEXT,
     analysis_data JSONB,
     quality_score INTEGER,
     created_at TIMESTAMPTZ DEFAULT NOW(),
     updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```

4. **Créer la Database Notion** (voir [docs/NOTION_SETUP.md](docs/NOTION_SETUP.md))

5. **Activer le workflow**

---

## 📡 API

### Endpoint

```
POST /webhook/analyze-youtube
```

### Request

```json
{
  "url": "https://www.youtube.com/watch?v=VIDEO_ID",
  "options": {
    "language": "fr",
    "notify_slack": true
  }
}
```

### Response

```json
{
  "id": "yt_VIDEO_ID_1701936000000",
  "generated_at": "2025-12-07T10:00:00.000Z",
  "processing_time_ms": 45000,
  
  "video": {
    "id": "VIDEO_ID",
    "title": "Titre de la vidéo",
    "channel": { "name": "Nom de la chaîne" },
    "duration_formatted": "15:30",
    "view_count": 10000
  },
  
  "classification": {
    "content_type": "tutorial",
    "primary_topic": "Intelligence Artificielle",
    "recommended_outputs": {
      "linkedin": true,
      "twitter": true,
      "newsletter": false,
      "reasoning": "Contenu éducatif tech, parfait pour LinkedIn et Twitter"
    }
  },
  
  "quality_score": { "score": 78, "grade": "B" },
  
  "summary": {
    "one_liner": "...",
    "executive_summary": "...",
    "key_points": ["...", "...", "..."]
  },
  
  "chapters": [...],
  "insights": [...],
  "takeaways": [...],
  
  "generated_content": {
    "linkedin": { "full_post": "..." },
    "twitter": { "tweets": [...] },
    "newsletter": null
  }
}
```

---

## 🤖 Modèles IA

| Tâche | Modèle | Température | Max Tokens |
|-------|--------|-------------|------------|
| Summary | Claude Sonnet 4.5 | 0.3 | 4096 |
| Insights | Claude Sonnet 4.5 | 0.2 | 3000 |
| Chunk Summary | Claude Haiku 4.5 | 0.3 | 1024 |
| LinkedIn | Claude Sonnet 4.5 | 0.7 | 2000 |
| Twitter | Claude Sonnet 4.5 | 0.7 | 2000 |
| Newsletter | Claude Sonnet 4.5 | 0.6 | 2000 |

---

## 💰 Coût Estimé

| Vidéo | Claude API | Apify | Total |
|-------|------------|-------|-------|
| Courte (<15min) | ~$0.05 | ~$0.01 | **~$0.06** |
| Moyenne (15-30min) | ~$0.08 | ~$0.02 | **~$0.10** |
| Longue (>30min) | ~$0.15 | ~$0.03 | **~$0.18** |

---

## 📂 Structure du Projet

```
youtube-analyzer-pro/
├── YouTube_Content_Analyzer_Pro.json   # Workflow n8n
├── README.md                           # Ce fichier
├── LICENSE                             # MIT
├── CHANGELOG.md                        # Historique des versions
├── docs/
│   ├── TECHNICAL.md                    # Documentation technique
│   ├── NOTION_SETUP.md                 # Guide config Notion
│   ├── PITCH.md                        # Pitch commercial
│   └── assets/
│       └── architecture-overview.png
└── sql/
    └── supabase_schema.sql             # Script création table
```

---

## 🔄 Changelog

### v2.0.0 (2025-12-07)
- ✅ Architecture Map-Reduce pour vidéos longues
- ✅ IA décisionnelle (recommended_outputs)
- ✅ Dashboard Notion complet
- ✅ Transcription via Apify
- ✅ 45 nodes optimisés

### v1.0.0 (2025-12-06)
- 🎉 Release initiale
- Analyse basique + génération contenu

---

## 🤝 Auteur

**Cyprien** - [Utilia AI](https://utilia.ai)

Fondateur de Utilia AI, formation et consulting spécialisé en automatisation IA.

---

## 📄 License

MIT License - voir [LICENSE](LICENSE)