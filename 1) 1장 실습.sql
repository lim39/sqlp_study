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



