unit uTicketLock;

interface
 uses windows;
 type
   TTicketLock = record
        OwnerThread : DWORD;
        NextTicketId    : integer;
        ServingTicketNo : integer;
        ReEnterCount : integer;
        procedure lock;
        procedure unlock;
        class function Create : TTicketLock; static;
   end;

implementation

{ TTicketLock }

class function TTicketLock.Create: TTicketLock;
begin
   result := default(TTicketLock);
end;

procedure TTicketLock.lock;
asm
     push esi
     mov  esi, eax
     call GetCurrentThreadId
     mov  ecx, eax   //save ecx = thread Id
     cmp  eax, [esi+TTicketLock.OwnerThread]
     je   @current_thread_branch
     xor  eax,eax
     inc  eax
LOCK xadd [esi+TTicketLock.NextTicketId],eax
@loop:
     cmp  eax, [esi+TTicketLock.ServingTicketNo]
     je   @on_get_ownership
     pause
     jmp  @loop
@on_get_ownership:
     mov  [esi+TTicketLock.OwnerThread], ecx
@current_thread_branch:
     inc  [esi+TTicketLock.ReEnterCount]
     pop esi
end;

procedure TTicketLock.unlock;
asm
     push  esi
     mov  esi, eax
     call GetCurrentThreadId
     cmp  eax, [esi+TTicketLock.OwnerThread]
     jnz  @return
     dec  [esi+TTicketLock.ReEnterCount]
     jnz  @return
     xor  eax,eax
     mov  [esi+TTicketLock.OwnerThread],eax
LOCK inc  [esi+TTicketLock.ServingTicketNo]
@return:
     pop  esi
end;


end.
