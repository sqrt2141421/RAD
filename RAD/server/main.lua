local pr=love.filesystem.getSourceBaseDirectory()
package.path=package.path..";"..pr.."/lib/?.lua"
local ch_s,err_s=loadfile(pr.."/lib/enet_1.lua")
local ch_d,err_d=loadfile(pr.."/server/data.lua")
if not (ch_s and ch_d) then error("ERROR LOAD MODULE:\n"..(err_s or"").."\n"..(err_d or"")) end
local s=ch_s()
local d=ch_d()
local adress=d.adress_servers[1]
local host=s.st_server(adress)
function love.load()
    love.window.close()
    CMD=love.thread.getChannel("cmd")
    THREAD_cmd=love.thread.newThread(d.cmd)
    THREAD_cmd:start()
    world={player_not_physic={},world={},chat_global={},next_id=1}
    px={};   py={}
    vpx={}; vpy={}
    apx={}; apy={}
    mass={}
    static={}
    chunk={}
    free_id={}
    d.init(world,px,py,vpx,vpy,apx,apy,mass,static,chunk,free_id)
    buffer={}
    idfp={}
    id_del={}
    acc_dt=0
    cmd_counter=1
    tick_counter=0
    print("Load Server complete\n|")
end
function love.update(dt)
    local COM=CMD:pop()
    if COM then
        local command,err=loadstring(COM)
        print("|")
        if command then
            local command_2,err_2=pcall(command)
            if command_2 then
            print("CMD complete: "..tostring(command_2).." | command conter: "..cmd_counter.."\n|")
            else
                print("CMD error: "..err_2.." | command counter: "..cmd_counter.."\n|")
            end
            cmd_counter=cmd_counter+1
        end
    end
    buffer[#buffer+1]=s.event_collect()
    acc_dt=acc_dt+dt
    if acc_dt>=0.05 then
        dt=0.05
        for _,events in ipairs(buffer) do
            for _,input in ipairs(events) do
                if input.action=="connect" then
                    local id=d.spawn_entity(1,100,100,"free")
                    local peer=input.peer
                    world.world[id]={type="player",peer=peer,nickname="unknown"}
                    idfp[input.peer:index()]=id
                    print("player connected.\nid: "..id.."\n|")
                elseif input.action=="disconnect" then
                    local peer_id=input.peer:index()
                    local id=idfp[peer_id]
                    if id then
                        d.delete(id)
                        idfp[peer_id]=nil
                        print("player disconnected.\nid: "..id.."\n|")
                    end
                elseif input.action=="receive" then
                    local id_player=idfp[input.peer:index()]
                    pack_size=#input.data.data
                    if pack_size>=500 then
                        print("error large packet\npack size: "..pack_size.."\n|")
                        goto continue
                    end
                    if id_player then
                        if input.data.type=="key_input" then
                            local d=input.data.data
                            local dx=0
                            local dy=0
                            if d[1]=="w" then dy=dy-1 end
                            if d[2]=="a" then dx=dx-1 end
                            if d[3]=="s" then dy=dy+1 end
                            if d[4]=="d" then dx=dx+1 end
                            local dir=d.normalized(dx,dy)
                            apx[id_player]=dir.ax*d.accel
                            apy[id_player]=dir.ay*d.accel
                        elseif input.data.type=="chat_client_all" then
                            local len_string=#input.data.data[1]
                                if len_string<=120 then
                                    local chat_input="player id: "..id_player.." say: "..input.data.data[1]
                                    world.chat_global[#world.chat_global+1]=chat_input
                                    print(chat_input.."\n|\nlen message: "..len_string.."\n|")
                                    s.message_all("chat_all",chat_input)
                                else
                                    print("error message, very big len.\nplayer id: "..id_player.."\n|")
                                end
                        elseif input.data.type=="my_id" then
                            s.message(input.peer,"your_id",{id_player})
                        elseif input.data.type=="my_nickname" then
                            if #input.data.data[1]<=40 then
                                world.world[id_player].nickname=tostring(input.data.data[1])
                            end
                        end
                    end
                end
                ::continue::
            end
        end
        local snapshot=d.physic(0.05)
        s.message_all("test_physic",{snapshot})
        acc_dt=acc_dt-0.05
        tick_counter=tick_counter+1
        buffer={}
    end
end