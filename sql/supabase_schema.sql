-- ============================================
-- YouTube Content Analyzer Pro - Schema SQL
-- Base de données: Supabase (PostgreSQL)
-- ============================================

-- Table principale des analyses
CREATE TABLE youtube_analyses (
    -- Identifiant unique auto-généré
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Identifiant YouTube (11 caractères)
    video_id TEXT UNIQUE NOT NULL,
    
    -- Métadonnées vidéo
    video_url TEXT NOT NULL,
    video_title TEXT,
    channel_name TEXT,
    
    -- Analyse complète (JSON)
    analysis_data JSONB,
    
    -- Score qualité (0-100)
    quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide par video_id
CREATE INDEX idx_youtube_analyses_video_id ON youtube_analyses(video_id);

-- Index pour tri par date
CREATE INDEX idx_youtube_analyses_created_at ON youtube_analyses(created_at DESC);

-- Index pour filtrage par score
CREATE INDEX idx_youtube_analyses_quality_score ON youtube_analyses(quality_score DESC);

-- Trigger pour updated_at automatique
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_youtube_analyses_updated_at
    BEFORE UPDATE ON youtube_analyses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Table des logs d'erreurs
-- ============================================

CREATE TABLE error_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Identification
    workflow TEXT NOT NULL DEFAULT 'YouTube Content Analyzer Pro',
    node TEXT,
    execution_id TEXT,
    
    -- Détails de l'erreur
    message TEXT NOT NULL,
    details JSONB,
    stack TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche par workflow
CREATE INDEX idx_error_logs_workflow ON error_logs(workflow);

-- Index pour tri par date
CREATE INDEX idx_error_logs_created_at ON error_logs(created_at DESC);

-- ============================================
-- Row Level Security (optionnel)
-- ============================================

-- Activer RLS
ALTER TABLE youtube_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Politique pour service_role (n8n)
CREATE POLICY "Service role can do everything on youtube_analyses"
    ON youtube_analyses
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role can do everything on error_logs"
    ON error_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- Vues utiles
-- ============================================

-- Vue des analyses récentes
CREATE VIEW recent_analyses AS
SELECT 
    video_id,
    video_title,
    channel_name,
    quality_score,
    created_at,
    (analysis_data->>'classification'->>'content_type') as content_type
FROM youtube_analyses
ORDER BY created_at DESC
LIMIT 50;

-- Vue des statistiques
CREATE VIEW analysis_stats AS
SELECT 
    COUNT(*) as total_analyses,
    AVG(quality_score) as avg_score,
    MAX(quality_score) as max_score,
    MIN(quality_score) as min_score,
    COUNT(DISTINCT channel_name) as unique_channels,
    MIN(created_at) as first_analysis,
    MAX(created_at) as last_analysis
FROM youtube_analyses;

-- ============================================
-- Requêtes utiles
-- ============================================

-- Rechercher par chaîne
-- SELECT * FROM youtube_analyses WHERE channel_name ILIKE '%ExplorIA%';

-- Analyses avec score > 70
-- SELECT video_title, quality_score FROM youtube_analyses WHERE quality_score > 70 ORDER BY quality_score DESC;

-- Erreurs des dernières 24h
-- SELECT * FROM error_logs WHERE created_at > NOW() - INTERVAL '24 hours';

-- Vider le cache (attention!)
-- DELETE FROM youtube_analyses WHERE created_at < NOW() - INTERVAL '30 days';
