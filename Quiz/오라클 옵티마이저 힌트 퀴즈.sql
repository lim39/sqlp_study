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

select table_name, num_rows, last_analyzed from user_tables where table_name = 'BIG_TABLE'; -- 통계정보 수집여부

-- 실행계획이랑 SQL트레이스 확인해보기
SELECT /*+ gather_plan_statistics */ * from big_table where owner='APPQOSSYS';
SELECT * FROM table(dbms_xplan.display_cursor(null, null, 'allstats last'));

-- 클러스터링팩터 조회쿼리
select INDEX_NAME, TABLE_NAME, CLUSTERING_FACTOR from dba_indexes where table_name = 'BIG_TABLE'; -- pk: 81,923  n1: 4,965,918

create index x01 on BIG_TABLE(owner, created);
drop index x01;

-- 왜 TFS(TABLE FULL SCAN) / INDEX (FULL/RANGE) SCAN 인가
-- 왜 INDEX FULL SCAN / INDEX RANGE SCAN인가
-- 왜 INDEX 로 (PK / X01) 이 선택됐는가
-- 왜 SORT가 발생해서 전체범위처리가 됐는가
-- 왜 옵티마이저모드를 변경한 것만으로도 index힌트를 사용한 실행계획과 동일한 실행계획을 갖는가
-- 왜 owner='SYS' 와 owner='APPQOSSYS'가 다른 실행결과를 갖는가

-- 인덱스 선두 컬럼: owner
-- 인덱스 후행 컬럼: created
-- 일반 컬럼(테이블 필터 조건): 

SELECT a.table_name 
     , a.index_name 
     , a.column_name 
  FROM all_ind_columns a 
 WHERE a.table_name = 'BIG_TABLE' 
 ORDER BY a.index_name
        , a.column_position;
        
        
        SELECT *
  FROM all_ind_columns a 
 WHERE a.index_name = 'x01' 
 ORDER BY a.index_name
        , a.column_position;
        
select count(*) from big_table;

select owner,count(*) as cnt from big_table group by owner;
--A-0
select /*+ 힌트없음 */    * from big_table X order by owner; -- Table Full Scan            [전체범위처리]   3.50s // 22K
select /*+ index(X) */   * from big_table X order by owner; -- index full scan of pk(id)  [전체범위처리] 132.53s // 20K
select /*+ FIRST_ROWS */ * from big_table X order by owner; -- index full scan of x01     [부분범위처리]   0.96s //33K  >> 부분범위 처리 조건에 
select /*+ FIRST_ROWS index(X x01) */ * from big_table X ;

--A-1
select /*+ 힌트없음    */ * from big_table X order by created; --Table Full Scan         [전체범위처리] // 22K
select /*+ index(X)   */ * from big_table X order by created; --Index Full Scan of pk   [전체범위처리] // 20K
select /*+ FIRST_ROWS */ * from big_table X order by created; --Table Full Scan         [전체범위처리] // 22K

--A-2
select /*+ 힌트없음    */ * from big_table X where owner='SYS' order by created; --Table Full Scan         [전체범위처리] 
select /*+ index(X)   */ * from big_table X where owner='SYS' order by created; --Index Full Scan of pk   [전체범위처리] 
select /*+ FIRST_ROWS */ * from big_table X where owner='SYS' order by created; --Index RangeScan of x01  [부분범위처리]

--A-3
select /*+ 힌트없음    */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]
select /*+ index(X)   */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]
select /*+ FIRST_ROWS */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]

--A-4
select /*+  힌트없음    */ * from big_table X order by id;     -- Index Full Scan of pk   [부분범위처리] 
select /*+  index(X)   */ * from big_table X order by id;     -- Index Full Scan of pk    [부분범위처리]
select /*+  FIRST_ROWS */ * from big_table X order by id;     -- Index Full Scan of pk    [부분범위처리]
select /*+  index(X x01) */ * from big_table X order by id;     -- Index Full Scan of pk    [전체범위처리]
--A-5
select /*+  힌트없음    */ * from big_table X where owner = 'SYS'    order by id;     -- Index Full Scan of pk    [부분범위처리]
select /*+  index(X)   */ * from big_table X where owner = 'SYS'    order by id;     -- Index Full Scan of pk    [부분범위처리]
select /*+  FIRST_ROWS */ * from  big_table X where owner = 'SYS'   order by id;     -- Index Full Scan of pk    [부분범위처리]

-- 성능고도화2권 p.368
select /*+ 힌트없음    */ * from big_table X order by owner, created;  --Table Full Scan         [전체범위처리] 
select /*+ FIRST_ROWS  */ * from big_table X order by owner, created; -- Index Full Scan of x01  [부분범위처리]