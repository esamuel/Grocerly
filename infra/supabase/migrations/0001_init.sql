-- Grocerly initial schema and basic RLS
create extension if not exists pgcrypto;

-- Users / Profiles
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text,
  locale text default 'en',
  created_at timestamptz default now()
);

-- Spaces (families/workspaces)
create table if not exists spaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

create table if not exists space_members (
  space_id uuid references spaces(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  role text default 'member',
  primary key (space_id, user_id)
);

-- Stores and order templates
create table if not exists stores (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

create table if not exists store_order_templates (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references stores(id) on delete cascade,
  section_order text[] not null default '{}'
);

-- Lists and items
create table if not exists lists (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  name text not null,
  store_id uuid references stores(id),
  currency text default 'USD',
  created_at timestamptz default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  synonyms text[] default '{}',
  default_category text
);

create table if not exists list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references lists(id) on delete cascade,
  product_id uuid references products(id),
  name text not null,
  quantity numeric default 1,
  unit text,
  note text,
  category text,
  price numeric,
  is_checked boolean default false,
  created_at timestamptz default now()
);

-- Pantry
create table if not exists pantry_items (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  product_id uuid references products(id),
  name text not null,
  quantity numeric default 1,
  unit text,
  location text,
  expires_at date,
  updated_at timestamptz default now()
);

-- Prices and budgets
create table if not exists prices (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  store_id uuid references stores(id) on delete cascade,
  amount numeric not null,
  currency text default 'USD',
  recorded_at timestamptz default now()
);

create table if not exists budgets (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  period text not null,
  limit_amount numeric not null,
  currency text default 'USD'
);

-- Recipes
create table if not exists recipes (
  id uuid primary key default gen_random_uuid(),
  space_id uuid not null references spaces(id) on delete cascade,
  title text not null,
  url text,
  servings integer,
  notes text,
  created_at timestamptz default now()
);

create table if not exists recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  name text not null,
  qty numeric,
  unit text
);

-- Reminders
create table if not exists reminders (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references lists(id) on delete cascade,
  type text not null,
  at_time timestamptz,
  geofence jsonb
);

-- RLS: enable on all relevant tables
alter table profiles enable row level security;
alter table spaces enable row level security;
alter table space_members enable row level security;
alter table stores enable row level security;
alter table store_order_templates enable row level security;
alter table lists enable row level security;
alter table list_items enable row level security;
alter table pantry_items enable row level security;
alter table products enable row level security;
alter table prices enable row level security;
alter table budgets enable row level security;
alter table recipes enable row level security;
alter table recipe_ingredients enable row level security;
alter table reminders enable row level security;

-- Helper policy: membership check
-- A user can access rows if they belong to the associated space.

-- Profiles: user can read/update own profile
create policy profiles_self_select on profiles for select using (id = auth.uid());
create policy profiles_self_update on profiles for update using (id = auth.uid());
create policy profiles_self_insert on profiles for insert with check (id = auth.uid());

-- Spaces: members can view
create policy spaces_member_select on spaces for select using (
  exists (select 1 from space_members sm where sm.space_id = spaces.id and sm.user_id = auth.uid())
);

-- Spaces: allow authenticated users to create spaces
create policy spaces_insert on spaces for insert with check (auth.role() = 'authenticated');

-- Space members: members can view membership of their spaces
create policy space_members_member_select on space_members for select using (
  user_id = auth.uid() or exists (
    select 1 from space_members sm where sm.space_id = space_members.space_id and sm.user_id = auth.uid()
  )
);

-- Space members: allow a user to add themself to a space
create policy space_members_self_insert on space_members for insert with check (user_id = auth.uid());

-- Stores
create policy stores_member_all on stores for all using (
  exists (select 1 from space_members sm where sm.space_id = stores.space_id and sm.user_id = auth.uid())
) with check (
  exists (select 1 from space_members sm where sm.space_id = stores.space_id and sm.user_id = auth.uid())
);

-- Lists
create policy lists_member_all on lists for all using (
  exists (select 1 from space_members sm where sm.space_id = lists.space_id and sm.user_id = auth.uid())
) with check (
  exists (select 1 from space_members sm where sm.space_id = lists.space_id and sm.user_id = auth.uid())
);

-- List items (via list membership)
create policy list_items_member_all on list_items for all using (
  exists (
    select 1 from lists l
    join space_members sm on sm.space_id = l.space_id and sm.user_id = auth.uid()
    where l.id = list_items.list_id
  )
) with check (
  exists (
    select 1 from lists l
    join space_members sm on sm.space_id = l.space_id and sm.user_id = auth.uid()
    where l.id = list_items.list_id
  )
);

-- Pantry items (by space)
create policy pantry_member_all on pantry_items for all using (
  exists (select 1 from space_members sm where sm.space_id = pantry_items.space_id and sm.user_id = auth.uid())
) with check (
  exists (select 1 from space_members sm where sm.space_id = pantry_items.space_id and sm.user_id = auth.uid())
);

-- Products: global read, restricted write
create policy products_public_select on products for select using (true);
create policy products_member_modify on products for all using (
  auth.role() = 'authenticated'
) with check (auth.role() = 'authenticated');

-- Prices (require membership to store's space)
create policy prices_member_all on prices for all using (
  exists (
    select 1 from stores s join space_members sm on sm.space_id = s.space_id and sm.user_id = auth.uid()
    where s.id = prices.store_id
  )
) with check (
  exists (
    select 1 from stores s join space_members sm on sm.space_id = s.space_id and sm.user_id = auth.uid()
    where s.id = prices.store_id
  )
);

-- Budgets (by space)
create policy budgets_member_all on budgets for all using (
  exists (select 1 from space_members sm where sm.space_id = budgets.space_id and sm.user_id = auth.uid())
) with check (
  exists (select 1 from space_members sm where sm.space_id = budgets.space_id and sm.user_id = auth.uid())
);

-- Recipes (by space)
create policy recipes_member_all on recipes for all using (
  exists (select 1 from space_members sm where sm.space_id = recipes.space_id and sm.user_id = auth.uid())
) with check (
  exists (select 1 from space_members sm where sm.space_id = recipes.space_id and sm.user_id = auth.uid())
);

-- Recipe ingredients (via recipe)
create policy recipe_ingredients_member_all on recipe_ingredients for all using (
  exists (
    select 1 from recipes r join space_members sm on sm.space_id = r.space_id and sm.user_id = auth.uid()
    where r.id = recipe_ingredients.recipe_id
  )
) with check (
  exists (
    select 1 from recipes r join space_members sm on sm.space_id = r.space_id and sm.user_id = auth.uid()
    where r.id = recipe_ingredients.recipe_id
  )
);

-- Reminders (via list)
create policy reminders_member_all on reminders for all using (
  exists (
    select 1 from lists l join space_members sm on sm.space_id = l.space_id and sm.user_id = auth.uid()
    where l.id = reminders.list_id
  )
) with check (
  exists (
    select 1 from lists l join space_members sm on sm.space_id = l.space_id and sm.user_id = auth.uid()
    where l.id = reminders.list_id
  )
);
