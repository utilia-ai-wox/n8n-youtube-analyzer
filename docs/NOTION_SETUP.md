# 📋 Configuration Notion

## Prérequis

1. Un compte Notion
2. Une intégration Notion (API Key)

---

## Étape 1 : Créer l'intégration Notion

1. Aller sur https://www.notion.so/my-integrations
2. Cliquer "New integration"
3. Nom : `YouTube Analyzer`
4. Capabilities : **Read**, **Update**, **Insert content**
5. Copier le **Internal Integration Token**

---

## Étape 2 : Créer la Database

### Option A : Dupliquer le template

[Lien vers le template Notion](#) *(à créer)*

### Option B : Créer manuellement

1. Créer une nouvelle page
2. Ajouter une Database **Full page**
3. Configurer les propriétés :

| Propriété | Type | Configuration |
|-----------|------|---------------|
| Titre | Title | (défaut) |
| URL | URL | - |
| Chaîne | Select | - |
| Score | Number | 0-100 |
| Grade | Formula | Voir ci-dessous |
| Type | Select | Tutorial, Review, Interview, News, Educational, Entertainment, Podcast, Vlog |
| Sentiment | Select | 😊 Positif, 😐 Neutre, 😞 Négatif |
| Topics | Multi-select | - |
| Durée (min) | Number | - |
| Vues | Number | - |
| Date Publi | Date | - |
| Date Analyse | Date | Include time |
| LinkedIn | Checkbox | - |
| Twitter | Checkbox | - |
| Newsletter | Checkbox | - |

### Formule Grade

```
if(prop("Score") >= 90, "A", if(prop("Score") >= 75, "B", if(prop("Score") >= 60, "C", if(prop("Score") >= 40, "D", "F"))))
```

---

## Étape 3 : Connecter l'intégration

1. Ouvrir la Database
2. Menu `...` → `Add connections`
3. Sélectionner `YouTube Analyzer`

---

## Étape 4 : Récupérer l'ID de la Database

1. Ouvrir la Database en pleine page
2. Copier l'URL : `https://notion.so/XXXXXXXX?v=YYYYYYYY`
3. Le **Database ID** = `XXXXXXXX` (32 caractères)

---

## Étape 5 : Configurer n8n

### Credential Notion

1. n8n → Credentials → Add
2. Type : Notion API
3. Coller le **Internal Integration Token**

### Node [NOTION] Create Page

1. Credential : Notion API
2. Resource : Database Page
3. Database ID : `XXXXXXXX`
4. Properties : Mapper selon le tableau ci-dessous

### Mapping des propriétés

| Propriété Notion | Expression n8n |
|------------------|----------------|
| Titre | `{{ $json.video.title }}` |
| URL | `{{ $json.video.url }}` |
| Chaîne | `{{ $json.video.channel.name }}` |
| Score | `{{ $json.quality_score.score }}` |
| Type | `{{ $json.classification.content_type }}` |
| Sentiment | Expression conditionnelle (voir ci-dessous) |
| Durée (min) | `{{ Math.round($json.video.duration_seconds / 60) }}` |
| Vues | `{{ $json.video.view_count }}` |
| Date Publi | `{{ $json.video.publish_date }}` |
| Date Analyse | `{{ $json.generated_at }}` |
| LinkedIn | `{{ !!$json.generated_content?.linkedin }}` |
| Twitter | `{{ !!$json.generated_content?.twitter }}` |
| Newsletter | `{{ !!$json.generated_content?.newsletter }}` |

### Expression Sentiment

```javascript
{{ $json.sentiment.overall === 'positive' ? '😊 Positif' : ($json.sentiment.overall === 'negative' ? '😞 Négatif' : '😐 Neutre') }}
```

---

## Étape 6 : Créer les vues

### 📊 Toutes les analyses (Table)

- Afficher toutes les propriétés
- Trier par : Date Analyse (Desc)

### 🖼️ Galerie

- Property shown : Thumbnail (si vous ajoutez cette propriété)
- Card preview : Page cover

### 📈 Par Score (Board)

- Group by : Grade
- Colonnes : A, B, C, D, F

### 🏷️ Par Type (Board)

- Group by : Type
- Colonnes : Tutorial, Review, Interview, etc.

### 📅 Timeline

- Date property : Date Publi
- Affichage : Month

### ⭐ Favoris (Table filtrée)

- Filter : Score > 80

---

## Structure de page générée

Chaque analyse crée une page avec ces sections :

```
📄 Page: {Titre de la vidéo}
├── Properties (sidebar)
│   ├── Score: 78/100 (B)
│   ├── Type: Tutorial
│   ├── Sentiment: 😊 Positif
│   └── ...
│
└── Content (body)
    ├── 🎯 TL;DR (callout)
    ├── 📝 Résumé Exécutif (paragraph)
    ├── 🔑 Points Clés (bullets)
    ├── 📚 Chapitres (callouts avec timestamps)
    ├── 💡 Insights (callouts avec catégorie)
    ├── 💬 Citations (quotes)
    ├── ✅ Actions à Retenir (todos)
    └── 📱 Contenu Généré
        ├── 💼 LinkedIn (code block)
        ├── 🐦 Twitter (code block)
        └── 📧 Newsletter (code block)
```

---

## Troubleshooting

### Erreur "Object not found"

→ Vérifier que l'intégration est connectée à la Database

### Erreur "Insufficient permissions"

→ Vérifier les capabilities de l'intégration (Read, Update, Insert)

### Les blocks ne s'ajoutent pas

→ Vérifier que le pageId est correct dans le node HTTP Request

### Les propriétés ne se mappent pas

→ Vérifier les noms exacts des propriétés (sensible à la casse)
