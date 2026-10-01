-- 회원 RAW 테이블 (자사몰 회원 내보내기 CSV 업로드용)
-- 실행: Supabase Dashboard > SQL Editor 에 붙여넣고 Run
-- 업로드: Table Editor > b2c_member_raw > Import data from CSV > uploads/b2c_member_raw_YYYYMMDD.csv (영문 헤더 변환본)

create table if not exists public.b2c_member_raw (
  member_id         text primary key,          -- 아이디
  name              text,                      -- 이름
  grade             text,                      -- 회원등급
  age               smallint,                  -- 나이
  email             text,                      -- 이메일
  phone             text,                      -- 휴대폰번호 (010-0000-0000)
  points_used       numeric(12,2) default 0,   -- 총 사용 적립금
  points_available  numeric(12,2) default 0,   -- 사용가능 적립금
  joined_at         date,                      -- 회원 가입일
  dormant_at        date,                      -- 휴면처리일
  withdrawn_at      date,                      -- 탈퇴일
  withdrawal_type   text,                      -- 탈퇴구분
  withdrawal_reason text,                      -- 탈퇴사유
  imported_at       timestamptz not null default now()
);

comment on table  public.b2c_member_raw is '자사몰 회원 RAW (CSV 업로드 원본)';
comment on column public.b2c_member_raw.member_id         is '아이디';
comment on column public.b2c_member_raw.name              is '이름';
comment on column public.b2c_member_raw.grade             is '회원등급';
comment on column public.b2c_member_raw.age               is '나이';
comment on column public.b2c_member_raw.email             is '이메일';
comment on column public.b2c_member_raw.phone             is '휴대폰번호';
comment on column public.b2c_member_raw.points_used       is '총 사용 적립금';
comment on column public.b2c_member_raw.points_available  is '사용가능 적립금';
comment on column public.b2c_member_raw.joined_at         is '회원 가입일';
comment on column public.b2c_member_raw.dormant_at        is '휴면처리일';
comment on column public.b2c_member_raw.withdrawn_at      is '탈퇴일';
comment on column public.b2c_member_raw.withdrawal_type   is '탈퇴구분';
comment on column public.b2c_member_raw.withdrawal_reason is '탈퇴사유';

create index if not exists b2c_member_raw_joined_at_idx on public.b2c_member_raw (joined_at);
create index if not exists b2c_member_raw_email_idx     on public.b2c_member_raw (email);

-- 개인정보(이름·이메일·휴대폰) 포함: RLS 켜고 공개 읽기 정책은 만들지 않음 (service_role 전용)
alter table public.b2c_member_raw enable row level security;

-- 재업로드 전 초기화가 필요할 때만 실행
-- truncate table public.b2c_member_raw;
