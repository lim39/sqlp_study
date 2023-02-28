-- 왜 TFS(TABLE FULL SCAN) / INDEX (FULL/RANGE) SCAN 인가
-- 왜 INDEX FULL SCAN / INDEX RANGE SCAN인가
-- 왜 INDEX 로 (PK / X01) 이 선택됐는가
-- 왜 SORT가 발생해서 전체범위처리가 됐는가
-- 왜 옵티마이저모드를 변경한 것만으로도 index힌트를 사용한 실행계획과 동일한 실행계획을 갖는가
-- 왜 owner='SYS' 와 owner='APPQOSSYS'가 다른 실행결과를 갖는가

A-0    select /*+ 힌트없음 */    * from big_table X order by owner; -- Table Full Scan            [전체범위처리]   5.69s
 A-0-1 select /*+ index(X) */   * from big_table X order by owner; -- index full scan of pk(id)  [전체범위처리] 132.53s
 A-0-2 select /*+ FIRST_ROWS */ * from big_table X order by owner; -- index full scan of x01     [부분범위처리]   0.96s

A-1.   select /*+ 힌트없음    */ * from big_table X                         order by created; --Table Full Scan         [전체범위처리] 
 A-1-1 select /*+ index(X)   */ * from big_table X                         order by created; --Index Full Scan of pk   [전체범위처리]
 A-1-2 select /*+ FIRST_ROWS */ * from big_table X                         order by created; --Table Full Scan         [전체범위처리] 

A-2.   select /*+ 힌트없음    */ * from big_table X where owner='SYS'       order by created; --Table Full Scan         [전체범위처리] 
 A-2-1.select /*+ index(X)   */ * from big_table X where owner='SYS'       order by created; --Index Full Scan of pk   [전체범위처리] 
 A-2-2.select /*+ FIRST_ROWS */ * from big_table X where owner='SYS'       order by created; --Index RangeScan of x01  [부분범위처리]

A-3.   select /*+ 힌트없음    */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]
 A-3-1.select /*+ index(X)   */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]
 A-3-2.select /*+ FIRST_ROWS */ * from big_table X where owner='APPQOSSYS' order by created; --Index RangeScan of x01 [부분범위처리]

B-1.   select /*+  힌트없음    */ * from big_table X                        order by id;     -- Index Full Scan of pk   [부분범위처리] 
 B-1-1.select /*+  index(X)   */ * from big_table X                        order by id;     -- Index Full Scan of pk    [부분범위처리]
 B-1-2.select /*+  FIRST_ROWS */ * from big_table X                        order by id;     -- Index Full Scan of pk    [부분범위처리]
 B-1-3.select /*+  index(X x01) */ * from big_table X                      order by id;     -- Index Full Scan of pk    [전체범위처리]

B-2.   select /*+  힌트없음    */ * from big_table X where owner = 'SYS'    order by id;     -- Index Full Scan of pk    [부분범위처리]
 B-2-1.select /*+  index(X)   */ * from big_table X where owner = 'SYS'    order by id;     -- Index Full Scan of pk    [부분범위처리]
 B-2-2.select /*+  FIRST_ROWS */ * from  big_table X where owner = 'SYS'   order by id;     -- Index Full Scan of pk    [부분범위처리]

(23.02.24추가) -- 성능고도화2권 p.368
A-4.   select /*+ 힌트없음    */ * from big_table X order by owner, created;  --Table Full Scan         [전체범위처리] 
 A-4-1.select /*+ FIRST_ROWS  */ * from big_table X order by owner, created; -- Index Full Scan of x01  [부분범위처리]


 --컬럼 정보
 select * from DBA_TAB_COLUMNS;