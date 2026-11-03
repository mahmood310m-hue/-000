-- =====================================================================
-- مدرسة كوثر الأهلية المختلطة — مخطط قاعدة البيانات + سياسات RLS
-- شغّل هذا الملف كاملاً في Supabase > SQL Editor
-- (جدول users هو auth.users الخاص بـ Supabase؛ و profiles يمتد منه)
-- =====================================================================
create extension if not exists pgcrypto;

-- ---------- الجداول ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role text not null default 'student'
    check (role in ('super_admin','admin','teacher','student','parent')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stage text not null,
  sort int not null default 0,
  unique (name, stage)
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  phone text,
  class_id uuid references public.classes(id) on delete set null,
  guardian_name text,
  guardian_phone text,
  user_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists students_class_idx on public.students(class_id);
create index if not exists students_user_idx on public.students(user_id);

create table if not exists public.teachers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  specialty text
);

create table if not exists public.parents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  relation text
);

create table if not exists public.parent_students (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  unique (parent_id, student_id)
);

create table if not exists public.honors (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null unique references public.students(id) on delete cascade,
  average numeric(5,2) not null check (average >= 0 and average <= 100),
  note text,
  photo_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  exam_name text not null,
  term text,
  score numeric(6,2) not null check (score >= 0),
  max_score numeric(6,2) not null default 100 check (max_score > 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  check (score <= max_score)
);
create index if not exists grades_student_idx on public.grades(student_id);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  date date not null default current_date,
  status text not null check (status in ('present','absent','late','excused')),
  note text,
  recorded_by uuid default auth.uid(),
  unique (student_id, date)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  category text not null default 'announcement'
    check (category in ('announcement','news','exam','holiday','activity')),
  image_url text,
  published_at timestamptz not null default now(),
  created_by uuid default auth.uid()
);

create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  active boolean not null default true,
  sort int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  can_manage_grades boolean not null default false,
  can_manage_attendance boolean not null default false
);

create table if not exists public.school_settings (
  key text primary key,
  value text not null default ''
);

-- ---------- دوال الصلاحيات (security definer لتجنب تكرار RLS) ----------
create or replace function public.current_role_name()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid() and active
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.current_role_name() = 'super_admin', false)
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.current_role_name() in ('admin','super_admin'), false)
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.current_role_name() in ('admin','super_admin','teacher'), false)
$$;

create or replace function public.can_manage_grades()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or (
    public.current_role_name() = 'teacher' and exists (
      select 1 from public.permissions p
      where p.user_id = auth.uid() and p.can_manage_grades))
$$;

create or replace function public.can_manage_attendance()
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_admin() or (
    public.current_role_name() = 'teacher' and exists (
      select 1 from public.permissions p
      where p.user_id = auth.uid() and p.can_manage_attendance))
$$;

create or replace function public.can_view_student(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select public.is_staff()
    or exists (select 1 from public.students s where s.id = sid and s.user_id = auth.uid())
    or exists (select 1 from public.parent_students ps
               where ps.student_id = sid and ps.parent_id = auth.uid())
$$;

-- إحصائيات عامة آمنة (أعداد فقط، بلا بيانات شخصية)
create or replace function public.get_stats()
returns json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'students',      (select count(*) from public.students),
    'honors',        (select count(*) from public.honors),
    'announcements', (select count(*) from public.announcements),
    'present',       (select count(*) from public.attendance where status = 'present'),
    'absent',        (select count(*) from public.attendance where status = 'absent'),
    'late',          (select count(*) from public.attendance where status = 'late'),
    'excused',       (select count(*) from public.attendance where status = 'excused'),
    'grades',        (select count(*) from public.grades),
    'users',         case when public.is_admin() then (select count(*) from public.profiles) else null end
  )
$$;

revoke all on function public.get_stats() from public, anon;
grant execute on function
  public.get_stats(), public.is_admin(), public.is_super_admin(), public.is_staff(),
  public.can_manage_grades(), public.can_manage_attendance(), public.can_view_student(uuid),
  public.current_role_name()
to authenticated;

-- ---------- إنشاء profile تلقائياً عند إنشاء مستخدم ----------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.phone, new.raw_user_meta_data->>'phone')
  ) on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users for each row execute function public.handle_new_user();

-- منع تغيير الدور إلا من المدير الأعلى (يُسمح من SQL Editor حيث auth.uid() فارغ)
create or replace function public.protect_profile()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_super_admin() then
    if new.role is distinct from old.role then
      raise exception 'تغيير الأدوار مسموح للمدير الأعلى فقط' using errcode = '42501';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists protect_profile_trg on public.profiles;
create trigger protect_profile_trg before update on public.profiles
for each row execute function public.protect_profile();

-- ---------- عرض آمن للمتفوقين (أعمدة غير حساسة فقط) ----------
create or replace view public.honor_list as
  select h.id, h.student_id, s.full_name, c.name as class_name, c.stage,
         h.average, h.note, h.photo_url
  from public.honors h
  join public.students s on s.id = h.student_id
  left join public.classes c on c.id = s.class_id;

