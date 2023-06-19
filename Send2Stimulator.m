function outstr=Send2Stimulator(port,instr)
%SEND2STIMULATOR  Send message to stimulator and return formatted response message.

arguments
    port (1,1) tcpclient
    instr {mustBeTextScalar}
end

if(port.BytesAvailable>0)
    read(port); %empties the buffer
end
write(port,uint8(sprintf('%s\r',instr)));
fprintf('Send= %s\t\t',instr);  %display send strring
c=0;
while(port.BytesAvailable<1)
    c=c+1;
    pause(0.00001);
end
rplyStr=read(port,port.BytesAvailable,'char');

rplyStr=erase(rplyStr,char(13));   % remove charriage returns
rplyStr=strrep(rplyStr,newline,'~'); %replace line feeds with ~
rplyStr=strrep(rplyStr,'~~','~');
if contains(rplyStr,'*')
    rplyStr=rplyStr(1:strfind(rplyStr,'*'));
end
if(contains(rplyStr,'Bad','IgnoreCase',true) || contains(rplyStr,'?','IgnoreCase',true) )
    fprintf(2,'  %i Reply= %s \n', c,rplyStr);  %display reply
else
    fprintf('  %i Reply= %s \n', c,rplyStr);  %display reply
end
outstr=rplyStr;
end