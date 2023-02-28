-- https://cafe.naver.com/dbian/61
-- Shared Pool의 Library Cache에 저장된 LiteralSQL (바인딩SQL은 해당안됨)
-- 맨 처음에 실행시 SQL 실행한게 없다면 비어있음
select *
from (
  select parsing_schema_name, sql_id, sql_text, executions
       , sum(executions) over (partition by force_matching_signature ) executions_sum
       , row_number() over (partition by force_matching_signature order by sql_id desc) rnum
       , count(*) over (partition by force_matching_signature ) cnt
       , force_matching_signature
  from   gv$sqlarea s
  where  force_matching_signature != 0
)
where  cnt > 5
--and    rnum = 1
order by cnt desc, sql_text

---------------------
-- SQL 조회
---------------------
-- Shared Pool의 Library Cache에 저장된 바인딩SQL
-- 처음 실행시는 없는게 정상 이후 밑에서 sql 실행시킨 후 sql확인가능

select sql_text, parse_calls, loads, executions, fetches 
from   v$sql
where  parsing_schema_name = USER
and    sql_text like '%test1%'
and    sql_text not like '%v$sql%'
and    sql_text not like 'declare%' ;

---------------------
--하드파싱부하 실습
---------------------
--3-1)
drop table t1 purge;
drop table t2 purge;
drop table t3 purge;
drop table t4 purge;
drop table t5 purge;

-- 테이블 생성
create table t1 ( a number, b varchar2(100) );
create table t2 ( a number, b varchar2(100) );
create table t3 ( a number, b varchar2(100) );
create table t4 ( a number, b varchar2(100) );
create table t5 ( a number, b varchar2(100) );

set timing on

-- (라이브러리 + 딕셔너리) 캐시 비우기 
alter system flush shared_pool;

-- 조인 순서 지정
declare
  l_cnt number;
begin
  for i in 1..10000
  loop
    execute immediate ' select /*+ ordered */ count(*)' ||
                      ' from t1, t2, t3, t4, t5 ' ||
                      ' where  t1.a = ' || i ||
                      ' and    t2.a = ' || i ||
                      ' and    t3.a = ' || i ||
                      ' and    t4.a = ' || i ||
                      ' and    t5.a = ' || i into l_cnt;
  end loop;
end;


alter system flush shared_pool;

-- 조인 순서 미지정
declare
  l_cnt number;
begin
  for i in 1..10000
  loop
    execute immediate ' select count(*)' ||
                      ' from t1, t2, t3, t4, t5 ' ||
                      ' where  t1.a = ' || i ||
                      ' and    t2.a = ' || i ||
                      ' and    t3.a = ' || i ||
                      ' and    t4.a = ' || i ||
                      ' and    t5.a = ' || i into l_cnt;
  end loop;
end;






--3-2)
drop table t ;

create table t
as
select * from all_objects;

insert into t 
select * from t;

update t set object_id = rownum;

create unique index t_idx on t(object_id);

exec dbms_stats.gather_table_stats(user, 't');

alter system flush shared_pool;

set timing on;

-- 테스트 1 : 바인드 변수 사용
declare
  type rc is ref cursor;
  l_rc rc;
  l_object_name t.object_name%type;
begin
  for i in 1..100000
  loop
    open l_rc for
      'select /* test1 */ object_name
       from   t
       where  object_id = :x' using i;
    fetch l_rc into l_object_name;
    close l_rc;
  end loop;
end;
/

select sql_text, parse_calls, loads, executions, fetches 
from   v$sql
where  parsing_schema_name = USER
and    sql_text like '%test1%'
and    sql_text not like '%v$sql%'
and    sql_text not like 'declare%' ;


-- 테스트 2 : 리터럴 SQL 사용 
declare
  type rc is ref cursor;
  l_rc rc;
  l_object_name t.object_name%type;
begin
  for i in 1..100000
  loop
    open l_rc for
      'select /* test2 */ object_name
       from   t
       where  object_id = ' || i;
    fetch l_rc into l_object_name;
    close l_rc;
  end loop;
end;
/

select sql_text, parse_calls, loads, executions, fetches
from   v$sql
where  parsing_schema_name = USER
and    sql_text like '%test2%'
and    sql_text not like '%v$sql%'
and    sql_text not like 'declare%'
order by 1 ;
