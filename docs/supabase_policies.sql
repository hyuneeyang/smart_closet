-- Smart Closet Supabase RLS and Storage policies
-- Apply after running schema.sql

-- Auth assumptions
-- 1. Anonymous auth is enabled for MVP.
-- 2. Every row belongs to auth.uid().
-- 3. Storage bucket name is clothing-images.
-- 4. Bucket is private. Clients read through signed URLs.

alter table users enable row level security;
alter table user_preferences enable row level security;
alter table clothing_items enable row level security;
alter table clothing_images enable row level security;
alter table clothing_links enable row level security;
alter table wear_history enable row level security;
alter table weather_snapshots enable row level security;
alter table outfit_recommendations enable row level security;
alter table outfit_recommendation_items enable row level security;
alter table outfit_feedback enable row level security;

-- users
create policy "users_select_own"
on users
for select
to authenticated, anon
using (id = auth.uid());

create policy "users_insert_self"
on users
for insert
to authenticated, anon
with check (id = auth.uid());

create policy "users_update_own"
on users
for update
to authenticated, anon
using (id = auth.uid())
with check (id = auth.uid());

-- user_preferences
create policy "user_preferences_select_own"
on user_preferences
for select
to authenticated, anon
using (user_id = auth.uid());

create policy "user_preferences_insert_own"
on user_preferences
for insert
to authenticated, anon
with check (user_id = auth.uid());

create policy "user_preferences_update_own"
on user_preferences
for update
to authenticated, anon
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- clothing_items
create policy "clothing_items_select_own"
on clothing_items
for select
to authenticated, anon
using (user_id = auth.uid());

create policy "clothing_items_insert_own"
on clothing_items
for insert
to authenticated, anon
with check (user_id = auth.uid());

create policy "clothing_items_update_own"
on clothing_items
for update
to authenticated, anon
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "clothing_items_delete_own"
on clothing_items
for delete
to authenticated, anon
using (user_id = auth.uid());

-- clothing_images via parent ownership
create policy "clothing_images_select_own"
on clothing_images
for select
to authenticated, anon
using (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_images.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

create policy "clothing_images_insert_own"
on clothing_images
for insert
to authenticated, anon
with check (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_images.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

create policy "clothing_images_delete_own"
on clothing_images
for delete
to authenticated, anon
using (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_images.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

-- clothing_links via parent ownership
create policy "clothing_links_select_own"
on clothing_links
for select
to authenticated, anon
using (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_links.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

create policy "clothing_links_insert_own"
on clothing_links
for insert
to authenticated, anon
with check (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_links.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

create policy "clothing_links_delete_own"
on clothing_links
for delete
to authenticated, anon
using (
  exists (
    select 1
    from clothing_items ci
    where ci.id = clothing_links.clothing_item_id
      and ci.user_id = auth.uid()
  )
);

-- wear_history
create policy "wear_history_select_own"
on wear_history
for select
to authenticated, anon
using (user_id = auth.uid());

create policy "wear_history_insert_own"
on wear_history
for insert
to authenticated, anon
with check (user_id = auth.uid());

create policy "wear_history_update_own"
on wear_history
for update
to authenticated, anon
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "wear_history_delete_own"
on wear_history
for delete
to authenticated, anon
using (user_id = auth.uid());

-- weather_snapshots
create policy "weather_snapshots_select_own"
on weather_snapshots
for select
to authenticated, anon
using (user_id = auth.uid() or user_id is null);

create policy "weather_snapshots_insert_own"
on weather_snapshots
for insert
to authenticated, anon
with check (user_id = auth.uid() or user_id is null);

-- outfit_recommendations
create policy "outfit_recommendations_select_own"
on outfit_recommendations
for select
to authenticated, anon
using (user_id = auth.uid());

create policy "outfit_recommendations_insert_own"
on outfit_recommendations
for insert
to authenticated, anon
with check (user_id = auth.uid());

create policy "outfit_recommendations_delete_own"
on outfit_recommendations
for delete
to authenticated, anon
using (user_id = auth.uid());

-- recommendation items via recommendation ownership
create policy "outfit_recommendation_items_select_own"
on outfit_recommendation_items
for select
to authenticated, anon
using (
  exists (
    select 1
    from outfit_recommendations r
    where r.id = outfit_recommendation_items.recommendation_id
      and r.user_id = auth.uid()
  )
);

create policy "outfit_recommendation_items_insert_own"
on outfit_recommendation_items
for insert
to authenticated, anon
with check (
  exists (
    select 1
    from outfit_recommendations r
    where r.id = outfit_recommendation_items.recommendation_id
      and r.user_id = auth.uid()
  )
);

create policy "outfit_recommendation_items_delete_own"
on outfit_recommendation_items
for delete
to authenticated, anon
using (
  exists (
    select 1
    from outfit_recommendations r
    where r.id = outfit_recommendation_items.recommendation_id
      and r.user_id = auth.uid()
  )
);

-- outfit_feedback
create policy "outfit_feedback_select_own"
on outfit_feedback
for select
to authenticated, anon
using (user_id = auth.uid());

create policy "outfit_feedback_insert_own"
on outfit_feedback
for insert
to authenticated, anon
with check (user_id = auth.uid());

create policy "outfit_feedback_delete_own"
on outfit_feedback
for delete
to authenticated, anon
using (user_id = auth.uid());

-- trend_signals
alter table trend_signals enable row level security;

create policy "trend_signals_public_read"
on trend_signals
for select
to authenticated, anon
using (true);

-- Storage bucket
insert into storage.buckets (id, name, public)
values ('clothing-images', 'clothing-images', false)
on conflict (id) do nothing;

-- Storage object policies
create policy "storage_clothing_images_read_public"
on storage.objects
for select
to authenticated, anon
using (
  bucket_id = 'clothing-images'
  and auth.uid() is not null
  and name like auth.uid()::text || '/%'
);

create policy "storage_clothing_images_insert_own_prefix"
on storage.objects
for insert
to authenticated, anon
with check (
  bucket_id = 'clothing-images'
  and auth.uid() is not null
  and name like auth.uid()::text || '/%'
);

create policy "storage_clothing_images_update_own_prefix"
on storage.objects
for update
to authenticated, anon
using (
  bucket_id = 'clothing-images'
  and auth.uid() is not null
  and name like auth.uid()::text || '/%'
)
with check (
  bucket_id = 'clothing-images'
  and auth.uid() is not null
  and name like auth.uid()::text || '/%'
);

create policy "storage_clothing_images_delete_own_prefix"
on storage.objects
for delete
to authenticated, anon
using (
  bucket_id = 'clothing-images'
  and auth.uid() is not null
  and name like auth.uid()::text || '/%'
);
