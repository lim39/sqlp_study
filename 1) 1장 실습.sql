create table EMP(
empno int,
ename varchar(30),
job varchar(30),
deptno int);

create table dept(
deptno int,
dname varchar(30),
loc varchar(50)
);

--truncate table emp;
insert into emp
select 7369,'SMITH','CLERK',20 from dual
union all
select 7499,'ALLEN','SALESMAN',30 from dual
union all
select 7521,'WARD','SALESMAN',30 from dual
union all
select 7566,'JONES','MANAGER',20 from dual
union all
select 7654,'MARTIN','SALESMAN',30 from dual
union all
select 7698,'BLAKE','MANAGER',30 from dual
union all
select 7782,'CLARK','MANAGER',10 from dual
union all
select 7788,'SCOTT','ANALYST',20 from dual
union all
select 7839,'KING','PRESIDENT',10 from dual
union all
select 7844,'TURNER','SALESMAN',30 from dual
union all
select 7876,'ADAMS','CLERK',20 from dual
union all
select 7900,'JAMES','CLERK',30 from dual
union all
select 7902,'FORD','ANALYST',20 from dual
union all
select 7934,'MILLER','CLERK',10 from dual;


insert into dept
select 10,'ACCOUNTING','NEW YORK' from dual
union ALL
select 20, 'RESEARCH','DALLAS' from dual
union all
select 30, 'SALES','CHICAGO' from dual
union all 
select 40, 'OPERATIONS','BOSTON' from dual;


select * from emp;
select * from dept;

--p18) emp (join) dept 
select e.empno, e.ename, e.job, d.dname, d.loc
from emp e, dept d
where e.deptno= d.deptno
order by e.ename;

--p21) test용 테이블 생성
create table t as 
select d.no,e.*
from emp e ,(select rownum no from dual connect by level <= 1000) d;

select * from t;

--p22) create index on t
create index t_x01 on t(deptno,no);
create index t_x02 on t(deptno,job,no);

--p22) 방금 생성한 t테이블의 통계정보를 수집하는 쿼리문
--sqlplus에선 실행되는데, 다른 쿼리 툴에선 실행되지 않음;;
--sqlplus에서 실행 시 PL/SQL 처리가 정상적으로 완료되었습니다. 라고 뜸
exec dbms_stats.gather_table_stats(system ,'t');
set autotrace tracenoly exp;
--위 두 줄은 sqlplus용인듯 , 쿼리박스에선 ctrl+e 로 autotrace 확인 가능
--autotrace 실행 후 실행 계획 --> Text Plan 탭 클릭하면 동일한 결과 확인 가능

--옵티마이저가 인덱스 t_x01을 선택하여 실행 > 성능이 가장 좋다고 판단했기 때문
select * from t
where deptno=10 
and no=1;

-- 힌트 추가하여 실행
--cost 늘어남
select /*+ index(t t_x02) */ * from t
where deptno=10 
and no=1;

--cost 더더 늘어남
--책에선 cost 29라고 나오는데 왜인지?
select /*+ full(t) */ * from t
where deptno=10 
and no=1;

--p24) 옵티마이저 힌트
select /*+ index(a 고객_pk) */
	고객명, 연락처, 주소, 가입일시
from 고객 A
where 고객ID = '000000008';

--힌트 안에 인자를 나열할 땐 콤마를 사용할 수 있지만, 힌트와 힌트 사이에 사용하면 안됨!!!
--예시)
-- /*+ INDEX(A A_X01) INDEX(B B_X03) */ ->모두 유효
-- /*+ INDEX(C), FULL(D) */ -> 첫 번째 힌트만 유효

--테이블명을 지정할 땐 스키마명까지 명시하면 안됨. 무효처리
--예시)
--SELECT /*+ FULL(SCOTT.EMP) */ ->무효

--FROM 테이블명 별칭* 을 지정했다면, 힌트에도 별칭으로 사용해야 함
--예시)
--SELECT /*+ FULL(EMP) */ -> 무효
--FROM EMP E
--SELECT /*+ FULL(E) */ -> 유효
--FROM EMP E

--주문일자 컬럼이 선두인 인덱스를 사용하도록 힌트로 지정하고, 조인 방식과 순서, 고객 테이블 액세스 방식은 옵티마이저가 알아서 판단하도록 남겨둠
SELECT /*+ INDEX(A (주문일자)) */
	A.주문번호, A.주문금액, B.고객명, B.연락처, B.주소
FROM 주문 A, 고객 B
WHERE A.주문일자= :ORD_DT
	AND A.고객ID = B.고객ID
	
--옵티마이저가 절대 선택하지 못하게, 힌트를 빈틈없이 지정
SELECT /*+ LEADING(A) USE_NL(B) INDEX(A (주문일자)) INDEX(B 고객_PK) */
	A.주문번호, A.주문금액, B.고객명, B.연락처, B.주소
FROM 주문 A, 고객 B
WHERE A.주문일자= :ORD_DT
	AND A.고객ID = B.고객ID
	
--!!! 어떤 방식이 옳은 지는 어플리케이션 환경에 따라 다름. 통계정보나 실행 환경 변화로 인해 옵티마이저가 가끔 실수하더라도 별문제가 없는 시스템이 있는가 하면, 
-- 옵티마이저의 작은 실수가 기업에 큰 손실을 끼치는 시스템이 있다.
-- 후자처럼 중대한 시스템이라면, 가끔 실수가 있더라도 옵티마이저의 자율적 판단에 맡기자는 말을 감히 할 수가 없음
--!!!!!기왕 힌트를 쓸 거면 빈틈없이 기술해야 함 >>> 후자인 경우에만????


--P27~28)자주 사용하는 힌트 목록 참고


--P33)공유 가능 SQL 
--의미가 같아도 한글자만 다르게 작성하면, 캐시를 별도로 저장한다는 뜻?