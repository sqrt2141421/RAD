local s={}
local enet=require("enet")
local bitser=require("bitser")
local host
function s.st_server(adress)
    host=enet.host_create(adress)
    return host
end
function s.st_client(adress)
    host=enet.host_create()
    local peer=host:connect(adress)
    return host,peer
end
function s.message(peer,type,data)
    local pack=bitser.dumps({type=type,data=data})
    peer:send(pack,0,"reliable")
end
function s.message_unr(peer,type,data)
    local pack=bitser.dumps({type=type,data=data})
    peer:send(pack,0,"unreliable")
end
function s.message_all(type,data)
    local pack=bitser.dumps({type=type,data=data})
    host:broadcast(pack,0,"reliable")
end
function s.event_collect(timeout)
    local data={}
    local event=host:service(timeout or 0) --вывод ошибки
    while event do
        if event.type=="receive" then
            local good,inp_data=pcall(bitser.loads,event.data)
            if good then data[#data+1]={action="receive",peer=event.peer,data=inp_data} end
        elseif event.type=="connect" then
            data[#data+1]={action="connect",peer=event.peer}
        elseif event.type=="disconnect" then
            data[#data+1]={action="disconnect",peer=event.peer}
        end
        event=host:check_events()
    end
    return data
end
return s