revoke all on public.honor_list from anon, public;
grant select on public.honor_list to authenticated;

-- ---------- تفعيل RLS ----------
alter table public.profiles        enable row level security;
alter table public.classes         enable row level security;
alter table public.subjects        enable row level security;
alter table public.students        enable row level security;
alter table public.teachers        enable row level security;
alter table public.parents         enable row level security;
alter table public.parent_students enable row level security;
alter table public.honors          enable row level security;
alter table public.grades          enable row level security;
alter table public.attendance      enable row level security;
alter table public.announcements   enable row level security;
alter table public.news            enable row level security;
alter table public.permissions     enable row level security;
alter table public.school_settings enable row level security;

-- ---------- السياسات ----------
-- profiles
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_admin());
drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated
  using (public.is_super_admin() or (public.is_admin() and role <> 'super_admin'))
  with check (public.is_super_admin() or (public.is_admin() and role <> 'super_admin'));

-- classes / subjects / announcements / news / settings: قراءة للجميع المسجلين، كتابة للإدارة
do $$
declare t text;
begin
  foreach t in array array['classes','subjects','announcements','news','school_settings'] loop
    execute format('drop policy if exists %I_read on public.%I', t, t);
    execute format('create policy %I_read on public.%I for select to authenticated using (true)', t, t);
    execute format('drop policy if exists %I_write on public.%I', t, t);
    execute format('create policy %I_write on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t, t);
  end loop;
end $$;

-- students
drop policy if exists students_read on public.students;
create policy students_read on public.students for select to authenticated
  using (public.can_view_student(id));
drop policy if exists students_write on public.students;
create policy students_write on public.students for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- honors (الجدول نفسه للموظفين فقط؛ البقية عبر honor_list)
drop policy if exists honors_read on public.honors;
create policy honors_read on public.honors for select to authenticated using (public.is_staff());
drop policy if exists honors_write on public.honors;
create policy honors_write on public.honors for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- grades
drop policy if exists grades_read on public.grades;
create policy grades_read on public.grades for select to authenticated
  using (public.can_view_student(student_id));
drop policy if exists grades_write on public.grades;
create policy grades_write on public.grades for all to authenticated
  using (public.can_manage_grades()) with check (public.can_manage_grades());

-- attendance
drop policy if exists attendance_read on public.attendance;
create policy attendance_read on public.attendance for select to authenticated
  using (public.can_view_student(student_id));
drop policy if exists attendance_write on public.attendance;
create policy attendance_write on public.attendance for all to authenticated
  using (public.can_manage_attendance()) with check (public.can_manage_attendance());

-- permissions
drop policy if exists permissions_read on public.permissions;
create policy permissions_read on public.permissions for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists permissions_write on public.permissions;
create policy permissions_write on public.permissions for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- teachers / parents / parent_students
drop policy if exists teachers_read on public.teachers;
create policy teachers_read on public.teachers for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists teachers_write on public.teachers;
create policy teachers_write on public.teachers for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists parents_read on public.parents;
create policy parents_read on public.parents for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
drop policy if exists parents_write on public.parents;
create policy parents_write on public.parents for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists ps_read on public.parent_students;
create policy ps_read on public.parent_students for select to authenticated
  using (parent_id = auth.uid() or public.is_admin());
drop policy if exists ps_write on public.parent_students;
create policy ps_write on public.parent_students for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ---------- التخزين (صور) ----------
insert into storage.buckets (id, name, public) values ('media', 'media', true)
on conflict (id) do nothing;

drop policy if exists media_read on storage.objects;
create policy media_read on storage.objects for select using (bucket_id = 'media');
drop policy if exists media_insert on storage.objects;
create policy media_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_admin());
drop policy if exists media_update on storage.objects;
create policy media_update on storage.objects for update to authenticated
  using (bucket_id = 'media' and public.is_admin());
drop policy if exists media_delete on storage.objects;
create policy media_delete on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.is_admin());

-- ---------- إعدادات افتراضية (نصوص واجهة، وليست بيانات طلاب) ----------
insert into public.school_settings (key, value) values
  ('school_name',      'مدرسة كوثر الأهلية المختلطة'),
  ('school_year',      '2026–2027'),
  ('welcome_title',    'مدرسة كوثر: بيت العلم والإبداع'),
  ('welcome_subtitle', 'مرحباً بكم في مدرسة كوثر'),
  ('welcome_body',     'بيئة تعليمية آمنة ومحفزة، نؤمن أن لكل طالب موهبة تستحق الرعاية.'),
  ('logo_url',         ''),
  ('hidden_sections',  '[]')
on conflict (key) do nothing;

-- =====================================================================
-- بعد إنشاء أول حساب (من لوحة Supabase > Authentication > Users)
-- ارفعه إلى مدير أعلى هكذا (مرة واحدة، من SQL Editor فقط):
--   update public.profiles set role = 'super_admin'
--   where phone in ('+9647XXXXXXXXX','9647XXXXXXXXX');
-- =====================================================================
