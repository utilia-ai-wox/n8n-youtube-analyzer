# 📚 Documentation Technique

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Phases du workflow](#phases-du-workflow)
3. [Nodes détaillés](#nodes-détaillés)
4. [Prompts IA](#prompts-ia)
5. [Gestion des erreurs](#gestion-des-erreurs)
6. [Optimisations](#optimisations)

---

## Vue d'ensemble

### Architecture générale

Le workflow suit un pattern **ETL (Extract-Transform-Load)** enrichi avec de l'IA :

```
EXTRACT → CACHE → TRANSFORM → ANALYZE → GENERATE → LOAD → NOTIFY
```

### Flux de données

```
Input: URL YouTube
    │
    ├── video_id (11 chars)
    ├── metadata (titre, chaîne, durée, vues)
    ├── transcript (segments + timestamps)
    │
    ▼
Transform: Analyse IA
    │
    ├── classification (type, topics, audience)
    ├── summary (one-liner, executive, key_points)
    ├── chapters (timestamps + résumés)
    ├── insights (business, tech, personal)
    ├── sentiment (score + tone)
    ├── quotes (citations mémorables)
    ├── takeaways (actions concrètes)
    │
    ▼
Generate: Contenu Social
    │
    ├── linkedin_post (si recommandé)
    ├── twitter_thread (si recommandé)
    ├── newsletter (si recommandé)
    │
    ▼
Output: Rapport JSON + Notion + Supabase + Slack
```

---

## Phases du workflow

### Phase 1: TRIGGER

**Nodes:** `[TRIGGER] Webhook`, `When chat message received`

Deux points d'entrée possibles :
- **Webhook POST** : Pour intégration API
- **Chat Trigger** : Pour usage interactif

### Phase 2: EXTRACT

**Nodes:** `[EXTRACT] Parse URL`, `[EXTRACT] YouTube API`, `[EXTRACT] Build Context`

1. Parse l'URL pour extraire le `video_id` (11 caractères)
2. Appelle YouTube Data API v3 pour les metadata
3. Construit le contexte unifié

### Phase 3: CACHE

**Nodes:** `[CACHE] Check Supabase`, `[CACHE] IF Exists`, `[CACHE] Return Cached`, `[CACHE] Merge Data`, `[DB] Create Entry`

1. Vérifie si la vidéo existe déjà en base
2. Si oui → retourne le cache (économie IA)
3. Si non → crée une entrée vide pour marquer le traitement

### Phase 4: TRANSCR

**Nodes:** `[TRANSCR] Apify Scraper`, `[TRANSCR] Get Data`, `[TRANSCR] Adapter`

1. Lance un actor Apify pour scraper les sous-titres
2. Récupère les données brutes
3. Adapte au format unifié (segments + timestamps)

### Phase 5: ROUTE

**Nodes:** `[ROUTE] Check Duration`, `[ROUTE] Merge Paths`

Routage conditionnel basé sur la durée :
- **< 30 min** : Traitement direct
- **> 30 min** : Map-Reduce (chunking)

### Phase 6: CHUNK (si vidéo longue)

**Nodes:** `[CHUNK] Prep Map-Reduce`, `[AI] MAP - Summarize Chunk`, `[CODE] Reduce & Aggregate`

Pattern Map-Reduce :
1. **Map** : Découpe en chunks de ~4000 mots
2. **Process** : Résumé de chaque chunk (Haiku)
3. **Reduce** : Agrégation des résumés

### Phase 7: ANALYZE

**Nodes:** `[ANALYZE] AI - Summary`, `[ANALYZE] AI - Insights`, `[ANALYZE] Merge AI`, `[ANALYZE] Merge Results`

Analyse parallèle avec Claude Sonnet :
- **Summary** : Résumé + chapitres + classification + recommended_outputs
- **Insights** : Sentiment + insights + quotes + takeaways

### Phase 8: SCORE

**Nodes:** `[SCORE] Calculate Quality`

Calcul du score qualité (0-100) basé sur :
- Disponibilité transcript (+10 / -20)
- Volume de contenu (+10 max)
- Richesse de l'analyse (+38 max)
- Qualité estimée (+5)
- Pénalités d'erreurs

### Phase 9: GEN

**Nodes:** `[GEN] IF LinkedIn/Twitter/Newsletter`, `[GEN] AI - LinkedIn/Twitter/Newsletter`, `[GEN] NoOp`, `[GEN] Merge Content`

Génération conditionnelle basée sur `recommended_outputs` de l'IA :
- LinkedIn : Post professionnel (150-250 mots)
- Twitter : Thread viral (6-8 tweets)
- Newsletter : Digest email

### Phase 10: OUTPUT

**Nodes:** `[OUTPUT] Build Report`, `[DB] Save to Supabase`, `[NOTION] Create Page`, `[NOTION] Prepare Blocks`, `[NOTION] Add Content`, `[OUTPUT] Merge Final`, `[OUTPUT] Respond`

1. Assemble le rapport final JSON
2. Sauvegarde dans Supabase
3. Crée la page Notion structurée
4. Ajoute les blocks de contenu
5. Répond au webhook

### Phase 11: NOTIFY

**Nodes:** `[NOTIFY] Slack`

Notification Slack avec :
- Titre et chaîne
- Score qualité
- Lien Notion
- Temps de traitement

### Phase 12: ERROR

**Nodes:** `[ERROR] Trigger`, `[ERROR] Format`, `[ERROR] Slack Alert`, `[ERROR] Respond`

Gestion globale des erreurs :
1. Capture automatique
2. Formatage structuré
3. Alerte Slack
4. Réponse HTTP 500

---

## Nodes détaillés

### [EXTRACT] Parse URL

```javascript
/**
 * Parse une URL YouTube et extrait le video_id
 * 
 * Formats supportés:
 * - youtube.com/watch?v=XXXXXXXXXXX
 * - youtu.be/XXXXXXXXXXX
 * - youtube.com/embed/XXXXXXXXXXX
 * - youtube.com/shorts/XXXXXXXXXXX
 * 
 * @input  {object} items[0].json - Input du trigger (body.url, url, ou chatInput)
 * @output {object} video_id, original_url, options, started_at
 */
const input = items[0].json;

// Support multiple input formats
const url = input.body?.url || input.url || input.chatInput;

if (!url) throw new Error('URL YouTube manquante');

// Patterns de matching pour video_id (11 caractères)
const patterns = [
  /(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})/,
  /(?:youtu\.be\/)([a-zA-Z0-9_-]{11})/,
  /(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
  /(?:youtube\.com\/shorts\/)([a-zA-Z0-9_-]{11})/
];

let videoId = null;
for (const pattern of patterns) {
  const match = url.match(pattern);
  if (match) { videoId = match[1]; break; }
}

if (!videoId) throw new Error('URL YouTube invalide: ' + url);

return [{
  json: {
    video_id: videoId,
    original_url: url.split('&')[0], // Nettoie &t=, &list=, etc.
    session_id: input.sessionId || null,
    options: {
      language: input.body?.options?.language || 'fr',
      notify_slack: input.body?.options?.notify_slack === true
    },
    started_at: new Date().toISOString()
  }
}];
```

### [EXTRACT] Build Context

```javascript
/**
 * Construit le contexte vidéo unifié
 * Combine les données de Parse URL + YouTube API
 * 
 * @input  {object} YouTube API response (snippet, contentDetails, statistics)
 * @output {object} Contexte vidéo complet et normalisé
 */
const urlData = $('[EXTRACT] Parse URL').first().json;
const video = items[0].json;

// Parse ISO 8601 duration (PT1H2M10S) to seconds
function parseDuration(durationStr) {
  if (!durationStr) return null;
  const match = durationStr.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!match) return null;
  return (parseInt(match[1]) || 0) * 3600 + 
         (parseInt(match[2]) || 0) * 60 + 
         (parseInt(match[3]) || 0);
}

// Format seconds to HH:MM:SS or MM:SS
function formatDuration(seconds) {
  if (!seconds) return null;
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  return h > 0 
    ? `${h}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`
    : `${m}:${String(s).padStart(2,'0')}`;
}

const durationSeconds = parseDuration(video.contentDetails?.duration);

return [{
  json: {
    video_id: urlData.video_id,
    url: urlData.original_url,
    title: video.snippet?.title || 'Titre inconnu',
    channel: {
      name: video.snippet?.channelTitle || 'Chaîne inconnue',
      url: `https://www.youtube.com/channel/${video.snippet?.channelId}`
    },
    thumbnail: video.snippet?.thumbnails?.maxres?.url || 
               video.snippet?.thumbnails?.high?.url || 
               video.snippet?.thumbnails?.medium?.url,
    duration_seconds: durationSeconds,
    duration_formatted: formatDuration(durationSeconds),
    view_count: parseInt(video.statistics?.viewCount) || null,
    like_count: parseInt(video.statistics?.likeCount) || null,
    comment_count: parseInt(video.statistics?.commentCount) || null,
    publish_date: video.snippet?.publishedAt?.split('T')[0] || null,
    description: (video.snippet?.description || '').substring(0, 500),
    tags: video.snippet?.tags || [],
    options: urlData.options,
    started_at: urlData.started_at
  }
}];
```

### [SCORE] Calculate Quality

```javascript
/**
 * Calcule un score de qualité (0-100) pour l'analyse
 * 
 * Critères:
 * - Disponibilité transcript: +10 / -20
 * - Volume de contenu: +10 max
 * - Richesse analyse: +38 max
 * - Qualité estimée: +5
 * - Pénalités erreurs: variable
 * 
 * @input  {object} Données analysées (chapters, insights, takeaways, etc.)
 * @output {object} Données + quality_score { score, grade, factors }
 */
const data = items[0].json;

let score = 50; // Score de base

// 1. DÉTECTION INTELLIGENTE DU CONTENU
const hasAnalysis = (data.chapters?.length > 0) || 
                   (data.summary?.executive_summary);
const hasTranscript = data.transcript?.available || 
                     (data.transcript?.word_count > 0) || 
                     hasAnalysis;

if (hasTranscript) score += 10;
else score -= 20;

// 2. VOLUME ET DENSITÉ (+10 max)
const wordCount = data.transcript?.word_count || 0;
const duration = data.video?.duration_seconds || 0;

if (wordCount > 1000 || duration > 300) score += 5;
if (wordCount > 3000 || duration > 900) score += 5;

// 3. RICHESSE DE L'ANALYSE (+38 max)
const chapterCount = data.chapters?.length || 0;
const insightCount = data.insights?.length || 0;
const takeawayCount = data.takeaways?.length || 0;
const quoteCount = data.quotes?.length || 0;

if (chapterCount >= 3) score += 5;
if (chapterCount >= 5) score += 5;
if (insightCount >= 3) score += 5;
if (insightCount >= 5) score += 5;
if (takeawayCount >= 3) score += 5;
if (quoteCount >= 2) score += 3;

// 4. QUALITÉ ESTIMÉE (+5)
const expertise = data.classification?.expertise_level || '';
if (['intermediate', 'advanced'].includes(expertise)) score += 5;

// 5. PÉNALITÉS D'ERREURS
if (data.summary?.error) score -= 15;
if (data.sentiment?.error) score -= 10;

// Bornage 0-100
score = Math.max(0, Math.min(100, score));

// Grade A-F
const grade = score >= 90 ? 'A' : 
              score >= 75 ? 'B' : 
              score >= 60 ? 'C' : 
              score >= 40 ? 'D' : 'F';

return [{
  json: {
    ...data,
    quality_score: {
      score,
      grade,
      factors: {
        has_transcript: hasTranscript,
        transcript_length: wordCount,
        chapter_count: chapterCount,
        insight_count: insightCount,
        takeaway_count: takeawayCount
      }
    }
  }
}];
```

### [CHUNK] Prep Map-Reduce

```javascript
/**
 * Prépare le Map-Reduce pour les vidéos longues
 * Découpe le transcript en chunks de ~4000 mots
 * 
 * @input  {object} Données avec transcript.segments
 * @output {array}  Multiple items (1 par chunk) pour traitement parallèle
 */
const input = items[0].json;
const segments = input.transcript.segments || [];
const CHUNK_SIZE = 4000; // mots par chunk

let chunks = [];
let currentChunk = [];
let currentWordCount = 0;

// 1. Découpage intelligent
for (const seg of segments) {
  const segWords = seg.text.split(/\s+/).length;
  
  if (currentWordCount + segWords > CHUNK_SIZE && currentChunk.length > 0) {
    chunks.push({
      text: currentChunk.map(s => s.text).join(' '),
      start: currentChunk[0].start_formatted,
      end: seg.start_formatted
    });
    currentChunk = [];
    currentWordCount = 0;
  }
  
  currentChunk.push(seg);
  currentWordCount += segWords;
}

// Dernier chunk
if (currentChunk.length > 0) {
  chunks.push({
    text: currentChunk.map(s => s.text).join(' '),
    start: currentChunk[0].start_formatted,
    end: segments[segments.length-1].start_formatted
  });
}

// 2. Retourne MULTIPLE ITEMS (n8n exécute le node suivant pour chaque)
return chunks.map((chunk, index) => ({
  json: {
    ...input,
    processing_mode: 'chunked',
    chunk_index: index + 1,
    total_chunks: chunks.length,
    chunk_content: chunk.text,
    chunk_start: chunk.start,
    chunk_end: chunk.end,
    transcript: { ...input.transcript, full_text: '' } // Allège la mémoire
  }
}));
```

---

## Prompts IA

### [ANALYZE] AI - Summary

**Température:** 0.3 | **Max Tokens:** 4096

```
Tu es un expert en analyse de contenu vidéo. Tu produis des analyses structurées, précises et actionnables.

GÉNÈRE UN JSON VALIDE avec cette structure:
{
  "summary": {
    "one_liner": "Résumé en une phrase percutante (max 120 caractères)",
    "executive_summary": "Résumé exécutif en 3-5 phrases pour un décideur pressé",
    "key_points": ["Point clé 1", "Point clé 2", "Point clé 3", "Point clé 4", "Point clé 5"],
    "tldr": "Version ultra-courte en 1-2 phrases"
  },
  "chapters": [
    {
      "title": "Titre du chapitre",
      "timestamp": "MM:SS",
      "duration_estimate": "X min",
      "summary": "Ce qui est couvert",
      "key_takeaway": "Le point le plus important"
    }
  ],
  "structure": {
    "has_intro": true,
    "has_conclusion": true,
    "main_sections": 5,
    "pacing": "slow|medium|fast"
  },
  "classification": {
    "content_type": "tutorial|interview|review|news|educational|entertainment|podcast|vlog",
    "primary_topic": "Sujet principal",
    "secondary_topics": ["topic1", "topic2"],
    "target_audience": "Description de l'audience cible",
    "expertise_level": "beginner|intermediate|advanced"
  },
  "recommended_outputs": {
    "linkedin": true,
    "twitter": true,
    "newsletter": false,
    "reasoning": "Explication courte du choix"
  }
}

RÈGLES CLASSIFICATION:
- linkedin: true si contenu professionnel, business, éducatif, tech
- twitter: true si insights rapides, quotable, news, opinions
- newsletter: true si contenu dense, long format, analyse approfondie

RÈGLES GÉNÉRALES:
- 5-8 chapitres maximum
- 5-7 points clés
- Timestamps au format MM:SS
- JSON VALIDE UNIQUEMENT
```

### [ANALYZE] AI - Insights

**Température:** 0.2 | **Max Tokens:** 3000

```
Tu es un expert en extraction d'insights business et développement personnel.

GÉNÈRE UN JSON VALIDE:
{
  "sentiment": {
    "overall": "positive|negative|neutral|mixed",
    "score": 0.75,
    "confidence": 0.9,
    "tone": ["informatif", "enthousiaste", "critique"]
  },
  "insights": [
    {
      "insight": "L'insight actionnable",
      "context": "Le contexte qui le supporte",
      "category": "business|tech|personal|strategy|trend|mindset",
      "importance": "high|medium|low",
      "applicable_to": "Qui peut appliquer cet insight"
    }
  ],
  "quotes": [
    {
      "quote": "Citation mémorable",
      "speaker": "Qui l'a dit",
      "significance": "Pourquoi c'est important",
      "tweetable": true
    }
  ],
  "actionable_takeaways": [
    {
      "action": "Action concrète à faire",
      "effort": "low|medium|high",
      "impact": "low|medium|high",
      "timeframe": "immediate|short-term|long-term"
    }
  ],
  "contrarian_views": ["Point de vue contre-intuitif 1"],
  "resources_mentioned": [
    {
      "name": "Nom de la ressource",
      "type": "book|tool|website|person",
      "context": "Comment elle a été mentionnée"
    }
  ]
}

RÈGLES:
- 5-8 insights classés par importance
- 2-4 citations mémorables
- 3-5 takeaways actionnables
- JSON VALIDE UNIQUEMENT
```

### [GEN] AI - LinkedIn

**Température:** 0.7 | **Max Tokens:** 2000

```
Tu es un expert LinkedIn avec 100k+ followers. Crée un post viral.

STRUCTURE:
1. HOOK (1ère ligne) - DOIT captiver en 2 secondes avec emoji
2. CORPS - 3-5 points avec emojis, insights transformés en valeur
3. CTA - Question engageante pour les commentaires
4. HASHTAGS - 4-5 pertinents et populaires

FORMAT:
- 150-250 mots total
- Sauts de ligne fréquents (mobile-first)
- Chaque ligne = 1 idée max
- Emojis stratégiques
- Ton professionnel mais humain

JSON:
{
  "linkedin_post": {
    "hook": "Première ligne d'accroche",
    "body": "Corps du post",
    "cta": "Question engageante",
    "hashtags": ["#tag1", "#tag2"],
    "full_post": "Post complet prêt à copier"
  }
}
```

### [GEN] AI - Twitter

**Température:** 0.7 | **Max Tokens:** 2000

```
Tu es un expert Twitter/X avec des threads viraux. Crée un thread engageant.

STRUCTURE:
- Tweet 1: 🧵 Hook puissant + annonce du thread
- Tweets 2-6: Un insight par tweet, numérotés (1/, 2/, etc.)
- Tweet final: Récap + CTA + lien vidéo

RÈGLES STRICTES:
- MAX 280 caractères par tweet (OBLIGATOIRE)
- 6-8 tweets total
- Chaque tweet = valeur standalone
- Emojis au début

JSON:
{
  "twitter_thread": {
    "tweets": [
      {"number": 1, "content": "🧵 Hook...", "char_count": 145}
    ],
    "total_tweets": 7
  }
}
```

---

## Gestion des erreurs

### Pattern Error Handling

```
[Tout node]
    │
    └── Error → [ERROR] Trigger
                    │
                    ▼
              [ERROR] Format
                    │
                    ▼
              [ERROR] Slack Alert
                    │
                    ▼
              [ERROR] Respond (500)
```

### Structure d'erreur

```json
{
  "error": true,
  "message": "Description de l'erreur",
  "node": "Nom du node fautif",
  "execution_id": "abc123",
  "timestamp": "2025-12-07T10:00:00.000Z",
  "workflow": "YouTube Content Analyzer Pro",
  "stack": "Stack trace (500 premiers chars)"
}
```

---

## Optimisations

### Performance

1. **Cache Supabase** : Évite de retraiter une vidéo déjà analysée
2. **Map-Reduce** : Parallélise le traitement des vidéos longues
3. **Haiku pour chunks** : Modèle plus rapide et moins cher pour les résumés intermédiaires
4. **NoOp nodes** : Skip propre des branches non utilisées

### Coûts

1. **IA décisionnelle** : Ne génère que le contenu pertinent
2. **Chunking intelligent** : Limite la taille des prompts
3. **Cache** : Économise 100% des coûts sur les vidéos déjà traitées

### Fiabilité

1. **Error handling global** : Capture toutes les erreurs
2. **Alertes Slack** : Notification immédiate des problèmes
3. **Optional chaining** : `?.` partout pour éviter les undefined
4. **Fallbacks** : Valeurs par défaut systématiques
