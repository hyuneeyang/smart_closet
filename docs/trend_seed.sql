insert into trend_signals (keyword, region, date, score, source, season_hint)
values
  ('minimal', 'KR', current_date, 0.84, 'internal_dictionary', 'all'),
  ('classic', 'KR', current_date, 0.82, 'internal_dictionary', 'all'),
  ('cleanfit', 'KR', current_date, 0.80, 'internal_dictionary', 'all'),
  ('casual', 'KR', current_date, 0.74, 'internal_dictionary', 'all'),
  ('sporty', 'KR', current_date, 0.61, 'internal_dictionary', 'all'),
  ('athleisure', 'KR', current_date, 0.58, 'internal_dictionary', 'all'),
  ('gorp', 'KR', current_date, 0.56, 'internal_dictionary', 'spring'),
  ('street', 'KR', current_date, 0.52, 'internal_dictionary', 'all'),
  ('oldmoney', 'KR', current_date, 0.49, 'internal_dictionary', 'fall'),
  ('formal', 'KR', current_date, 0.43, 'internal_dictionary', 'all')
on conflict (keyword, region, date) do update
set
  score = excluded.score,
  source = excluded.source,
  season_hint = excluded.season_hint;
