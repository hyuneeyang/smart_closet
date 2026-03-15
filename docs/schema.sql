create extension if not exists "pgcrypto";

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  nickname text not null,
  locale text not null default 'ko-KR',
  region text,
  created_at timestamptz not null default now()
);

create table if not exists user_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  preferred_style_tags text[] not null default '{}',
  preferred_colors text[] not null default '{}',
  frequent_contexts text[] not null default '{}',
  dislike_style_tags text[] not null default '{}',
  notification_hour int,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists clothing_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  source_type text not null check (source_type in ('upload', 'link', 'manual')),
  title text not null,
  category text not null,
  subcategory text,
  primary_color text,
  secondary_color text,
  pattern text,
  material text,
  style_tags text[] not null default '{}',
  season_tags text[] not null default '{}',
  warmth_score numeric(4,2) not null default 0,
  formality_score numeric(4,2) not null default 0,
  waterproof boolean not null default false,
  image_url text,
  source_url text,
  analysis_raw_json jsonb,
  confidence numeric(4,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_clothing_items_user_category
  on clothing_items(user_id, category);

create table if not exists clothing_images (
  id uuid primary key default gen_random_uuid(),
  clothing_item_id uuid not null references clothing_items(id) on delete cascade,
  storage_path text not null,
  width int,
  height int,
  created_at timestamptz not null default now()
);

create table if not exists clothing_links (
  id uuid primary key default gen_random_uuid(),
  clothing_item_id uuid not null references clothing_items(id) on delete cascade,
  source_url text not null,
  domain text,
  scraped_title text,
  scraped_payload jsonb,
  created_at timestamptz not null default now()
);

create table if not exists wear_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  clothing_item_id uuid not null references clothing_items(id) on delete cascade,
  worn_date date not null,
  context text,
  rating int,
  created_at timestamptz not null default now()
);

create index if not exists idx_wear_history_user_date
  on wear_history(user_id, worn_date desc);

create table if not exists weather_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references users(id) on delete set null,
  region text not null,
  current_temp numeric(5,2) not null,
  feels_like_temp numeric(5,2) not null,
  min_temp numeric(5,2),
  max_temp numeric(5,2),
  precipitation_probability numeric(5,2) not null default 0,
  wind_speed numeric(5,2) not null default 0,
  summary text,
  hourly_forecast jsonb not null default '[]'::jsonb,
  fetched_at timestamptz not null default now()
);

create table if not exists trend_signals (
  id uuid primary key default gen_random_uuid(),
  keyword text not null,
  region text not null,
  date date not null,
  score numeric(5,2) not null,
  source text not null,
  season_hint text,
  created_at timestamptz not null default now()
);

create index if not exists idx_trend_signals_keyword_region_date
  on trend_signals(keyword, region, date desc);

create table if not exists outfit_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references users(id) on delete cascade,
  context text not null,
  weather_snapshot_id uuid references weather_snapshots(id) on delete set null,
  title text not null,
  total_score numeric(5,2) not null,
  score_breakdown jsonb not null,
  explanation_text text not null,
  card_image_cache_url text,
  created_at timestamptz not null default now()
);

create table if not exists outfit_recommendation_items (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references outfit_recommendations(id) on delete cascade,
  clothing_item_id uuid not null references clothing_items(id) on delete cascade,
  role text not null check (role in ('top', 'bottom', 'outer', 'shoes', 'bag')),
  item_score numeric(5,2) not null default 0
);

create table if not exists outfit_feedback (
  id uuid primary key default gen_random_uuid(),
  recommendation_id uuid not null references outfit_recommendations(id) on delete cascade,
  user_id uuid not null references users(id) on delete cascade,
  feedback_type text not null check (
    feedback_type in ('like', 'dislike', 'worn', 'more_like_this', 'less_formal')
  ),
  note text,
  created_at timestamptz not null default now()
);
