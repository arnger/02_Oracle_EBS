create or replace package slt_utils_pkg is

  -- Author  : LAWRENCE_CHEN
  -- Created : 2016/7/19 PM 02:56:32
  -- Purpose : Common Utils

  function rightStrNum(str varchar2, seperate char, numLength number)
    return varchar2;
    
  function leftStrNum(str varchar2, seperate char, numLength number)
    return varchar2;

end slt_utils_pkg;
/
create or replace package body slt_utils_pkg is

  function rightStrNum(str varchar2, seperate char, numLength number)
    return varchar2 is
    rtn varchar2(30);
  begin
    select substr(str, length(str) - numLength + 1, numLength)
      into rtn
      from dual
     where regexp_like(str,
                       seperate || '[0-9]{' || to_char(numLength) || '}$');
    return(rtn);
  end;

  function leftStrNum(str varchar2, seperate char, numLength number)
    return varchar2 is
    rtn varchar2(30);
  begin
    select substr(str, 1, length(str) - numLength - 1)
      into rtn
      from dual
     where regexp_like(str,
                       seperate || '[0-9]{' || to_char(numLength) || '}$');
    return(rtn);
  end;

end slt_utils_pkg;
/
