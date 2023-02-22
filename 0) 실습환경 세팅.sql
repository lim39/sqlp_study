create table BIG_TABLE
(
	id NUMBER GENERATED ALWAYS as IDENTITY(START with 1 INCREMENT by 1),
	owner varchar2(255) not null,
	object_name varchar2(255) ,
	created DATE not null
);

select * from BIG_TABLE where ROWNUM<=100;

alter table BIG_TABLE add constraint big_table_pk primary key (id);

--데이터 생성및 부풀리기(1000만건 될 때까지 여러번 실행)
insert into BIG_TABLE (owner, object_name, created) 
select owner, object_name, created FROM all_objects order by dbms_random.value;

--100만건짜리 테이블 생성
insert into BIG_TABLE2 (owner, object_name, created) 
select owner, object_name, created FROM all_objects order by dbms_random.value;

--중간중간 갯수세어보세요
select count(*) from BIG_TABLE;

create index x01 on BIG_TABLE(owner, created);
create index x001 on BIG_TABLE2(owner, created);
--x01이라는 인덱스명 존재하여, 지우고 다시 생성
--drop index x01;

-- 통계정보 수집
begin
  dbms_stats.gather_table_stats
  ( ownname          => USER
  , tabname          => 'BIG_TABLE'
  , estimate_percent => 100
  , block_sample     => true
  , method_opt       => 'for all columns size auto'
  );
end;

begin
  dbms_stats.gather_table_stats
  ( ownname          => USER
  , tabname          => 'BIG_TABLE2'
  , estimate_percent => 100
  , block_sample     => true
  , method_opt       => 'for all columns size auto'
  );
end;


select table_name, num_rows, last_analyzed from user_tables where table_name = 'BIG_TABLE'; -- 통계정보 수집여부

-- 실행계획이랑 SQL트레이스 확인해보기
SELECT /*+ gather_plan_statistics */ * from big_table where owner='APPQOSSYS';
SELECT * FROM table(dbms_xplan.display_cursor(null, null, 'allstats last'));

-- 클러스터링팩터 조회쿼리
t