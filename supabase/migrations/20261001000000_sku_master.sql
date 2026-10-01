-- 상품관리 탭(SKU 마스터) 테이블
-- 대시보드 '상품관리' 탭의 컬럼: SKU ID · 상품명 · 상품코드 · 판매가 · 단가(VAT-)
-- 실행: Supabase Dashboard > SQL Editor 에 붙여넣고 Run (여러 번 실행해도 안전)

create table if not exists public.sku_master (
  sku_id            text primary key,                       -- SKU ID (예: RJPDCR22A-10)
  product_name      text not null,                          -- 상품명 (sales_data.product_sub 와 매칭)
  product_code      text not null,                          -- 상품코드/카테고리 (PDRN, LIP, MASK ...)
  sale_price        integer not null default 0              -- 판매가 (원, VAT 포함)
                    check (sale_price >= 0),
  unit_price_ex_vat integer generated always as             -- 단가(VAT-) = 판매가 / 1.1 반올림
                    (round(sale_price / 1.1)) stored,
  label             text,                                   -- 대시보드 표시용 짧은 이름
  sort_order        integer not null default 999,           -- 상품관리 탭 정렬 순서
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on table  public.sku_master is 'B2C 대시보드 상품관리 탭 · SKU 마스터';
comment on column public.sku_master.sku_id            is 'SKU ID';
comment on column public.sku_master.product_name      is '상품명 (sales_data.product_sub 매칭 키)';
comment on column public.sku_master.product_code      is '상품코드';
comment on column public.sku_master.sale_price        is '판매가 (VAT 포함, 원)';
comment on column public.sku_master.unit_price_ex_vat is '단가(VAT-) = round(판매가/1.1)';

create unique index if not exists sku_master_product_name_key on public.sku_master (product_name);
create index if not exists sku_master_product_code_idx on public.sku_master (product_code);

-- updated_at 자동 갱신
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists sku_master_set_updated_at on public.sku_master;
create trigger sku_master_set_updated_at
  before update on public.sku_master
  for each row execute function public.set_updated_at();

-- RLS: 읽기는 공개(anon), 쓰기는 로그인 사용자/service_role 만
alter table public.sku_master enable row level security;

drop policy if exists "sku_master read" on public.sku_master;
create policy "sku_master read" on public.sku_master
  for select to anon, authenticated using (true);

drop policy if exists "sku_master write" on public.sku_master;
create policy "sku_master write" on public.sku_master
  for all to authenticated using (true) with check (true);

-- 초기 데이터: 현재 대시보드에 임베드된 14종 (판매가 0 = 미정)
insert into public.sku_master (sku_id, product_name, product_code, sale_price, label, sort_order) values
  ('RJPDCR22A-10', '(1개입) PDRN 리쥬비네이팅 크림 30ml', 'PDRN', 45000, 'PDRN 크림 30ml', 0),
  ('RJPDCR22A-07', '(1개입) PDRN 리쥬비네이팅 크림 60ml', 'PDRN 60', 0, 'PDRN 크림 60ml', 10),
  ('RJPDLP22A-03', '(1개입) PDRN 리쥬비네이팅 립세럼 10ml', 'LIP', 16000, 'PDRN 립세럼', 20),
  ('RJPDMK22F-01', '(6매) PDRN 리쥬비네이팅 마스크 36ml', 'MASK', 29000, 'PDRN 마스크 6P', 30),
  ('RJCMCR22A-01', '(1개입) 엘씨 세라마이드 베리어 크림 90ml', 'CERAMIDE', 39000, '세라마이드 크림', 40),
  ('RJPLCR22A-01', '(1개입) PDLLA 퍼밍 크림', 'PDLLA', 45000, 'PDLLA 퍼밍크림', 60),
  ('RJRTSR22A-01', '(1개입) 레티노 멜라 세럼 50ml', 'Mela Cream', 48000, '레티노멜라 세럼', 70),
  ('RJRTCR22A-01', '(1개입) 레티노 멜라 톤 크림', 'Mela Cream', 28000, '레티노멜라 톤크림', 70),
  ('RJCOSD92F-01', '리쥬올 어드밴스드 스킨케어 프로그램 세트', 'GIFT', 132000, '기프트세트 6P', 80),
  ('RJPDSR22A-03', '(1개입) PDRN 카밍 선 세럼 50ml', 'Sun Serum', 25000, 'PDRN 카밍선세럼', 90),
  ('RJPDSR22A-01', '(1개입) PDRN 헤어 덴시티 스칼프 세럼 15ml', 'Hair Scalp', 25000, 'PDRN 헤어세럼', 100),
  ('RJPDSR22A-02', '(1개입) PDRN 코퍼 펩타이드 세럼 30ml', 'Peptide', 0, 'PDRN 코퍼세럼', 110),
  ('RJPDST22C-01', 'PDRN 시그니처 세트', 'Korean', 0, 'PDRN 시그니처세트', 120),
  ('RJCOST99C-01', 'PDRN 파우치 3종 5ml', 'ETC', 0, '트라이얼 키트 3P', 140)
on conflict (sku_id) do update set
  product_name = excluded.product_name,
  product_code = excluded.product_code,
  sale_price   = excluded.sale_price,
  label        = excluded.label,
  sort_order   = excluded.sort_order;
