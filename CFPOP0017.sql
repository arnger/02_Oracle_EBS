REM $Header: SLTPOP0017.sql 120.1 2016/02/05 10:00:00 Lawrence.Chen noship $
/*
*Description : PR Transfer to RFQ
*Parameters : 
*           1 - Org Id <OU>
*           2 - Requisition Number
*Author : Lawrence Chen
*/

WHENEVER SQLERROR EXIT FAILURE ROLLBACK;
WHENEVER OSERROR EXIT FAILURE ROLLBACK; 

declare
  l_return_status       VARCHAR2(1);
  l_msg_count           NUMBER;
  l_msg_data            VARCHAR2(2000);
  x_document_id         number := null;
  x_num_lines_processed number;
  l_document_number     PO_HEADERS_ALL.segment1%TYPE;

  l_poh_iface_rec   po_headers_interface%rowtype;
  l_pol_iface_rec   po_lines_interface%rowtype;
  l_iface_header_id number;
  l_iface_line_id   number;
  v_auth_status     varchar2(25);
  l_req_header_id   number;

  p_org_id  number;
  p_req_num varchar2(20);

  cursor pr_headers_cursor(l_org_id in number, l_req_header_id in number) is
    select *
      from po_requisition_headers_all
     where org_id = l_org_id
       and requisition_header_id = l_req_header_id;

  cursor pr_lines_cursor(l_org_id in number, l_req_header_id in number) is
    select *
      from po_requisition_lines_all
     where org_id = l_org_id
       and requisition_header_id = l_req_header_id;

begin
  p_req_num := '&&2';
  p_org_id  := '&&1';

  fnd_file.put_line(fnd_file.LOG,'Input Req No. = ' || p_req_num);
  fnd_file.put_line(fnd_file.log,'Input Org id = ' || p_org_id);

  select upper(authorization_status), requisition_header_id
    into v_auth_status, l_req_header_id
    from po_requisition_headers_all
   where segment1 = p_req_num
     and org_id = p_org_id;

  if (v_auth_status <> 'APPROVED') then
    return;
  end if;

  dbms_output.put_line('PR Authorization Status = ' || v_auth_status ||
                       chr(13) || chr(10) || '  Next step doing ...');

  begin
  
    for pr_header in pr_headers_cursor(p_org_id, l_req_header_id) loop
    
      select po_headers_interface_s.nextval
        into l_iface_header_id
        from dual;
    
      l_poh_iface_rec.interface_header_id   := l_iface_header_id;
      l_poh_iface_rec.interface_source_code := 'PO';
      l_poh_iface_rec.batch_id              := l_iface_header_id;
      l_poh_iface_rec.process_code          := 'NEW';
      l_poh_iface_rec.action                := 'NEW';
      l_poh_iface_rec.document_type_code    := 'RFQ';
      l_poh_iface_rec.document_subtype      := 'STANDARD';
      l_poh_iface_rec.document_num          := null;
      l_poh_iface_rec.group_code            := 'DEFAULT';
      l_poh_iface_rec.vendor_id             := null;
      l_poh_iface_rec.vendor_site_id        := null;
      l_poh_iface_rec.release_num           := null;
      l_poh_iface_rec.release_date          := null;
      l_poh_iface_rec.agent_id              := pr_header.preparer_id;
      l_poh_iface_rec.vendor_list_header_id := null;
      l_poh_iface_rec.pcard_id              := null;
      l_poh_iface_rec.creation_date         := sysdate;
      l_poh_iface_rec.created_by            := FND_Global.USER_ID;
      l_poh_iface_rec.last_update_date      := sysdate;
      l_poh_iface_rec.last_updated_by       := FND_Global.USER_ID;
      l_poh_iface_rec.org_id                := pr_header.org_id;
      l_poh_iface_rec.style_id              := 1;
    
      for pr_line in pr_lines_cursor(p_org_id, l_req_header_id) loop
        select po_lines_interface_s.nextval into l_iface_line_id from dual;
      
        l_pol_iface_rec.interface_header_id := l_iface_header_id;
        l_pol_iface_rec.interface_line_id   := l_iface_line_id;
        l_pol_iface_rec.action              := null;
        l_pol_iface_rec.line_num            := pr_line.line_num;
        l_pol_iface_rec.shipment_num        := null;
        l_pol_iface_rec.requisition_line_id := pr_line.requisition_line_id;
        l_pol_iface_rec.creation_date       := sysdate;
        l_pol_iface_rec.created_by          := FND_Global.USER_ID;
        l_pol_iface_rec.from_header_id      := null;
        l_pol_iface_rec.from_line_id        := null;
        l_pol_iface_rec.consigned_flag      := 'N';
        l_pol_iface_rec.contract_id         := null;
        l_pol_iface_rec.last_update_date    := sysdate;
        l_pol_iface_rec.last_updated_by     := FND_Global.USER_ID;
      
        l_poh_iface_rec.currency_code  := nvl(pr_line.currency_code, 'NTD');
        l_poh_iface_rec.rate_type_code := pr_line.rate_type;
        l_poh_iface_rec.rate_date      := pr_line.rate_date;
        l_poh_iface_rec.rate           := pr_line.rate;
        insert into po_lines_interface values l_pol_iface_rec;
      
      end loop;
      insert into po_headers_interface values l_poh_iface_rec;
    end loop;
  
    PO_INTERFACE_S.create_documents(p_api_version              => 1.0,
                                    x_return_status            => l_return_status,
                                    x_msg_count                => l_msg_count,
                                    x_msg_data                 => l_msg_data,
                                    p_batch_id                 => to_number(l_iface_header_id),
                                    p_req_operating_unit_id    => p_org_id,
                                    p_purch_operating_unit_id  => p_org_id,
                                    x_document_id              => x_document_id,
                                    x_number_lines             => x_num_lines_processed,
                                    x_document_number          => l_document_number,
                                    p_document_creation_method => 'AUTOCREATE', -- <DBI FPJ>
                                    p_orig_org_id              => p_org_id --<R12 MOAC>
                                    );
   if l_return_status = 'S' then
     commit;
   else
     rollback;
   end if;                                    
  
  exception
    when others then
      fnd_file.put_line(fnd_file.log,'Exception Msg = ' || sqlerrm);
      raise;
  end;

  fnd_file.put_line(fnd_file.log,'1:Return Status = ' || l_return_status);
  fnd_file.put_line(fnd_file.log,'2:Msg Count = ' || l_msg_count);
  fnd_file.put_line(fnd_file.log,'3:Msg Data = ' || l_msg_data);
  fnd_file.put_line(fnd_file.log,'4:Document Id = ' || x_document_id);
  fnd_file.put_line(fnd_file.log,'5:Num lines processed = ' || x_num_lines_processed);
  fnd_file.put_line(fnd_file.log,'6:RFQ Document No. = ' || l_document_number);
  fnd_file.put_line(fnd_file.log,'==End of handled==');
end;
/
commit;
exit;

